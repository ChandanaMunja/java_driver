import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/utils/app_logger.dart';
// import '../services/order_service.dart';
// import 'package:jippydriver_driver/services/order_service.dart';
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
    // final charges = await FireStoreUtils().getDriverCharges();
    // print(" Pickup: ${charges["pickup_charges"]}");
    // print("Delivery: ${charges["user_delivery_charge"]}");
    // DRIVER_TO_RESTAURANT_RATE_PER_KM =double.parse(charges["pickup_charges"]);
    // RESTAURANT_TO_CUSTOMER_RATE_PER_KM = double.parse(charges["user_delivery_charge"]);; // ₹7 per km
    print(" Pickup: ${editProfileController.selectedZone.value.pickupCharges}");
    print("Delivery: ${editProfileController.selectedZone.value.userDeliveryCharge}");
    DRIVER_TO_RESTAURANT_RATE_PER_KM =double.parse(editProfileController.selectedZone.value.pickupCharges??'2');
    RESTAURANT_TO_CUSTOMER_RATE_PER_KM = double.parse(editProfileController.selectedZone.value.userDeliveryCharge??"7");; // ₹7 per
    print(" ${driverToRestaurantCharge.value} driverToRestaurantCharge ");
    update();
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
    double distanceInMeters = Geolocator.distanceBetween(
      driverModel.value.location!.latitude!,
      driverModel.value.location!.longitude!,
      currentOrder.value.vendor!.latitude ?? 0.0,
      currentOrder.value.vendor!.longitude ?? 0.0,
    );
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


  Future<void> calculateRestaurantToCustomerDetails() async {
    double distanceInMeters = Geolocator.distanceBetween(
      currentOrder.value.vendor!.latitude ?? 0.0,
      currentOrder.value.vendor!.longitude ?? 0.0,
      currentOrder.value.address!.location!.latitude ?? 0.0,
      currentOrder.value.address!.location!.longitude ?? 0.0,
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

  @override
  void onInit() {
    getArgument();
    setIcons();
    getDriver();
    driverChargeAdd();
    super.onInit();
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
    await AudioPlayerService.playSound(false);
    AppLogger.log('Sound played for acceptOrder()', tag: 'Audio');
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      if (currentOrder.value.id == null || driverModel.value.id == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Order or driver ID is missing!".tr);
        AppLogger.log('Order or driver ID is missing!', tag: 'Error');
        return;
      }
      AppLogger.log('Attempting to assign order to driver', tag: 'Firestore');
      // Calculate charges before accepting
      bool success = await FireStoreUtils.assignOrderToDriverFCFS(
        orderId: currentOrder.value.id!,
        driverId: driverModel.value.id!,
        driverModel: driverModel.value,
      );
      AppLogger.log('assignOrderToDriverFCFS result: $success', tag: 'Firestore');
      if (success) {
        driverModel.value.orderRequestData?.remove(currentOrder.value.id);
        driverModel.value.inProgressOrderID ??= [];
        driverModel.value.inProgressOrderID?.add(currentOrder.value.id!);
        await FireStoreUtils.updateUser(driverModel.value);
        AppLogger.log('Driver updated in Firestore after accept', tag: 'Firestore');
        currentOrder.value.status = Constant.driverAccepted;
        currentOrder.value.driverID = driverModel.value.id;
        currentOrder.value.driver = driverModel.value;
        await calculateOrderCharges();
        await FireStoreUtils.setOrder(currentOrder.value);
        AppLogger.log('Order updated in Firestore after accept', tag: 'Firestore');
        ShowToastDialog.closeLoader();
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
        AppLogger.log('Order accepted successfully', tag: 'UI');
      } else {
        ShowToastDialog.closeLoader();
        Get.snackbar(
          "Order Unavailable",
          "This order was already accepted by another driver.",
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
        AppLogger.log('Order already accepted by another driver', tag: 'Error');
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
    AppLogger.log('Sound played for rejectOrder()', tag: 'Audio');
    currentOrder.value.rejectedByDrivers ??= [];
    AppLogger.log('Rejected drivers list initialized or used', tag: 'Firestore');
    if (driverModel.value.id != null) {
      currentOrder.value.rejectedByDrivers!.add(driverModel.value.id);
      AppLogger.log('Driver ID ${driverModel.value.id} added to rejected list', tag: 'Firestore');
    }
    await FireStoreUtils.setOrder(currentOrder.value);
    AppLogger.log('Firestore updated restaurant_orders/${currentOrder.value.id}', tag: 'Firestore');
    driverModel.value.orderRequestData?.remove(currentOrder.value.id);
    await FireStoreUtils.updateUser(driverModel.value);
    AppLogger.log('Driver updated in Firestore with removed orderRequestData', tag: 'Firestore');
    currentOrder.value = OrderModel();
    clearMap();
    AppLogger.log('Map cleared and current order reset', tag: 'UI');
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
      // osmMapController = flutterMap.MapController();
    }
    update();
  }

  getCurrentOrder() async {
    AppLogger.log('getCurrentOrder() called', tag: 'Function');
    AppLogger.log('inProgressOrderID: ${driverModel.value.inProgressOrderID}', tag: 'Function');
    AppLogger.log('orderRequestData: ${driverModel.value.orderRequestData}', tag: 'Function');
    AppLogger.log('currentOrder.id: ${currentOrder.value.id}', tag: 'Function');
    
    if (currentOrder.value.id != null &&
        !(driverModel.value.orderRequestData?.contains(currentOrder.value.id) ?? false) &&
        !(driverModel.value.inProgressOrderID?.contains(currentOrder.value.id) ?? false)) {
      currentOrder.value = OrderModel();
      await clearMap();
      await AudioPlayerService.playSound(false);
      AppLogger.log('No current order, cleared map and stopped sound', tag: 'UI');
      return;
    }

    // Determine firstOrderId
    String? firstOrderId;
    final inProgress = driverModel.value.inProgressOrderID;
    final orderRequest = driverModel.value.orderRequestData;
    if (Constant.singleOrderReceive == true) {
      if (inProgress != null && inProgress.isNotEmpty) {
        firstOrderId = inProgress.first;
        AppLogger.log('Using inProgressOrderID first order: $firstOrderId', tag: 'Function');
      } else if (orderRequest != null && orderRequest.isNotEmpty) {
        firstOrderId = orderRequest.first;
        AppLogger.log('Using orderRequestData first order: $firstOrderId', tag: 'Function');
      }
    } else if (orderModel.value.id != null) {
      firstOrderId = orderModel.value.id.toString();
      AppLogger.log('Using orderModel.id: $firstOrderId', tag: 'Function');
    }
    if (firstOrderId == null || firstOrderId.isEmpty) {
      AppLogger.log('No valid firstOrderId found, exiting getCurrentOrder()', tag: 'UI');
      return;
    }
    // Construct API URL
    final excludeStatuses = (inProgress?.contains(firstOrderId) ?? false)
        ? 'Order Cancelled,Driver Rejected,Order Completed'
        : 'Order Cancelled,Driver Rejected';
    final uri = Uri.parse(
        '${Constant.baseUrl}driver/get-current-reject-accept?order_id=$firstOrderId&exclude_statuses=$excludeStatuses');
    AppLogger.log('getCurrentOrder API URL: $uri', tag: 'API');
    try {
      final response = await http.get(uri);
      AppLogger.log('getCurrentOrder API response status: ${response.statusCode}', tag: 'API');
      AppLogger.log('getCurrentOrder API response body: ${response.body}', tag: 'API');
      
      if (response.statusCode != 200) {
        AppLogger.log('API call failed with status: ${response.statusCode}', tag: 'API');
        return;
      }
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['order'] != null) {
        currentOrder.value = OrderModel.fromJson(data['order']);
        AppLogger.log('Order fetched successfully - ID: ${currentOrder.value.id}, Status: ${currentOrder.value.status}, DriverID: ${currentOrder.value.driverID}', tag: 'API');
        calculateOrderChargesInitial();
        if ((inProgress?.contains(currentOrder.value.id) ?? false) ||
            (orderRequest?.contains(currentOrder.value.id) ?? false)) {
          changeData();
          AppLogger.log('Fetched order: $firstOrderId via API and called changeData()', tag: 'API');
        }
        update(); // Ensure UI updates after fetching order
      } else {
        AppLogger.log('API returned success=false or order=null. Response: $data', tag: 'API');
        // Remove missing/completed order from driver lists
        if (inProgress?.contains(firstOrderId) ?? false) {
          inProgress!.remove(firstOrderId);
          await FireStoreUtils.updateUser(driverModel.value);
          AppLogger.log('Removed completed order from inProgressOrderID', tag: 'API');
        } else if (orderRequest?.contains(firstOrderId) ?? false) {
          orderRequest!.remove(firstOrderId);
          await FireStoreUtils.updateUser(driverModel.value);
          AppLogger.log('Removed missing order from orderRequestData', tag: 'API');
        }
        currentOrder.value = OrderModel();
        await clearMap();
        await AudioPlayerService.playSound(false);
        update();
        AppLogger.log('No order found, cleared map and stopped sound', tag: 'UI');
      }
    } catch (e, stackTrace) {
      AppLogger.log('Error fetching order via API: $e', tag: 'API');
      AppLogger.log('Stack trace: $stackTrace', tag: 'API');
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
    AppLogger.log('changeData() called', tag: 'Function');
    print(
        "currentOrder.value.status ::  [${currentOrder.value.id} :: ${currentOrder.value.status} :: ( ${orderModel.value.driver?.vendorID != null} :: ${orderModel.value.status})");

    if (Constant.mapType == "inappmap") {
      if (Constant.selectedMapType == "osm") {
        getOSMPolyline();
        AppLogger.log('getOSMPolyline() called', tag: 'UI');
      } else {
        getDirections();
        AppLogger.log('getDirections() called', tag: 'UI');
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
      var response = await http.get(Uri.parse("${Constant.baseUrl}users/$userId"));
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse["success"] == true && jsonResponse["data"] != null) {
          driverModel.value = UserModel.fromJson(jsonResponse["data"]);
          if (driverModel.value.id != null) {
            isLoading.value = false;
            update();
            changeData();
            getCurrentOrder();
            AppLogger.log("Driver profile fetched & order flow executed", tag: "API");
          }
        }
      } else {
        AppLogger.log("API failed: ${response.statusCode}", tag: "API");
      }

    } catch (e) {
      AppLogger.log("getDriver() Exception: $e", tag: "API");
    }
  }


  GoogleMapController? mapController;

  Rx<PolylinePoints> polylinePoints = PolylinePoints(apiKey:  Constant.mapAPIKey,).obs;
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
    if (currentOrder.value.id != null) {
      if (currentOrder.value.status != Constant.driverPending) {
        if (currentOrder.value.status == Constant.orderShipped) {
          List<LatLng> polylineCoordinates = [];

          PolylineResult result = await polylinePoints.value
              .getRouteBetweenCoordinates(
              // googleApiKey: Constant.mapAPIKey,
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

          markers.remove("Departure");
          markers['Departure'] = Marker(
              markerId: const MarkerId('Departure'),
              infoWindow: const InfoWindow(title: "Departure"),
              position: LatLng(currentOrder.value.vendor?.latitude ?? 0.0,
                  currentOrder.value.vendor?.longitude ?? 0.0),
              icon: departureIcon!);
          // ignore: invalid_use_of_protected_member
          if (markers.value.containsKey("Destination")) {
            markers.remove("Destination");
          }
          // markers['Destination'] = Marker(
          //     markerId: const MarkerId('Destination'),
          //     infoWindow: const InfoWindow(title: "Destination"),
          //     position: LatLng(currentOrder.value.address!.location!.latitude ?? 0.0, currentOrder.value.address!.location!.longitude ?? 0.0),
          //     icon: destinationIcon!);

          markers.remove("Driver");
          markers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(driverModel.value.location?.latitude ?? 0.0,
                  driverModel.value.location?.longitude ?? 0.0),
              icon: taxiIcon!,
              rotation: double.parse(driverModel.value.rotation.toString()));

          addPolyLine(polylineCoordinates);
        } else if (currentOrder.value.status == Constant.orderInTransit) {
          List<LatLng> polylineCoordinates = [];

          PolylineResult result = await polylinePoints.value
              .getRouteBetweenCoordinates(
              // googleApiKey: Constant.mapAPIKey,
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
          // ignore: invalid_use_of_protected_member
          if (markers.value.containsKey("Departure")) {
            markers.remove("Departure");
          }
          // markers['Departure'] = Marker(
          //     markerId: const MarkerId('Departure'),
          //     infoWindow: const InfoWindow(title: "Departure"),
          //     position: LatLng(currentOrder.value.vendor!.latitude ?? 0.0, currentOrder.value.vendor!.longitude ?? 0.0),
          //     icon: departureIcon!);

          markers.remove("Destination");
          markers['Destination'] = Marker(
              markerId: const MarkerId('Destination'),
              infoWindow: const InfoWindow(title: "Destination"),
              position: LatLng(
                  currentOrder.value.address?.location?.latitude ?? 0.0,
                  currentOrder.value.address?.location?.longitude ?? 0.0),
              icon: destinationIcon!);

          markers.remove("Driver");
          markers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(driverModel.value.location?.latitude ?? 0.0,
                  driverModel.value.location?.longitude ?? 0.0),
              icon: taxiIcon!,
              rotation: double.parse(driverModel.value.rotation.toString()));
          addPolyLine(polylineCoordinates);
        }
      } else {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.value
            .getRouteBetweenCoordinates(
            // googleApiKey: Constant.mapAPIKey,
            request: PolylineRequest(
                origin: PointLatLng(
                    currentOrder.value.author?.location?.latitude ?? 0.0,
                    currentOrder.value.author?.location?.longitude ?? 0.0),
                destination: PointLatLng(
                    currentOrder.value.vendor?.latitude ?? 0.0,
                    currentOrder.value.vendor?.longitude ?? 0.0),
                mode: TravelMode.driving));

        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }

        markers.remove("Departure");
        markers['Departure'] = Marker(
            markerId: const MarkerId('Departure'),
            infoWindow: const InfoWindow(title: "Departure"),
            position: LatLng(currentOrder.value.vendor?.latitude ?? 0.0,
                currentOrder.value.vendor?.longitude ?? 0.0),
            icon: departureIcon!);

        markers.remove("Destination");
        markers['Destination'] = Marker(
            markerId: const MarkerId('Destination'),
            infoWindow: const InfoWindow(title: "Destination"),
            position: LatLng(
                currentOrder.value.address?.location?.latitude ?? 0.0,
                currentOrder.value.address?.location?.longitude ?? 0.0),
            icon: destinationIcon!);

        markers.remove("Driver");
        markers['Driver'] = Marker(
            markerId: const MarkerId('Driver'),
            infoWindow: const InfoWindow(title: "Driver"),
            position: LatLng(driverModel.value.location?.latitude ?? 0.0,
                driverModel.value.location?.longitude ?? 0.0),
            icon: taxiIcon!,
            rotation: double.parse(driverModel.value.rotation.toString()));
        addPolyLine(polylineCoordinates);
      }
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
    polyLines[id] = polyline;
    update();

    // Safely update camera location only if polyline coordinates exist
    if (polylineCoordinates.isNotEmpty) {
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

  void animateToSource() {
    osmMapController.move(
        location.LatLng(driverModel.value.location?.latitude ?? 0.0,
            driverModel.value.location?.longitude ?? 0.0),
        16);
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
          if (currentOrder.value.status == Constant.orderShipped) {
            current.value = location.LatLng(
                driverModel.value.location?.latitude ?? 0.0,
                driverModel.value.location?.longitude ?? 0.0);
            destination.value = location.LatLng(
              currentOrder.value.vendor?.latitude ?? 0.0,
              currentOrder.value.vendor?.longitude ?? 0.0,
            );
            animateToSource();
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
            animateToSource();
          }
        } else {
          print("====>5");
          current.value = location.LatLng(
              currentOrder.value.author?.location?.latitude ?? 0.0,
              currentOrder.value.author?.location?.longitude ?? 0.0);

          destination.value = location.LatLng(
              currentOrder.value.vendor?.latitude ?? 0.0,
              currentOrder.value.vendor?.longitude ?? 0.0);
          animateToSource();
          fetchRoute(current.value, destination.value).then((value) {
            setOsmMapMarker();
          });
          animateToSource();
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
            currentOrder.value = OrderModel.fromJson(body["data"]);

            AppLogger.log(
                "Order Refreshed via API -> ID: ${currentOrder.value.id} | Status: ${currentOrder.value.status}",
                tag: "API"
            );

            changeData();
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
    AppLogger.log('refreshHomeScreen() called', tag: 'Function');

    try {
      String? userId = await LoginController.getFirebaseId();
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
        }
      } else {
        AppLogger.log("Failed to get user | Code: ${response.statusCode}",
            tag: "API");
      }

      /// Refresh existing order
      if (currentOrder.value.id != null) {
        await refreshCurrentOrder(); // convert this also later
      }

      /// Setup order listeners again (convert later)
      getCurrentOrder();

      update();
      AppLogger.log('Home screen refresh completed', tag: 'UI');

    } catch (e) {
      AppLogger.log('Error refreshing home screen: $e', tag: 'Error');
    }
  }

}
