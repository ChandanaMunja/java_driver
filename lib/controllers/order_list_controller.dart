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
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  int _currentPage = 1;
  static const int _perPage = 10;

  /// Builds the paginated orders API URL
  Uri _buildOrdersUrl({int page = 1, int? perPage}) {
    final queryParams = <String, String>{
      'driver_id': ?Constant.userModel!.firebaseId,
      'page': page.toString(),
    };
    if (perPage != null) {
      queryParams['per_page'] = perPage.toString();
    }
    return Uri.parse('${Constant.baseUrl}driver/ordersList')
        .replace(queryParameters: queryParams);
  }

  /// Fetches first page, clears existing list
  getOrder() async {
    try {
      isLoading.value = true;
      orderList.clear();
      _currentPage = 1;
      hasMore.value = true;

      final url = _buildOrdersUrl(page: 1, perPage: _perPage);
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['orders'] != null) {
          for (var element in data['orders']) {
            orderList.add(OrderModel.fromJson(element));
          }
          final orders = data['orders'] as List;
          hasMore.value = orders.length >= _perPage;
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

  /// Loads next page and appends to list
  loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      _currentPage++;
      final url = _buildOrdersUrl(page: _currentPage, perPage: _perPage);
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['orders'] != null) {
          final orders = data['orders'] as List;
          for (var element in orders) {
            orderList.add(OrderModel.fromJson(element));
          }
          hasMore.value = orders.length >= _perPage;
        } else {
          hasMore.value = false;
        }
      } else {
        _currentPage--;
        log('Error fetching orders: ${response.statusCode}');
      }
    } catch (e) {
      _currentPage--;
      log('Error in loadMore(): $e');
    } finally {
      isLoadingMore.value = false;
    }
  }




}