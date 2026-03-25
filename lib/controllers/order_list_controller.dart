// import 'dart:convert';
// import 'dart:developer';
//
// import 'package:http/http.dart' as http;
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/models/order_model.dart';
// import 'package:jippydriver_driver/utils/app_logger.dart';
// import 'package:get/get.dart';
//
// class OrderListController extends GetxController{
//
//   RxBool isLoading  = true.obs;
//   @override
//   void onInit() {
//     AppLogger.log('OrderListController onInit() called', tag: 'Controller');
//     getOrder();
//     super.onInit();
//   }
//   @override
//   void onClose() {
//     AppLogger.log('OrderListController onClose() called', tag: 'Controller');
//     super.onClose();
//   }
//   RxList<OrderModel> orderList = <OrderModel>[].obs;
//   RxBool isLoadingMore = false.obs;
//   RxBool hasMore = true.obs;
//   int _currentPage = 1;
//   static const int _perPage = 10;
//
//   /// Builds the paginated orders API URL
//   Uri _buildOrdersUrl({int page = 1, int? perPage}) {
//     final queryParams = <String, String>{
//       'driver_id': ?Constant.userModel!.firebaseId,
//       'page': page.toString(),
//     };
//     if (perPage != null) {
//       queryParams['per_page'] = perPage.toString();
//     }
//     return Uri.parse('${Constant.baseUrl}driver/ordersList')
//         .replace(queryParameters: queryParams);
//   }
//
//   /// Fetches first page, clears existing list
//   getOrder() async {
//     try {
//       isLoading.value = true;
//       orderList.clear();
//       _currentPage = 1;
//       hasMore.value = true;
//
//       final url = _buildOrdersUrl(page: 1, perPage: _perPage);
//       final response = await http.get(
//         url,
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = jsonDecode(response.body);
//         if (data['success'] == true && data['orders'] != null) {
//           for (var element in data['orders']) {
//             orderList.add(OrderModel.fromJson(element));
//           }
//           final orders = data['orders'] as List;
//           hasMore.value = orders.length >= _perPage;
//         }
//       } else {
//         log('Error fetching orders: ${response.statusCode}');
//       }
//     } catch (e) {
//       log('Error in getOrder(): $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   /// Loads next page and appends to list
//   loadMore() async {
//     if (isLoadingMore.value || !hasMore.value) return;
//
//     try {
//       isLoadingMore.value = true;
//       _currentPage++;
//       final url = _buildOrdersUrl(page: _currentPage, perPage: _perPage);
//       final response = await http.get(
//         url,
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = jsonDecode(response.body);
//         if (data['success'] == true && data['orders'] != null) {
//           final orders = data['orders'] as List;
//           for (var element in orders) {
//             orderList.add(OrderModel.fromJson(element));
//           }
//           hasMore.value = orders.length >= _perPage;
//         } else {
//           hasMore.value = false;
//         }
//       } else {
//         _currentPage--;
//         log('Error fetching orders: ${response.statusCode}');
//       }
//     } catch (e) {
//       _currentPage--;
//       log('Error in loadMore(): $e');
//     } finally {
//       isLoadingMore.value = false;
//     }
//   }
//
//
//
//
// }


import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/orders_report_response_model.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:get/get.dart';

class OrderListController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  RxList<OrderModel> orderList = <OrderModel>[].obs;
  RxInt totalOrders = 0.obs;
  RxInt totalCompleted = 0.obs;
  RxDouble totalEarnings = 0.0.obs;
  RxDouble totalTips = 0.0.obs;
  RxDouble totalDeliveryCharge = 0.0.obs;

  int _currentPage = 1;
  static const int _perPage = 10;

  // Prevent concurrent fetches
  bool _isFetching = false;

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

  // ─── Build paginated URL ──────────────────────────────────────────────────
  Uri _buildOrdersUrl({int page = 1, int perPage = _perPage}) {
    // FIX: removed invalid `?` null-assertion syntax on map key assignment
    final String driverId = Constant.userModel?.firebaseId ?? '';
    return Uri.parse('${Constant.baseUrl}ordersReport').replace(
      queryParameters: {
        'driver_id': driverId,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
  }

  // ─── Headers helper ───────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── Initial / Refresh load ───────────────────────────────────────────────
  Future<void> getOrder() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      isLoading.value = true;
      orderList.clear();
      _currentPage = 1;
      hasMore.value = true;
      totalOrders.value = 0;
      totalCompleted.value = 0;
      totalEarnings.value = 0;
      totalTips.value = 0;
      totalDeliveryCharge.value = 0;

      final response = await http
          .get(_buildOrdersUrl(page: 1), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _handleSuccess(response.body, isFirstPage: true);
      } else {
        log('getOrder() – HTTP ${response.statusCode}');
      }
    } catch (e) {
      log('getOrder() error: $e');
    } finally {
      isLoading.value = false;
      _isFetching = false;
    }
  }

  // ─── Pagination ───────────────────────────────────────────────────────────
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || _isFetching) return;
    _isFetching = true;

    try {
      isLoadingMore.value = true;
      _currentPage++;

      final response = await http
          .get(_buildOrdersUrl(page: _currentPage), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _handleSuccess(response.body, isFirstPage: false);
      } else {
        _currentPage--;
        log('loadMore() – HTTP ${response.statusCode}');
      }
    } catch (e) {
      _currentPage--;
      log('loadMore() error: $e');
    } finally {
      isLoadingMore.value = false;
      _isFetching = false;
    }
  }

  // ─── Shared response parser ───────────────────────────────────────────────
  void _handleSuccess(String body, {required bool isFirstPage}) {
    try {
      final Map<String, dynamic> data = jsonDecode(body);
      final report = OrdersReportResponse.fromJson(data);

      if (!report.success) {
        if (!isFirstPage) _currentPage--;
        hasMore.value = false;
        return;
      }

      // Use pagination meta from server when available
      final pagination = report.pagination;
      if (pagination != null) {
        final int currentPage = pagination.currentPage;
        final int lastPage = pagination.lastPage;
        hasMore.value = currentPage < lastPage;
        totalOrders.value = pagination.total;
      } else {
        hasMore.value = report.orders.length >= _perPage;
      }

      // Consume top-level earnings summary from API response
      final earnings = report.earnings;
      if (earnings != null) {
        totalEarnings.value = earnings.totalEarnings;
        totalTips.value = earnings.totalTips;
        totalCompleted.value = earnings.totalCompleted;
        totalDeliveryCharge.value = earnings.deliveryCharge;
      }

      orderList.addAll(report.orders);

      // Fallbacks when API omits summary fields
      if (totalOrders.value == 0) totalOrders.value = orderList.length;
      if (earnings == null) {
        double fallbackEarnings = 0;
        double fallbackTips = 0;
        int fallbackCompleted = 0;
        for (final order in report.orders) {
          if ((order.status ?? '').toLowerCase() == 'order completed') {
            fallbackCompleted++;
          }
          final m = order.calculatedCharges ?? const {};
          fallbackEarnings += _toDouble(m['totalCalculatedCharge']) ?? 0;
          fallbackTips += _toDouble(order.tipAmount) ?? 0;
        }
        totalEarnings.value += fallbackEarnings;
        totalTips.value += fallbackTips;
        totalCompleted.value = fallbackCompleted;
        totalDeliveryCharge.value = totalEarnings.value - totalTips.value;
      }
    } catch (e) {
      log('_handleSuccess() parse error: $e');
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }
}