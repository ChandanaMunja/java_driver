import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:get/get.dart';

class OrderListController extends GetxController{

  RxBool isLoading  = true.obs;
  @override
  void onInit() {
    AppLogger.log('OrderListController onInit() called', tag: 'Controller');
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
    try {
      isLoading.value = true;
      orderList.clear();
      final url = Uri.parse('${Constant.baseUrl}driver/orders');
      final body = jsonEncode({
        "driver_id": Constant.userModel!.id,
      });
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Add auth token if your API requires it
          //'Authorization': 'Bearer ${Constant.userToken}',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['orders'] != null) {
          // const activeStatuses = [
          //   Constant.driverPending,
          //   Constant.driverAccepted,
          //   Constant.orderShipped,
          //   Constant.orderInTransit,
          //   Constant.orderCompleted,
          //   Constant.orderCancelled,
          // ];
          for (var element in data['orders']) {
            OrderModel order = OrderModel.fromJson(element);
            // Only add orders that match driverID and active status
            // if (order.driverID == Constant.userModel!.id &&
            //     activeStatuses.contains(order.status)) {
              orderList.add(order);
            // }
          }
        }
      } else {
        log('Error fetching orders: ${response.statusCode}');
      }
    } catch (e) {
      log('Error in getOrder(): $e');
    } finally {
      isLoading.value = false;
    }
  }




}