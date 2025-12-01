import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippydriver_driver/constant/collection_name.dart';
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

  getUser() async {
    String? userId = await LoginController.getFirebaseId();
    await updateCurrentLocation();
    FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(userId)
        .snapshots()
        .listen(
      (event) {
        if (event.exists) {
          userModel.value = UserModel.fromJson(event.data()!);
          Constant.userModel = UserModel.fromJson(event.data()!);
        }
      },
    );
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
    Timestamp startTimestamp = Timestamp.now();
    DateTime currentDate = startTimestamp.toDate();
    currentDate = currentDate.subtract(const Duration(hours: 3));
    startTimestamp = Timestamp.fromDate(currentDate);

    List<OrderModel> orders = [];

    await FirebaseFirestore.instance
        .collection(CollectionName.restaurantOrders)
        .where('status',
            whereIn: [Constant.orderAccepted, Constant.orderRejected])
        .where('createdAt', isGreaterThan: startTimestamp)
        .get()
        .then((value) async {
          await Future.forEach(value.docs,
              (QueryDocumentSnapshot<Map<String, dynamic>> element) {
            try {
              orders.add(OrderModel.fromJson(element.data()));
            } catch (e, s) {
              print('watchOrdersStatus parse error ${element.id}$e $s');
            }
          });
        });

    orders.forEach((element) async {
      OrderModel orderModel = element;
      orderModel.triggerDelivery = Timestamp.now();
      await FireStoreUtils.setOrder(orderModel);
    });
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
