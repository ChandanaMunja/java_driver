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
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
    }
    isLoading.value = false;
    update();
  }
}
