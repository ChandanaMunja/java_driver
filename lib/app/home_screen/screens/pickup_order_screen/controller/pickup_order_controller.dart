import 'package:flutter/material.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:get/get.dart';

class PickupOrderController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool conformPickup = false.obs;
  void confirmPickupFunction(){
    print("${conformPickup.value} conformPickup " );
    if(   conformPickup.value
    ){
      conformPickup.value =false;
    }else{
      conformPickup.value =true;
    }
  }
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => getArgument());
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  void getArgument() {
    final argumentData = Get.arguments;
    if (argumentData != null) {
      final order = argumentData['orderModel'];
      if (order is OrderModel) {
        orderModel.value = order;
      }
    }
    isLoading.value = false;
  }
}
