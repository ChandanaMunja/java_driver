import 'dart:developer';

import 'package:jippydriver_driver/constant/collection_name.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:get/get.dart';

class OrderListController extends GetxController{

  RxBool isLoading  = true.obs;
  @override
  void onInit() {
    AppLogger.log('OrderListController onInit() called', tag: 'Controller');
    // TODO: implement onInit
    getOrder();
    super.onInit();
  }
  @override
  void onClose() {
    AppLogger.log('OrderListController onClose() called', tag: 'Controller');
    super.onClose();
  }

  RxList<OrderModel> orderList = <OrderModel>[].obs;


  getOrder() async {
    orderList.clear(); // Clear old orders before adding new ones
    const activeStatuses = [
      Constant.driverPending,
      Constant.driverAccepted,
      Constant.orderShipped,
      Constant.orderInTransit,

      Constant.orderCompleted,
  Constant.orderCancelled,
      // Add any other active statuses you want to show
    ];
    await FireStoreUtils.fireStore
        .collection(CollectionName.restaurantOrders)
        .where('driverID', isEqualTo: Constant.userModel!.id.toString())
        .where('status', whereIn: activeStatuses)
        .orderBy('createdAt', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        OrderModel order = OrderModel.fromJson(element.data());
        // Double-check: only add if driverID matches and status is active
        if (order.driverID == Constant.userModel!.id.toString() &&
            activeStatuses.contains(order.status)) {
          orderList.add(order);
        }
      }
    }).catchError((error) {
      log(error.toString());
    });

    isLoading.value = false;
  }



}