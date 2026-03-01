import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/app/home_screen/controller/home_controller.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/preferences.dart';
import 'package:jippydriver_driver/utils/version_utils.dart';
import 'package:jippydriver_driver/app/mandatory_update_screen.dart';
import 'package:get/get.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:flutter/material.dart';
import 'package:location/location.dart' as location_package;

class DashBoardController extends GetxController with WidgetsBindingObserver {
  RxInt drawerIndex = 0.obs;
  
  // Location update throttling variables
  UserLocation? _lastUpdatedLocation; // Last location that was sent to Firestore
  DateTime? _lastUpdateTime; // Last time location was updated to Firestore
  List<UserLocation> _pendingLocationUpdates = []; // Queue for batching updates
  Timer? _batchUpdateTimer; // Timer for batched updates
  bool _isAppInForeground = true; // Track app lifecycle state
  
  // Throttling constants
  static const double _minDistanceMeters = 100.0; // Minimum distance to trigger update (changed from 50m)
  static const Duration _minTimeInterval = Duration(seconds: 30); // Minimum time between updates
  static const Duration _batchInterval = Duration(seconds: 10); // Batch updates every 10 seconds
  static const int _maxBatchSize = 5; // Maximum locations to batch
  
  // Background optimization
  static const double _backgroundMinDistanceMeters = 200.0; // Larger distance in background
  static const Duration _backgroundMinTimeInterval = Duration(seconds: 60); // Longer interval in background

  @override
  void onInit() {
    AppLogger.log('DashBoardController onInit() called', tag: 'Controller');
    WidgetsBinding.instance.addObserver(this);
    
    // Check for mandatory update when user is already logged in
    _checkMandatoryUpdate();
    
    getUser();
    updateDriverOrder();
    getThem();
    // Initialize HomeController to ensure it's available for HomeScreen
    Get.put(HomeController());
    super.onInit();
  }
  
  /// Check for mandatory update (for already logged-in users)
  Future<void> _checkMandatoryUpdate() async {
    try {
      await FireStoreUtils.getForceUpdateConfig();
      final updateRequired = await isMandatoryUpdateRequired();
      if (updateRequired) {
        AppLogger.log('Mandatory update required (logged-in user) -> MandatoryUpdateScreen', tag: 'Update');
        Get.offAll(const MandatoryUpdateScreen());
      }
    } catch (e) {
      AppLogger.log('Error checking mandatory update: $e', tag: 'Update');
    }
  }

  @override
  void onClose() {
    AppLogger.log('DashBoardController onClose() called', tag: 'Controller');
    WidgetsBinding.instance.removeObserver(this);
    _batchUpdateTimer?.cancel();
    super.onClose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    AppLogger.log('📱 Location update - App lifecycle: ${_isAppInForeground ? "Foreground" : "Background"}', tag: 'Location');
    
    // Flush pending updates when app comes to foreground
    if (_isAppInForeground && _pendingLocationUpdates.isNotEmpty) {
      _flushPendingUpdates();
    }
    
    // Check for mandatory update when app comes to foreground
    if (_isAppInForeground) {
      _checkMandatoryUpdate();
    }
  }

  Rx<UserModel> userModel = UserModel().obs;

  DateTime? currentBackPressTime;
  RxBool canPopNow = false.obs;

  Future<void> getUser() async {
    String? userId = await LoginController.getFirebaseId();
    await updateCurrentLocation();

    final response = await http.get(Uri.parse("${Constant.baseUrl}users/$userId"));
print("getUser ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        userModel.value = UserModel.fromJson(data['data']);
        Constant.userModel = UserModel.fromJson(data['data']);
      }
    } else {
      print("Error fetching user → ${response.statusCode}");
    }
  }

  RxString isDarkMode = "Light".obs;
  RxBool isDarkModeSwitch = false.obs;
  getThem() {
    isDarkMode.value = Preferences.getString(Preferences.themKey);
    if (isDarkMode.value == "Dark") {
      isDarkModeSwitch.value = true;
    } else if (isDarkMode.value == "Light") {
      isDarkModeSwitch.value = false;
    } else {
      isDarkModeSwitch.value = false;
    }
  }


  updateDriverOrder() async {
    List<OrderModel> orders = [];
    final response = await http.get(
      Uri.parse('${Constant.baseUrl}update-driver-order'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['orders'] != null) {
        for (var element in data['orders']) {
          try {
            orders.add(OrderModel.fromJson(element));
          } catch (e, s) {
            print('watchOrdersStatus parse error ${element['id']} $e $s');
          }
        }
      }
    } else {
      print('API request failed with status: ${response.statusCode}');
    }
    // Update triggerDelivery for each order
    for (var orderModel in orders) {
      // Ensure we always store a valid Firestore Timestamp
      orderModel.triggerDelivery = Timestamp.now();
      // Send updated order back (assuming setOrder is same)
      await FireStoreUtils.setOrder(orderModel);
    }
  }

  location_package.Location location = location_package.Location();
  
  /// Calculate distance between two locations in meters
  double _calculateDistance(UserLocation loc1, UserLocation loc2) {
    // Handle nullable coordinates with defaults
    final lat1 = loc1.latitude ?? 0.0;
    final lon1 = loc1.longitude ?? 0.0;
    final lat2 = loc2.latitude ?? 0.0;
    final lon2 = loc2.longitude ?? 0.0;
    
    return geolocator.Geolocator.distanceBetween(
      lat1,
      lon1,
      lat2,
      lon2,
    );
  }
  
  /// Check if location update should be sent based on throttling rules
  bool _shouldUpdateLocation(UserLocation newLocation) {
    final now = DateTime.now();
    
    // Get throttling parameters based on app state
    final minDistance = _isAppInForeground 
        ? _minDistanceMeters 
        : _backgroundMinDistanceMeters;
    final minTimeInterval = _isAppInForeground 
        ? _minTimeInterval 
        : _backgroundMinTimeInterval;
    
    // First update - always allow
    if (_lastUpdatedLocation == null || _lastUpdateTime == null) {
      return true;
    }
    
    // Check distance threshold
    final distanceMoved = _calculateDistance(_lastUpdatedLocation!, newLocation);
    if (distanceMoved < minDistance) {
      AppLogger.log('📍 Location update skipped - distance too small: ${distanceMoved.toStringAsFixed(1)}m < ${minDistance}m', tag: 'Location');
      return false;
    }
    
    // Check time threshold
    final timeSinceLastUpdate = now.difference(_lastUpdateTime!);
    if (timeSinceLastUpdate < minTimeInterval) {
      AppLogger.log('📍 Location update skipped - too soon: ${timeSinceLastUpdate.inSeconds}s < ${minTimeInterval.inSeconds}s', tag: 'Location');
      return false;
    }
    
    return true;
  }
  
  /// Add location to batch queue
  void _addToBatch(UserLocation location, double? heading) {
    _pendingLocationUpdates.add(location);
    
    // Start batch timer if not already running
    if (_batchUpdateTimer == null || !_batchUpdateTimer!.isActive) {
      _batchUpdateTimer = Timer(_batchInterval, () {
        _flushPendingUpdates();
      });
    }
    
    // Flush immediately if batch is full
    if (_pendingLocationUpdates.length >= _maxBatchSize) {
      _flushPendingUpdates();
    }
  }
  
  /// Flush pending location updates to Firestore
  Future<void> _flushPendingUpdates() async {
    if (_pendingLocationUpdates.isEmpty) return;
    
    // Cancel batch timer
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = null;
    
    // Get the most recent location from batch (most accurate)
    final latestLocation = _pendingLocationUpdates.last;
    _pendingLocationUpdates.clear();
    
    // Update Firestore with latest location
    await _updateLocationToFirestore(latestLocation, null);
  }
  
  /// Update location to Firestore (with throttling check)
  Future<void> _updateLocationToFirestore(UserLocation newLocation, double? heading) async {
    try {
      String? userId = await LoginController.getFirebaseId();
      if (userId == null) return;
      
      await FireStoreUtils.getUserProfile(userId).then((value) async {
        if (value != null) {
          userModel.value = value;
          if (userModel.value.isActive == true) {
            userModel.value.location = newLocation;
            if (heading != null) {
              userModel.value.rotation = heading;
            }
            
            await FireStoreUtils.updateUser(userModel.value);
            
            // Update tracking variables
            _lastUpdatedLocation = newLocation;
            _lastUpdateTime = DateTime.now();
            
            final distanceMoved = _lastUpdatedLocation != null && _lastUpdatedLocation != newLocation
                ? _calculateDistance(_lastUpdatedLocation!, newLocation)
                : 0.0;
            
            AppLogger.log(
              '✅ Location updated to Firestore - Distance: ${distanceMoved.toStringAsFixed(1)}m, '
              'Lat: ${(newLocation.latitude ?? 0.0).toStringAsFixed(6)}, Lng: ${(newLocation.longitude ?? 0.0).toStringAsFixed(6)}, '
              'Mode: ${_isAppInForeground ? "Foreground" : "Background"}',
              tag: 'Location'
            );
            // Note: HomeController is already updated in _handleLocationUpdate for immediate map updates
          }
        }
      });
    } catch (e) {
      AppLogger.log('Error updating location to Firestore: $e', tag: 'Location');
    }
  }
  
  /// Handle location update with throttling and batching
  Future<void> _handleLocationUpdate(location_package.LocationData locationData) async {
    // Always update local location data for immediate use
    Constant.locationDataFinal = locationData;
    
    final newLocation = UserLocation(
      latitude: locationData.latitude ?? 0.0,
      longitude: locationData.longitude ?? 0.0,
    );
    
    // Update HomeController immediately for smooth map marker movement (like Zomato)
    // This ensures the driver marker moves smoothly even before Firestore update
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        // Update driver location immediately for smooth map updates
        homeController.driverModel.value.location = newLocation;
        if (locationData.heading != null) {
          homeController.driverModel.value.rotation = locationData.heading!;
        }
        // Update bike marker position immediately (no debounce) - follows blue dot smoothly
        // Also optionally update camera to follow driver (smooth, non-intrusive)
        homeController.updateDriverMarkerPosition(updateCamera: true);
        // Also trigger full map update (debounced) for route recalculation if needed
        homeController.changeData();
      }
    } catch (e) {
      // HomeController might not be initialized yet, that's okay
      AppLogger.log('⚠️ Could not update HomeController location immediately: $e', tag: 'Location');
    }
    
    // Check if update should be sent based on throttling rules
    if (_shouldUpdateLocation(newLocation)) {
      // In foreground, update immediately for better UX
      // In background, batch updates to reduce writes
      if (_isAppInForeground) {
        await _updateLocationToFirestore(newLocation, locationData.heading);
      } else {
        _addToBatch(newLocation, locationData.heading);
      }
    } else {
      // Still add to batch for background mode (will be processed later)
      if (!_isAppInForeground) {
        _addToBatch(newLocation, locationData.heading);
      }
    }
  }
  
  updateCurrentLocation() async {
    try {
      String? userId = await LoginController.getFirebaseId();
      location_package.PermissionStatus permissionStatus = await location.hasPermission();
      
      // Use 100m distance filter (increased from 50m) but keep high accuracy
      // The actual throttling logic is handled in _handleLocationUpdate
      final distanceFilter = 100.0; // Increased from 50m
      
      if (permissionStatus == location_package.PermissionStatus.granted) {
        location.enableBackgroundMode(enable: true);
        location.changeSettings(
          accuracy: location_package.LocationAccuracy.high, // Keep high accuracy for GPS
          distanceFilter: distanceFilter, // Filter at OS level (100m)
        );
        
        location.onLocationChanged.listen((locationData) async {
          await _handleLocationUpdate(locationData);
        });
      } else {
        location.requestPermission().then((permissionStatus) {
          if (permissionStatus == location_package.PermissionStatus.granted) {
            location.enableBackgroundMode(enable: true);
            location.changeSettings(
              accuracy: location_package.LocationAccuracy.high, // Keep high accuracy
              distanceFilter: distanceFilter, // Filter at OS level (100m)
            );
            
            location.onLocationChanged.listen((locationData) async {
              await _handleLocationUpdate(locationData);
              ShowToastDialog.closeLoader();
            });
          } else {
            ShowToastDialog.closeLoader();
          }
        });
      }
    } catch (e) {
      AppLogger.log('Error in updateCurrentLocation: $e', tag: 'Location');
    }
  }
}
