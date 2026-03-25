// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/controllers/dash_board_controller.dart';
// import 'package:jippydriver_driver/controllers/order_list_controller.dart';
// import 'package:jippydriver_driver/models/order_model.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart';
// import 'package:jippydriver_driver/themes/round_button_fill.dart';
// import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
// import 'package:jippydriver_driver/utils/app_logger.dart';
// import 'package:jippydriver_driver/widget/my_separator.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:timelines_plus/timelines_plus.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class OrderListScreen extends StatefulWidget {
//   const OrderListScreen({super.key});
//
//   @override
//   State<OrderListScreen> createState() => _OrderListScreenState();
// }
//
// class _OrderListScreenState extends State<OrderListScreen> {
//   final orderListController = Get.put(OrderListController());
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//   }
//
//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 200) {
//       orderListController.loadMore();
//     }
//   }
//
//   @override
//   void dispose() {
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     AppLogger.log('OrderListScreen build() called', tag: 'Screen');
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     return GetX<OrderListController>(
//         init: orderListController,
//         builder: (controller) {
//           return Scaffold(
//             body: controller.isLoading.value
//                 ? Constant.loader()
//                 : Constant.isDriverVerification == true &&
//                         Constant.userModel?.isDocumentVerify == false
//                     ? Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Container(
//                               decoration: ShapeDecoration(
//                                 color: themeChange.getThem()
//                                     ? AppThemeData.grey700
//                                     : AppThemeData.grey200,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(120),
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(20),
//                                 child: SvgPicture.asset(
//                                     "assets/icons/ic_document.svg"),
//                               ),
//                             ),
//                             const SizedBox(
//                               height: 12,
//                             ),
//                             Text(
//                               "Document Verification in Pending".tr,
//                               style: TextStyle(
//                                   color: themeChange.getThem()
//                                       ? AppThemeData.grey100
//                                       : AppThemeData.grey800,
//                                   fontSize: 22,
//                                   fontFamily: AppThemeData.semiBold),
//                             ),
//                             const SizedBox(
//                               height: 5,
//                             ),
//                             Text(
//                               "Your documents are being reviewed. We will notify you once the verification is complete."
//                                   .tr,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                   color: themeChange.getThem()
//                                       ? AppThemeData.grey50
//                                       : AppThemeData.grey500,
//                                   fontSize: 16,
//                                   fontFamily: AppThemeData.bold),
//                             ),
//                             const SizedBox(
//                               height: 20,
//                             ),
//                             RoundedButtonFill(
//                               title: "View Status".tr,
//                               width: 55,
//                               height: 5.5,
//                               color: AppThemeData.secondary300,
//                               textColor: AppThemeData.grey50,
//                               onPress: () async {
//                                 DashBoardController dashBoardController =
//                                     Get.put(DashBoardController());
//                                 dashBoardController.drawerIndex.value = 4;
//                               },
//                             ),
//                           ],
//                         ),
//                       )
//                     : Padding(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 10),
//                         child: controller.orderList.isEmpty
//                             ? Constant.showEmptyView(
//                                 message: "Order Not found".tr)
//                             : ListView.builder(
//                                 controller: _scrollController,
//                                 itemCount: controller.orderList.length +
//                                     (controller.hasMore.value ? 1 : 0),
//                                 itemBuilder: (context, index) {
//                                   if (index >= controller.orderList.length) {
//                                     return controller.isLoadingMore.value
//                                         ? const Padding(
//                                             padding: EdgeInsets.all(16),
//                                             child: Center(
//                                                 child:
//                                                     CircularProgressIndicator()),
//                                           )
//                                         : const SizedBox.shrink();
//                                   }
//                                   OrderModel orderModel =
//                                       controller.orderList[index];
//                                   return Padding(
//                                     padding:
//                                         const EdgeInsets.symmetric(vertical: 5),
//                                     child: InkWell(
//                                       // onTap: () {
//                                       //   Get.to(const OrderDetailsScreen(),
//                                       //       arguments: {
//                                       //         "orderModel": orderModel
//                                       //       });
//                                       // },
//                                       child: Container(
//                                         decoration: ShapeDecoration(
//                                           color: themeChange.getThem()
//                                               ? AppThemeData.grey900
//                                               : AppThemeData.grey50,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(16),
//                                           ),
//                                         ),
//                                         child: Padding(
//                                           padding: const EdgeInsets.all(8.0),
//                                           child: Column(
//                                             children: [
//                                               Row(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Expanded(
//                                                     child: Text(
//                                                       "Order ID".tr,
//                                                       textAlign:
//                                                           TextAlign.start,
//                                                       style: TextStyle(
//                                                         fontFamily: AppThemeData
//                                                             .regular,
//                                                         color: themeChange
//                                                                 .getThem()
//                                                             ? AppThemeData
//                                                                 .grey300
//                                                             : AppThemeData
//                                                                 .grey600,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     Constant.orderId(
//                                                         orderId: orderModel.id
//                                                             .toString()),
//                                                     textAlign: TextAlign.start,
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.semiBold,
//                                                       color: themeChange
//                                                               .getThem()
//                                                           ? AppThemeData.grey50
//                                                           : AppThemeData
//                                                               .grey900,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                               const SizedBox(
//                                                 height: 5,
//                                               ),
//                                               Row(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Expanded(
//                                                     child: Text(
//                                                       "Status".tr,
//                                                       textAlign:
//                                                           TextAlign.start,
//                                                       style: TextStyle(
//                                                         fontFamily: AppThemeData
//                                                             .regular,
//                                                         color: themeChange
//                                                                 .getThem()
//                                                             ? AppThemeData
//                                                                 .grey300
//                                                             : AppThemeData
//                                                                 .grey600,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     orderModel.status
//                                                         .toString(),
//                                                     textAlign: TextAlign.start,
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.semiBold,
//                                                       color:
//                                                           Constant.statusColor(
//                                                               status: orderModel
//                                                                   .status),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                               const SizedBox(
//                                                 height: 5,
//                                               ),
//                                               Row(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Expanded(
//                                                     child: Text(
//                                                       "Date".tr,
//                                                       textAlign:
//                                                           TextAlign.start,
//                                                       style: TextStyle(
//                                                         fontFamily: AppThemeData
//                                                             .regular,
//                                                         color: themeChange
//                                                                 .getThem()
//                                                             ? AppThemeData
//                                                                 .grey300
//                                                             : AppThemeData
//                                                                 .grey600,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     Constant
//                                                         .timestampToDateTime(
//                                                             orderModel
//                                                                 .createdAt ?? Timestamp.now()),
//                                                     textAlign: TextAlign.start,
//                                                     style: TextStyle(
//                                                       fontFamily:
//                                                           AppThemeData.semiBold,
//                                                       color: themeChange
//                                                               .getThem()
//                                                           ? AppThemeData.grey50
//                                                           : AppThemeData
//                                                               .grey900,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                               Padding(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         vertical: 10),
//                                                 child: MySeparator(
//                                                     color: themeChange.getThem()
//                                                         ? AppThemeData.grey700
//                                                         : AppThemeData.grey200),
//                                               ),
//                                               Timeline.tileBuilder(
//                                                 shrinkWrap: true,
//                                                 padding: EdgeInsets.zero,
//                                                 physics:
//                                                     const NeverScrollableScrollPhysics(),
//                                                 theme: TimelineThemeData(
//                                                   nodePosition: 0,
//                                                   // indicatorPosition: 0,
//                                                 ),
//                                                 builder: TimelineTileBuilder
//                                                     .connected(
//                                                   contentsAlign:
//                                                       ContentsAlign.basic,
//                                                   indicatorBuilder:
//                                                       (context, index) {
//                                                     return index == 0
//                                                         ? Container(
//                                                             decoration:
//                                                                 ShapeDecoration(
//                                                               color: AppThemeData
//                                                                   .primary50,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             120),
//                                                               ),
//                                                             ),
//                                                             child: Padding(
//                                                               padding:
//                                                                   const EdgeInsets
//                                                                       .all(10),
//                                                               child: SvgPicture
//                                                                   .asset(
//                                                                 "assets/icons/ic_building.svg",
//                                                                 colorFilter: const ColorFilter
//                                                                     .mode(
//                                                                     AppThemeData
//                                                                         .primary300,
//                                                                     BlendMode
//                                                                         .srcIn),
//                                                               ),
//                                                             ),
//                                                           )
//                                                         : Container(
//                                                             decoration:
//                                                                 ShapeDecoration(
//                                                               color: AppThemeData
//                                                                   .driverApp50,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             120),
//                                                               ),
//                                                             ),
//                                                             child: Padding(
//                                                               padding:
//                                                                   const EdgeInsets
//                                                                       .all(10),
//                                                               child: SvgPicture
//                                                                   .asset(
//                                                                 "assets/icons/ic_location.svg",
//                                                                 colorFilter: ColorFilter.mode(
//                                                                     AppThemeData
//                                                                         .driverApp300,
//                                                                     BlendMode
//                                                                         .srcIn),
//                                                               ),
//                                                             ),
//                                                           );
//                                                   },
//                                                   connectorBuilder: (context,
//                                                       index, connectorType) {
//                                                     return const DashedLineConnector(
//                                                       color:
//                                                           AppThemeData.grey300,
//                                                       gap: 3,
//                                                     );
//                                                   },
//                                                   contentsBuilder:
//                                                       (context, index) {
//                                                     return Padding(
//                                                       padding: const EdgeInsets
//                                                           .symmetric(
//                                                           horizontal: 10,
//                                                           vertical: 10),
//                                                       child: index == 0
//                                                           ? Column(
//                                                               crossAxisAlignment:
//                                                                   CrossAxisAlignment
//                                                                       .start,
//                                                               children: [
//                                                                 Text(
//                                                                   "${orderModel.vendor?.title ?? 'Restaurant'}",
//                                                                   textAlign:
//                                                                       TextAlign
//                                                                           .start,
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontFamily:
//                                                                         AppThemeData
//                                                                             .semiBold,
//                                                                     fontSize:
//                                                                         16,
//                                                                     color: themeChange.getThem()
//                                                                         ? AppThemeData
//                                                                             .grey50
//                                                                         : AppThemeData
//                                                                             .grey900,
//                                                                   ),
//                                                                 ),
//                                                                 Text(
//                                                                   "${orderModel.vendor?.location ?? 'Location not available'}",
//                                                                   textAlign:
//                                                                       TextAlign
//                                                                           .start,
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontFamily:
//                                                                         AppThemeData
//                                                                             .medium,
//                                                                     fontSize:
//                                                                         12,
//                                                                     color: themeChange.getThem()
//                                                                         ? AppThemeData
//                                                                             .grey300
//                                                                         : AppThemeData
//                                                                             .grey600,
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             )
//                                                           : Column(
//                                                               crossAxisAlignment:
//                                                                   CrossAxisAlignment
//                                                                       .start,
//                                                               children: [
//                                                                 Text(
//                                                                   "Deliver to the"
//                                                                       .tr,
//                                                                   textAlign:
//                                                                       TextAlign
//                                                                           .start,
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontFamily:
//                                                                         AppThemeData
//                                                                             .semiBold,
//                                                                     fontSize:
//                                                                         16,
//                                                                     color: themeChange.getThem()
//                                                                         ? AppThemeData
//                                                                             .grey50
//                                                                         : AppThemeData
//                                                                             .grey900,
//                                                                   ),
//                                                                 ),
//                                                                 Text(
//                                                                   orderModel
//                                                                       .address
//                                                                       ?.getFullAddress() ?? 'Address not available',
//                                                                   textAlign:
//                                                                       TextAlign
//                                                                           .start,
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontFamily:
//                                                                         AppThemeData
//                                                                             .medium,
//                                                                     fontSize:
//                                                                         12,
//                                                                     color: themeChange.getThem()
//                                                                         ? AppThemeData
//                                                                             .grey300
//                                                                         : AppThemeData
//                                                                             .grey600,
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                     );
//                                                   },
//                                                   itemCount: 2,
//                                                 ),
//                                               ),
//                                               Visibility(
//                                                 visible: (Constant.userModel
//                                                         ?.vendorID?.isEmpty ==
//                                                     true),
//                                                 child: Column(children: [
//                                                   Padding(
//                                                     padding: const EdgeInsets
//                                                         .symmetric(vertical: 5),
//                                                     child: MySeparator(
//                                                         color: themeChange
//                                                                 .getThem()
//                                                             ? AppThemeData
//                                                                 .grey700
//                                                             : AppThemeData
//                                                                 .grey200),
//                                                   ),
//                                                   const SizedBox(
//                                                     height: 10,
//                                                   ),
//                                                   Row(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       Expanded(
//                                                         child: Text(
//                                                           "Delivery Charge".tr,
//                                                           textAlign:
//                                                               TextAlign.start,
//                                                           style: TextStyle(
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .regular,
//                                                             color: themeChange
//                                                                     .getThem()
//                                                                 ? AppThemeData
//                                                                     .grey300
//                                                                 : AppThemeData
//                                                                     .grey600,
//                                                             fontSize: 16,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       Text(
//                                                         "${(double.tryParse(orderModel.calculatedCharges?['totalCalculatedCharge']?.toString().trim() ?? '0') ?? 0)-(double.tryParse(orderModel.tipAmount.toString().trim()) ?? 0)}",
//                                                         // Constant.amountShow(
//                                                         //     amount: orderModel
//                                                         //         .deliveryCharge),
//                                                         textAlign:
//                                                             TextAlign.start,
//                                                         style: TextStyle(
//                                                           fontFamily:
//                                                               AppThemeData
//                                                                   .semiBold,
//                                                           color: themeChange
//                                                                   .getThem()
//                                                               ? AppThemeData
//                                                                   .grey50
//                                                               : AppThemeData
//                                                                   .grey900,
//                                                           fontSize: 16,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ]),
//                                               ),
//                                               const SizedBox(
//                                                 height: 5,
//                                               ),
//                                               orderModel.tipAmount == null ||
//                                                       orderModel
//                                                           .tipAmount?.isEmpty == true ||
//                                                       double.parse(orderModel
//                                                               .tipAmount
//                                                               .toString()) <=
//                                                           0
//                                                   ? const SizedBox()
//                                                   : Row(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         Expanded(
//                                                           child: Text(
//                                                             "Tips".tr,
//                                                             textAlign:
//                                                                 TextAlign.start,
//                                                             style: TextStyle(
//                                                               fontFamily:
//                                                                   AppThemeData
//                                                                       .regular,
//                                                               color: themeChange
//                                                                       .getThem()
//                                                                   ? AppThemeData
//                                                                       .grey300
//                                                                   : AppThemeData
//                                                                       .grey600,
//                                                               fontSize: 16,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         Text(
//                                                           Constant.amountShow(
//                                                               amount: orderModel
//                                                                   .tipAmount),
//                                                           textAlign:
//                                                               TextAlign.start,
//                                                           style: TextStyle(
//                                                             fontFamily:
//                                                                 AppThemeData
//                                                                     .semiBold,
//                                                             color: themeChange
//                                                                     .getThem()
//                                                                 ? AppThemeData
//                                                                     .grey50
//                                                                 : AppThemeData
//                                                                     .grey900,
//                                                             fontSize: 16,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                               const SizedBox(
//                                                 height: 10,
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//           );
//         });
//   }
// }


import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/controllers/dash_board_controller.dart';
import 'package:jippydriver_driver/controllers/order_list_controller.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/round_button_fill.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with TickerProviderStateMixin {
  late final OrderListController _ctrl;
  final ScrollController _scrollCtrl = ScrollController();
  final Set<int> _expanded = {};
  final Map<int, AnimationController> _animMap = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(OrderListController());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    for (final c in _animMap.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Scroll to load more ────────────────────────────────────────────────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      _ctrl.loadMore();
    }
  }

  // ── Per-card animation controller ─────────────────────────────────────────
  AnimationController _anim(int i) => _animMap.putIfAbsent(
    i,
        () => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    ),
  );

  void _toggle(int i) {
    final c = _anim(i);
    setState(() {
      if (_expanded.contains(i)) {
        _expanded.remove(i);
        c.reverse();
      } else {
        _expanded.add(i);
        c.forward();
      }
    });
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────
  static Color _bg(bool d) =>
      d ? const Color(0xFF0F1117) : const Color(0xFFF5F7FA);
  static Color _card(bool d) => d ? const Color(0xFF1E2330) : Colors.white;
  static Color _title(bool d) =>
      d ? const Color(0xFFF0F2F8) : const Color(0xFF111827);
  static Color _sub(bool d) =>
      d ? const Color(0xFF7E8499) : const Color(0xFF6B7280);
  static Color _divider(bool d) =>
      d ? const Color(0xFF2A2F3E) : const Color(0xFFF0F1F5);

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    AppLogger.log('OrderListScreen build()', tag: 'Screen');
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetX<OrderListController>(
      init: _ctrl,
      builder: (ctrl) {
        // ── Loading ────────────────────────────────────────────────────────
        if (ctrl.isLoading.value) {
          return Scaffold(
            backgroundColor: _bg(isDark),
            body: Center(child: Constant.loader()),
          );
        }

        // ── Doc verification pending ───────────────────────────────────────
        if (Constant.isDriverVerification == true &&
            Constant.userModel?.isDocumentVerify == false) {
          return Scaffold(
            backgroundColor: _bg(isDark),
            body: _VerificationPending(isDark: isDark, themeChange: themeChange),
          );
        }

        // ── Main list ──────────────────────────────────────────────────────
        return Scaffold(
          backgroundColor: _bg(isDark),
          body: RefreshIndicator(
            color: AppThemeData.secondary300,
            onRefresh: ctrl.getOrder,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Dashboard header
                SliverToBoxAdapter(
                  child: _DashboardHeader(
                    ctrl: ctrl,
                    isDark: isDark,
                  ),
                ),

                // Section label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'Order History'.tr,
                          style: TextStyle(
                            fontFamily: AppThemeData.bold,
                            fontSize: 17,
                            color: _title(isDark),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CountBadge(count: ctrl.orderList.length),
                      ],
                    ),
                  ),
                ),

                // List / empty
                ctrl.orderList.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child: Constant.showEmptyView(
                        message: 'Order Not found'.tr),
                  ),
                )
                    : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                        // Load-more spinner at end
                        if (i >= ctrl.orderList.length) {
                          return ctrl.isLoadingMore.value
                              ? const _LoadMoreSpinner()
                              : const SizedBox.shrink();
                        }
                        final order = ctrl.orderList[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _OrderCard(
                            key: ValueKey(order.id),
                            order: order,
                            index: i,
                            isExpanded: _expanded.contains(i),
                            isDark: isDark,
                            themeChange: themeChange,
                            animController: _anim(i),
                            onTap: () => _toggle(i),
                          ),
                        );
                      },
                      childCount: ctrl.orderList.length +
                          (ctrl.hasMore.value ? 1 : 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HEADER  (extracted widget = no rebuild cascade)
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.ctrl, required this.isDark});
  final OrderListController ctrl;
  final bool isDark;

  Color get _title =>
      isDark ? const Color(0xFFF0F2F8) : const Color(0xFF111827);
  Color get _sub => isDark ? const Color(0xFF7E8499) : const Color(0xFF6B7280);
  Color get _card => isDark ? const Color(0xFF1E2330) : Colors.white;
  Color get _divider =>
      isDark ? const Color(0xFF2A2F3E) : const Color(0xFFF0F1F5);

  @override
  Widget build(BuildContext context) {
    final orders = ctrl.orderList;
    final int total = ctrl.totalOrders.value > 0 ? ctrl.totalOrders.value : orders.length;
    final int delivered = ctrl.totalCompleted.value > 0
        ? ctrl.totalCompleted.value
        : orders.where((o) => (o.status ?? '').toLowerCase() == 'order completed').length;
    final int active = orders
        .where((o) =>
    o.status?.toLowerCase() == 'accepted' ||
        o.status?.toLowerCase() == 'pending')
        .length;

    final double earnings = ctrl.totalEarnings.value;
    final double tips = ctrl.totalTips.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              _Avatar(name: Constant.userModel?.fullName() ?? 'Driver'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back!',
                        style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 12,
                            color: _sub)),
                    Text(
                      Constant.userModel?.fullName() ?? 'Driver',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 17,
                        color: _title,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const _OnlineBadge(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Earnings card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _EarningsCard(
            isDark: isDark,
            earnings: earnings,
            tips: tips,
            delivered: delivered,
          ),
        ),

        const SizedBox(height: 16),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatCard(
                isDark: isDark,
                icon: 'assets/icons/ic_building.svg',
                iconBg: AppThemeData.secondary300.withOpacity(0.12),
                iconColor: AppThemeData.secondary300,
                value: total.toString(),
                label: 'Total Orders',
                valueColor: _title,
              ),
              const SizedBox(width: 10),
              _StatCard(
                isDark: isDark,
                icon: 'assets/icons/ic_location.svg',
                iconBg: const Color(0xFF2ED07A).withOpacity(0.12),
                iconColor: const Color(0xFF2ED07A),
                value: delivered.toString(),
                label: 'Delivered',
                valueColor: const Color(0xFF2ED07A),
              ),
              const SizedBox(width: 10),
              _StatCard(
                isDark: isDark,
                icon: 'assets/icons/ic_building.svg',
                iconBg: const Color(0xFF3B8EF0).withOpacity(0.12),
                iconColor: const Color(0xFF3B8EF0),
                value: active.toString(),
                label: 'Active',
                valueColor: const Color(0xFF3B8EF0),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppThemeData.secondary300, Color(0xFFF07226)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(initial,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: AppThemeData.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2ED07A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF2ED07A).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF2ED07A), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          const Text('Online',
              style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 12,
                  color: Color(0xFF2ED07A))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EARNINGS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.isDark,
    required this.earnings,
    required this.tips,
    required this.delivered,
  });
  final bool isDark;
  final double earnings, tips;
  final int delivered;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A2F50), const Color(0xFF1B2E48)]
              : [
            AppThemeData.secondary300,
            AppThemeData.secondary300.withRed(220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.secondary300.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Earnings',
                    style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.65),
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(
                  Constant.amountShow(amount: earnings.toStringAsFixed(2)),
                  style: const TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 30,
                      color: Colors.white,
                      letterSpacing: -1),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${Constant.amountShow(amount: tips.toStringAsFixed(2))} tips',
                    style: const TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 11,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(delivered.toString(),
                    style: const TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 26,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                Text('Done',
                    style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.valueColor,
  });
  final bool isDark;
  final String icon, value, label;
  final Color iconBg, iconColor, valueColor;

  Color get _divider =>
      isDark ? const Color(0xFF2A2F3E) : const Color(0xFFF0F1F5);
  Color get _card => isDark ? const Color(0xFF1E2330) : Colors.white;
  Color get _sub => isDark ? const Color(0xFF7E8499) : const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider, width: 1),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: SvgPicture.asset(icon,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
              ),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 22,
                    color: valueColor,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontFamily: AppThemeData.regular,
                    fontSize: 10,
                    color: _sub),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNT BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppThemeData.secondary300.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(count.toString(),
          style: const TextStyle(
              fontFamily: AppThemeData.semiBold,
              fontSize: 12,
              color: AppThemeData.secondary300)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOAD MORE SPINNER
// ─────────────────────────────────────────────────────────────────────────────
class _LoadMoreSpinner extends StatelessWidget {
  const _LoadMoreSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppThemeData.secondary300),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD  (const-friendly extracted widget)
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    super.key,
    required this.order,
    required this.index,
    required this.isExpanded,
    required this.isDark,
    required this.themeChange,
    required this.animController,
    required this.onTap,
  });

  final OrderModel order;
  final int index;
  final bool isExpanded, isDark;
  final DarkThemeProvider themeChange;
  final AnimationController animController;
  final VoidCallback onTap;

  Color get _card => isDark ? const Color(0xFF1E2330) : Colors.white;
  Color get _divider =>
      isDark ? const Color(0xFF2A2F3E) : const Color(0xFFF0F1F5);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? AppThemeData.secondary300.withOpacity(0.25)
              : _divider,
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
              color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.04),
              blurRadius: isExpanded ? 18 : 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: AppThemeData.secondary300.withOpacity(0.06),
            highlightColor: AppThemeData.secondary300.withOpacity(0.03),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    order: order,
                    isExpanded: isExpanded,
                    isDark: isDark,
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _ExpandedBody(
                      order: order,
                      isDark: isDark,
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.order,
    required this.isExpanded,
    required this.isDark,
  });
  final OrderModel order;
  final bool isExpanded, isDark;

  Color get _sub => isDark ? const Color(0xFF7E8499) : const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon box
        Container(
          width: 40,
          height: 46,
          decoration: BoxDecoration(
            color: AppThemeData.secondary300.withOpacity(0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: SvgPicture.asset('assets/icons/ic_building.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                    AppThemeData.secondary300, BlendMode.srcIn)),
          ),
        ),
        const SizedBox(width: 12),

        // Vendor + order id + status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.vendor?.title ?? 'Restaurant',
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFF0F2F8)
                      : const Color(0xFF111827),
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    Constant.orderId(orderId: order.id.toString()),
                    style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        fontSize: 11,
                        color: _sub),
                  ),
                  const SizedBox(width: 4),
                  _StatusChip(status: order.status ?? ''),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Date + chevron
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Constant.timestampToDateTime(order.createdAt ?? Timestamp.now()),
              style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontSize: 10,
                  color: _sub),
            ),
            const SizedBox(height: 6),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF0F1F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isExpanded ? AppThemeData.secondary300 : _sub,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDED BODY
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.order, required this.isDark});
  final OrderModel order;
  final bool isDark;

  Color get _divider =>
      isDark ? const Color(0xFF2A2F3E) : const Color(0xFFF0F1F5);

  @override
  Widget build(BuildContext context) {
    final double deliveryCharge =
        (double.tryParse(order.calculatedCharges?['totalCalculatedCharge']
            ?.toString()
            .trim() ??
            '0') ??
            0) -
            (double.tryParse(order.tipAmount?.toString().trim() ?? '0') ?? 0);

    final bool hasTip = order.tipAmount != null &&
        order.tipAmount!.isNotEmpty &&
        (double.tryParse(order.tipAmount.toString()) ?? 0) > 0;

    final bool showDeliveryCharge =
        Constant.userModel?.vendorID?.isEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Divider(color: _divider, height: 1, thickness: 1),
        const SizedBox(height: 14),

        // Route timeline
        _RouteTimeline(order: order, isDark: isDark),

        // Charges
        if (showDeliveryCharge || hasTip) ...[
          const SizedBox(height: 12),
          Divider(color: _divider, height: 1, thickness: 1),
          const SizedBox(height: 12),
          if (showDeliveryCharge)
            _ChargeRow(
              label: 'Delivery Charge'.tr,
              value: Constant.amountShow(
                  amount: deliveryCharge.toStringAsFixed(2)),
              isDark: isDark,
            ),
          if (hasTip) ...[
            const SizedBox(height: 6),
            _ChargeRow(
              label: 'Tips'.tr,
              value: Constant.amountShow(amount: order.tipAmount),
              isDark: isDark,
              valueColor: const Color(0xFF2ED07A),
              showTipBadge: true,
            ),
          ],
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE TIMELINE
// ─────────────────────────────────────────────────────────────────────────────
class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({required this.order, required this.isDark});
  final OrderModel order;
  final bool isDark;

  Color get _sub => isDark ? const Color(0xFF7E8499) : const Color(0xFF6B7280);
  Color get _titleC =>
      isDark ? const Color(0xFFF0F2F8) : const Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Timeline.tileBuilder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      theme:  TimelineThemeData(nodePosition: 0),
      builder: TimelineTileBuilder.connected(
        contentsAlign: ContentsAlign.basic,
        itemCount: 2,
        indicatorBuilder: (_, i) => i == 0
            ? _TlDot(
          bg: AppThemeData.secondary300.withOpacity(0.12),
          iconPath: 'assets/icons/ic_building.svg',
          iconColor: AppThemeData.secondary300,
        )
            : _TlDot(
          bg: const Color(0xFF3B8EF0).withOpacity(0.12),
          iconPath: 'assets/icons/ic_location.svg',
          iconColor: const Color(0xFF3B8EF0),
        ),
        connectorBuilder: (_, __, ___) => DashedLineConnector(
          color: _sub.withOpacity(0.35),
          gap: 4,
        ),
        contentsBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: i == 0
              ? _TlContent(
            title: order.vendor?.title ?? 'Restaurant',
            subtitle:
            order.vendor?.location ?? 'Location not available',
            isDark: isDark,
          )
              : _TlContent(
            title: 'Deliver to'.tr,
            subtitle: order.address?.getFullAddress() ??
                'Address not available',
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE DOT
// ─────────────────────────────────────────────────────────────────────────────
class _TlDot extends StatelessWidget {
  const _TlDot(
      {required this.bg, required this.iconPath, required this.iconColor});
  final Color bg, iconColor;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: SvgPicture.asset(iconPath,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _TlContent extends StatelessWidget {
  const _TlContent(
      {required this.title, required this.subtitle, required this.isDark});
  final String title, subtitle;
  final bool isDark;

  Color get _title =>
      isDark ? const Color(0xFFF0F2F8) : const Color(0xFF111827);
  Color get _sub => isDark ? const Color(0xFF7E8499) : const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontFamily: AppThemeData.semiBold, fontSize: 13, color: _title)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 11,
                color: _sub,
                height: 1.4)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHARGE ROW
// ─────────────────────────────────────────────────────────────────────────────
class _ChargeRow extends StatelessWidget {
  const _ChargeRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.showTipBadge = false,
  });
  final String label, value;
  final bool isDark;
  final Color? valueColor;
  final bool showTipBadge;

  Color get _title =>
      isDark ? const Color(0xFFF0F2F8) : const Color(0xFF111827);
  Color get _sub => isDark ? const Color(0xFF7E8499) : const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (showTipBadge) ...[
                const Icon(Icons.favorite_rounded,
                    size: 13, color: Color(0xFF2ED07A)),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: TextStyle(
                      fontFamily: AppThemeData.regular,
                      fontSize: 13,
                      color: _sub)),
            ],
          ),
        ),
        Text(value,
            style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 13,
                color: valueColor ?? _title)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = Constant.statusColor(status: status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 0.8),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 9,
            color: color,
            letterSpacing: 0.2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFICATION PENDING
// ─────────────────────────────────────────────────────────────────────────────
class _VerificationPending extends StatelessWidget {
  const _VerificationPending(
      {required this.isDark, required this.themeChange});
  final bool isDark;
  final DarkThemeProvider themeChange;

  Color get _title =>
      isDark ? const Color(0xFFF0F2F8) : const Color(0xFF111827);
  Color get _sub => isDark ? const Color(0xFF7E8499) : const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppThemeData.secondary300.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset('assets/icons/ic_document.svg',
                  width: 42,
                  height: 42,
                  colorFilter: const ColorFilter.mode(
                      AppThemeData.secondary300, BlendMode.srcIn)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Document Verification Pending'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _title,
                  fontSize: 20,
                  fontFamily: AppThemeData.bold,
                  letterSpacing: -0.3)),
          const SizedBox(height: 10),
          Text(
            'Your documents are being reviewed. We will notify you once the verification is complete.'
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _sub,
                fontSize: 14,
                fontFamily: AppThemeData.regular,
                height: 1.6),
          ),
          const SizedBox(height: 28),
          RoundedButtonFill(
            title: 'View Status'.tr,
            width: 55,
            height: 5.5,
            color: AppThemeData.secondary300,
            textColor: Colors.white,
            onPress: () {
              Get.put(DashBoardController()).drawerIndex.value = 4;
            },
          ),
        ],
      ),
    );
  }
}