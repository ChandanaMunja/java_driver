import 'dart:convert';

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
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';

class DashBoardController extends GetxController {
  RxInt drawerIndex = 0.obs;

  @override
  void onInit() {
    AppLogger.log('DashBoardController onInit() called', tag: 'Controller');
    // TODO: implement onInit

    getUser();
    updateDriverOrder();
    getThem();
    // Initialize HomeController to ensure it's available for HomeScreen
    Get.put(HomeController());
    super.onInit();
  }

  @override
  void onClose() {
    AppLogger.log('DashBoardController onClose() called', tag: 'Controller');
    super.onClose();
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
      orderModel.triggerDelivery = DateTime.now() as Timestamp?;
      // Send updated order back (assuming setOrder is same)
      await FireStoreUtils.setOrder(orderModel);
    }
  }

  Location location = Location();
  updateCurrentLocation() async {
    try {
      String? userId = await LoginController.getFirebaseId();
      PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == PermissionStatus.granted) {
        location.enableBackgroundMode(enable: true);
        location.changeSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: double.parse(Constant.driverLocationUpdate));
        location.onLocationChanged.listen((locationData) async {
          String? userId = await LoginController.getFirebaseId();
          Constant.locationDataFinal = locationData;
          await FireStoreUtils.getUserProfile(userId)
              .then((value) async {
            if (value != null) {
              userModel.value = value;
              if (userModel.value.isActive == true) {
                userModel.value.location = UserLocation(
                    latitude: locationData.latitude ?? 0.0,
                    longitude: locationData.longitude ?? 0.0);
                userModel.value.rotation = locationData.heading;
                await FireStoreUtils.updateUser(userModel.value);
              }
            }
          });
        });
      } else {
        location.requestPermission().then((permissionStatus) {
          if (permissionStatus == PermissionStatus.granted) {
            location.enableBackgroundMode(enable: true);
            location.changeSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: double.parse(Constant.driverLocationUpdate));
            location.onLocationChanged.listen((locationData) async {
              Constant.locationDataFinal = locationData;
              await FireStoreUtils.getUserProfile(
                     userId)
                  .then((value) async {
                if (value != null) {
                  userModel.value = value;
                  if (userModel.value.isActive == true) {
                    userModel.value.location = UserLocation(
                        latitude: locationData.latitude ?? 0.0,
                        longitude: locationData.longitude ?? 0.0);
                    userModel.value.rotation = locationData.heading;
                    await FireStoreUtils.updateUser(userModel.value);
                  }
                  ShowToastDialog.closeLoader();
                }
              });
            });
          } else {
            ShowToastDialog.closeLoader();
          }
        });
      }
    } catch (e) {
      print(e);
    }
  }
}
