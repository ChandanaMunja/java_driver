import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:jippydriver_driver/app/home_screen/home_screen.dart' show fetchOrderSurgeFee;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/send_notification.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/edit_profile_controller.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/services/audio_player_service.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as location;
import '../../../models/order_model.dart';
import '../../../models/vendor_model.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
// import '../services/order_service.dart';
// import 'package:jippydriver_driver/services/order_service.dart';

// Simple CancelToken class for request cancellation
class CancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
  void reset() => _isCancelled = false;
}

class HomeController extends GetxController {

  RxBool arrowDrop = false.obs;
  void changeArrow(){
if(arrowDrop.value){
  arrowDrop.value =false;

}else{
  arrowDrop.value =true;
}
  }


  //NEW FUNCTIONS
  EditProfileController editProfileController = Get.find<EditProfileController>();
  RxDouble driverToRestaurantDistance = 0.0.obs;
  RxDouble restaurantToCustomerDistance = 0.0.obs;
  RxDouble driverToRestaurantDuration = 0.0.obs; // in minutes
  RxDouble restaurantToCustomerDuration = 0.0.obs; // in minutes
  RxDouble driverToRestaurantCharge = 0.0.obs;
  RxDouble restaurantToCustomerCharge = 0.0.obs;
  RxDouble totalCalculatedCharge = 0.0.obs;
  void driverChargeAdd()async{
    try {
      final charges = await FireStoreUtils.getDriverCharges();
      print("✅ Pickup charges from API: ${charges["pickup_charges"]}");
      print("✅ Delivery charges from API: ${charges["user_delivery_charge"]}");
      // Use API charges, fallback to zone data, then default to 2 for pickup and 7 for delivery
      DRIVER_TO_RESTAURANT_RATE_PER_KM = double.tryParse(charges["pickup_charges"]?.toString() ?? '') ?? 
                                         double.tryParse(editProfileController.selectedZone.value.pickupCharges ?? '') ?? 
                                         2.0;
      RESTAURANT_TO_CUSTOMER_RATE_PER_KM = double.tryParse(charges["user_delivery_charge"]?.toString() ?? '') ?? 
                                           double.tryParse(editProfileController.selectedZone.value.userDeliveryCharge ?? '') ?? 
                                           7.0;
      print("✅ Final Pickup Rate: $DRIVER_TO_RESTAURANT_RATE_PER_KM per km");
      print("✅ Final Delivery Rate: $RESTAURANT_TO_CUSTOMER_RATE_PER_KM per km");
    print(" ${driverToRestaurantCharge.value} driverToRestaurantCharge ");
    update();
    } catch (e) {
      print("❌ Error fetching driver charges from API: $e");
      // Fallback to zone data or defaults
      DRIVER_TO_RESTAURANT_RATE_PER_KM = double.tryParse(editProfileController.selectedZone.value.pickupCharges ?? '') ?? 2.0;
      RESTAURANT_TO_CUSTOMER_RATE_PER_KM = double.tryParse(editProfileController.selectedZone.value.userDeliveryCharge ?? '') ?? 7.0;
      print("⚠️ Using fallback rates - Pickup: $DRIVER_TO_RESTAURANT_RATE_PER_KM, Delivery: $RESTAURANT_TO_CUSTOMER_RATE_PER_KM");
      update();
    }
  }
// Pricing constants
  double DRIVER_TO_RESTAURANT_RATE_PER_KM = 0.0; // ₹2 per km
  double RESTAURANT_TO_CUSTOMER_RATE_PER_KM = 0.0; // ₹7 per km
  // Calculate distances and charges when order is accepted
  Future<void> calculateOrderChargesInitial() async {
    print(" calculateOrderChargesId ${currentOrder.value.id} ");
    if (currentOrder.value.id == null) return;
    try {
      // Calculate driver to restaurant distance & duration
      if (driverModel.value.location != null &&
          currentOrder.value.vendor != null) {
        await calculateDriverToRestaurantDetails();
      }
      if (currentOrder.value.vendor != null &&
          currentOrder.value.address?.location != null) {
        await calculateRestaurantToCustomerDetails();
      }
      calculateCharges();
    } catch (e) {
      print('Error calculating order charges: $e');
    }
  }
  Future<void> calculateOrderCharges() async {
    print(" calculateOrderChargesId ${currentOrder.value.id} ");
    try {
      // Calculate driver to restaurant distance & duration
      if (driverModel.value.location != null &&
          currentOrder.value.vendor != null) {
        await calculateDriverToRestaurantDetails();
      }
      // Calculate restaurant to customer distance & duration
      if (currentOrder.value.vendor != null &&
          currentOrder.value.address?.location != null) {
        await calculateRestaurantToCustomerDetails();
      }
      // Calculate charges
      calculateCharges();
      // Update the order with calculated charges
      await updateOrderWithCalculatedCharges();
    } catch (e) {
      print('Error calculating order charges: $e');
    }
  }

  Future<void> calculateDriverToRestaurantDetails() async {
    print(" ${driverToRestaurantCharge.value} driverToRestaurantCharge ");
    print(" ${driverToRestaurantCharge.value} driverToRestaurantCharge ");
    VendorModel? vendorModels = await getVendorById(
        currentOrder.value.vendorID.toString());
    double distanceInMeters = 0.0;
    print(" ${distanceInMeters} calculateDriverToRestaurantDetailscalculateDriverToRestaurantDetails zero ");
    if(vendorModels==null){
      distanceInMeters =   Geolocator.distanceBetween(
        driverModel.value.location!.latitude!,
        driverModel.value.location!.longitude!,
        currentOrder.value.vendor!.latitude ?? 0.0,
        currentOrder.value.vendor!.longitude ?? 0.0,
      );
      print(" ${distanceInMeters} calculateDriverToRestaurantDetailscalculateDriverToRestaurantDetails one ");
    }else{
      distanceInMeters =   Geolocator.distanceBetween(
        driverModel.value.location!.latitude!,
        driverModel.value.location!.longitude!,
        currentOrder.value.vendor!.latitude ?? 0.0,
        currentOrder.value.vendor!.longitude ?? 0.0,
      );
      print(" ${distanceInMeters} calculateDriverToRestaurantDetailscalculateDriverToRestaurantDetails two ");
    }
    // Convert to kilometers
    driverToRestaurantDistance.value = distanceInMeters / 1000;
    // Calculate duration (assuming average speed of 30 km/h)
    driverToRestaurantDuration.value = (driverToRestaurantDistance.value / 30) * 60;
    // Calculate charge and round to nearest integer
    double charge = driverToRestaurantDistance.value * DRIVER_TO_RESTAURANT_RATE_PER_KM;
    driverToRestaurantCharge.value = charge.round().toDouble();
    print(" ${driverToRestaurantCharge.value} driverToRestaurantCharge ");
    print(" ${driverToRestaurantDuration.value}  driverToRestaurantDuration ");
    print(" ${driverToRestaurantDistance.value}  driverToRestaurantDistance ");
    print(" ${distanceInMeters}  distanceInMeters ");
    update();
  }
  static Future<VendorModel?> getVendorById(String vendorId) async {
    VendorModel? vendorModel;
    try {
      String? url = '${Constant.baseUrl}restaurant/vendors/$vendorId';
      print("getVendorById $url ");
      if (vendorId.isNotEmpty) {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            vendorModel = VendorModel.fromJson(responseData['data']);
          }
        } else if (response.statusCode == 404) {
          return null;
        } else {
          throw Exception('Failed to load vendor: ${response.statusCode}');
        }
      }
    } catch (e, s) {
      log('getVendorById error: $e $s');
      return null;
    }
    return vendorModel;
  }
  Future<void> calculateRestaurantToCustomerDetails() async {
    // Use latitudeValue/longitudeValue getters which handle both latitude/longitude fields and coordinates GeoPoint
    final vendorLat = currentOrder.value.vendor?.latitudeValue ?? 
                      currentOrder.value.vendor?.latitude ?? 
                      currentOrder.value.vendor?.coordinates?.latitude ?? 0.0;
    final vendorLng = currentOrder.value.vendor?.longitudeValue ?? 
                      currentOrder.value.vendor?.longitude ?? 
                      currentOrder.value.vendor?.coordinates?.longitude ?? 0.0;
    double distanceInMeters = Geolocator.distanceBetween(
      vendorLat,
      vendorLng,
      currentOrder.value.address?.location!.latitude ?? 0.0,
      currentOrder.value.address?.location!.longitude ?? 0.0,
    );
    // Convert to kilometers
    restaurantToCustomerDistance.value = distanceInMeters / 1000;
    // Calculate duration (assuming average speed of 30 km/h)
    restaurantToCustomerDuration.value = (restaurantToCustomerDistance.value / 30) * 60;
    // Calculate charge and round to nearest integer
    double charge = restaurantToCustomerDistance.value * RESTAURANT_TO_CUSTOMER_RATE_PER_KM;
    restaurantToCustomerCharge.value = charge.round().toDouble();
    print(" ${restaurantToCustomerCharge.value} calculateRestaurantToCustomerDetails ");
  }
  // Calculate total charges
  void calculateCharges() {
    totalCalculatedCharge.value = driverToRestaurantCharge.value + restaurantToCustomerCharge.value;
    print(" ${totalCalculatedCharge.value} calculateCharges ");
    print(" ${driverToRestaurantCharge.value} driverToRestaurantCharge ");
    update();
  }
  Map<String, dynamic> calculatedCharges={};
  // Update order with calculated charges
  Future<void> updateOrderWithCalculatedCharges() async {
    // Create a map to store calculated charges
 double? surgeAmount =await   fetchOrderSurgeFee(
        currentOrder.value.id.toString());
    Map<String, dynamic> calculatedCharges = {
      'driverToRestaurantDistance': driverToRestaurantDistance.value,
      'driverToRestaurantDuration': driverToRestaurantDuration.value,
      'driverToRestaurantCharge': driverToRestaurantCharge.value,
      'restaurantToCustomerDistance': restaurantToCustomerDistance.value,
      'restaurantToCustomerDuration': restaurantToCustomerDuration.value,
      'restaurantToCustomerCharge': restaurantToCustomerCharge.value,
      'tipsAmount':currentOrder.value.tipAmount,
      'surgeAmount':surgeAmount.toString(),
      'totalCalculatedCharge': "${totalCalculatedCharge.value+(surgeAmount??0 ) + double.parse(currentOrder.value.tipAmount
          .toString())}",
      'calculatedAt': FieldValue.serverTimestamp(),
    };
    print( "${calculatedCharges} calculatedCharges");
    currentOrder.value.calculatedCharges = calculatedCharges;
  }
  // Get calculated charges for display
  Map<String, dynamic>? getCalculatedCharges() {
    return currentOrder.value.calculatedCharges;
  }
  //NEW FUNCTION IN DRIVER APPLICATION
  RxBool isLoading = true.obs;
  flutterMap.MapController osmMapController = flutterMap.MapController();
  RxList<flutterMap.Marker> osmMarkers = <flutterMap.Marker>[].obs;
  
  // Timer for automatic order polling
  Timer? _orderPollingTimer;
  bool _isPolling = false;
  bool _isRefreshing = false; // Flag to prevent multiple simultaneous refreshes
  Duration _currentPollInterval = Duration(seconds: 5); // Current polling interval
  
  // Track which orders have already been notified to prevent duplicates
  final Set<String> _notifiedOrderIds = <String>{};
  
  // Performance optimizations
  Timer? _changeDataDebounceTimer;
  String? _lastRouteCacheKey; // Cache key for route calculations
  List<LatLng>? _cachedPolylineCoordinates; // Cached route coordinates
  CancelToken? _currentApiRequest; // For canceling duplicate API calls
  DateTime? _lastRouteCalculationTime;
  DateTime? _lastGetCurrentOrderTime;
  String? _lastFetchedOrderId; // Track last fetched order to avoid redundant calls
  static const Duration _routeCacheDuration = Duration(minutes: 2); // Cache routes for 2 minutes
  static const Duration _changeDataDebounceDelay = Duration(milliseconds: 300); // Debounce changeData calls
  static const Duration _minGetCurrentOrderInterval = Duration(seconds: 2); // Minimum interval between getCurrentOrder calls
  
  // Local notifications plugin for manual order updates
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    getArgument();
    setIcons();
    _initializeLocalNotifications();
    getDriver();
    driverChargeAdd();
    // Start automatic polling for new orders every 3 seconds
    _startOrderPolling();
    super.onInit();
  }
  
  /// Initialize local notifications for manual order updates
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: iosInitializationSettings,
    );
    await _localNotifications.initialize(initializationSettings);
    AppLogger.log('Local notifications initialized', tag: 'Notifications');
  }
  
  /// Show local notification when new orders are detected (for manual updates)
  Future<void> _showNewOrderNotification(String orderId) async {
    // Prevent duplicate notifications for the same order
    if (_notifiedOrderIds.contains(orderId)) {
      AppLogger.log('⚠️ Notification already shown for order: $orderId, skipping duplicate', tag: 'Notifications');
      return;
    }
    
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'manual_order_channel',
        'Manual Order Notifications',
        description: 'Notifications for manually inserted orders',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('order_ringtone'),
      );
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'manual_order_channel',
        'Manual Order Notifications',
        channelDescription: 'Notifications for manually inserted orders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: channel.sound,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([1000, 1000, 1000, 1000]),
        timeoutAfter: 30000, // 30 seconds
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'New Order Received',
        'You have a new order: $orderId. Please accept it soon!',
        notificationDetails,
        payload: orderId,
      );
      
      // Mark this order as notified to prevent duplicates
      _notifiedOrderIds.add(orderId);
      
      AppLogger.log('✅ Local notification shown for order: $orderId', tag: 'Notifications');
    } catch (e) {
      AppLogger.log('Error showing local notification: $e', tag: 'Notifications');
    }
  }
  
  /// Show popup dialog when new orders are detected
  Future<void> _showNewOrderDialog(String orderId) async {
    try {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'New Order Received!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have received a new order:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.orange, size: 24),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        orderId,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Text(
                'The order will appear on your screen shortly. Please check and accept it!',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Get.back();
                AppLogger.log('View Order clicked for: $orderId', tag: 'UserAction');
                // Force fetch this specific order
                await _forceFetchOrderById(orderId);
              },
              child: Text(
                'View Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'OK',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        barrierDismissible: false,
      );
      
      AppLogger.log('✅ Popup dialog shown for order: $orderId', tag: 'Notifications');
    } catch (e) {
      AppLogger.log('Error showing popup dialog: $e', tag: 'Notifications');
    }
  }
  
  /// Force fetch a specific order by ID and display it
  Future<void> _forceFetchOrderById(String orderId) async {
    AppLogger.log('Force fetching order: $orderId', tag: 'Function');
    try {
      // Try primary endpoint first
      final excludeStatuses = 'Order Cancelled,Driver Rejected,Order Completed';
      final primaryUri = Uri.parse(
          '${Constant.baseUrl}driver/get-current-reject-accept?order_id=$orderId&exclude_statuses=$excludeStatuses');
      bool orderFetched = false;
      try {
        final response = await http.get(
          primaryUri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          if (!response.body.trim().startsWith('<!') && !response.body.trim().startsWith('<html')) {
            try {
              final data = jsonDecode(response.body);
              if (data['success'] == true && data['order'] != null) {
                currentOrder.value = OrderModel.fromJson(data['order']);
                AppLogger.log('✅ Order fetched via PRIMARY endpoint - ID: ${currentOrder.value.id}', tag: 'API');
                orderFetched = true;
              }
            } catch (e) {
              AppLogger.log('Error parsing primary API response: $e', tag: 'API');
            }
          }
        }
      } catch (e) {
        AppLogger.log('Primary API failed: $e - will try fallback', tag: 'API');
      }
      
      // Try fallback endpoint if primary failed
      if (!orderFetched) {
        AppLogger.log('Trying FALLBACK endpoint for order: $orderId', tag: 'API');
        try {
          final fallbackUri = Uri.parse('${Constant.baseUrl}restaurant/orders/$orderId');
          final response = await http.get(
            fallbackUri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ).timeout(Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            if (!response.body.trim().startsWith('<!') && !response.body.trim().startsWith('<html')) {
              try {
                final data = jsonDecode(response.body);
                if (data['success'] == true && data['data'] != null) {
                  currentOrder.value = OrderModel.fromJson(data['data']);
                  AppLogger.log('✅ Order fetched via FALLBACK endpoint - ID: ${currentOrder.value.id}', tag: 'API');
                  orderFetched = true;
                }
              } catch (e) {
                AppLogger.log('Error parsing fallback API response: $e', tag: 'API');
              }
            }
          }
        } catch (e) {
          AppLogger.log('Fallback API also failed: $e', tag: 'API');
        }
      }
      
      // Process the fetched order
      if (orderFetched && currentOrder.value.id != null) {
        try {
          AppLogger.log('Order fetched successfully - ID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}', tag: 'API');
          
          // Ensure order status is set correctly for accept/reject buttons to show
          // If order is in orderRequestData, set status to Driver Pending if not already set
          if (driverModel.value.orderRequestData?.contains(orderId) ?? false) {
            if (currentOrder.value.status != Constant.driverPending && 
                (currentOrder.value.driverID == null || currentOrder.value.driverID?.isEmpty == true)) {
              currentOrder.value.status = Constant.driverPending;
              AppLogger.log('✅ Set order status to Driver Pending for accept/reject buttons', tag: 'UI');
            }
          }
          
          // Log order details for debugging
          AppLogger.log('Order Details - ID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}, DriverID: ${currentOrder.value.driverID}', tag: 'UI');
          AppLogger.log('Order Details - Vendor: ${currentOrder.value.vendor != null}, Address: ${currentOrder.value.address != null}', tag: 'UI');
          
          // If vendor is missing but vendorID exists, try to fetch vendor data
          if (currentOrder.value.vendor == null && 
              currentOrder.value.vendorID != null && 
              currentOrder.value.vendorID!.isNotEmpty) {
            AppLogger.log('Vendor missing, fetching vendor data for vendorID: ${currentOrder.value.vendorID}', tag: 'API');
            await _fetchVendorData(currentOrder.value.vendorID!);
          }
      
          calculateOrderChargesInitial();
          changeData();
          update(); // Force UI update
          AppLogger.log('✅ Order displayed successfully - Accept/Reject buttons should now work', tag: 'UI');
          AppLogger.log('Order Status: ${currentOrder.value.status}, DriverID: ${currentOrder.value.driverID}, Vendor: ${currentOrder.value.vendor != null}, Address: ${currentOrder.value.address != null}', tag: 'UI');
        } catch (e) {
          AppLogger.log('Error processing fetched order: $e', tag: 'Error');
          ShowToastDialog.showToast('Error processing order data. Please try again.');
        }
      } else {
        AppLogger.log('❌ Failed to fetch order: $orderId', tag: 'Error');
        ShowToastDialog.showToast('Failed to load order. Please try again.');
      }
    } catch (e) {
      AppLogger.log('Exception in _forceFetchOrderById: $e', tag: 'Error');
      ShowToastDialog.showToast('Error loading order. Please try again.');
    }
  }
  
  @override
  void onClose() {
    // Cancel polling timer when controller is disposed
    _orderPollingTimer?.cancel();
    _changeDataDebounceTimer?.cancel();
    _currentApiRequest?.cancel();
    super.onClose();
  }
  
  /// Start automatic polling for new orders with adaptive frequency
  void _startOrderPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _currentPollInterval = Duration(seconds: 5); // Start with 5 seconds
    AppLogger.log('Starting automatic order polling with adaptive frequency', tag: 'Polling');
    
    void _pollCallback(Timer timer) async {
      // Prevent multiple simultaneous refreshes
      if (_isRefreshing) {
        AppLogger.log('Skipping refresh - already in progress', tag: 'Polling');
        return;
      }
      
      try {
        // Refresh driver data to get latest orderRequestData
        await refreshHomeScreen();
        
        // Adaptive polling: If no active orders, poll less frequently
        final hasActiveOrders = (driverModel.value.orderRequestData?.isNotEmpty ?? false) ||
                               (driverModel.value.inProgressOrderID?.isNotEmpty ?? false) ||
                               (currentOrder.value.id != null);
        
        Duration desiredInterval = hasActiveOrders 
            ? Duration(seconds: 5)  // Active orders: poll every 5 seconds
            : Duration(seconds: 15); // No active orders: poll every 15 seconds
        
        // Restart timer with new interval if it changed
        if (_currentPollInterval != desiredInterval) {
          timer.cancel();
          _currentPollInterval = desiredInterval;
          _orderPollingTimer = Timer.periodic(_currentPollInterval, _pollCallback);
          AppLogger.log('Changed polling frequency to ${_currentPollInterval.inSeconds}s (${hasActiveOrders ? "active orders" : "no active orders"})', tag: 'Polling');
        }
        
        AppLogger.log('Periodic order check completed', tag: 'Polling');
      } catch (e) {
        AppLogger.log('Error in periodic order check: $e', tag: 'Polling');
        // Continue polling even on error - don't let temporary errors stop the timer
      }
    }
    
    _orderPollingTimer = Timer.periodic(_currentPollInterval, _pollCallback);
  }
  
  /// Manually trigger an immediate order refresh (called on app resume, pull-to-refresh, etc.)
  Future<void> forceRefreshOrders() async {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshing) {
      AppLogger.log('Force refresh skipped - already in progress', tag: 'Polling');
      return;
    }
    
    AppLogger.log('Force refresh orders triggered', tag: 'Polling');
    try {
      await refreshHomeScreen();
      AppLogger.log('Force refresh completed', tag: 'Polling');
    } catch (e) {
      AppLogger.log('Error in force refresh: $e', tag: 'Polling');
    }
  }
  

  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<OrderModel> currentOrder = OrderModel().obs;
  Rx<UserModel> driverModel = UserModel().obs;

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
    }
  }

  //acceptOrder() async {

  Future<void> acceptOrder() async {
    AppLogger.log('acceptOrder() called', tag: 'Function');
    AppLogger.log('Current Order ID: ${currentOrder.value.id}', tag: 'Function');
    AppLogger.log('Driver ID: ${driverModel.value.id}', tag: 'Function');
    AppLogger.log('Order Status: ${currentOrder.value.status}', tag: 'Function');
    AppLogger.log('Order Vendor: ${currentOrder.value.vendor != null}', tag: 'Function');
    AppLogger.log('Order Address: ${currentOrder.value.address != null}', tag: 'Function');
    await AudioPlayerService.playSound(false);
    AppLogger.log('Sound played for acceptOrder()', tag: 'Audio');
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      // Validate order and driver IDs
      if (currentOrder.value.id == null || currentOrder.value.id!.isEmpty) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Order ID is missing!".tr);
        AppLogger.log('❌ Order ID is missing! currentOrder.value.id: ${currentOrder.value.id}', tag: 'Error');
        // Try to refresh driver data and get order again
        await refreshHomeScreen();
        await getCurrentOrder();
        return;
      }
      
      if (driverModel.value.id == null || driverModel.value.id!.isEmpty) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Driver ID is missing!".tr);
        AppLogger.log('❌ Driver ID is missing! driverModel.value.id: ${driverModel.value.id}', tag: 'Error');
        // Try to refresh driver data
        await getDriver();
        return;
      }
      AppLogger.log('Attempting to assign order to driver', tag: 'Firestore');
      final assignResult = await FireStoreUtils.assignOrderToDriverFCFS(
        orderId: currentOrder.value.id!,
        driverId: driverModel.value.id!,
        driverModel: driverModel.value,
      );
      AppLogger.log('assignOrderToDriverFCFS result: $assignResult', tag: 'Firestore');
      // Handle rate limiting (429)
      if (assignResult == null) {
        ShowToastDialog.closeLoader();
        Get.snackbar(
          "Rate Limited",
          "Too many requests. Please wait a moment and try again.",
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
        AppLogger.log('Rate limited (429) - order not cleared, user can retry', tag: 'Error');
        await AudioPlayerService.playSound(false); // Stop sound
        return; // Don't clear order, allow retry
      }
      if (assignResult == true) {
        driverModel.value.orderRequestData?.remove(currentOrder.value.id);
        // Clean up notification tracking for accepted order
        if (currentOrder.value.id != null) {
          _notifiedOrderIds.remove(currentOrder.value.id!);
        }
        driverModel.value.inProgressOrderID ??= [];
        driverModel.value.inProgressOrderID?.add(currentOrder.value.id!);
        await FireStoreUtils.updateUser(driverModel.value);
        AppLogger.log('Driver updated in Firestore after accept', tag: 'Firestore');
        // Update order status and driver info
        currentOrder.value.status = Constant.driverAccepted;
        currentOrder.value.driverID = driverModel.value.id;
        currentOrder.value.driver = driverModel.value;
        // Calculate charges before saving
        await calculateOrderCharges();
        // Save order to Firestore
        await FireStoreUtils.setOrder(currentOrder.value);
        AppLogger.log('Order updated in Firestore after accept', tag: 'Firestore');
        // Refresh order from API to get complete details (vendor address, etc.)
        AppLogger.log('Refreshing order from API to get complete details', tag: 'API');
        try {
          final refreshResponse = await http.get(
            Uri.parse("${Constant.baseUrl}restaurant/orders/${currentOrder.value.id}"),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ).timeout(Duration(seconds: 10));
          if (refreshResponse.statusCode == 200) {
            if (!refreshResponse.body.trim().startsWith('<!') && !refreshResponse.body.trim().startsWith('<html')) {
              try {
                final refreshData = jsonDecode(refreshResponse.body);
                if (refreshData['success'] == true && refreshData['data'] != null) {
                  currentOrder.value = OrderModel.fromJson(refreshData['data']);
                  AppLogger.log('✅ Order refreshed after accept - ID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}', tag: 'API');
                  AppLogger.log('Vendor: ${currentOrder.value.vendor != null}, Address: ${currentOrder.value.address != null}', tag: 'API');
                  
                  // If vendor is missing but vendorID exists, fetch vendor data
                  if (currentOrder.value.vendor == null && 
                      currentOrder.value.vendorID != null && 
                      currentOrder.value.vendorID!.isNotEmpty) {
                    AppLogger.log('Vendor missing after refresh, fetching vendor data for vendorID: ${currentOrder.value.vendorID}', tag: 'API');
                    await _fetchVendorData(currentOrder.value.vendorID!);
                  }
                  
                  // Recalculate charges with fresh data
                  await calculateOrderChargesInitial();
                  changeData(); // Update map and directions
                }
              } catch (e) {
                AppLogger.log('Error parsing refreshed order: $e', tag: 'API');
              }
            }
          }
        } catch (e) {
          AppLogger.log('Error refreshing order after accept: $e', tag: 'API');
          // Continue even if refresh fails - order is already accepted
        }
        ShowToastDialog.closeLoader();
        // Send notifications
        if (currentOrder.value.author?.fcmToken != null) {
          await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
              currentOrder.value.author!.fcmToken.toString(), {});
          AppLogger.log('Notification sent to customer', tag: 'CloudFunction');
        }
        if (currentOrder.value.vendor?.fcmToken != null) {
          await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
              currentOrder.value.vendor!.fcmToken.toString(), {});
          AppLogger.log('Notification sent to vendor', tag: 'CloudFunction');
        }
        ShowToastDialog.showToast("Order accepted successfully!".tr);
        AppLogger.log('✅ Order accepted successfully - Showing vendor address and full details', tag: 'UI');
        await AudioPlayerService.playSound(false); // Stop sound after accept
        update(); // Force UI update after accepting
      } else {
        ShowToastDialog.closeLoader();
        Get.snackbar(
          "Order Unavailable",
          "This order was already accepted by another driver.",
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
        AppLogger.log('Order already accepted by another driver', tag: 'Error');
        await AudioPlayerService.playSound(false); // Stop sound
        driverModel.value.orderRequestData?.remove(currentOrder.value.id);
        // Clean up notification tracking for rejected order
        if (currentOrder.value.id != null) {
          _notifiedOrderIds.remove(currentOrder.value.id!);
        }
        await FireStoreUtils.updateUser(driverModel.value);
        currentOrder.value = OrderModel();
        await clearMap();
        update();
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      Get.snackbar(
        "Error",
        "Failed to accept order. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
      AppLogger.log('Exception in acceptOrder: $e', tag: 'Error');
    }
  }
  // acceptOrder() async {
  //   await AudioPlayerService.playSound(false);
  //   ShowToastDialog.showLoader("Please wait".tr);
  //   driverModel.value.inProgressOrderID ?? [];
  //   driverModel.value.orderRequestData!.remove(currentOrder.value.id);
  //   driverModel.value.inProgressOrderID!.add(currentOrder.value.id);
  //
  //   await FireStoreUtils.updateUser(driverModel.value);
  //
  //   currentOrder.value.status = Constant.driverAccepted;
  //   currentOrder.value.driverID = driverModel.value.id;
  //   currentOrder.value.driver = driverModel.value;
  //
  //   await FireStoreUtils.setOrder(currentOrder.value);
  //   ShowToastDialog.closeLoader();
  //   await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
  //       currentOrder.value.author!.fcmToken.toString(), {});
  //   await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
  //       currentOrder.value.vendor!.fcmToken.toString(), {});
  // }
  Future<void> rejectOrder() async {
    AppLogger.log('rejectOrder() called', tag: 'Function');
    AppLogger.log('Current Order ID:  [${currentOrder.value.id}', tag: 'Function');
    await AudioPlayerService.playSound(false);
    AppLogger.log('Sound stopped for rejectOrder()', tag: 'Audio');
    currentOrder.value.rejectedByDrivers ??= [];
    AppLogger.log('Rejected drivers list initialized or used', tag: 'Firestore');
    if (driverModel.value.id != null) {
      currentOrder.value.rejectedByDrivers!.add(driverModel.value.id);
      AppLogger.log('Driver ID ${driverModel.value.id} added to rejected list', tag: 'Firestore');
    }
    await FireStoreUtils.setOrder(currentOrder.value);
    AppLogger.log('Firestore updated restaurant_orders/${currentOrder.value.id}', tag: 'Firestore');
    driverModel.value.orderRequestData?.remove(currentOrder.value.id);
    // Clean up notification tracking for rejected order
    if (currentOrder.value.id != null) {
      _notifiedOrderIds.remove(currentOrder.value.id!);
    }
    await FireStoreUtils.updateUser(driverModel.value);
    AppLogger.log('Driver updated in Firestore with removed orderRequestData', tag: 'Firestore');
    currentOrder.value = OrderModel();
    await clearMap();
    AppLogger.log('Map cleared and current order reset', tag: 'UI');
    update(); // Force UI update after rejecting
    if (Constant.singleOrderReceive == false) {
      Get.back();
      AppLogger.log('Navigated back after rejection (multi order allowed)', tag: 'Navigation');
    }
  }
  // rejectOrder() async {
  //   await AudioPlayerService.playSound(false);
  //   currentOrder.value.rejectedByDrivers ??= [];

  //   if (driverModel.value.id != null) {
  //     currentOrder.value.rejectedByDrivers!.add(driverModel.value.id);
  //   }
  //   await FireStoreUtils.setOrder(currentOrder.value);
  //   driverModel.value.orderRequestData?.remove(currentOrder.value.id);
  //   await FireStoreUtils.updateUser(driverModel.value);
  //   currentOrder.value = OrderModel();
  //   clearMap();
  //   if (Constant.singleOrderReceive == false) {
  //     Get.back();
  //   }
  // }

  clearMap() async {
    await AudioPlayerService.playSound(false);
    if (Constant.selectedMapType != 'osm') {
      markers.clear();
      polyLines.clear();
    } else {
      osmMarkers.clear();
      routePoints.clear();
      // Reset map ready flag when clearing map
      _osmMapReady = false;
    }
    update();
  }
  getCurrentOrder() async {
    // Throttle: Prevent too frequent calls
    if (_lastGetCurrentOrderTime != null && 
        DateTime.now().difference(_lastGetCurrentOrderTime!) < _minGetCurrentOrderInterval) {
      AppLogger.log('getCurrentOrder() throttled - too soon since last call', tag: 'Performance');
      return;
    }
    
    AppLogger.log('getCurrentOrder() called', tag: 'Function');
    AppLogger.log('inProgressOrderID: ${driverModel.value.inProgressOrderID}', tag: 'Function');
    AppLogger.log('orderRequestData: ${driverModel.value.orderRequestData}', tag: 'Function');
    AppLogger.log('currentOrder.id: ${currentOrder.value.id}', tag: 'Function');
    
    _lastGetCurrentOrderTime = DateTime.now();
    // Clear current order if it's no longer in driver's lists (unless it's in progress or pending)
    // BUT: Keep it if it has Driver Pending status with no driver assigned (handles timing issues)
    if (currentOrder.value.id != null &&
        !(driverModel.value.orderRequestData?.contains(currentOrder.value.id) ?? false) &&
        !(driverModel.value.inProgressOrderID?.contains(currentOrder.value.id) ?? false)) {
      // Don't clear if order is still pending and has no driver (might be timing issue)
      final isPendingWithNoDriver = (currentOrder.value.status == Constant.driverPending ||
                                      currentOrder.value.status == Constant.orderAccepted ||
                                      currentOrder.value.status == "Order Accepted") &&
                                     (currentOrder.value.driverID == null || 
                                      currentOrder.value.driverID?.isEmpty == true);
      if (!isPendingWithNoDriver) {
        currentOrder.value = OrderModel();
        await clearMap();
        await AudioPlayerService.playSound(false);
        AppLogger.log('No current order, cleared map and stopped sound', tag: 'UI');
      } else {
        AppLogger.log('Keeping pending order despite not being in arrays (timing issue): ${currentOrder.value.id}', tag: 'UI');
      }
      // Don't return here - continue to check for new orders
    }
    // Determine firstOrderId - prioritize inProgress orders
    String? firstOrderId;
    final inProgress = driverModel.value.inProgressOrderID;
    final orderRequest = driverModel.value.orderRequestData;
    
    AppLogger.log('Determining firstOrderId - singleOrderReceive: ${Constant.singleOrderReceive}, '
        'inProgress: $inProgress, orderRequest: $orderRequest', tag: 'Function');
    
    // Always check inProgress and orderRequest arrays (regardless of singleOrderReceive setting)
    // Priority 1: In-progress orders
    if (inProgress != null && inProgress.isNotEmpty) {
      // Filter out empty strings
      final validInProgress = inProgress.where((id) => id.isNotEmpty).toList();
      AppLogger.log('Valid inProgress orders: $validInProgress', tag: 'Function');
      if (validInProgress.isNotEmpty) {
        firstOrderId = validInProgress.first;
        AppLogger.log('✅ Using inProgressOrderID first order: $firstOrderId', tag: 'Function');
      } else {
        AppLogger.log('⚠️ inProgress array has items but all are empty strings', tag: 'Function');
      }
    } else {
      AppLogger.log('⚠️ inProgress is null or empty: $inProgress', tag: 'Function');
    }
    
    // Priority 2: Pending order requests
    if (firstOrderId == null && orderRequest != null && orderRequest.isNotEmpty) {
      // Filter out empty strings and already displayed orders
      final validOrderRequests = orderRequest.where((id) => 
        id.isNotEmpty && id != currentOrder.value.id).toList();
      AppLogger.log('Valid orderRequest orders: $validOrderRequests (excluding current: ${currentOrder.value.id})', tag: 'Function');
      if (validOrderRequests.isNotEmpty) {
        firstOrderId = validOrderRequests.first;
        AppLogger.log('✅ Using orderRequestData first order: $firstOrderId', tag: 'Function');
      } else {
        AppLogger.log('⚠️ orderRequest array has items but all are empty or already displayed', tag: 'Function');
      }
    } else if (firstOrderId == null) {
      AppLogger.log('⚠️ orderRequest is null or empty: $orderRequest', tag: 'Function');
    }
    
    // Fallback: If singleOrderReceive is false and we have orderModel, use it
    if (firstOrderId == null && Constant.singleOrderReceive == false && orderModel.value.id != null) {
      firstOrderId = orderModel.value.id.toString();
      AppLogger.log('Using orderModel.id: $firstOrderId', tag: 'Function');
    }
    // If we have a current order that's still valid, keep it
    if (firstOrderId == null || firstOrderId.isEmpty) {
      // If we already have a valid current order, keep it
      if (currentOrder.value.id != null && 
          ((inProgress?.contains(currentOrder.value.id) ?? false) ||
           (orderRequest?.contains(currentOrder.value.id) ?? false))) {
        AppLogger.log('Keeping existing current order: ${currentOrder.value.id}', tag: 'Function');
        return;
      }
      
      // FALLBACK: Check if we have a current order that should still be displayed
      // (e.g., order was just created but not yet in orderRequestData due to Cloud Function delay)
      if (currentOrder.value.id != null && 
          currentOrder.value.status == Constant.driverPending &&
          (currentOrder.value.driverID == null || currentOrder.value.driverID?.isEmpty == true)) {
        AppLogger.log('Keeping current order (Driver Pending, no driver assigned): ${currentOrder.value.id}', tag: 'Function');
        // Ensure it's processed and displayed
        if (currentOrder.value.vendor != null && currentOrder.value.address != null) {
          await calculateOrderChargesInitial();
          changeData();
          update();
        }
        return;
      }
      
      AppLogger.log('No valid firstOrderId found, exiting getCurrentOrder()', tag: 'UI');
      return;
    }
    // If the firstOrderId is the same as current order and it's still valid, skip API call
    if (currentOrder.value.id == firstOrderId) {
      AppLogger.log('Order $firstOrderId already displayed, skipping API call', tag: 'Function');
      return;
    }
    // Try to fetch order with fallback mechanism
    bool orderFetched = false;
    // METHOD 1: Try primary endpoint first
    final excludeStatuses = (inProgress?.contains(firstOrderId) ?? false)
        ? 'Order Cancelled,Driver Rejected,Order Completed'
        : 'Order Cancelled,Driver Rejected';
    final primaryUri = Uri.parse(
        '${Constant.baseUrl}driver/get-current-reject-accept?order_id=$firstOrderId&exclude_statuses=$excludeStatuses');
    AppLogger.log('getCurrentOrder - Trying primary API: $primaryUri', tag: 'API');
    try {
      final response = await http.get(
        primaryUri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      AppLogger.log('Primary API response status: ${response.statusCode}', tag: 'API');
      
      if (response.statusCode == 200) {
        // Check for HTML responses (error pages)
        if (!response.body.trim().startsWith('<!') && !response.body.trim().startsWith('<html')) {
          try {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['order'] != null) {
        currentOrder.value = OrderModel.fromJson(data['order']);
        _lastFetchedOrderId = currentOrder.value.id; // Track fetched order
        AppLogger.log('✅ Order fetched via PRIMARY endpoint - ID: ${currentOrder.value.id}', tag: 'API');
        orderFetched = true;
      }
          } catch (e) {
            AppLogger.log('Error parsing primary API response: $e', tag: 'API');
          }
        }
      } else if (response.statusCode == 500) {
        AppLogger.log('🚨 Primary API returned 500 - will try fallback endpoint', tag: 'API');
      }
    } catch (e) {
      AppLogger.log('Primary API failed: $e - will try fallback', tag: 'API');
    }
    // METHOD 2: Fallback to restaurant/orders endpoint if primary failed
    if (!orderFetched) {
      AppLogger.log('Trying FALLBACK endpoint: restaurant/orders/$firstOrderId', tag: 'API');
      try {
        final fallbackUri = Uri.parse('${Constant.baseUrl}restaurant/orders/$firstOrderId');
        final response = await http.get(
          fallbackUri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 10));
        
        AppLogger.log('Fallback API response status: ${response.statusCode}', tag: 'API');
        
        if (response.statusCode == 200) {
          // Check for HTML responses
          if (!response.body.trim().startsWith('<!') && !response.body.trim().startsWith('<html')) {
            try {
              final data = jsonDecode(response.body);
              if (data['success'] == true && data['data'] != null) {
                currentOrder.value = OrderModel.fromJson(data['data']);
                _lastFetchedOrderId = currentOrder.value.id; // Track fetched order
                AppLogger.log('✅ Order fetched via FALLBACK endpoint - ID: ${currentOrder.value.id}', tag: 'API');
                orderFetched = true;
              }
            } catch (e) {
              AppLogger.log('Error parsing fallback API response: $e', tag: 'API');
            }
          }
        }
      } catch (e) {
        AppLogger.log('Fallback API also failed: $e', tag: 'API');
      }
    }
    
    // If order was successfully fetched, process it
    if (orderFetched && currentOrder.value.id != null) {
      try {
        AppLogger.log('Order fetched successfully - ID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}', tag: 'API');
        // Ensure order status is set correctly for accept/reject buttons to show
        // If order is in orderRequestData OR has no driver assigned, set status to Driver Pending if needed
        if ((orderRequest?.contains(currentOrder.value.id) ?? false) ||
            (currentOrder.value.driverID == null || currentOrder.value.driverID?.isEmpty == true)) {
          // Set to Driver Pending if status is Order Accepted (restaurant accepted, waiting for driver)
          // or if status is not set and no driver assigned
          if ((currentOrder.value.status == Constant.orderAccepted || 
               currentOrder.value.status == "Order Accepted") &&
              (currentOrder.value.driverID == null || currentOrder.value.driverID?.isEmpty == true)) {
            // Keep Order Accepted status - UI will handle it
            AppLogger.log('Order has Order Accepted status, will show accept/reject buttons', tag: 'UI');
          } else if (currentOrder.value.status != Constant.driverPending && 
              currentOrder.value.status != Constant.driverAccepted &&
              currentOrder.value.status != Constant.orderShipped &&
              currentOrder.value.status != Constant.orderInTransit &&
              currentOrder.value.status != Constant.orderCompleted &&
              currentOrder.value.status != Constant.orderAccepted &&
              currentOrder.value.status != "Order Accepted") {
            currentOrder.value.status = Constant.driverPending;
            AppLogger.log('✅ Set order status to Driver Pending for accept/reject buttons', tag: 'UI');
          }
        }
        // Log order details before processing
        AppLogger.log('Order Details - ID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}, DriverID: ${currentOrder.value.driverID}', tag: 'UI');
        AppLogger.log('Order Details - Vendor: ${currentOrder.value.vendor != null}, Address: ${currentOrder.value.address != null}', tag: 'UI');
        
        // If vendor is missing but vendorID exists, try to fetch vendor data
        if (currentOrder.value.vendor == null && 
            currentOrder.value.vendorID != null && 
            currentOrder.value.vendorID!.isNotEmpty) {
          AppLogger.log('Vendor missing, fetching vendor data for vendorID: ${currentOrder.value.vendorID}', tag: 'API');
          await _fetchVendorData(currentOrder.value.vendorID!);
        }
        
        // Calculate charges early based on location (if vendor and address are available)
        if (currentOrder.value.vendor != null && 
            (driverModel.value.location != null || currentOrder.value.address?.location != null)) {
          AppLogger.log('Calculating charges early based on location', tag: 'Function');
          await calculateOrderChargesInitial();
        }
        
        // Track fetched order ID
        _lastFetchedOrderId = currentOrder.value.id;
        
        // Process and display order if:
        // 1. It's in inProgressOrderID or orderRequestData, OR
        // 2. It has Driver Pending status with no driver assigned (fallback for timing issues)
        if ((inProgress?.contains(currentOrder.value.id) ?? false) ||
            (orderRequest?.contains(currentOrder.value.id) ?? false) ||
            (currentOrder.value.status == Constant.driverPending &&
             (currentOrder.value.driverID == null || currentOrder.value.driverID?.isEmpty == true))) {
          changeData();
          AppLogger.log('Order processed and displayed', tag: 'API');
        }
        // Use reactive update for specific observables instead of full rebuild
        currentOrder.refresh();
        AppLogger.log('✅ Order Status: ${currentOrder.value.status}, DriverID: ${currentOrder.value.driverID}, Vendor: ${currentOrder.value.vendor != null}, Address: ${currentOrder.value.address != null}', tag: 'UI');
      } catch (parseError) {
        AppLogger.log('Error processing fetched order: $parseError', tag: 'API');
        currentOrder.value = OrderModel();
        await clearMap();
        update();
      }
      } else {
      // Order not found in either endpoint
      AppLogger.log('Order not found in any endpoint. Order ID: $firstOrderId', tag: 'API');
        // Remove missing/completed order from driver lists
        if (inProgress?.contains(firstOrderId) ?? false) {
          inProgress!.remove(firstOrderId);
          await FireStoreUtils.updateUser(driverModel.value);
        AppLogger.log('Removed missing order from inProgressOrderID', tag: 'API');
        } else if (orderRequest?.contains(firstOrderId) ?? false) {
          orderRequest!.remove(firstOrderId);
          await FireStoreUtils.updateUser(driverModel.value);
          AppLogger.log('Removed missing order from orderRequestData', tag: 'API');
        }
      
      // Only clear if this was the current order
      if (currentOrder.value.id == firstOrderId) {
        currentOrder.value = OrderModel();
        await clearMap();
        await AudioPlayerService.playSound(false);
        update();
        AppLogger.log('No order found, cleared map and stopped sound', tag: 'UI');
      }
    }
  }

  // Future<void> getCurrentOrder() async {
  //   final response = await http.post(
  //     Uri.parse("${Constant.baseUrl}driver/get-current-order"),
  //     body: {
  //       "driver_id": driverModel.value.id,
  //       "current_order_id": currentOrder.value.id ?? "",
  //       "argument_order_id": orderModel.value.id ?? "",
  //       "single_order_receive": Constant.singleOrderReceive.toString()
  //     },
  //   );
  //   final data = jsonDecode(response.body);
  //   switch(data["action"]) {
  //     case "clear_and_stopSound":
  //       currentOrder.value = OrderModel();
  //       await clearMap();
  //       await AudioPlayerService.playSound(false);
  //       break;
  //
  //     case "in_progress":
  //       currentOrder.value = OrderModel.fromJson(data["order"]);
  //       calculateOrderChargesInitial();
  //       changeData();
  //       break;
  //     case "remove_inProgress_and_clear":
  //       currentOrder.value = OrderModel();
  //       await clearMap();
  //       await AudioPlayerService.playSound(false);
  //       break;
  //     case "order_request":
  //       currentOrder.value = OrderModel.fromJson(data["order"]);
  //       calculateOrderChargesInitial();
  //       changeData();
  //       break;
  //     case "remove_request":
  //       currentOrder.value = OrderModel();
  //       await AudioPlayerService.playSound(false);
  //       break;
  //     case "order_by_argument":
  //       currentOrder.value = OrderModel.fromJson(data["order"]);
  //       calculateOrderChargesInitial();
  //       changeData();
  //       break;
  //     case "argument_not_found_stopSound":
  //       currentOrder.value = OrderModel();
  //       await AudioPlayerService.playSound(false);
  //       break;
  //   }
  //   update();
  // }
//finded
  RxBool isChange = false.obs;

  changeData() async {
    // Debounce: Cancel previous timer if exists
    _changeDataDebounceTimer?.cancel();
    
    // Create new debounced call
    _changeDataDebounceTimer = Timer(_changeDataDebounceDelay, () async {
      await _changeDataInternal();
    });
  }
  
  Future<void> _changeDataInternal() async {
    AppLogger.log('changeData() called', tag: 'Function');
    print(
        "currentOrder.value.status ::  [${currentOrder.value.id} :: ${currentOrder.value.status} :: ( ${orderModel.value.driver?.vendorID != null} :: ${orderModel.value.status})");

    if (Constant.mapType == "inappmap") {
      if (Constant.selectedMapType == "osm") {
        AppLogger.log('getOSMPolyline() called', tag: 'UI');
        getOSMPolyline();
      } else {
        AppLogger.log('🚀 getDirections() called - OrderID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}', tag: 'Function');
        // Check if Google Maps API key is available
        if (Constant.mapAPIKey.isEmpty) {
          AppLogger.log('⚠️ Google Maps API key is empty - attempting to fetch settings...', tag: 'Function');
          try {
            await FireStoreUtils.getSettings();
            // Update polylinePoints with the new API key if it was fetched
            if (Constant.mapAPIKey.isNotEmpty) {
              updatePolylinePoints();
            }
            AppLogger.log('✅ Settings fetched - API key: ${Constant.mapAPIKey.isEmpty ? "STILL EMPTY" : "SET (${Constant.mapAPIKey.length} chars)"}', tag: 'Function');
            if (Constant.mapAPIKey.isEmpty) {
              AppLogger.log('⚠️ Google Maps API key still empty - falling back to OSM', tag: 'Function');
              // Fallback to OSM if Google Maps key is not available
              if (Constant.selectedMapType != "osm") {
                getOSMPolyline();
                return;
              }
            }
          } catch (e, stackTrace) {
            AppLogger.log('Error fetching settings: $e', tag: 'Error');
            AppLogger.log('Stack trace: $stackTrace', tag: 'Error');
            AppLogger.log('⚠️ Google Maps API key still empty - falling back to OSM', tag: 'Function');
            if (Constant.selectedMapType != "osm") {
              getOSMPolyline();
              return;
            }
          }
        }
        getDirections();
      }
    }
    if (currentOrder.value.status == Constant.driverPending) {
      await AudioPlayerService.playSound(true);
      AppLogger.log('Sound played for driverPending', tag: 'Audio');
    } else {
      await AudioPlayerService.playSound(false);
      AppLogger.log('Sound stopped for non-pending order', tag: 'Audio');
    }
  }


  Future<void> getDriver() async {
    String? userId = await LoginController.getFirebaseId();
    AppLogger.log('getDriver() API called', tag: 'Function');
    try {
      var response = await http.get(
        Uri.parse("${Constant.baseUrl}users/$userId"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse["success"] == true && jsonResponse["data"] != null) {
          final previousOrderRequestData = driverModel.value.orderRequestData?.toList();
          driverModel.value = UserModel.fromJson(jsonResponse["data"]);
          if (driverModel.value.id != null) {
            isLoading.value = false;
            update();
            changeData();
            
            // Check if orderRequestData has changed and fetch orders immediately
            final currentOrderRequestData = driverModel.value.orderRequestData?.toList();
            final hasNewOrders = (currentOrderRequestData?.isNotEmpty ?? false) &&
                (previousOrderRequestData == null || 
                 currentOrderRequestData.toString() != previousOrderRequestData.toString());
            
            if (hasNewOrders) {
              AppLogger.log('🆕 NEW ORDERS DETECTED in orderRequestData: $currentOrderRequestData', tag: 'Function');
              
              // Find which orders are new
              final newOrderIds = currentOrderRequestData?.where((orderId) => 
                previousOrderRequestData == null || 
                !previousOrderRequestData.contains(orderId)
              ).toList() ?? [];
              
              // Show notification, popup, and play sound for each new order
              for (final orderId in newOrderIds) {
                if (orderId.isNotEmpty) {
                  AppLogger.log('📢 Showing notification for new order: $orderId', tag: 'Notifications');
                  await _showNewOrderNotification(orderId);
                  await AudioPlayerService.playSound(true);
                  AppLogger.log('🔊 Sound played for new order: $orderId', tag: 'Audio');
                }
              }
              // Wait a bit for dialog to show, then fetch orders immediately
              await Future.delayed(Duration(milliseconds: 500));
              await getCurrentOrder();
              // Force UI update to show the order
              update();
              AppLogger.log('✅ Order fetching completed after new order detection', tag: 'Function');
            } else if (driverModel.value.orderRequestData?.isNotEmpty ?? false) {
              // If orders exist, fetch them even if not new
              AppLogger.log('Existing orders in orderRequestData, fetching...', tag: 'Function');
              await getCurrentOrder();
            } else {
              // If no orders, still check in case we have inProgressOrderID
              await getCurrentOrder();
            }
            AppLogger.log("Driver profile fetched & order flow executed", tag: "API");
          }
        }
      } else if (response.statusCode == 429) {
        AppLogger.log("Rate limited (429) - will retry on next poll", tag: "API");
        // Don't throw error, just log - will retry on next poll
      } else {
        AppLogger.log("API failed: ${response.statusCode}", tag: "API");
      }

    } catch (e) {
      AppLogger.log("getDriver() Exception: $e", tag: "API");
    }
  }


  GoogleMapController? mapController;

  Rx<PolylinePoints> polylinePoints = PolylinePoints(apiKey: Constant.mapAPIKey.isNotEmpty ? Constant.mapAPIKey : '').obs;
  
  // Update polylinePoints when API key changes
  void updatePolylinePoints() {
    polylinePoints.value = PolylinePoints(apiKey: Constant.mapAPIKey.isNotEmpty ? Constant.mapAPIKey : '');
    AppLogger.log('Updated polylinePoints with API key: ${Constant.mapAPIKey.isNotEmpty ? "SET (${Constant.mapAPIKey.length} chars)" : "EMPTY"}', tag: 'Function');
  }
  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  RxMap<String, Marker> markers = <String, Marker>{}.obs;

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;

  setIcons() async {
    if (Constant.selectedMapType == 'google') {
      final Uint8List departure = await Constant()
          .getBytesFromAsset('assets/images/location_black3x.png', 100);
      final Uint8List destination = await Constant()
          .getBytesFromAsset('assets/images/location_orange3x.png', 100);
      final Uint8List driver = await Constant()
          .getBytesFromAsset('assets/images/food_delivery.png', 120);

      departureIcon = BitmapDescriptor.fromBytes(departure);
      destinationIcon = BitmapDescriptor.fromBytes(destination);
      taxiIcon = BitmapDescriptor.fromBytes(driver);
    }
  }

  getDirections() async {
    AppLogger.log('🚀 getDirections() called - OrderID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}', tag: 'Function');
    AppLogger.log('📍 Using Google Maps API key: ${Constant.mapAPIKey.isNotEmpty ? "SET (${Constant.mapAPIKey.length} chars)" : "EMPTY"}', tag: 'Function');
    if (currentOrder.value.id != null) {
      // Check if we can use cached route
      final routeCacheKey = _generateRouteCacheKey();
      if (routeCacheKey == _lastRouteCacheKey && 
          _cachedPolylineCoordinates != null &&
          _lastRouteCalculationTime != null &&
          DateTime.now().difference(_lastRouteCalculationTime!) < _routeCacheDuration) {
        AppLogger.log('✅ Using cached route (${_cachedPolylineCoordinates!.length} points)', tag: 'Performance');
        _applyCachedRoute();
        return;
      }
      if (currentOrder.value.status != Constant.driverPending) {
        if (currentOrder.value.status == Constant.orderShipped || 
            currentOrder.value.status == Constant.driverAccepted) {
          List<LatLng> polylineCoordinates = [];

          PolylineResult result = await polylinePoints.value
              .getRouteBetweenCoordinates(
              request: PolylineRequest(
                  origin: PointLatLng(
                      driverModel.value.location?.latitude ?? 0.0,
                      driverModel.value.location?.longitude ?? 0.0),
                  destination: PointLatLng(
                      currentOrder.value.vendor?.latitude ?? 0.0,
                      currentOrder.value.vendor?.longitude ?? 0.0),
                  mode: TravelMode.driving));
          if (result.points.isNotEmpty) {
            for (var point in result.points) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }
          }

          // Batch marker updates for better performance
          final newMarkers = <String, Marker>{};
          
          newMarkers['Departure'] = Marker(
              markerId: const MarkerId('Departure'),
              infoWindow: const InfoWindow(title: "Departure"),
              position: LatLng(currentOrder.value.vendor?.latitude ?? 0.0,
                  currentOrder.value.vendor?.longitude ?? 0.0),
              icon: departureIcon!);
          
          newMarkers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(driverModel.value.location?.latitude ?? 0.0,
                  driverModel.value.location?.longitude ?? 0.0),
              icon: taxiIcon!,
              rotation: double.parse(driverModel.value.rotation.toString()));
          
          // Update all markers at once
          markers.value = newMarkers;
          markers.refresh();

          // Cache the route for future use
          if (polylineCoordinates.isNotEmpty) {
            _lastRouteCacheKey = routeCacheKey;
            _cachedPolylineCoordinates = List.from(polylineCoordinates);
            _lastRouteCalculationTime = DateTime.now();
          }
          addPolyLine(polylineCoordinates);
        } else if (currentOrder.value.status == Constant.orderInTransit) {
          List<LatLng> polylineCoordinates = [];

          PolylineResult result = await polylinePoints.value
              .getRouteBetweenCoordinates(
              request: PolylineRequest(
                  origin: PointLatLng(
                      driverModel.value.location?.latitude ?? 0.0,
                      driverModel.value.location?.longitude ?? 0.0),
                  destination: PointLatLng(
                      currentOrder.value.address?.location?.latitude ?? 0.0,
                      currentOrder.value.address?.location?.longitude ??
                          0.0),
                  mode: TravelMode.driving));

          if (result.points.isNotEmpty) {
            for (var point in result.points) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }
          }
          // Batch marker updates for better performance
          final newMarkers = <String, Marker>{};
          
          newMarkers['Destination'] = Marker(
              markerId: const MarkerId('Destination'),
              infoWindow: const InfoWindow(title: "Destination"),
              position: LatLng(
                  currentOrder.value.address?.location?.latitude ?? 0.0,
                  currentOrder.value.address?.location?.longitude ?? 0.0),
              icon: destinationIcon!);

          newMarkers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(driverModel.value.location?.latitude ?? 0.0,
                  driverModel.value.location?.longitude ?? 0.0),
              icon: taxiIcon!,
              rotation: double.parse(driverModel.value.rotation.toString()));
          
          // Update all markers at once
          markers.value = newMarkers;
          markers.refresh();
          
          // Cache the route for future use
          if (polylineCoordinates.isNotEmpty) {
            _lastRouteCacheKey = routeCacheKey;
            _cachedPolylineCoordinates = List.from(polylineCoordinates);
            _lastRouteCalculationTime = DateTime.now();
          }
          addPolyLine(polylineCoordinates);
        }
      } else {
        // For driverPending status, use driver location as origin (not author location)
        // Author location may not be available, but we need to show route from driver to vendor
        List<LatLng> polylineCoordinates = [];

        // Get vendor coordinates - try latitudeValue/longitudeValue first, then fallback to coordinates GeoPoint
        final vendorLat = currentOrder.value.vendor?.latitudeValue ?? 
                          currentOrder.value.vendor?.latitude ?? 
                          currentOrder.value.vendor?.coordinates?.latitude;
        final vendorLng = currentOrder.value.vendor?.longitudeValue ?? 
                          currentOrder.value.vendor?.longitude ?? 
                          currentOrder.value.vendor?.coordinates?.longitude;
        
        // Validate we have vendor coordinates before calculating route
        if (vendorLat == null || vendorLng == null ||
            driverModel.value.location?.latitude == null ||
            driverModel.value.location?.longitude == null) {
          AppLogger.log(
            '⚠️ Cannot calculate directions (driverPending) - missing data. '
            'Vendor: ${currentOrder.value.vendor != null}, '
            'VendorLat: $vendorLat, '
            'VendorLng: $vendorLng, '
            'DriverLat: ${driverModel.value.location?.latitude}, '
            'DriverLng: ${driverModel.value.location?.longitude}',
            tag: 'Function');
          return;
        }

        PolylineResult result = await polylinePoints.value
            .getRouteBetweenCoordinates(
            request: PolylineRequest(
                origin: PointLatLng(
                    driverModel.value.location!.latitude!,
                    driverModel.value.location!.longitude!),
                destination: PointLatLng(vendorLat, vendorLng),
                mode: TravelMode.driving));

        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
          AppLogger.log('✅ Route calculated successfully - ${polylineCoordinates.length} points', tag: 'Function');
        } else {
          AppLogger.log('⚠️ Route calculation returned no points', tag: 'Function');
        }

        // Batch marker updates for better performance
        final newMarkers = <String, Marker>{};
        
        if (vendorLat != null && vendorLng != null) {
          newMarkers['Departure'] = Marker(
              markerId: const MarkerId('Departure'),
              infoWindow: const InfoWindow(title: "Departure"),
              position: LatLng(vendorLat, vendorLng),
              icon: departureIcon!);
        }

        if (currentOrder.value.address?.location?.latitude != null &&
            currentOrder.value.address?.location?.longitude != null) {
          newMarkers['Destination'] = Marker(
              markerId: const MarkerId('Destination'),
              infoWindow: const InfoWindow(title: "Destination"),
              position: LatLng(
                  currentOrder.value.address!.location!.latitude!,
                  currentOrder.value.address!.location!.longitude!),
              icon: destinationIcon!);
        }

        if (driverModel.value.location?.latitude != null && driverModel.value.location?.longitude != null) {
          newMarkers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(driverModel.value.location!.latitude!,
                  driverModel.value.location!.longitude!),
              icon: taxiIcon!,
              rotation: double.parse(driverModel.value.rotation.toString()));
        }
        
        // Update all markers at once
        markers.value = newMarkers;
        markers.refresh();
        
        if (polylineCoordinates.isNotEmpty) {
          // Cache the route for future use
          _lastRouteCacheKey = routeCacheKey;
          _cachedPolylineCoordinates = List.from(polylineCoordinates);
          _lastRouteCalculationTime = DateTime.now();
          addPolyLine(polylineCoordinates);
        } else {
          // Only refresh markers, not full update
          markers.refresh();
        }
      }
    }
  }
  
  // Generate cache key based on order status and coordinates
  String _generateRouteCacheKey() {
    final orderId = currentOrder.value.id ?? '';
    final status = currentOrder.value.status ?? '';
    final driverLat = driverModel.value.location?.latitude?.toStringAsFixed(4) ?? '0';
    final driverLng = driverModel.value.location?.longitude?.toStringAsFixed(4) ?? '0';
    
    if (status == Constant.orderShipped || status == Constant.driverAccepted) {
      final vendorLat = (currentOrder.value.vendor?.latitudeValue ?? 
                        currentOrder.value.vendor?.latitude ?? 0.0).toStringAsFixed(4);
      final vendorLng = (currentOrder.value.vendor?.longitudeValue ?? 
                        currentOrder.value.vendor?.longitude ?? 0.0).toStringAsFixed(4);
      return '$orderId-$status-$driverLat,$driverLng-$vendorLat,$vendorLng';
    } else if (status == Constant.orderInTransit) {
      final destLat = currentOrder.value.address?.location?.latitude?.toStringAsFixed(4) ?? '0';
      final destLng = currentOrder.value.address?.location?.longitude?.toStringAsFixed(4) ?? '0';
      return '$orderId-$status-$driverLat,$driverLng-$destLat,$destLng';
    } else if (status == Constant.driverPending) {
      final vendorLat = (currentOrder.value.vendor?.latitudeValue ?? 
                        currentOrder.value.vendor?.latitude ?? 0.0).toStringAsFixed(4);
      final vendorLng = (currentOrder.value.vendor?.longitudeValue ?? 
                        currentOrder.value.vendor?.longitude ?? 0.0).toStringAsFixed(4);
      return '$orderId-$status-$driverLat,$driverLng-$vendorLat,$vendorLng';
    }
    return '$orderId-$status-$driverLat,$driverLng';
  }
  
  // Apply cached route to map
  void _applyCachedRoute() {
    if (_cachedPolylineCoordinates != null && _cachedPolylineCoordinates!.isNotEmpty) {
      addPolyLine(_cachedPolylineCoordinates!);
    }
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    // mapOsmController.clearAllRoads();
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: AppThemeData.secondary300,
      points: polylineCoordinates,
      width: 8,
      geodesic: true,
    );
    // Use reactive update instead of full rebuild
    polyLines[id] = polyline;
    // Only update markers and polylines, not entire controller
    markers.refresh();
    polyLines.refresh();

    // Safely update camera location only if polyline coordinates exist
    if (polylineCoordinates.isNotEmpty && mapController != null) {
      updateCameraLocation(polylineCoordinates.first, mapController);
    }
  }

  Future<void> updateCameraLocation(
      LatLng source,
      GoogleMapController? mapController,
      ) async {
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: source,
          zoom: currentOrder.value.id == null ||
              currentOrder.value.status == Constant.driverPending
              ? 16
              : 20,
          bearing: double.parse(driverModel.value.rotation.toString()),
        ),
      ),
    );
  }

  // Track if OSM map is ready
  bool _osmMapReady = false;
  
  void setOsmMapReady(bool ready) {
    _osmMapReady = ready;
  }
  
  void animateToSource() {
    try {
      if (!_osmMapReady) {
        // Map not ready yet, schedule for later
        AppLogger.log('OSM map not ready yet, will retry after delay', tag: 'Function');
        Future.delayed(Duration(milliseconds: 1000), () {
          if (_osmMapReady) {
            try {
              osmMapController.move(
                  location.LatLng(driverModel.value.location?.latitude ?? 0.0,
                      driverModel.value.location?.longitude ?? 0.0),
                  16);
            } catch (e) {
              AppLogger.log('Error animating to source after delay: $e', tag: 'Error');
            }
          }
        });
        return;
      }
      osmMapController.move(
          location.LatLng(driverModel.value.location?.latitude ?? 0.0,
              driverModel.value.location?.longitude ?? 0.0),
          16);
    } catch (e) {
      AppLogger.log('Error animating to source: $e - Map may not be rendered yet', tag: 'Error');
      // Don't throw, just log - map will be ready on next update
      // Schedule retry
      Future.delayed(Duration(milliseconds: 1000), () {
        if (_osmMapReady) {
          try {
            osmMapController.move(
                location.LatLng(driverModel.value.location?.latitude ?? 0.0,
                    driverModel.value.location?.longitude ?? 0.0),
                16);
          } catch (e2) {
            AppLogger.log('Error animating to source on retry: $e2', tag: 'Error');
          }
        }
      });
    }
  }

  Rx<location.LatLng> source =
      location.LatLng(21.1702, 72.8311).obs; // Start (e.g., Surat)
  Rx<location.LatLng> current =
      location.LatLng(21.1800, 72.8400).obs; // Moving marker
  Rx<location.LatLng> destination =
      location.LatLng(21.2000, 72.8600).obs; // Destination

  setOsmMapMarker() {
    osmMarkers.value = [
      flutterMap.Marker(
        point: current.value,
        width: 45,
        height: 45,
        rotate: true,
        child: Image.asset('assets/images/food_delivery.png'),
      ),
      flutterMap.Marker(
        point: source.value,
        width: 40,
        height: 40,
        child: Image.asset('assets/images/location_black3x.png'),
      ),
      flutterMap.Marker(
        point: destination.value,
        width: 40,
        height: 40,
        child: Image.asset('assets/images/location_orange3x.png'),
      )
    ];
  }

  void getOSMPolyline() async {
    try {
      if (currentOrder.value.id != null) {
        if (currentOrder.value.status != Constant.driverPending) {
          print(
              "Order Status :: ${currentOrder.value.status} :: OrderId :: ${currentOrder.value.id}} ::");
          if (currentOrder.value.status == Constant.orderShipped || 
              currentOrder.value.status == Constant.driverAccepted) {
            current.value = location.LatLng(
                driverModel.value.location?.latitude ?? 0.0,
                driverModel.value.location?.longitude ?? 0.0);
            // Get vendor coordinates - try latitudeValue/longitudeValue first, then fallback to coordinates GeoPoint
            final vendorLat = currentOrder.value.vendor?.latitudeValue ?? 
                              currentOrder.value.vendor?.latitude ?? 
                              currentOrder.value.vendor?.coordinates?.latitude ?? 0.0;
            final vendorLng = currentOrder.value.vendor?.longitudeValue ?? 
                              currentOrder.value.vendor?.longitude ?? 
                              currentOrder.value.vendor?.coordinates?.longitude ?? 0.0;
            destination.value = location.LatLng(vendorLat, vendorLng);
            // Delay animateToSource to ensure map is rendered
            Future.delayed(Duration(milliseconds: 500), () {
              animateToSource();
            });
            fetchRoute(current.value, destination.value).then((value) {
              setOsmMapMarker();
            });
          } else if (currentOrder.value.status == Constant.orderInTransit) {
            print(
                ":::::::::::::${currentOrder.value.status}::::::::::::::::::44");
            current.value = location.LatLng(
                driverModel.value.location?.latitude ?? 0.0,
                driverModel.value.location?.longitude ?? 0.0);
            destination.value = location.LatLng(
              currentOrder.value.address?.location?.latitude ?? 0.0,
              currentOrder.value.address?.location?.longitude ?? 0.0,
            );
            setOsmMapMarker();
            fetchRoute(current.value, destination.value).then((value) {
              setOsmMapMarker();
            });
            // Delay animateToSource to ensure map is rendered
            Future.delayed(Duration(milliseconds: 500), () {
              animateToSource();
            });
          }
        } else {
          // For driverPending status, use driver location as origin (not author location)
          // Author location may not be available, but we need to show route from driver to vendor
          print("====>5");
          
          // Get vendor coordinates - try latitudeValue/longitudeValue first, then fallback to coordinates GeoPoint
          final vendorLat = currentOrder.value.vendor?.latitudeValue ?? 
                            currentOrder.value.vendor?.latitude ?? 
                            currentOrder.value.vendor?.coordinates?.latitude;
          final vendorLng = currentOrder.value.vendor?.longitudeValue ?? 
                            currentOrder.value.vendor?.longitude ?? 
                            currentOrder.value.vendor?.coordinates?.longitude;
          
          // Validate we have vendor and driver coordinates before calculating route
          if (vendorLat == null || vendorLng == null ||
              driverModel.value.location?.latitude == null ||
              driverModel.value.location?.longitude == null) {
            AppLogger.log(
              '⚠️ Cannot calculate OSM directions (driverPending) - author or vendor data missing. '
              'Author: ${currentOrder.value.author != null}, '
              'Vendor: ${currentOrder.value.vendor != null}, '
              'VendorLat: $vendorLat, '
              'VendorLng: $vendorLng, '
              'DriverLat: ${driverModel.value.location?.latitude}, '
              'DriverLng: ${driverModel.value.location?.longitude}',
              tag: 'Function');
            return;
          }

          current.value = location.LatLng(
              driverModel.value.location!.latitude!,
              driverModel.value.location!.longitude!);

          destination.value = location.LatLng(vendorLat, vendorLng);
          // Delay animateToSource to ensure map is rendered
          Future.delayed(Duration(milliseconds: 500), () {
            animateToSource();
          });
          fetchRoute(current.value, destination.value).then((value) {
            setOsmMapMarker();
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  RxList<location.LatLng> routePoints = <location.LatLng>[].obs;
  Future<void> fetchRoute(
      location.LatLng source, location.LatLng destination) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${source.longitude},${source.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Safely access routes array
      if (decoded['routes'] != null &&
          decoded['routes'] is List &&
          decoded['routes'].isNotEmpty &&
          decoded['routes'][0] != null &&
          decoded['routes'][0]['geometry'] != null &&
          decoded['routes'][0]['geometry']['coordinates'] != null) {

        final geometry = decoded['routes'][0]['geometry']['coordinates'];

        routePoints.clear();
        for (var coord in geometry) {
          if (coord is List && coord.length >= 2) {
            final lon = coord[0];
            final lat = coord[1];
            routePoints.add(location.LatLng(lat, lon));
          }
        }
      } else {
        print("Invalid route data structure received");
      }
    } else {
      print("Failed to get route: ${response.body}");
    }
  }


  Future<void> refreshCurrentOrder() async {
    AppLogger.log('refreshCurrentOrder() API called', tag: 'Function');
    if (currentOrder.value.id != null) {
      try {
        final response = await http.get(
          Uri.parse("${Constant.baseUrl}restaurant/orders/${currentOrder.value.id}"),
        );
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body["success"] == true && body["data"] != null) {
            try {
              currentOrder.value = OrderModel.fromJson(body["data"]);
              AppLogger.log(
                  "Order Refreshed via API -> ID: ${currentOrder.value.id} | Status: ${currentOrder.value.status}",
                  tag: "API"
              );
              
              // Log vendor parsing status
              if (currentOrder.value.vendor != null) {
                final vendorLat = currentOrder.value.vendor?.latitudeValue ?? 
                                  currentOrder.value.vendor?.latitude ?? 
                                  currentOrder.value.vendor?.coordinates?.latitude;
                final vendorLng = currentOrder.value.vendor?.longitudeValue ?? 
                                  currentOrder.value.vendor?.longitude ?? 
                                  currentOrder.value.vendor?.coordinates?.longitude;
                AppLogger.log(
                    "[OrderModel] Vendor parsed from order - Location: ${currentOrder.value.vendor?.location}, "
                    "Title: ${currentOrder.value.vendor?.title}, "
                    "Lat: $vendorLat, Lng: $vendorLng",
                    tag: "OrderModel");
              } else if (currentOrder.value.vendorID != null) {
                AppLogger.log(
                    "[OrderModel] Vendor not in order, but vendorID exists: ${currentOrder.value.vendorID}",
                    tag: "OrderModel");
                // Try to fetch vendor data if missing
                await _fetchVendorData(currentOrder.value.vendorID!);
              } else {
                AppLogger.log(
                    "[OrderModel] No vendor data in order and no vendorID",
                    tag: "OrderModel");
              }
            } catch (e, stackTrace) {
              AppLogger.log(
                  "Error parsing order from API response: $e\nStack trace: $stackTrace",
                  tag: "API");
              AppLogger.log("Response body: ${response.body}", tag: "API");
              rethrow;
            }
            
            // Ensure order status is set correctly for accept/reject buttons
            // If order is in orderRequestData and no driver assigned, set status to Driver Pending
            if (driverModel.value.orderRequestData?.contains(currentOrder.value.id) ?? false) {
              if (currentOrder.value.status != Constant.driverPending && 
                  (currentOrder.value.driverID == null || currentOrder.value.driverID?.isEmpty == true)) {
                currentOrder.value.status = Constant.driverPending;
                AppLogger.log('✅ Set order status to Driver Pending after refresh', tag: 'UI');
              }
            }
            
            AppLogger.log('Order Details - Vendor: ${currentOrder.value.vendor != null}, Address: ${currentOrder.value.address != null}', tag: 'UI');
            
            // If vendor is missing but vendorID exists, try to fetch vendor data
            if (currentOrder.value.vendor == null && 
                currentOrder.value.vendorID != null && 
                currentOrder.value.vendorID!.isNotEmpty) {
              AppLogger.log('Vendor missing, fetching vendor data for vendorID: ${currentOrder.value.vendorID}', tag: 'API');
              await _fetchVendorData(currentOrder.value.vendorID!);
            }

            changeData();
            update(); // Force UI update
          } else {
            AppLogger.log("Order not found - clearing", tag: "API");
            currentOrder.value = OrderModel();
            update();
          }
        } else {
          AppLogger.log("API Error → ${response.statusCode}", tag: "API");
        }

      } catch (e) {
        AppLogger.log("API Exception → $e", tag: "Exception");
      }
    }
  }

  Future<void> refreshHomeScreen() async {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshing) {
      AppLogger.log('refreshHomeScreen() skipped - already in progress', tag: 'Function');
      return;
    }
    
    _isRefreshing = true;
    AppLogger.log('refreshHomeScreen() called', tag: 'Function');

    try {
      String? userId = await LoginController.getFirebaseId();
      
      // Store previous orderRequestData to detect changes
      final previousOrderRequestData = driverModel.value.orderRequestData?.toList();
      
      /// API CALL instead of Firestore
      final response = await http.get(
        Uri.parse("${Constant.baseUrl}users/$userId"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          /// Convert to UserModel from response.data
          driverModel.value = UserModel.fromJson(responseData['data']);
          AppLogger.log("Driver data refreshed from API", tag: "API");
          AppLogger.log("orderRequestData: ${driverModel.value.orderRequestData}", tag: "API");
          AppLogger.log("inProgressOrderID: ${driverModel.value.inProgressOrderID}", tag: "API");
          
          // Check if orderRequestData has changed (new orders detected)
          final currentOrderRequestData = driverModel.value.orderRequestData?.toList();
          final hasNewOrders = (currentOrderRequestData?.isNotEmpty ?? false) &&
              (previousOrderRequestData == null || 
               currentOrderRequestData.toString() != previousOrderRequestData.toString());
          
          if (hasNewOrders) {
            AppLogger.log('🆕 NEW ORDERS DETECTED! Fetching immediately...', tag: 'API');
            
            // Find which orders are new
            final newOrderIds = currentOrderRequestData?.where((orderId) => 
              previousOrderRequestData == null || 
              !previousOrderRequestData.contains(orderId)
            ).toList() ?? [];
            
            // Show notification, popup, and play sound for each new order
            for (final orderId in newOrderIds) {
              if (orderId.isNotEmpty) {
                AppLogger.log('📢 Showing notification for new order: $orderId', tag: 'Notifications');
                await _showNewOrderNotification(orderId);
                // await _showNewOrderDialog(orderId);
                await AudioPlayerService.playSound(true);
                AppLogger.log('🔊 Sound played for new order: $orderId', tag: 'Audio');
              }
            }
            
            // Wait a bit for dialog to show, then fetch orders immediately
            await Future.delayed(Duration(milliseconds: 500));
            await getCurrentOrder();
            // Force UI update to show the order
            update();
            AppLogger.log('✅ Order fetching completed after new order detection', tag: 'API');
          }
        }
      } else if (response.statusCode == 429) {
        AppLogger.log("Rate limited (429) - will retry on next poll", tag: "API");
        // Don't throw error, just log - will retry on next poll
      } else {
        AppLogger.log("Failed to get user | Code: ${response.statusCode}",
            tag: "API");
      }

      /// Refresh existing order if we have one
      if (currentOrder.value.id != null) {
        await refreshCurrentOrder();
      } else {
        // If no current order, check for new orders from orderRequestData
        await getCurrentOrder();
        
        // FALLBACK: If still no order but orderRequestData is empty, 
        // check if there's a pending order that should be displayed
        // (handles case where order was created but Cloud Function hasn't updated orderRequestData yet)
        if (currentOrder.value.id == null && 
            (driverModel.value.orderRequestData?.isEmpty ?? true) &&
            (driverModel.value.inProgressOrderID?.isEmpty ?? true)) {
          AppLogger.log('No orders in arrays, checking for pending orders via API fallback', tag: 'Function');
          // This is handled by the periodic polling, so we don't need to do anything here
          // The next poll will catch it once Cloud Function updates orderRequestData
        }
      }

      update();
      AppLogger.log('Home screen refresh completed', tag: 'UI');

    } catch (e) {
      AppLogger.log('Error refreshing home screen: $e', tag: 'Error');
      // Even on error, try to fetch current order
      await getCurrentOrder();
    } finally {
      // Always reset the refresh flag
      _isRefreshing = false;
    }
  }

  /// Fetch vendor data by vendorID if missing from order
  Future<void> _fetchVendorData(String vendorID) async {
    try {
      AppLogger.log('Fetching vendor data for vendorID: $vendorID', tag: 'API');
      
      // Try API endpoint first
      final response = await http.get(
        Uri.parse("${Constant.baseUrl}restaurant/vendors/$vendorID"),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('<!') && !response.body.trim().startsWith('<html')) {
          try {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['data'] != null) {
              try {
                // Handle case where data['data'] might be a String (JSON string) or Map
                dynamic vendorData = data['data'];
                if (vendorData is String) {
                  // If it's a JSON string, parse it first
                  vendorData = jsonDecode(vendorData);
                }
                if (vendorData is Map<String, dynamic>) {
                  currentOrder.value.vendor = VendorModel.fromJson(vendorData);
                  AppLogger.log('✅ Vendor data fetched successfully', tag: 'API');
                  update(); // Update UI
                  return;
                } else {
                  AppLogger.log('Vendor data is not a Map: ${vendorData.runtimeType}', tag: 'API');
                }
              } catch (parseError) {
                AppLogger.log('Error creating VendorModel from API data: $parseError', tag: 'API');
                AppLogger.log('Vendor data type: ${data['data'].runtimeType}', tag: 'API');
              }
            }
          } catch (e) {
            AppLogger.log('Error parsing vendor API response: $e', tag: 'API');
          }
        }
      }
      
      // Fallback: Try Firestore
      AppLogger.log('API failed, trying Firestore for vendor: $vendorID', tag: 'API');
      try {
        final vendorDoc = await firestore.FirebaseFirestore.instance.collection('vendors').doc(vendorID).get();
        if (vendorDoc.exists) {
          final vendorData = vendorDoc.data();
          if (vendorData != null) {
            try {
              currentOrder.value.vendor = VendorModel.fromJson(Map<String, dynamic>.from(vendorData));
              AppLogger.log('✅ Vendor data fetched from Firestore', tag: 'API');
              update(); // Update UI
            } catch (parseError) {
              AppLogger.log('Error creating VendorModel from Firestore data: $parseError', tag: 'API');
              AppLogger.log('Vendor data: $vendorData', tag: 'API');
            }
          } else {
            AppLogger.log('❌ Vendor document exists but data is null', tag: 'API');
          }
        } else {
          AppLogger.log('❌ Vendor not found in Firestore', tag: 'API');
        }
      } catch (firestoreError) {
        AppLogger.log('Firestore error: $firestoreError', tag: 'API');
      }
    } catch (e) {
      AppLogger.log('Error fetching vendor data: $e', tag: 'API');
    }
  }

}
