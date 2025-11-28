import 'package:jippydriver_driver/constant/collection_name.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/send_notification.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/services/audio_player_service.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class HomeScreenMultipleOrderController extends GetxController {
  Rx<UserModel> driverModel = Constant.userModel!.obs;
  RxBool isLoading = true.obs;
  RxInt selectedTabIndex = 0.obs;

  RxList<dynamic> newOrder = [].obs;
  RxList<dynamic> activeOrder = [].obs;

  @override
  void onInit() {
    // TODO: implement onInt
    getDriver();
    super.onInit();
  }

  getDriver() async {
    String? userId = await LoginController.getFirebaseId();
    FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(userId)
        .snapshots()
        .listen(
          (event) async {
        if (event.exists) {
          driverModel.value = UserModel.fromJson(event.data()!);
          Constant.userModel = driverModel.value;
          newOrder.clear();
          activeOrder.clear();
          // Enforce one in-progress order at a time
          if (driverModel.value.inProgressOrderID != null &&
              driverModel.value.inProgressOrderID!.isNotEmpty &&
              !(driverModel.value.inProgressOrderID!.length == 1 && driverModel.value.inProgressOrderID!.first == "")) {
            // Only show the in-progress order
            for (var element in driverModel.value.inProgressOrderID!) {
              activeOrder.add(element);
            }
            // Do not show new order requests
            await AudioPlayerService.playSound(false);
            return;
          }
          // If no in-progress order, show the first order request (if any)
          if (driverModel.value.orderRequestData != null && driverModel.value.orderRequestData!.isNotEmpty) {
            newOrder.add(driverModel.value.orderRequestData!.first);
          }
          if (newOrder.isEmpty == true) {
            await AudioPlayerService.playSound(false);
          }
          if (newOrder.isNotEmpty) {
            if (driverModel.value.vendorID?.isEmpty == true) {
              await AudioPlayerService.playSound(true);
            }
          }
        }
      },
    );
    isLoading.value = false;
  }

  acceptOrder(OrderModel currentOrder) async {
    // Prevent accepting if already in progress
    if (driverModel.value.inProgressOrderID != null &&
        driverModel.value.inProgressOrderID!.isNotEmpty &&
        !(driverModel.value.inProgressOrderID!.length == 1 && driverModel.value.inProgressOrderID!.first == "")) {
      ShowToastDialog.showToast("You already have an order in progress. Complete it before accepting a new one.");
      return;
    }
    if (currentOrder.id == null || driverModel.value.id == null) {
      ShowToastDialog.showToast("Order or driver ID is missing!".tr);
      return;
    }
    await AudioPlayerService.playSound(false);
    ShowToastDialog.showLoader("Please wait".tr);

    // Try to atomically assign the order
    bool success = await FireStoreUtils.assignOrderToDriverFCFS(
      orderId: currentOrder.id!,
      driverId: driverModel.value.id!,
      driverModel: driverModel.value,
    );

    ShowToastDialog.closeLoader();

    if (success) {
      // Update driver's order lists
      driverModel.value.orderRequestData?.remove(currentOrder.id);
      driverModel.value.inProgressOrderID ??= [];
      driverModel.value.inProgressOrderID!.add(currentOrder.id!);

      await FireStoreUtils.updateUser(driverModel.value);

      // Optionally: send notifications
      if (currentOrder.author?.fcmToken != null) {
        await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
            currentOrder.author!.fcmToken.toString(), {});
      }
      if (currentOrder.vendor?.fcmToken != null) {
        await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
            currentOrder.vendor!.fcmToken.toString(), {});
      }

      // Show success message
      ShowToastDialog.showToast("Order assigned successfully!".tr);
    } else {
      // Show failure message
      ShowToastDialog.showToast("Order already taken by another driver.".tr);
      // Optionally: remove this order from the available list in UI
    }
  }

  rejectOrder(OrderModel currentOrder) async {
    await AudioPlayerService.playSound(false);
    currentOrder.rejectedByDrivers ??= [];

    currentOrder.rejectedByDrivers!.add(driverModel.value.id);
    currentOrder.status = Constant.driverRejected;
    await FireStoreUtils.setOrder(currentOrder);

    driverModel.value.orderRequestData!.remove(currentOrder.id);
    await FireStoreUtils.updateUser(driverModel.value);
  }
}
