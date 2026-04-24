import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/send_notification.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/today_dashboard_response_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/vendor_model.dart';
import 'package:jippydriver_driver/services/audio_player_service.dart';
import 'package:jippydriver_driver/services/api_cache_service.dart';
import 'package:jippydriver_driver/services/order_workflow_service.dart';
import 'package:jippydriver_driver/services/http_client_service.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/perf_telemetry.dart';
import 'package:jippydriver_driver/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as location;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:typed_data';

// ---------------------------------------------------------------------------
//  Lightweight cancel token (kept for backward compat)
// ---------------------------------------------------------------------------
class CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
  void reset()  => _isCancelled = false;
}

// ---------------------------------------------------------------------------
//  HomeController
// ---------------------------------------------------------------------------
class HomeController extends GetxController {

  // ── UI toggle ─────────────────────────────────────────────────────────
  final RxBool arrowDrop = false.obs;
  void changeArrow() => arrowDrop.value = !arrowDrop.value;

  // ── Charge Rx fields ──────────────────────────────────────────────────
  // Written once when order loads. UI reads with Obx() — zero extra HTTP.
  final RxDouble driverToRestaurantDistance   = 0.0.obs;
  final RxDouble restaurantToCustomerDistance = 0.0.obs;
  final RxDouble driverToRestaurantDuration   = 0.0.obs;
  final RxDouble restaurantToCustomerDuration = 0.0.obs;
  final RxDouble driverToRestaurantCharge     = 0.0.obs;
  final RxDouble restaurantToCustomerCharge   = 0.0.obs;
  /// Whole km used for restaurant→customer **pricing** (nearest km: 2.4→2, 2.5→3).
  double _restaurantToCustomerBillableKm = 0;
  final RxDouble totalCalculatedCharge        = 0.0.obs;
  final RxDouble surgeFee                     = 0.0.obs;
  final RxDouble toPayAmount                  = 0.0.obs;
  final RxBool isNavigatingToMap              = false.obs;

  // Driver→restaurant (pickup) and restaurant→customer (delivery)
  // coefficients (fetched once and cached). Defaults are used immediately.
  double _pickupRsPerKm = 3.0;
  double _deliveryFirstSlabKm = 4.0;
  double _deliveryRsPerKmFirstSlab = 8.0;
  double _deliveryRsPerKmBeyond = 10.0;
  /// Restaurant→customer: from `driver-sql/charges` (`delivery_short_trip_*`).
  double _deliveryShortTripMaxKm = 2.0;
  double _deliveryShortTripBaseCharge = 21.0;

  double _pickupChargeFromKm(double km) {
    if (km <= 0) return 0;
    // Bill pickup by full started kilometer (ceil), at configured Rs/km.
    final billableKm = km.ceilToDouble();
    return (billableKm * _pickupRsPerKm).roundToDouble();
  }

  /// Nearest whole kilometer for restaurant→customer **charge only** (not driver→restaurant).
  /// Examples: 2.4 → 2, 2.49 → 2, 2.5 → 3, 2.6 → 3.
  ///
  /// Any **positive** leg still bills at least **1 km** so sub‑500m drops (e.g. 0.22 km)
  /// do not round to 0 and wipe the delivery fee (was showing `3.00 + 0.00`).
  double _billableRestaurantToCustomerKm(double rawKm) {
    if (rawKm <= 0) return 0;
    final rounded = rawKm.roundToDouble();
    return math.max(1.0, rounded);
  }

  /// Restaurant→customer delivery only. [billableKm] = nearest whole km from
  /// [_billableRestaurantToCustomerKm] (raw route is only for display/ETA).
  ///
  /// - **≤ [_deliveryShortTripMaxKm]** (e.g. 2 km): entire R→C leg is flat
  ///   **[_deliveryShortTripBaseCharge]** (no per‑km slab in that band).
  /// - **Above short‑trip max, ≤ [_deliveryFirstSlabKm]:** pro‑rata first slab,
  ///   with **minimum [_deliveryShortTripBaseCharge]** when short trip is enabled.
  /// - **Above [_deliveryFirstSlabKm]:** first slab block + beyond rate × ceil(extra km).
  double _restaurantToCustomerChargeFromBillableKm(double billableKm) {
    if (billableKm <= 0) return 0;
    // Short trip: R→C within max km (from API, e.g. 2) → fixed base for that leg only.
    if (_deliveryShortTripMaxKm > 0 && billableKm <= _deliveryShortTripMaxKm) {
      return _deliveryShortTripBaseCharge;
    }
    if (billableKm <= _deliveryFirstSlabKm) {
      final proRata =
          (billableKm * _deliveryRsPerKmFirstSlab).roundToDouble();
      final slab =
          math.max(_deliveryRsPerKmFirstSlab, proRata).toDouble();
      if (_deliveryShortTripMaxKm > 0) {
        return math.max(_deliveryShortTripBaseCharge, slab);
      }
      return slab;
    }
    final beyondKm = billableKm - _deliveryFirstSlabKm;
    final billableBeyondKm = beyondKm.ceil();
    final block = _deliveryFirstSlabKm * _deliveryRsPerKmFirstSlab +
        billableBeyondKm * _deliveryRsPerKmBeyond;
    return block.roundToDouble();
  }

  // ── Core observables ──────────────────────────────────────────────────
  final Rx<OrderModel> currentOrder = OrderModel().obs;
  final Rx<OrderModel> orderModel   = OrderModel().obs;
  final Rx<UserModel>  driverModel  = UserModel().obs;
  final RxBool isLoading = true.obs;
  final RxBool isChange  = false.obs;

  // ── Today dashboard (separate API) ─────────────────────────────────────
  final Rxn<TodayDashboardData> todayDashboard = Rxn<TodayDashboardData>();
  final RxBool todayDashboardLoading = false.obs;
  DateTime? _todayDashboardLastFetchAt;

  // Separate Rx for driver lat/lng — only the map marker widget rebuilds.
  final Rx<LatLng?> driverLatLng = Rx<LatLng?>(null);

  // ── Map ───────────────────────────────────────────────────────────────
  GoogleMapController? mapController;
  flutterMap.MapController osmMapController = flutterMap.MapController();

  final RxMap<PolylineId, Polyline> polyLines   = <PolylineId, Polyline>{}.obs;
  final RxMap<String, Marker>       markers     = <String, Marker>{}.obs;
  final RxList<flutterMap.Marker>   osmMarkers  = <flutterMap.Marker>[].obs;
  final RxList<location.LatLng>     routePoints = <location.LatLng>[].obs;

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;

  // ── Marker smooth animation ───────────────────────────────────────────
  LatLng? _markerAnimStart;
  LatLng? _markerAnimTarget;
  Timer?  _markerAnimTimer;
  static const Duration _markerAnimDuration = Duration(milliseconds: 300);
  static const int      _markerAnimSteps    = 10;

  // ── Camera follow ─────────────────────────────────────────────────────
  bool    hasInitialCameraSet = false;
  bool    _shouldFollowDriver = true;
  LatLng? _lastCameraPos;
  static const double _cameraFollowDistance = 10.0; // metres

  // ── Route cache ───────────────────────────────────────────────────────
  String?       _lastRouteCacheKey;
  List<LatLng>? _cachedPolyline;
  List<LatLng>? _cachedSimplified;
  DateTime?     _lastRouteCalcTime;
  LatLng?       _lastRouteOrigin;
  bool          _routeCallInFlight = false;

  static const Duration _routeCacheDuration  = Duration(minutes: 3);
  static const double   _routeRecalcDistance = 60.0;  // metres
  static const double   _coordPrecision      = 0.005;
  static const int      _maxDisplayPoints    = 80;

  // ── Polling ───────────────────────────────────────────────────────────
  Timer?   _pollTimer;
  bool     _isPolling     = false;
  bool     _isRefreshing  = false;
  Duration _pollInterval  = const Duration(seconds: 5);
  int      _noOrderCount  = 0;
  bool     _isAppForeground = true;
  bool     _isConnected     = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  String? _lastETag;
  String? _lastModified;

  // ── Status tracking ───────────────────────────────────────────────────
  String?   _lastKnownStatus;
  DateTime? _lastStatusChangeTime;
  static const Duration _statusCooldown = Duration(seconds: 5);

  // ── Completed-order guard ─────────────────────────────────────────────
  static const Duration _completedRetention = Duration(minutes: 5);
  final Map<String, DateTime> _recentlyCompleted = {};

  // ── Notification dedup ────────────────────────────────────────────────
  final Set<String> _notifiedOrderIds = {};
  final Map<String, DateTime> _recentlyHandledOrderMutes = {};
  static const Duration _handledOrderMuteTtl = Duration(seconds: 20);
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // ── Vendor cache ──────────────────────────────────────────────────────
  final Map<String, VendorModel> _vendorCache     = {};
  final Map<String, DateTime>    _vendorCacheTime = {};
  static const Duration _vendorCacheTTL = Duration(hours: 2);

  // ── OSM ───────────────────────────────────────────────────────────────
  bool _osmMapReady = false;
  void setOsmMapReady(bool v) => _osmMapReady = v;

  Rx<location.LatLng> source      = location.LatLng(0, 0).obs;
  Rx<location.LatLng> current     = location.LatLng(0, 0).obs;
  Rx<location.LatLng> destination = location.LatLng(0, 0).obs;

  // ── Debounce ──────────────────────────────────────────────────────────
  Timer? _changeDataDebounce;
  static const Duration _changeDataDelay = Duration(milliseconds: 150);

  // ── Misc guards ───────────────────────────────────────────────────────
  bool      _isAcceptingOrder     = false;
  bool      _isRejectingOrder    = false;

  /// True while [acceptOrder] is running — keeps offer UI from disappearing
  /// if [orderRequestData] clears before [inProgressOrderID] reflects accept.
  bool get isAcceptingOrder => _isAcceptingOrder;
  bool      _isCalculatingCharges = false;
  bool      _driverChargesWarmupInFlight = false;
  bool      _driverChargesApplied = false;
  DateTime? _driverChargesAppliedAt;
  bool      _hasCalculatedBaseCharges = false;
  bool      _driverChargesNeedsRecalc = false;
  Timer?    _chargesRecalcDebounce;
  DateTime? _lastGetOrderTime;
  static const Duration _minOrderInterval = Duration(seconds: 2);
  String?   _lastFetchedOrderId;
  /// Last order id for which [calculateOrderChargesInitial] finished successfully.
  String?   _chargesComputedForOrderId;

  // ── Polyline points ───────────────────────────────────────────────────
  Rx<PolylinePoints> polylinePoints =
      PolylinePoints(apiKey: Constant.mapAPIKey.isNotEmpty ? Constant.mapAPIKey : '').obs;

  void updatePolylinePoints() {
    polylinePoints.value =
        PolylinePoints(apiKey: Constant.mapAPIKey.isNotEmpty ? Constant.mapAPIKey : '');
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Lifecycle
  // ══════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    _getArguments();
    _setIcons();
    _initLocalNotifications();
    _initConnectivity();
    getDriver();
    // Warm up driver charges from cache (non-blocking).
    unawaited(_warmUpDriverCharges());
    // Lightweight call; cached. Keeps UI smooth and avoids heavy recompute.
    ensureTodayDashboardLoaded();
    _startPolling();
    super.onInit();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _changeDataDebounce?.cancel();
    _markerAnimTimer?.cancel();
    _chargesRecalcDebounce?.cancel();
    _connectivitySub?.cancel();
    _tryCleanupCache();
    super.onClose();
  }

  Future<void> _warmUpDriverCharges() async {
    if (_driverChargesWarmupInFlight || _driverChargesApplied) return;
    _driverChargesWarmupInFlight = true;
    try {
      // Force refresh once on warmup so stale cache does not keep old rates.
      final c = await FireStoreUtils.getDriverCharges(forceRefresh: true);

      double toDouble(dynamic v, double fallback) {
        if (v == null) return fallback;
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v.trim()) ?? fallback;
        return fallback;
      }

      final pickup = toDouble(c['pickup_rs_per_km'], _pickupRsPerKm);
      final deliveryFirstSlabKm =
          toDouble(c['delivery_first_slab_km'], _deliveryFirstSlabKm);
      final deliveryRsPerKmFirstSlab = toDouble(
          c['delivery_rs_per_km_first_slab'], _deliveryRsPerKmFirstSlab);
      final deliveryRsPerKmBeyond = toDouble(
          c['delivery_rs_per_km_beyond'], _deliveryRsPerKmBeyond);
      final shortTripMaxKm =
          toDouble(c['delivery_short_trip_max_km'], _deliveryShortTripMaxKm);
      final shortTripBaseCharge = toDouble(
          c['delivery_short_trip_base_charge'], _deliveryShortTripBaseCharge);

      AppLogger.log(
        'Driver charges warmup fetched: '
        'pickup=$pickup '
        'firstSlabKm=$deliveryFirstSlabKm '
        'firstSlabRate=$deliveryRsPerKmFirstSlab '
        'beyondRate=$deliveryRsPerKmBeyond '
        'shortTrip≤${shortTripMaxKm}km=flat₹$shortTripBaseCharge',
        tag: 'Charges',
      );

      if (pickup == 3.0 &&
          deliveryFirstSlabKm == 4.0 &&
          deliveryRsPerKmFirstSlab == 8.0 &&
          deliveryRsPerKmBeyond == 10.0 &&
          shortTripMaxKm == 2.0 &&
          shortTripBaseCharge == 21.0) {
        AppLogger.log(
          'Driver charges are at fallback defaults (3/4/8/10, short 2km/21). '
          'If this is unexpected, verify driver-sql/charges API payload.',
          tag: 'Charges',
        );
      }

      final changed = pickup != _pickupRsPerKm ||
          deliveryFirstSlabKm != _deliveryFirstSlabKm ||
          deliveryRsPerKmFirstSlab != _deliveryRsPerKmFirstSlab ||
          deliveryRsPerKmBeyond != _deliveryRsPerKmBeyond ||
          shortTripMaxKm != _deliveryShortTripMaxKm ||
          shortTripBaseCharge != _deliveryShortTripBaseCharge;

      _pickupRsPerKm = pickup;
      _deliveryFirstSlabKm = deliveryFirstSlabKm;
      _deliveryRsPerKmFirstSlab = deliveryRsPerKmFirstSlab;
      _deliveryRsPerKmBeyond = deliveryRsPerKmBeyond;
      _deliveryShortTripMaxKm = shortTripMaxKm;
      _deliveryShortTripBaseCharge = shortTripBaseCharge;

      _driverChargesApplied = true;
      _driverChargesAppliedAt = DateTime.now();

      // If we already calculated base charges for the current order,
      // re-calc locally using the new coefficients (no surge/to-pay network).
      //
      // If a charge calculation is currently in-flight, wait briefly (max 4s)
      // so the base UI updates with the new coefficients.
      if (changed &&
          currentOrder.value.id != null &&
          currentOrder.value.vendor != null) {
        // If we're currently calculating (likely waiting on surge/to-pay),
        // request a follow-up recalculation once that finishes.
        if (_isCalculatingCharges) {
          _driverChargesNeedsRecalc = true;
        } else {
          await calculateOrderChargesInitial(fetchSurgeAndToPay: false);
          _updateOrderWithCharges();
          currentOrder.refresh();
        }
      }
    } catch (e) {
      AppLogger.log('Driver charges warmup failed: $e', tag: 'Charges');
    } finally {
      _driverChargesWarmupInFlight = false;
    }
  }

  /// Ensures dashboard data is available without spamming the API.
  /// Called from `onInit()` and can also be triggered lazily from the widget.
  void ensureTodayDashboardLoaded() {
    final last = _todayDashboardLastFetchAt;
    if (todayDashboardLoading.value) return;
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 20)) {
      return;
    }
    fetchTodayDashboard();
  }

  Future<void> fetchTodayDashboard({bool forceRefresh = false}) async {
    // Prefer the freshly fetched driver profile id; fall back to session user model.
    final driverId = (driverModel.value.id?.toString().trim().isNotEmpty ?? false)
        ? driverModel.value.id!.toString().trim()
        : (Constant.userModel?.id?.toString().trim() ?? '');
    if (driverId.isEmpty) return;

    todayDashboardLoading.value = true;
    try {
      final url = Uri.parse('${Constant.baseUrl}driver/dashboard/today?driver_id=$driverId');
      final httpClient = HttpClientService();
      final response = await httpClient.get(
        url,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        cacheStrategy: CacheStrategy.custom,
        customTTL: const Duration(seconds: 20),
        useCache: true,
        forceRefresh: forceRefresh,
        timeout: const Duration(seconds: 12),
        enableRetry: true,
      );

      if (response.statusCode == 200) {
        if (response.body.startsWith('<')) {
          AppLogger.log('Today dashboard response looks like HTML (wrong endpoint/auth?): ${response.body}', tag: 'API');
          return;
        }
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          final parsed = TodayDashboardResponse.fromJson(raw);
          if (parsed.success) {
            todayDashboard.value = parsed.data;
            todayDashboard.refresh(); // ensure Obx rebuild even if data is identical
            _todayDashboardLastFetchAt = DateTime.now();
            AppLogger.log(
              '✅ Today dashboard loaded: orders=${parsed.data?.totalOrdersToday} earnings=${parsed.data?.totalEarningsToday}',
              tag: 'API',
            );
          } else {
            AppLogger.log('Today dashboard API returned success=false', tag: 'API');
          }
        }
      } else {
        AppLogger.log('Today dashboard HTTP ${response.statusCode}: ${response.body}', tag: 'API');
      }
    } catch (e) {
      AppLogger.log('Today dashboard fetch failed: $e', tag: 'API');
    } finally {
      todayDashboardLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Init helpers
  // ══════════════════════════════════════════════════════════════════════

  void _getArguments() {
    final args = Get.arguments;
    if (args != null) orderModel.value = args['orderModel'];
  }

  Future<void> _setIcons() async {
    if (Constant.selectedMapType == 'google') {
      final dep    = await Constant().getBytesFromAsset('assets/images/location_black3x.png', 100);
      final dest   = await Constant().getBytesFromAsset('assets/images/location_orange3x.png', 100);
      final driver = await Constant().getBytesFromAsset('assets/images/food_delivery.png', 120);
      departureIcon   = BitmapDescriptor.fromBytes(dep);
      destinationIcon = BitmapDescriptor.fromBytes(dest);
      taxiIcon        = BitmapDescriptor.fromBytes(driver);
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _localNotifications.initialize(
        const InitializationSettings(android: android, iOS: ios));
  }

  void _initConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final was = _isConnected;
      _isConnected = results.any((r) => r != ConnectivityResult.none);
      if (!was && _isConnected) {
        AppLogger.log('Network restored', tag: 'Poll');
        if (!_isPolling) _startPolling();
      } else if (was && !_isConnected) {
        AppLogger.log('Network lost', tag: 'Poll');
        _pollTimer?.cancel();
        _isPolling = false;
      }
    });
    Connectivity().checkConnectivity().then((r) {
      _isConnected = r.any((x) => x != ConnectivityResult.none);
    });
  }

  void _tryCleanupCache() {
    try { ApiCacheService().forceCleanup(); } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════
  //  App lifecycle
  // ══════════════════════════════════════════════════════════════════════

  void updateAppLifecycleState(AppLifecycleState state) {
    final wasFg = _isAppForeground;
    _isAppForeground = state == AppLifecycleState.resumed;
    if (wasFg && !_isAppForeground) {
      _tryCleanupCache();
      if (_isPolling) _restartPolling(const Duration(seconds: 30));
    } else if (!wasFg && _isAppForeground) {
      _noOrderCount = 0;
      if (_isPolling) _restartPolling(const Duration(seconds: 5));
      forceRefreshOrders();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Marker smooth animation — PRIVATE internals
  // ══════════════════════════════════════════════════════════════════════

  void _animateMarkerTo(LatLng target) {
    if (taxiIcon == null) return;
    _markerAnimTimer?.cancel();

    final start = _markerAnimStart ?? target;
    _markerAnimStart  = start;
    _markerAnimTarget = target;

    int step = 0;
    _markerAnimTimer = Timer.periodic(
      Duration(milliseconds: _markerAnimDuration.inMilliseconds ~/ _markerAnimSteps),
          (t) {
        step++;
        final progress = step / _markerAnimSteps;
        final curved   = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
        final pos = LatLng(
          _lerpD(start.latitude,  target.latitude,  curved),
          _lerpD(start.longitude, target.longitude, curved),
        );
        _writeDriverMarker(pos);
        driverLatLng.value = pos;
        if (step >= _markerAnimSteps) {
          t.cancel();
          _markerAnimStart = target;
        }
      },
    );
  }

  void _writeDriverMarker(LatLng pos) {
    if (taxiIcon == null) return;
    final existing = markers.value['Driver'];
    if (existing != null) {
      final p = existing.position;
      if ((p.latitude - pos.latitude).abs() < 1e-7 &&
          (p.longitude - pos.longitude).abs() < 1e-7) {
        return;
      }
    }
    final updated = Map<String, Marker>.from(markers.value);
    updated['Driver'] = Marker(
      markerId: const MarkerId('Driver'),
      position: pos,
      icon: taxiIcon!,
      rotation: (driverModel.value.rotation ?? 0.0).toDouble(),
      anchor: const Offset(0.5, 0.5),
    );
    markers.value = updated;
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;

  // ══════════════════════════════════════════════════════════════════════
  //  updateDriverMarkerPosition — PUBLIC (called by DashBoardController)
  //
  //  Identical signature to the original home_controller.dart so no other
  //  file needs to change. Internally uses smooth lerp instead of a jump.
  // ══════════════════════════════════════════════════════════════════════

  void updateDriverMarkerPosition({bool updateCamera = false}) {
    if (driverModel.value.location?.latitude == null ||
        driverModel.value.location?.longitude == null ||
        taxiIcon == null ||
        Constant.selectedMapType == 'osm') {
      return;
    }

    final target = LatLng(
      driverModel.value.location!.latitude!,
      driverModel.value.location!.longitude!,
    );

    // Ignore sub-metre jitter
    if (_markerAnimStart != null &&
        _distanceBetween(_markerAnimStart!, target) < 1.0) {
      if (updateCamera) _smoothCameraFollow(target);
      return;
    }

    _animateMarkerTo(target);
    if (updateCamera) _smoothCameraFollow(target);
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Camera
  // ══════════════════════════════════════════════════════════════════════

  void setCameraFollowDriver(bool v) => _shouldFollowDriver = v;

  void _smoothCameraFollow(LatLng pos) {
    if (mapController == null || !_shouldFollowDriver) return;
    if (_lastCameraPos != null &&
        _distanceBetween(_lastCameraPos!, pos) < _cameraFollowDistance) return;
    mapController!.animateCamera(CameraUpdate.newLatLng(pos));
    _lastCameraPos = pos;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Polling
  // ══════════════════════════════════════════════════════════════════════

  void _startPolling() {
    if (_isPolling || !_isConnected) return;
    _isPolling    = true;
    _noOrderCount = 0;
    _pollInterval = _isAppForeground
        ? const Duration(seconds: 5)
        : const Duration(seconds: 20);
    _schedulePoll();
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _onPollTick());
  }

  Future<void> _onPollTick() async {
    if (_isRefreshing || !_isConnected) return;
    try {
      PerfTelemetry.inc('poll_requests');
      await refreshHomeScreen();
      final hasOrders =
          (driverModel.value.orderRequestData?.isNotEmpty ?? false) ||
              (driverModel.value.inProgressOrderID?.isNotEmpty ?? false) ||
              currentOrder.value.id != null;
      final desired = _computePollInterval(hasOrders);
      if (desired != _pollInterval) {
        _pollInterval = desired;
        _schedulePoll();
      }
    } catch (e) {
      AppLogger.log('Poll error: $e', tag: 'Poll');
    }
  }

  Duration _computePollInterval(bool hasOrders) {
    if (hasOrders) {
      _noOrderCount = 0;
      return _isAppForeground
          ? const Duration(seconds: 5)
          : const Duration(seconds: 10);
    }
    _noOrderCount++;
    final base = _noOrderCount == 1 ? 10 : _noOrderCount == 2 ? 20 : 30;
    final secs = _isAppForeground ? base : (base * 2).clamp(30, 60);
    return Duration(seconds: secs);
  }

  void _restartPolling(Duration interval) {
    if (!_isPolling) return;
    _pollInterval = interval;
    _schedulePoll();
  }

  Future<void> forceRefreshOrders() async {
    if (_isRefreshing) return;
    await Future.wait<Object?>([
      refreshHomeScreen().catchError((_, __) => false),
      fetchTodayDashboard(forceRefresh: true).catchError((_, __) => null),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Order status helpers
  // ══════════════════════════════════════════════════════════════════════

  void resetStatusTracking() {
    _lastKnownStatus      = null;
    _lastStatusChangeTime = null;
  }

  void _notifyOrderUiChanged({bool refreshOrder = true}) {
    PerfTelemetry.inc('home_order_ui_refreshes');
    if (refreshOrder) {
      currentOrder.refresh();
    }
  }

  void markOrderAsCompleted(String? id) {
    if (id == null || id.isEmpty) return;
    _recentlyCompleted[id] = DateTime.now();
  }

  void _cleanupCompletedIds() {
    final cutoff = DateTime.now().subtract(_completedRetention);
    _recentlyCompleted.removeWhere((_, t) => t.isBefore(cutoff));
  }

  void _filterCompletedFromUser(UserModel m) {
    _cleanupCompletedIds();
    if (_recentlyCompleted.isEmpty) return;
    final ids = _recentlyCompleted.keys.toSet();
    m.inProgressOrderID?.removeWhere((id) => ids.contains(id?.toString()));
    m.orderRequestData?.removeWhere((id) => ids.contains(id?.toString()));
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Charge calculations
  // ══════════════════════════════════════════════════════════════════════

  Future<void> calculateOrderChargesInitial(
      {bool fetchSurgeAndToPay = true}) async {
    if (currentOrder.value.id == null || _isCalculatingCharges) return;
    _isCalculatingCharges = true;
    var completedOk = false;
    var hadR2cInputs = false;
    try {
      AppLogger.log(
        'Charges: start order=${currentOrder.value.id} '
        'pickup=₹${_pickupRsPerKm}/km '
        'delivery≤${_deliveryShortTripMaxKm}km=flat₹${_deliveryShortTripBaseCharge} '
        'then≤${_deliveryFirstSlabKm}km=₹${_deliveryRsPerKmFirstSlab}/km(min₹${_deliveryShortTripBaseCharge}) '
        'beyond=${_deliveryFirstSlabKm.toInt()}×${_deliveryRsPerKmFirstSlab}+ceil(extra)×${_deliveryRsPerKmBeyond}',
        tag: 'Charges',
      );
      if (currentOrder.value.vendor != null) {
        await _calcDriverToRestaurant();
      }
      if (currentOrder.value.vendor != null &&
          _customerDropLatLng(currentOrder.value.address) != null) {
        await _calcRestaurantToCustomer();
      }
      _calcTotalCharge();

      if (fetchSurgeAndToPay) {
        final fee = await _fetchSurgeFee(currentOrder.value.id.toString());
        surgeFee.value = fee ?? 0.0;

        if (currentOrder.value.paymentMethod?.toLowerCase() == 'cod') {
          final tp = await _fetchToPay(currentOrder.value.id.toString());
          toPayAmount.value = tp ?? 0.0;
        }
      } else {
        // Keep surgeFee as-is; only re-derive COD amount locally.
        if (currentOrder.value.paymentMethod?.toLowerCase() == 'cod') {
          final tip = double.tryParse(
                  currentOrder.value.tipAmount?.toString() ?? '0') ??
              0.0;
          toPayAmount.value =
              totalCalculatedCharge.value + surgeFee.value + tip;
        }
      }
      hadR2cInputs = currentOrder.value.vendor != null &&
          _customerDropLatLng(currentOrder.value.address) != null;
      completedOk = true;
    } catch (e) {
      AppLogger.log('Charge calc error: $e', tag: 'Charges');
    } finally {
      _isCalculatingCharges = false;
      _hasCalculatedBaseCharges = true;
      // Only mark "done" when R→C inputs were present; otherwise a later vendor
      // load would be skipped by _syncVendorAndChargesForCurrentOrder (r2c stayed 0).
      if (completedOk && currentOrder.value.id != null && hadR2cInputs) {
        _chargesComputedForOrderId = currentOrder.value.id!.toString();
      }

      // If driver charge coefficients arrived while we were calculating,
      // do a quick local recalculation (no surge/to-pay network).
      if (_driverChargesNeedsRecalc &&
          _driverChargesApplied &&
          currentOrder.value.id != null &&
          currentOrder.value.vendor != null) {
        _driverChargesNeedsRecalc = false;
        unawaited(() async {
          try {
            await calculateOrderChargesInitial(fetchSurgeAndToPay: false);
            _updateOrderWithCharges();
            currentOrder.refresh();
          } catch (_) {}
        }());
      }
    }
  }

  Future<void> calculateOrderCharges() async {
    await calculateOrderChargesInitial();
    _updateOrderWithCharges();
  }

  /// Called from [DashBoardController] when GPS delivers non-null lat/lng.
  void notifyDriverLocationUpdated() {
    if (currentOrder.value.id == null || currentOrder.value.vendor == null) {
      return;
    }
    _chargesRecalcDebounce?.cancel();
    _chargesRecalcDebounce = Timer(const Duration(milliseconds: 700), () async {
      if (currentOrder.value.id == null) return;
      if (driverToRestaurantDistance.value >= 0.0005) return;
      AppLogger.log(
        'Charges: recalc after GPS (pickup km was ${driverToRestaurantDistance.value})',
        tag: 'Charges',
      );
      try {
        await calculateOrderCharges();
      } catch (e) {
        AppLogger.log('Charges: recalc error: $e', tag: 'Charges');
      }
    });
  }

  /// True when we have plausible GPS (excludes null, 0,0 placeholder, out-of-range).
  bool _isUsableDriverCoord(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    return true;
  }

  /// When [getCurrentOrder] sees the same id as already loaded, the full fetch is skipped;
  /// this still loads vendor coords and runs charge math if that was never done (fixes 0.00 UI).
  Future<void> _syncVendorAndChargesForCurrentOrder() async {
    final oid = currentOrder.value.id?.toString();
    if (oid == null || oid.isEmpty) return;

    if (currentOrder.value.vendor == null &&
        (currentOrder.value.vendorID?.isNotEmpty ?? false)) {
      await _fetchVendorData(currentOrder.value.vendorID!);
    }

    final v = currentOrder.value.vendor;
    final cust = _customerDropLatLng(currentOrder.value.address);
    final vp = v != null ? _vendorLatLng(v) : null;
    final hasR2cInputs = vp != null && cust != null;

    // Hot path: already computed and R→C fee applied — skip distance math + network.
    if (hasR2cInputs &&
        _chargesComputedForOrderId == oid &&
        restaurantToCustomerCharge.value > 0) {
      return;
    }

    var straightLegKm = 0.0;
    if (hasR2cInputs) {
      straightLegKm = Geolocator.distanceBetween(
            vp.lat,
            vp.lng,
            cust.lat,
            cust.lng,
          ) /
          1000;
    }

    // Leg has real distance but delivery fee is still zero → re-run (stale id, or
    // first run before vendor/coords; matches UI "Trip distance" > 0 with 3+0 row).
    final r2cMissing = hasR2cInputs &&
        straightLegKm > 0.0005 &&
        restaurantToCustomerCharge.value <= 0;

    final needCharges = hasR2cInputs &&
        (_chargesComputedForOrderId != oid || r2cMissing);

    if (needCharges) {
      await calculateOrderChargesInitial();
      _updateOrderWithCharges();
      currentOrder.refresh();
    }
  }

  /// Customer drop-off point when [ShippingAddress.location] was filled by [UserLocation.tryParseCoords].
  ({double lat, double lng})? _customerDropLatLng(ShippingAddress? a) {
    if (a == null) return null;
    final lat = a.location?.latitude;
    final lng = a.location?.longitude;
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  /// Restaurant point for distance math — same fields the map uses, plus Firestore `g.geopoint`.
  ({double lat, double lng})? _vendorLatLng(VendorModel v) {
    final lat = v.latitudeValue ??
        v.latitude ??
        v.coordinates?.latitude ??
        v.g?.geopoint?.latitude;
    final lng = v.longitudeValue ??
        v.longitude ??
        v.coordinates?.longitude ??
        v.g?.geopoint?.longitude;
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  void _logDriverCoordSnapshot(String phase) {
    final oid = currentOrder.value.id;
    final dl  = driverLatLng.value;
    final lf  = Constant.locationDataFinal;
    AppLogger.log(
      '$phase order=$oid '
      'driverLatLng=${dl?.latitude.toStringAsFixed(6)},${dl?.longitude.toStringAsFixed(6)} '
      'locDataFinal=${lf?.latitude},${lf?.longitude} '
      'modelLoc=${driverModel.value.location?.latitude},${driverModel.value.location?.longitude}',
      tag: 'Charges',
    );
  }

  /// Live marker → stream snapshot → profile → Geolocator (permission-aware) → last known.
  Future<({double lat, double lng, String source})?>
      _resolveDriverLatLngForCharges() async {
    _logDriverCoordSnapshot('DriverCoords: before resolve');

    double? lat;
    double? lng;
    var source = '';

    final dl = driverLatLng.value;
    if (_isUsableDriverCoord(dl?.latitude, dl?.longitude)) {
      lat = dl!.latitude;
      lng = dl.longitude;
      source = 'driverLatLng';
    }

    if (!_isUsableDriverCoord(lat, lng)) {
      final lf = Constant.locationDataFinal;
      if (_isUsableDriverCoord(lf?.latitude, lf?.longitude)) {
        lat = lf!.latitude;
        lng = lf.longitude;
        source = 'Constant.locationDataFinal';
      }
    }

    if (!_isUsableDriverCoord(lat, lng)) {
      final loc = driverModel.value.location;
      if (_isUsableDriverCoord(loc?.latitude, loc?.longitude)) {
        lat = loc!.latitude;
        lng = loc.longitude;
        source = 'driverModel.location';
      }
    }

    if (!_isUsableDriverCoord(lat, lng)) {
      try {
        final pos = await Utils.getCurrentLocation();
        if (pos != null &&
            _isUsableDriverCoord(pos.latitude, pos.longitude)) {
          lat = pos.latitude;
          lng = pos.longitude;
          source = 'Utils.getCurrentLocation';
          driverModel.value.location = UserLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
          driverLatLng.value = LatLng(pos.latitude, pos.longitude);
          driverModel.refresh();
        } else {
          AppLogger.log(
            'DriverCoords: Utils.getCurrentLocation returned null (service/permission?)',
            tag: 'Charges',
          );
        }
      } catch (e) {
        AppLogger.log('DriverCoords: Utils.getCurrentLocation error: $e',
            tag: 'Charges');
      }
    }

    if (!_isUsableDriverCoord(lat, lng)) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null &&
            _isUsableDriverCoord(last.latitude, last.longitude)) {
          lat = last.latitude;
          lng = last.longitude;
          source = 'Geolocator.getLastKnownPosition';
          driverModel.value.location = UserLocation(
            latitude: last.latitude,
            longitude: last.longitude,
          );
          driverLatLng.value = LatLng(last.latitude, last.longitude);
          driverModel.refresh();
        }
      } catch (e) {
        AppLogger.log('DriverCoords: getLastKnownPosition error: $e',
            tag: 'Charges');
      }
    }

    if (!_isUsableDriverCoord(lat, lng)) {
      _logDriverCoordSnapshot('DriverCoords: FAILED all sources');
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        var perm = await Geolocator.checkPermission();
        AppLogger.log(
          'DriverCoords: serviceEnabled=$enabled permission=$perm',
          tag: 'Charges',
        );
      } catch (e) {
        AppLogger.log('DriverCoords: could not read service/permission: $e',
            tag: 'Charges');
      }
      return null;
    }

    AppLogger.log(
      'DriverCoords: OK source=$source lat=$lat lng=$lng',
      tag: 'Charges',
    );
    return (lat: lat!, lng: lng!, source: source);
  }

  Future<void> _calcDriverToRestaurant() async {
    final v  = currentOrder.value.vendor!;
    final vp = _vendorLatLng(v);
    if (vp == null) {
      driverToRestaurantDistance.value = 0.0;
      driverToRestaurantDuration.value = 0.0;
      driverToRestaurantCharge.value = 0.0;
      AppLogger.log(
        'Driver->Restaurant: vendor has no coordinates '
        'vendorId=${v.id} lat=${v.latitude} lng=${v.longitude} '
        'coordinates=${v.coordinates} g.geopoint=${v.g?.geopoint}',
        tag: 'Charges',
      );
      return;
    }

    final driver = await _resolveDriverLatLngForCharges();
    if (driver == null) {
      driverToRestaurantDistance.value = 0.0;
      driverToRestaurantDuration.value = 0.0;
      driverToRestaurantCharge.value = 0.0;
      AppLogger.log(
        'Driver->Restaurant: no driver GPS; restaurant at ${vp.lat},${vp.lng}',
        tag: 'Charges',
      );
      return;
    }

    final routeKm = await _resolveLegDistanceKm(
      origin: LatLng(driver.lat, driver.lng),
      destination: LatLng(vp.lat, vp.lng),
      legTag: 'Driver->Restaurant',
    );
    driverToRestaurantDistance.value = routeKm;
    driverToRestaurantDuration.value = (routeKm / 30) * 60;
    driverToRestaurantCharge.value =
        _pickupChargeFromKm(driverToRestaurantDistance.value);
    AppLogger.log(
      'Driver->Restaurant: km=${driverToRestaurantDistance.value.toStringAsFixed(3)} '
      'charge=${driverToRestaurantCharge.value} (×$_pickupRsPerKm/km) '
      'driver(${driver.lat},${driver.lng}) source=${driver.source} '
      'restaurant(${vp.lat},${vp.lng})',
      tag: 'Charges',
    );
  }

  Future<void> _calcRestaurantToCustomer() async {
    final cust = _customerDropLatLng(currentOrder.value.address);
    final vp   = _vendorLatLng(currentOrder.value.vendor!);
    if (vp == null || cust == null) {
      restaurantToCustomerDistance.value = 0.0;
      restaurantToCustomerDuration.value = 0.0;
      restaurantToCustomerCharge.value = 0.0;
      _restaurantToCustomerBillableKm = 0;
      AppLogger.log(
        'Restaurant->Customer coords missing: '
        'vendor=${vp == null ? "null" : "${vp.lat},${vp.lng}"} '
        'customer=${cust == null ? "null" : "${cust.lat},${cust.lng}"}',
        tag: 'Charges',
      );
      return;
    }
    final routeKm = await _resolveLegDistanceKm(
      origin: LatLng(vp.lat, vp.lng),
      destination: LatLng(cust.lat, cust.lng),
      legTag: 'Restaurant->Customer',
    );
    restaurantToCustomerDistance.value = routeKm;
    restaurantToCustomerDuration.value = (routeKm / 30) * 60;
    final billableKm = _billableRestaurantToCustomerKm(routeKm);
    _restaurantToCustomerBillableKm = billableKm;
    restaurantToCustomerCharge.value =
        _restaurantToCustomerChargeFromBillableKm(billableKm);
    final rawKm = routeKm;
    if (_deliveryShortTripMaxKm > 0 && billableKm <= _deliveryShortTripMaxKm) {
      AppLogger.log(
        'Restaurant->Customer: routeKm=${rawKm.toStringAsFixed(3)} '
        'billableKm=${billableKm.toStringAsFixed(1)} (nearest whole km) '
        '≤${_deliveryShortTripMaxKm}km flat ₹${_deliveryShortTripBaseCharge} '
        '= ${restaurantToCustomerCharge.value} '
        'vendor(${vp.lat},${vp.lng}) customer(${cust.lat},${cust.lng})',
        tag: 'Charges',
      );
    } else if (billableKm <= _deliveryFirstSlabKm) {
      final minNote = _deliveryShortTripMaxKm > 0
          ? '(min ₹${_deliveryShortTripBaseCharge} above ${_deliveryShortTripMaxKm}km) '
          : '';
      AppLogger.log(
        'Restaurant->Customer: routeKm=${rawKm.toStringAsFixed(3)} '
        'billableKm=${billableKm.toStringAsFixed(1)} '
        'pro‑rata ${billableKm.toStringAsFixed(1)}×$_deliveryRsPerKmFirstSlab '
        '$minNote'
        '= ${restaurantToCustomerCharge.value} '
        'vendor(${vp.lat},${vp.lng}) customer(${cust.lat},${cust.lng})',
        tag: 'Charges',
      );
    } else {
      final beyondKm = billableKm - _deliveryFirstSlabKm;
      final units = beyondKm.ceil();
      AppLogger.log(
        'Restaurant->Customer: routeKm=${rawKm.toStringAsFixed(3)} '
        'billableKm=${billableKm.toStringAsFixed(1)} '
        '4×$_deliveryRsPerKmFirstSlab + ${units}×$_deliveryRsPerKmBeyond '
        '(extra ${beyondKm.toStringAsFixed(3)}km → ceil $units) '
        '= ${restaurantToCustomerCharge.value} '
        'vendor(${vp.lat},${vp.lng}) customer(${cust.lat},${cust.lng})',
        tag: 'Charges',
      );
    }
  }

  Future<double> _resolveLegDistanceKm({
    required LatLng origin,
    required LatLng destination,
    required String legTag,
  }) async {
    final straightKm =
        Geolocator.distanceBetween(origin.latitude, origin.longitude,
                destination.latitude, destination.longitude) /
            1000;

    if (Constant.selectedMapType != 'google' || Constant.mapAPIKey.isEmpty) {
      return straightKm;
    }

    try {
      final result = await polylinePoints.value.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      final pts = result.points;
      if (pts.length < 2) return straightKm;

      var meters = 0.0;
      for (var i = 0; i < pts.length - 1; i++) {
        meters += Geolocator.distanceBetween(
          pts[i].latitude,
          pts[i].longitude,
          pts[i + 1].latitude,
          pts[i + 1].longitude,
        );
      }

      final routeKm = meters / 1000;
      if (routeKm <= 0) return straightKm;

      AppLogger.log(
        '$legTag routeKm=${routeKm.toStringAsFixed(3)} '
        'straightKm=${straightKm.toStringAsFixed(3)} points=${pts.length}',
        tag: 'Charges',
      );
      return routeKm;
    } catch (e) {
      AppLogger.log('$legTag route distance fallback to straight line: $e',
          tag: 'Charges');
      return straightKm;
    }
  }

  void _calcTotalCharge() {
    totalCalculatedCharge.value =
        driverToRestaurantCharge.value + restaurantToCustomerCharge.value;
  }

  void _updateOrderWithCharges() {
    // Use already-computed `surgeFee` to avoid an extra network call.
    final surge = surgeFee.value;
    final tip =
        double.tryParse(currentOrder.value.tipAmount?.toString() ?? '0') ??
            0.0;
    currentOrder.value.calculatedCharges = {
      'driverToRestaurantDistance'  : driverToRestaurantDistance.value,
      'driverToRestaurantDuration'  : driverToRestaurantDuration.value,
      'driverToRestaurantCharge'    : driverToRestaurantCharge.value,
      'restaurantToCustomerDistance': restaurantToCustomerDistance.value,
      'restaurantToCustomerBillableKm': _restaurantToCustomerBillableKm,
      'restaurantToCustomerDuration': restaurantToCustomerDuration.value,
      'restaurantToCustomerCharge'  : restaurantToCustomerCharge.value,
      'tipsAmount'                  : currentOrder.value.tipAmount,
      'surgeAmount'                 : surge.toString(),
      'totalCalculatedCharge'       :
      '${totalCalculatedCharge.value + surge + tip}',
      'calculatedAt'                : FieldValue.serverTimestamp(),
    };
  }

  Future<double?> _fetchSurgeFee(String orderId) async {
    try {
      final res = await http
          .get(Uri.parse(
          '${Constant.baseUrl}mobile/orders/$orderId/billing/surge-fee'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true) {
          final v = j['data']?['total_surge_fee'];
          if (v != null) return (v as num).toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<double?> _fetchToPay(String orderId) async {
    try {
      final res = await http
          .get(Uri.parse(
          '${Constant.baseUrl}mobile/orders/$orderId/billing/to-pay'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true && j['data']?['found'] == true) {
          return (j['data']['to_pay'] as num).toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Kept for any external callers.
  Future<double?> fetchOrderSurgeFeePublic(String orderId) =>
      _fetchSurgeFee(orderId);

  // ══════════════════════════════════════════════════════════════════════
  //  changeData — debounced entry point for map updates
  // ══════════════════════════════════════════════════════════════════════

  void changeData() {
    PerfTelemetry.inc('route_update_triggers');
    _changeDataDebounce?.cancel();
    _changeDataDebounce = Timer(_changeDataDelay, _changeDataInternal);
  }

  Future<void> _changeDataInternal() async {
    if (Constant.mapType == 'inappmap') {
      if (Constant.selectedMapType == 'osm') {
        _getOSMPolyline();
      } else {
        if (Constant.mapAPIKey.isEmpty) {
          try {
            await FireStoreUtils.getSettings();
            if (Constant.mapAPIKey.isNotEmpty) updatePolylinePoints();
          } catch (_) {}
        }
        await _getDirections();
      }
    }
    // Do not restart ringtone while accept is in flight (debounced route
    // updates can still see Driver Pending until the backend returns).
    final pending = currentOrder.value.status == Constant.driverPending;
    if (pending && !_isAcceptingOrder && !_isRejectingOrder) {
      await AudioPlayerService.playSound(true);
    } else {
      await AudioPlayerService.playSound(false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Google Maps directions
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _getDirections() async {
    if (currentOrder.value.id == null) return;
    if (_routeCallInFlight) return;

    final dLoc = driverModel.value.location;
    if (dLoc?.latitude == null) return;
    final curPos = LatLng(dLoc!.latitude!, dLoc.longitude!);

    // Reuse cached route if driver hasn't moved far enough
    if (_lastRouteOrigin != null &&
        _distanceBetween(_lastRouteOrigin!, curPos) < _routeRecalcDistance) {
      _applyCachedRoute();
      return;
    }

    // Reuse if cache key + TTL still valid
    final cacheKey = _buildRouteCacheKey(curPos);
    if (cacheKey == _lastRouteCacheKey &&
        _cachedSimplified != null &&
        _lastRouteCalcTime != null &&
        DateTime.now().difference(_lastRouteCalcTime!) < _routeCacheDuration) {
      _applyCachedRoute();
      _animateMarkerTo(curPos);
      return;
    }

    _routeCallInFlight = true;
    try {
      await _doDirectionFetch(curPos, cacheKey);
    } finally {
      _routeCallInFlight = false;
    }
  }

  Future<void> _doDirectionFetch(LatLng origin, String cacheKey) async {
    PerfTelemetry.inc('route_calls');
    final status = currentOrder.value.status ?? '';
    LatLng? dest;

    if (status == Constant.orderShipped || status == Constant.driverAccepted) {
      final v = currentOrder.value.vendor;
      if (v == null) return;
      dest = LatLng(
        v.latitudeValue ?? v.latitude ?? v.coordinates?.latitude ?? 0.0,
        v.longitudeValue ?? v.longitude ?? v.coordinates?.longitude ?? 0.0,
      );
    } else if (status == Constant.orderInTransit) {
      final loc = currentOrder.value.address?.location;
      if (loc == null) return;
      dest = LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0);
    } else if (status == Constant.driverPending) {
      final v = currentOrder.value.vendor;
      if (v == null) return;
      dest = LatLng(
        v.latitudeValue ?? v.latitude ?? v.coordinates?.latitude ?? 0.0,
        v.longitudeValue ?? v.longitude ?? v.coordinates?.longitude ?? 0.0,
      );
    } else {
      return;
    }

    final result = await polylinePoints.value.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin:      PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(dest.latitude, dest.longitude),
        mode:        TravelMode.driving,
      ),
    );

    final coords =
    result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    if (coords.isEmpty) return;

    _lastRouteOrigin   = origin;
    _lastRouteCacheKey = cacheKey;
    _cachedPolyline    = List.from(coords);
    _cachedSimplified  = _simplifyPolyline(coords);
    _lastRouteCalcTime = DateTime.now();

    _applyCachedRoute();
    _buildMarkersForStatus(origin, dest, status);
  }

  void _buildMarkersForStatus(LatLng origin, LatLng dest, String status) {
    final nm = <String, Marker>{};

    if ((status == Constant.orderShipped ||
        status == Constant.driverAccepted) &&
        departureIcon != null) {
      nm['Departure'] = Marker(
          markerId: const MarkerId('Departure'),
          position: dest,
          icon: departureIcon!);
    } else if (status == Constant.orderInTransit && destinationIcon != null) {
      nm['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          position: dest,
          icon: destinationIcon!);
    } else if (status == Constant.driverPending) {
      if (departureIcon != null) {
        nm['Departure'] = Marker(
            markerId: const MarkerId('Departure'),
            position: dest,
            icon: departureIcon!);
      }
      final cust = _customerDropLatLng(currentOrder.value.address);
      if (cust != null && destinationIcon != null) {
        nm['Destination'] = Marker(
            markerId: const MarkerId('Destination'),
            position: LatLng(cust.lat, cust.lng),
            icon: destinationIcon!);
      }
    }

    _animateMarkerTo(origin);
    nm['Driver'] = markers.value['Driver'] ??
        Marker(
          markerId: const MarkerId('Driver'),
          position: origin,
          icon: taxiIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
        );

    markers.value = nm;
  }

  void _applyCachedRoute() {
    if (_cachedSimplified == null || _cachedSimplified!.isEmpty) return;
    const id = PolylineId('poly');
    polyLines.value = {
      id: Polyline(
        polylineId: id,
        color: AppThemeData.secondary300,
        points: _cachedSimplified!,
        width: 7,
        geodesic: true,
      ),
    };
  }

  List<LatLng> _simplifyPolyline(List<LatLng> pts) {
    if (pts.length <= _maxDisplayPoints) return pts;
    final step = (pts.length / _maxDisplayPoints).ceil();
    final out  = <LatLng>[pts.first];
    for (int i = step; i < pts.length - step; i += step) out.add(pts[i]);
    if (out.last != pts.last) out.add(pts.last);
    return out;
  }

  String _buildRouteCacheKey(LatLng origin) {
    final oLat   = _snap(origin.latitude);
    final oLng   = _snap(origin.longitude);
    final status = currentOrder.value.status ?? '';
    final id     = currentOrder.value.id ?? '';
    return '$id-$status-$oLat,$oLng';
  }

  double _snap(double v) => (v / _coordPrecision).round() * _coordPrecision;

  void _clearRouteCache() {
    _lastRouteCacheKey = null;
    _cachedPolyline    = null;
    _cachedSimplified  = null;
    _lastRouteCalcTime = null;
    _lastRouteOrigin   = null;
    _routeCallInFlight = false;
    _markerAnimTimer?.cancel();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  clearMap
  // ══════════════════════════════════════════════════════════════════════

  Future<void> clearMap() async {
    await AudioPlayerService.playSound(false);
    if (Constant.selectedMapType != 'osm') {
      markers.value   = {};
      polyLines.value = {};
    } else {
      osmMarkers.value  = [];
      routePoints.value = [];
      _osmMapReady = false;
    }
    _clearRouteCache();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Accept / Reject
  // ══════════════════════════════════════════════════════════════════════

  Future<void> acceptOrder() async {
    if (_isAcceptingOrder) return;
    if (currentOrder.value.status == Constant.driverAccepted &&
        currentOrder.value.driverID == driverModel.value.id) return;

    _changeDataDebounce?.cancel();
    _isAcceptingOrder = true;
    await AudioPlayerService.playSound(false);
    ShowToastDialog.showLoader('Please wait'.tr);

    try {
      if ((currentOrder.value.id ?? '').isEmpty ||
          (driverModel.value.id ?? '').isEmpty) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast('Order or driver ID missing');
        return;
      }

      final result = await OrderWorkflowService.acceptOrderBackend(
        order: currentOrder.value,
        driverModel: driverModel.value,
      );

      if (result == null) {
        ShowToastDialog.closeLoader();
        Get.snackbar('Rate Limited', 'Please wait and try again.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (result == true) {
        final orderId = currentOrder.value.id!;
        _markOrderHandledAndMute(orderId);
        _notifiedOrderIds.remove(orderId);

        // Service already mutated order status/driver + driver lists + cache invalidation.
        _lastKnownStatus            = Constant.driverAccepted;
        _lastStatusChangeTime       = DateTime.now();

        await calculateOrderCharges();
        await FireStoreUtils.setOrder(currentOrder.value);
        await _forceRefreshOrder(orderId);

        ShowToastDialog.closeLoader();

        if (currentOrder.value.author?.fcmToken != null) {
          await SendNotification.sendFcmMessage(
              Constant.driverAcceptedNotification,
              currentOrder.value.author!.fcmToken.toString(), {});
        }
        if (currentOrder.value.vendor?.fcmToken != null) {
          await SendNotification.sendFcmMessage(
              Constant.driverAcceptedNotification,
              currentOrder.value.vendor!.fcmToken.toString(), {});
        }

        ShowToastDialog.showToast('Order accepted!'.tr);
        _notifyOrderUiChanged();
        // Get.to(() => const OrderMapScreen());
      } else {
        ShowToastDialog.closeLoader();
        Get.snackbar('Unavailable', 'Order accepted by another driver.',
            snackPosition: SnackPosition.BOTTOM);
        await AudioPlayerService.playSound(false);
        _notifiedOrderIds.remove(currentOrder.value.id);
        currentOrder.value = OrderModel();
        _chargesComputedForOrderId = null;
        await clearMap();
        update();
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      Get.snackbar('Error', 'Failed to accept order. Try again.',
          snackPosition: SnackPosition.BOTTOM);
      AppLogger.log('acceptOrder error: $e', tag: 'Error');
    } finally {
      await AudioPlayerService.playSound(false);
      _isAcceptingOrder = false;
    }
  }

  Future<void> rejectOrder() async {
    _changeDataDebounce?.cancel();
    _isRejectingOrder = true;
    await AudioPlayerService.playSound(false);
    try {
      final id = currentOrder.value.id;
      if (id != null) _markOrderHandledAndMute(id);
      _notifiedOrderIds.remove(id);

      await OrderWorkflowService.rejectOrderBackend(
        order: currentOrder.value,
        driverModel: driverModel.value,
      );

      currentOrder.value = OrderModel();
      _chargesComputedForOrderId = null;
      await clearMap();
      _notifyOrderUiChanged(refreshOrder: false);

      if (Constant.singleOrderReceive == false) Get.back();
    } finally {
      await AudioPlayerService.playSound(false);
      _isRejectingOrder = false;
    }
  }

  bool get isPickupNavigationState {
    final status = currentOrder.value.status ?? '';
    return status == Constant.driverAccepted ||
        status == Constant.orderShipped ||
        status == Constant.driverPending ||
        status == Constant.orderAccepted;
  }

  bool get isDropNavigationState {
    final status = currentOrder.value.status ?? '';
    return status == Constant.orderInTransit;
  }

  Future<void> openCurrentOrderNavigation() async {
    if (isNavigatingToMap.value) return;
    final order = currentOrder.value;
    final originLat = driverModel.value.location?.latitude;
    final originLng = driverModel.value.location?.longitude;

    double? destLat;
    double? destLng;
    if (isPickupNavigationState) {
      destLat = order.vendor?.latitude;
      destLng = order.vendor?.longitude;
    } else if (isDropNavigationState) {
      destLat = order.address?.location?.latitude;
      destLng = order.address?.location?.longitude;
    }

    if (destLat == null || destLng == null) {
      Get.snackbar(
        'Navigation unavailable',
        'Location coordinates are missing for this order.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isNavigatingToMap.value = true;
    try {
      final opened = (originLat != null && originLng != null)
          ? await Utils.openGoogleMaps(originLat, originLng, destLat, destLng)
          : await Utils.openGoogleMapsToDestination(destLat, destLng);
      if (!opened) {
        Get.snackbar('Unable to open maps',
          'Google Maps could not be opened on this device.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Unable to open maps',
        'Something went wrong while opening navigation.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isNavigatingToMap.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Driver profile
  // ══════════════════════════════════════════════════════════════════════

  Future<void> getDriver() async {
    final userId = await LoginController.getFirebaseId();
    try {
      final h = HttpClientService();
      final res = await h.get(
        Uri.parse('${Constant.baseUrl}users/$userId'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        cacheStrategy: CacheStrategy.driverProfile,
        useCache: true,
        timeout: const Duration(seconds: 10),
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true && j['data'] != null) {
          final prev   = driverModel.value.orderRequestData?.toList();
          final parsed = UserModel.fromJson(j['data']);
          _filterCompletedFromUser(parsed);
          driverModel.value = parsed;

          if (driverModel.value.id != null) {
            isLoading.value = false;
            changeData();
            // Ensure "Today Dashboard" API is requested once driver id is available.
            fetchTodayDashboard(forceRefresh: true);

            final curr   = driverModel.value.orderRequestData?.toList();
            final hasNew = (curr?.isNotEmpty ?? false) &&
                (prev == null || curr.toString() != prev.toString());

            if (hasNew) {
              final newIds = curr
                  ?.where((id) => prev == null || !prev.contains(id))
                  .toList() ??
                  [];
              for (final oid in newIds) {
                if (oid.isNotEmpty && !_isOrderMuted(oid)) {
                  await _showOrderNotification(oid);
                  await AudioPlayerService.playSound(true);
                }
              }
              await Future.delayed(const Duration(milliseconds: 500));
            }
            await getCurrentOrder();
          }
        }
      }
    } catch (e) {
      AppLogger.log('getDriver error: $e', tag: 'API');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  getCurrentOrder
  // ══════════════════════════════════════════════════════════════════════

  Future<void> getCurrentOrder() async {
    if (_lastGetOrderTime != null &&
        DateTime.now().difference(_lastGetOrderTime!) < _minOrderInterval) return;
    _lastGetOrderTime = DateTime.now();

    final inProgress = driverModel.value.inProgressOrderID ?? [];
    final requests   = driverModel.value.orderRequestData ?? [];

    if (currentOrder.value.id != null &&
        !inProgress.contains(currentOrder.value.id) &&
        !requests.contains(currentOrder.value.id)) {
      if (_isAcceptingOrder) return;
      final isPendingNoDriver =
          currentOrder.value.status == Constant.driverPending &&
              (currentOrder.value.driverID?.isEmpty ?? true);
      if (!isPendingNoDriver) {
        currentOrder.value = OrderModel();
        _chargesComputedForOrderId = null;
        await clearMap();
        await AudioPlayerService.playSound(false);
        return;
      }
    }

    String? firstId;
    final validProgress =
    inProgress.where((id) => id?.isNotEmpty ?? false).toList();
    if (validProgress.isNotEmpty) {
      firstId = validProgress.first;
    } else {
      final validReqs = requests
          .where((id) =>
      (id?.isNotEmpty ?? false) && id != currentOrder.value.id)
          .toList();
      if (validReqs.isNotEmpty) firstId = validReqs.first;
    }

    if (firstId == null) return;
    if (currentOrder.value.id == firstId) {
      await _syncVendorAndChargesForCurrentOrder();
      return;
    }

    await _fetchAndDisplayOrder(firstId,
        inProgress: inProgress, requests: requests);
  }

  Future<void> _fetchAndDisplayOrder(
      String orderId, {
        required List inProgress,
        required List requests,
      }) async {
    OrderModel? fetched;

    // Primary
    try {
      final h   = HttpClientService();
      final res = await h.get(
        Uri.parse(
            '${Constant.baseUrl}driver/get-current-reject-accept'
                '?order_id=$orderId'
                '&exclude_statuses=Order+Cancelled,Driver+Rejected,Order+Completed'),
        headers: {'Accept': 'application/json'},
        cacheStrategy: CacheStrategy.order,
        useCache: true,
        timeout: const Duration(seconds: 10),
      );
      if (res.statusCode == 200 && !res.body.startsWith('<')) {
        final d = jsonDecode(res.body);
        if (d['success'] == true && d['order'] != null) {
          fetched = OrderModel.fromJson(d['order']);
        }
      }
    } catch (_) {}

    // Fallback
    if (fetched == null) {
      try {
        final h   = HttpClientService();
        final res = await h.get(
          Uri.parse('${Constant.baseUrl}restaurant/orders/$orderId'),
          headers: {'Accept': 'application/json'},
          cacheStrategy: CacheStrategy.order,
          useCache: true,
          timeout: const Duration(seconds: 10),
        );
        if (res.statusCode == 200 && !res.body.startsWith('<')) {
          final d = jsonDecode(res.body);
          if (d['success'] == true && d['data'] != null) {
            fetched = OrderModel.fromJson(d['data']);
          }
        }
      } catch (_) {}
    }

    if (fetched == null || fetched.id == null) {
      inProgress.remove(orderId);
      requests.remove(orderId);
      await FireStoreUtils.updateUser(driverModel.value);
      if (currentOrder.value.id == orderId) {
        currentOrder.value = OrderModel();
        _chargesComputedForOrderId = null;
        await clearMap();
        await AudioPlayerService.playSound(false);
      }
      return;
    }

    if (fetched.status == Constant.orderCompleted ||
        fetched.status == 'Order Completed') {
      markOrderAsCompleted(fetched.id);
      driverModel.value.inProgressOrderID?.remove(fetched.id);
      driverModel.value.orderRequestData?.remove(fetched.id);
      await FireStoreUtils.updateUser(driverModel.value);
      resetStatusTracking();
      _notifyOrderUiChanged(refreshOrder: false);
      return;
    }

    currentOrder.value = fetched;
    _chargesComputedForOrderId = null;
    _lastFetchedOrderId   = fetched.id;
    _lastKnownStatus      = fetched.status;
    _lastStatusChangeTime = DateTime.now();

    if (currentOrder.value.vendor == null &&
        (currentOrder.value.vendorID?.isNotEmpty ?? false)) {
      await _fetchVendorData(currentOrder.value.vendorID!);
    }
    if (currentOrder.value.vendor != null) {
      await calculateOrderChargesInitial();
    }

    changeData();
    _notifyOrderUiChanged();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  refreshCurrentOrder
  // ══════════════════════════════════════════════════════════════════════

  Future<void> refreshCurrentOrder({bool forceRefresh = false}) async {
    if (currentOrder.value.id == null) return;
    try {
      final h = HttpClientService();
      if (forceRefresh) await h.invalidateCache('orders/${currentOrder.value.id}');

      final res = await h.get(
        Uri.parse(
            '${Constant.baseUrl}restaurant/orders/${currentOrder.value.id}'),
        cacheStrategy: CacheStrategy.order,
        useCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (res.statusCode != 200) return;

      final body = jsonDecode(res.body);
      if (body['success'] != true || body['data'] == null) return;

      final refreshed = OrderModel.fromJson(body['data']);
      final priority  = {
        Constant.driverPending: 1, Constant.driverAccepted: 2,
        Constant.orderShipped: 2,  Constant.orderInTransit: 3,
        Constant.orderCompleted: 4,
      };
      final cur = priority[currentOrder.value.status] ?? 0;
      final nw  = priority[refreshed.status] ?? 0;

      if (refreshed.status == Constant.orderCompleted) {
        markOrderAsCompleted(currentOrder.value.id);
        driverModel.value.inProgressOrderID?.remove(currentOrder.value.id);
        driverModel.value.orderRequestData?.remove(currentOrder.value.id);
        await FireStoreUtils.updateUser(driverModel.value);
        currentOrder.value = OrderModel();
        _chargesComputedForOrderId = null;
        await clearMap();
        resetStatusTracking();
        _notifyOrderUiChanged(refreshOrder: false);
        return;
      }

      if (nw >= cur || forceRefresh) {
        final changed =
            _lastKnownStatus != null && _lastKnownStatus != refreshed.status;
        currentOrder.value = refreshed;
        if (forceRefresh) _chargesComputedForOrderId = null;
        if (changed) {
          _lastStatusChangeTime = DateTime.now();
          _lastKnownStatus      = refreshed.status;
          currentOrder.refresh();
        } else {
          _lastKnownStatus = refreshed.status;
        }
      }

      if (currentOrder.value.vendor == null &&
          (currentOrder.value.vendorID?.isNotEmpty ?? false)) {
        await _fetchVendorData(currentOrder.value.vendorID!);
      }

      await _syncVendorAndChargesForCurrentOrder();

      changeData();
      _notifyOrderUiChanged(refreshOrder: false);
    } catch (e) {
      AppLogger.log('refreshCurrentOrder error: $e', tag: 'API');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  refreshHomeScreen
  // ══════════════════════════════════════════════════════════════════════

  Future<bool> refreshHomeScreen() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final userId = await LoginController.getFirebaseId();
      final prev   = driverModel.value.orderRequestData?.toList();

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (_lastETag     != null) headers['If-None-Match']     = _lastETag!;
      if (_lastModified != null) headers['If-Modified-Since'] = _lastModified!;

      final h   = HttpClientService();
      final res = await h.get(
        Uri.parse('${Constant.baseUrl}users/$userId'),
        headers: headers,
        cacheStrategy: CacheStrategy.driverProfile,
        useCache: true,
        forceRefresh: _lastETag != null || _lastModified != null,
      );

      if (res.statusCode == 304) return false;
      if (res.statusCode != 200) return false;

      final etag = res.headers['etag'];
      final lm   = res.headers['last-modified'];
      if (etag != null) _lastETag     = etag;
      if (lm   != null) _lastModified = lm;

      final j = jsonDecode(res.body);
      if (j['success'] != true) return false;

      final parsed = UserModel.fromJson(j['data']);
      _filterCompletedFromUser(parsed);
      driverModel.value = parsed;

      final curr   = driverModel.value.orderRequestData?.toList();
      final hasNew = (curr?.isNotEmpty ?? false) &&
          (prev == null || curr.toString() != prev.toString());

      if (hasNew) {
        final newIds =
            curr?.where((id) => prev == null || !prev.contains(id)).toList() ??
                [];
        for (final oid in newIds) {
          if (oid.isNotEmpty && !_isOrderMuted(oid)) {
            await _showOrderNotification(oid);
            await AudioPlayerService.playSound(true);
          }
        }
        await Future.delayed(const Duration(milliseconds: 500));
        await getCurrentOrder();
      } else if (currentOrder.value.id != null) {
        final shouldRefresh = _lastStatusChangeTime == null ||
            DateTime.now().difference(_lastStatusChangeTime!) > _statusCooldown;
        if (shouldRefresh) await refreshCurrentOrder();
      } else {
        await getCurrentOrder();
      }

      _notifyOrderUiChanged(refreshOrder: false);
      return true;
    } catch (e) {
      AppLogger.log('refreshHomeScreen error: $e', tag: 'API');
      await getCurrentOrder();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Force-refresh one order
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _forceRefreshOrder(String orderId) async {
    try {
      final h = HttpClientService();
      await h.invalidateCache('orders/$orderId');
      final res = await h.get(
        Uri.parse('${Constant.baseUrl}restaurant/orders/$orderId'),
        headers: {'Accept': 'application/json'},
        cacheStrategy: CacheStrategy.order,
        useCache: false,
        forceRefresh: true,
        timeout: const Duration(seconds: 10),
      );
      if (res.statusCode == 200 && !res.body.startsWith('<')) {
        final d = jsonDecode(res.body);
        if (d['success'] == true && d['data'] != null) {
          final refreshed = OrderModel.fromJson(d['data']);
          final priority  = {
            Constant.driverPending: 1, Constant.driverAccepted: 2,
            Constant.orderShipped: 2,  Constant.orderInTransit: 3,
            Constant.orderCompleted: 4,
          };
          final cur = priority[currentOrder.value.status] ?? 0;
          final nw  = priority[refreshed.status] ?? 0;
          if (nw >= cur) {
            refreshed.driverID = driverModel.value.id;
            refreshed.driver   = driverModel.value;
            currentOrder.value = refreshed;
          }
          if (currentOrder.value.vendor == null &&
              (currentOrder.value.vendorID?.isNotEmpty ?? false)) {
            await _fetchVendorData(currentOrder.value.vendorID!);
          }
          await calculateOrderChargesInitial();
          changeData();
          _notifyOrderUiChanged();
        }
      }
    } catch (e) {
      AppLogger.log('_forceRefreshOrder error: $e', tag: 'API');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Vendor cache
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _fetchVendorData(String vendorId) async {
    if (_vendorCache.containsKey(vendorId)) {
      final age = DateTime.now().difference(_vendorCacheTime[vendorId]!);
      if (age < _vendorCacheTTL) {
        final cached = _vendorCache[vendorId]!;
        if (!identical(currentOrder.value.vendor, cached)) {
          currentOrder.value.vendor = cached;
          update();
        }
        return;
      }
      _vendorCache.remove(vendorId);
    }

    try {
      final h   = HttpClientService();
      final res = await h.get(
        Uri.parse('${Constant.baseUrl}restaurant/vendors/$vendorId'),
        headers: {'Accept': 'application/json'},
        cacheStrategy: CacheStrategy.vendor,
        useCache: true,
        timeout: const Duration(seconds: 10),
      );
      if (res.statusCode == 200 && !res.body.startsWith('<')) {
        final d = jsonDecode(res.body);
        if (d['success'] == true && d['data'] is Map<String, dynamic>) {
          final v = VendorModel.fromJson(d['data'] as Map<String, dynamic>);
          _vendorCache[vendorId]     = v;
          _vendorCacheTime[vendorId] = DateTime.now();
          currentOrder.value.vendor  = v;
          update();
          return;
        }
      }
    } catch (_) {}

    try {
      final snap = await firestore.FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .get();
      if (snap.exists && snap.data() != null) {
        final v =
        VendorModel.fromJson(Map<String, dynamic>.from(snap.data()!));
        _vendorCache[vendorId]     = v;
        _vendorCacheTime[vendorId] = DateTime.now();
        currentOrder.value.vendor  = v;
        update();
      }
    } catch (e) {
      AppLogger.log('Vendor Firestore error: $e', tag: 'VendorCache');
    }
  }

  static Future<VendorModel?> getVendorById(String vendorId) async {
    if (vendorId.isEmpty) return null;
    try {
      HomeController? ctrl;
      try { ctrl = Get.find<HomeController>(); } catch (_) {}
      if (ctrl != null && ctrl._vendorCache.containsKey(vendorId)) {
        final age =
        DateTime.now().difference(ctrl._vendorCacheTime[vendorId]!);
        if (age < _vendorCacheTTL) return ctrl._vendorCache[vendorId];
      }
      final h   = HttpClientService();
      final res = await h.get(
        Uri.parse('${Constant.baseUrl}restaurant/vendors/$vendorId'),
        headers: {'Accept': 'application/json'},
        cacheStrategy: CacheStrategy.vendor,
        useCache: true,
      );
      if (res.statusCode == 200 && !res.body.startsWith('<')) {
        final d = jsonDecode(res.body);
        if (d['success'] == true && d['data'] is Map<String, dynamic>) {
          final v = VendorModel.fromJson(d['data'] as Map<String, dynamic>);
          ctrl?._vendorCache[vendorId]     = v;
          ctrl?._vendorCacheTime[vendorId] = DateTime.now();
          return v;
        }
      }
    } catch (_) {}
    return null;
  }

  void clearVendorCache() {
    _vendorCache.clear();
    _vendorCacheTime.clear();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Notification
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _showOrderNotification(String orderId) async {
    if (_notifiedOrderIds.contains(orderId)) return;
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'New Order',
        'Order $orderId is waiting for you!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'order_channel', 'Orders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([500, 500, 500, 500]),
          ),
          iOS: const DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: orderId,
      );
      _notifiedOrderIds.add(orderId);
    } catch (e) {
      AppLogger.log('Notification error: $e', tag: 'Notifications');
    }
  }

  void _markOrderHandledAndMute(String orderId) {
    if (orderId.isEmpty) return;
    _recentlyHandledOrderMutes[orderId] = DateTime.now();
  }

  bool _isOrderMuted(String orderId) {
    if (orderId.isEmpty) return false;
    final at = _recentlyHandledOrderMutes[orderId];
    if (at == null) return false;
    if (DateTime.now().difference(at) > _handledOrderMuteTtl) {
      _recentlyHandledOrderMutes.remove(orderId);
      return false;
    }
    return true;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  OSM helpers
  // ══════════════════════════════════════════════════════════════════════

  void _getOSMPolyline() {
    try {
      if (currentOrder.value.id == null) return;
      final status = currentOrder.value.status;
      final dLoc   = driverModel.value.location;
      if (dLoc?.latitude == null) return;

      if (status == Constant.orderShipped ||
          status == Constant.driverAccepted) {
        final v = currentOrder.value.vendor;
        if (v == null) return;
        current.value = location.LatLng(dLoc!.latitude!, dLoc.longitude!);
        destination.value = location.LatLng(
          v.latitudeValue ?? v.latitude ?? v.coordinates?.latitude ?? 0.0,
          v.longitudeValue ?? v.longitude ?? v.coordinates?.longitude ?? 0.0,
        );
        Future.delayed(const Duration(milliseconds: 500), _animateToSource);
        fetchRoute(current.value, destination.value)
            .then((_) => _setOSMMarkers());
      } else if (status == Constant.orderInTransit) {
        final loc = currentOrder.value.address?.location;
        if (loc == null) return;
        current.value = location.LatLng(dLoc!.latitude!, dLoc.longitude!);
        destination.value =
            location.LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0);
        _setOSMMarkers();
        fetchRoute(current.value, destination.value)
            .then((_) => _setOSMMarkers());
        Future.delayed(const Duration(milliseconds: 500), _animateToSource);
      } else if (status == Constant.driverPending) {
        final v = currentOrder.value.vendor;
        if (v == null) return;
        current.value = location.LatLng(dLoc!.latitude!, dLoc.longitude!);
        destination.value = location.LatLng(
          v.latitudeValue ?? v.latitude ?? v.coordinates?.latitude ?? 0.0,
          v.longitudeValue ?? v.longitude ?? v.coordinates?.longitude ?? 0.0,
        );
        Future.delayed(const Duration(milliseconds: 500), _animateToSource);
        fetchRoute(current.value, destination.value)
            .then((_) => _setOSMMarkers());
      }
    } catch (e) {
      AppLogger.log('OSM polyline error: $e', tag: 'OSM');
    }
  }

  void _setOSMMarkers() {
    osmMarkers.value = [
      flutterMap.Marker(
        point: current.value,
        width: 45, height: 45, rotate: true,
        child: Image.asset('assets/images/food_delivery.png'),
      ),
      flutterMap.Marker(
        point: source.value,
        width: 40, height: 40,
        child: Image.asset('assets/images/location_black3x.png'),
      ),
      flutterMap.Marker(
        point: destination.value,
        width: 40, height: 40,
        child: Image.asset('assets/images/location_orange3x.png'),
      ),
    ];
  }

  void _animateToSource() {
    if (!_osmMapReady) return;
    try {
      osmMapController.move(
        location.LatLng(
          driverModel.value.location?.latitude ?? 0.0,
          driverModel.value.location?.longitude ?? 0.0,
        ),
        16,
      );
    } catch (_) {}
  }

  Future<void> fetchRoute(location.LatLng src, location.LatLng dst) async {
    try {
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
              '${src.longitude},${src.latitude};'
              '${dst.longitude},${dst.latitude}'
              '?overview=full&geometries=geojson');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final d      = jsonDecode(res.body);
        final coords = d['routes']?[0]?['geometry']?['coordinates'];
        if (coords is List) {
          routePoints.value = coords
              .whereType<List>()
              .where((c) => c.length >= 2)
              .map((c) =>
              location.LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        }
      }
    } catch (e) {
      AppLogger.log('fetchRoute error: $e', tag: 'OSM');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  Utility
  // ══════════════════════════════════════════════════════════════════════

  double _distanceBetween(LatLng a, LatLng b) {
    const r    = 6371000.0;
    final dLat = _rad(b.latitude  - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final x    = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  double _rad(double deg) => deg * math.pi / 180.0;
}