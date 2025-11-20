import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/withdrawal_model.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart' show AppThemeData;
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:jippydriver_driver/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_utils/get_utils.dart';

import '../../model/delivery_amount_model.dart' show DriverAmountWalletTransactionModel;
import '../controller/delivery_amount_wallet_controller.dart' show DeliveryAmountWalletController;

Widget deliveryWalletTable({required BuildContext context,required DarkThemeProvider themeChange,required DeliveryAmountWalletController controller}){
  return  Expanded(
    child: DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            onTap: (value) {
              controller.selectedTabIndex.value = value;
            },
            // tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
                fontFamily: AppThemeData.semiBold),
            labelColor: themeChange.getThem()
                ? AppThemeData.secondary300
                : AppThemeData.secondary300,
            unselectedLabelStyle: const TextStyle(
                fontFamily: AppThemeData.medium),
            unselectedLabelColor: themeChange.getThem()
                ? AppThemeData.grey400
                : AppThemeData.grey500,
            indicatorColor: AppThemeData.secondary300,
            indicatorWeight: 1,
            isScrollable: true,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                text: "Earnings History".tr,
              ),
              Tab(
                text: "Withdrawal History".tr,
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<
                            String>(
                            borderRadius:
                            const BorderRadius.all(
                                Radius.circular(0)),
                            hint: Text(
                              'Select zone'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: themeChange.getThem()
                                    ? AppThemeData.grey700
                                    : AppThemeData.grey700,
                                fontFamily:
                                AppThemeData.regular,
                              ),
                            ),
                            decoration: InputDecoration(
                              errorStyle: const TextStyle(
                                  color: Colors.red),
                              isDense: true,
                              filled: true,
                              fillColor:
                              themeChange.getThem()
                                  ? AppThemeData.grey900
                                  : AppThemeData.grey50,
                              disabledBorder:
                              UnderlineInputBorder(
                                borderRadius:
                                const BorderRadius.all(
                                    Radius.circular(
                                        400)),
                                borderSide: BorderSide(
                                    color: themeChange
                                        .getThem()
                                        ? AppThemeData
                                        .grey900
                                        : AppThemeData
                                        .grey50,
                                    width: 1),
                              ),
                              focusedBorder:
                              OutlineInputBorder(
                                borderRadius:
                                const BorderRadius.all(
                                    Radius.circular(
                                        400)),
                                borderSide: BorderSide(
                                    color: themeChange
                                        .getThem()
                                        ? AppThemeData
                                        .secondary300
                                        : AppThemeData
                                        .secondary300,
                                    width: 1),
                              ),
                              enabledBorder:
                              OutlineInputBorder(
                                borderRadius:
                                const BorderRadius.all(
                                    Radius.circular(
                                        400)),
                                borderSide: BorderSide(
                                    color: themeChange
                                        .getThem()
                                        ? AppThemeData
                                        .grey900
                                        : AppThemeData
                                        .grey50,
                                    width: 1),
                              ),
                              errorBorder:
                              OutlineInputBorder(
                                borderRadius:
                                const BorderRadius.all(
                                    Radius.circular(
                                        400)),
                                borderSide: BorderSide(
                                    color: themeChange
                                        .getThem()
                                        ? AppThemeData
                                        .grey900
                                        : AppThemeData
                                        .grey50,
                                    width: 1),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                const BorderRadius.all(
                                    Radius.circular(
                                        400)),
                                borderSide: BorderSide(
                                    color: themeChange
                                        .getThem()
                                        ? AppThemeData
                                        .grey900
                                        : AppThemeData
                                        .grey50,
                                    width: 1),
                              ),
                            ),
                            value: controller
                                .selectedDropDownValue
                                .value,
                            onChanged: (value) {
                              controller
                                  .selectedDropDownValue
                                  .value = value!;
                              controller.update();
                            },
                            style: TextStyle(
                                fontSize: 14,
                                color: themeChange.getThem()
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                                fontFamily:
                                AppThemeData.medium),
                            items: controller.dropdownValue
                                .map((item) {
                              return DropdownMenuItem<
                                  String>(
                                value: item,
                                child:
                                Text(item.toString()),
                              );
                            }).toList()),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        child: Container(
                          decoration: ShapeDecoration(
                            color: themeChange.getThem()
                                ? AppThemeData.grey900
                                : AppThemeData.grey50,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                          child: Padding(
                            padding:
                            const EdgeInsets.all(8.0),
                            child: transactionCardForOrder(
                              themeChange,
                              controller.selectedDropDownValue
                                  .value ==
                                  "Daily"
                                  ? controller
                                  .dailyEarningList
                                  : controller.selectedDropDownValue
                                  .value ==
                                  "Monthly"
                                  ? controller
                                  .monthlyEarningList
                                  : controller
                                  .yearlyEarningList,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                controller.withdrawalList.isEmpty
                    ? Constant.showEmptyView(
                    message:
                    "Withdrawal history not found"
                        .tr)
                    : Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Container(
                    decoration: ShapeDecoration(
                      color: themeChange.getThem()
                          ? AppThemeData.grey900
                          : AppThemeData.grey50,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(8.0),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: controller
                            .withdrawalList.length,
                        itemBuilder:
                            (context, index) {
                          WithdrawalModel
                          walletTractionModel =
                          controller
                              .withdrawalList[
                          index];
                          return transactionCardWithdrawal(
                              controller,
                              themeChange,
                              walletTractionModel);
                        },
                        separatorBuilder:
                            (BuildContext context,
                            int index) {
                          return Padding(
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: 5),
                            child: MySeparator(
                                color: themeChange
                                    .getThem()
                                    ? AppThemeData
                                    .grey700
                                    : AppThemeData
                                    .grey200),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}

transactionCardWithdrawal(DeliveryAmountWalletController controller, themeChange,
    WithdrawalModel transactionModel) {
  return InkWell(
    onTap: () async {},
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    width: 1,
                    color: themeChange.getThem()
                        ? AppThemeData.grey800
                        : AppThemeData.grey100),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(
                "assets/icons/ic_debit.svg",
                height: 16,
                width: 16,
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transactionModel.note.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w600,
                              color: themeChange.getThem()
                                  ? AppThemeData.grey100
                                  : AppThemeData.grey800,
                            ),
                          ),
                          Text(
                            "(${transactionModel.withdrawMethod!.capitalizeString()})",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.medium,
                              fontWeight: FontWeight.w600,
                              color: themeChange.getThem()
                                  ? AppThemeData.grey100
                                  : AppThemeData.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "-${Constant.amountShow(amount: transactionModel.amount.toString())}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.danger300,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transactionModel.paymentStatus.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                          color: transactionModel.paymentStatus == "Success"
                              ? AppThemeData.success400
                              : transactionModel.paymentStatus == "Pending"
                              ? AppThemeData.primary300
                              : AppThemeData.danger300,
                        ),
                      ),
                    ),
                    Text(
                      Constant.timestampToDateTime(
                          transactionModel.paidDate!),
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.medium,
                          fontWeight: FontWeight.w500,
                          color: themeChange.getThem()
                              ? AppThemeData.grey200
                              : AppThemeData.grey700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

transactionCardForOrder(themeChange, List<DriverAmountWalletTransactionModel> list) {
  return list.isEmpty
      ? Constant.showEmptyView(message: "Transaction history not found".tr)
      : ListView.separated(
    padding: EdgeInsets.zero,
    shrinkWrap: true,
    itemCount: list.length,
    itemBuilder: (context, index) {
      DriverAmountWalletTransactionModel walletTractionModel = list[index];



      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      width: 1,
                      color: themeChange.getThem()
                          ? AppThemeData.grey800
                          : AppThemeData.grey100),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SvgPicture.asset(
                  "assets/icons/ic_credit.svg",
                  height: 16,
                  width: 16,
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ( walletTractionModel.bonus??false)  ?        Row(
                    children: [
                      Expanded(
                        child: Text(
                             "Bonus Amount".tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w600,
                            color: themeChange.getThem()
                                ? AppThemeData.primary400
                                : AppThemeData.primary400,
                          ),
                        ),
                      ),
                      Text(  walletTractionModel.bonusAmount.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.success400,
                        ),
                      )
                    ],
                  ):SizedBox(),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Delivery Amount".tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w600,
                            color: themeChange.getThem()
                                ? AppThemeData.grey100
                                : AppThemeData.grey800,
                          ),
                        ),
                      ),
                      Text(
                        "${(double.tryParse(walletTractionModel.totalEarnings.toString()) ?? 0.0)-(double.tryParse(walletTractionModel.bonusAmount.toString()) ?? 0.0) 
                            }",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.success400,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    Constant.timestampToDateTime(
                        walletTractionModel.date!),
                    style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.medium,
                        fontWeight: FontWeight.w500,
                        color: themeChange.getThem()
                            ? AppThemeData.grey200
                            : AppThemeData.grey700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
    separatorBuilder: (BuildContext context, int index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: MySeparator(
            color: themeChange.getThem()
                ? AppThemeData.grey700
                : AppThemeData.grey200),
      );
    },
  );
}

transactionCard(DeliveryAmountWalletController controller, themeChange,
    DriverAmountWalletTransactionModel transactionModel) {
  return InkWell(
    onTap: () async {},
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    width: 1,
                    color: themeChange.getThem()
                        ? AppThemeData.grey800
                        : AppThemeData.grey100),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: transactionModel.bonus == false
                  ? SvgPicture.asset(
                "assets/icons/ic_debit.svg",
                height: 16,
                width: 16,
              )
                  : SvgPicture.asset(
                "assets/icons/ic_credit.svg",
                height: 16,
                width: 16,
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transactionModel.type.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                          color: themeChange.getThem()
                              ? AppThemeData.grey100
                              : AppThemeData.grey800,
                        ),
                      ),
                    ),
                    Text(
                      transactionModel.bonus == false
                          ? "-${Constant.amountShow(amount: transactionModel.totalEarnings.toString())}"
                          : Constant.amountShow(
                          amount: transactionModel.totalEarnings.toString()),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.medium,
                        color: transactionModel.bonus == true
                            ? AppThemeData.success400
                            : AppThemeData.danger300,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  Constant.timestampToDateTime(transactionModel.date!),
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.medium,
                      fontWeight: FontWeight.w500,
                      color: themeChange.getThem()
                          ? AppThemeData.grey200
                          : AppThemeData.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/models/order_model.dart';
// import 'package:jippydriver_driver/models/withdrawal_model.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart' show AppThemeData;
// import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
// import 'package:jippydriver_driver/widget/my_separator.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get_utils/get_utils.dart';
//
// import '../../model/delivery_amount_model.dart' show DriverAmountWalletTransactionModel;
// import '../controller/delivery_amount_wallet_controller.dart' show DeliveryAmountWalletController;
//
// Widget deliveryWalletTable({required BuildContext context,required DarkThemeProvider themeChange,required DeliveryAmountWalletController controller}){
//   return  Expanded(
//     child: DefaultTabController(
//       length: 2,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           TabBar(
//             onTap: (value) {
//               controller.selectedTabIndex.value = value;
//             },
//             tabAlignment: TabAlignment.start,
//             labelStyle: const TextStyle(
//                 fontFamily: AppThemeData.semiBold),
//             labelColor: themeChange.getThem()
//                 ? AppThemeData.secondary300
//                 : AppThemeData.secondary300,
//             unselectedLabelStyle: const TextStyle(
//                 fontFamily: AppThemeData.medium),
//             unselectedLabelColor: themeChange.getThem()
//                 ? AppThemeData.grey400
//                 : AppThemeData.grey500,
//             indicatorColor: AppThemeData.secondary300,
//             indicatorWeight: 1,
//             isScrollable: true,
//             dividerColor: Colors.transparent,
//             tabs: [
//               Tab(
//                 text: "Transaction History".tr,
//               ),
//               Tab(
//                 text: "Withdrawal History".tr,
//               ),
//             ],
//           ),
//           Expanded(
//             child: TabBarView(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 10),
//                   child: Column(
//                     crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Container(
//                           decoration: ShapeDecoration(
//                             color: themeChange.getThem()
//                                 ? AppThemeData.grey900
//                                 : AppThemeData.grey50,
//                             shape: RoundedRectangleBorder(
//                               borderRadius:
//                               BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: Padding(
//                             padding:
//                             const EdgeInsets.all(8.0),
//                             child: transactionCardForOrder(
//                                 themeChange,
//                                 controller.walletTopTransactionList
//
//                             ),
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//                 controller.withdrawalList.isEmpty
//                     ? Constant.showEmptyView(
//                     message:
//                     "Withdrawal history not found"
//                         .tr)
//                     : Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 10),
//                   child: Container(
//                     decoration: ShapeDecoration(
//                       color: themeChange.getThem()
//                           ? AppThemeData.grey900
//                           : AppThemeData.grey50,
//                       shape: RoundedRectangleBorder(
//                         borderRadius:
//                         BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Padding(
//                       padding:
//                       const EdgeInsets.all(8.0),
//                       child: ListView.separated(
//                         padding: EdgeInsets.zero,
//                         shrinkWrap: true,
//                         itemCount: controller
//                             .withdrawalList.length,
//                         itemBuilder:
//                             (context, index) {
//                           WithdrawalModel
//                           walletTractionModel =
//                           controller
//                               .withdrawalList[
//                           index];
//                           return transactionCardWithdrawal(
//                               controller,
//                               themeChange,
//                               walletTractionModel);
//                         },
//                         separatorBuilder:
//                             (BuildContext context,
//                             int index) {
//                           return Padding(
//                             padding: const EdgeInsets
//                                 .symmetric(
//                                 vertical: 5),
//                             child: MySeparator(
//                                 color: themeChange
//                                     .getThem()
//                                     ? AppThemeData
//                                     .grey700
//                                     : AppThemeData
//                                     .grey200),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     ),
//   );
// }
//
// transactionCardWithdrawal(DeliveryAmountWalletController controller, themeChange,
//     WithdrawalModel transactionModel) {
//   return InkWell(
//     onTap: () async {},
//     child: Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         children: [
//           Container(
//             decoration: ShapeDecoration(
//               shape: RoundedRectangleBorder(
//                 side: BorderSide(
//                     width: 1,
//                     color: themeChange.getThem()
//                         ? AppThemeData.grey800
//                         : AppThemeData.grey100),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: SvgPicture.asset(
//                 "assets/icons/ic_debit.svg",
//                 height: 16,
//                 width: 16,
//               ),
//             ),
//           ),
//           const SizedBox(
//             width: 10,
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             transactionModel.note.toString(),
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontFamily: AppThemeData.semiBold,
//                               fontWeight: FontWeight.w600,
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey100
//                                   : AppThemeData.grey800,
//                             ),
//                           ),
//                           Text(
//                             "(${transactionModel.withdrawMethod!.capitalizeString()})",
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontFamily: AppThemeData.medium,
//                               fontWeight: FontWeight.w600,
//                               color: themeChange.getThem()
//                                   ? AppThemeData.grey100
//                                   : AppThemeData.grey800,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Text(
//                       "-${Constant.amountShow(amount: transactionModel.amount.toString())}",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontFamily: AppThemeData.medium,
//                         color: AppThemeData.danger300,
//                       ),
//                     )
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 2,
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         transactionModel.paymentStatus.toString(),
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontFamily: AppThemeData.semiBold,
//                           fontWeight: FontWeight.w600,
//                           color: transactionModel.paymentStatus == "Success"
//                               ? AppThemeData.success400
//                               : transactionModel.paymentStatus == "Pending"
//                               ? AppThemeData.primary300
//                               : AppThemeData.danger300,
//                         ),
//                       ),
//                     ),
//                     Text(
//                       Constant.timestampToDateTime(
//                           transactionModel.paidDate!),
//                       style: TextStyle(
//                           fontSize: 12,
//                           fontFamily: AppThemeData.medium,
//                           fontWeight: FontWeight.w500,
//                           color: themeChange.getThem()
//                               ? AppThemeData.grey200
//                               : AppThemeData.grey700),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
//
// transactionCardForOrder(themeChange, List<DriverAmountWalletTransactionModel> list) {
//   return list.isEmpty
//       ? Constant.showEmptyView(message: "Transaction history not found".tr)
//       : ListView.separated(
//     padding: EdgeInsets.zero,
//     shrinkWrap: true,
//     itemCount: list.length,
//     itemBuilder: (context, index) {
//       DriverAmountWalletTransactionModel walletTractionModel = list[index];
//
//
//
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 5),
//         child: Row(
//           children: [
//             Container(
//               decoration: ShapeDecoration(
//                 shape: RoundedRectangleBorder(
//                   side: BorderSide(
//                       width: 1,
//                       color: themeChange.getThem()
//                           ? AppThemeData.grey800
//                           : AppThemeData.grey100),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: SvgPicture.asset(
//                   "assets/icons/ic_credit.svg",
//                   height: 16,
//                   width: 16,
//                 ),
//               ),
//             ),
//             const SizedBox(
//               width: 10,
//             ),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           "Completed Delivery".tr,
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontFamily: AppThemeData.semiBold,
//                             fontWeight: FontWeight.w600,
//                             color: themeChange.getThem()
//                                 ? AppThemeData.grey100
//                                 : AppThemeData.grey800,
//                           ),
//                         ),
//                       ),
//                       Text(walletTractionModel.totalEarnings.toString(),
//                         //Constant.amountShow(amount: amount.toString()),
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontFamily: AppThemeData.medium,
//                           color: AppThemeData.success400,
//                         ),
//                       )
//                     ],
//                   ),
//                   const SizedBox(
//                     height: 2,
//                   ),
//                   Text(
//                     Constant.timestampToDateTime(
//                       walletTractionModel.date??Timestamp.now(),),
//                     style: TextStyle(
//                         fontSize: 12,
//                         fontFamily: AppThemeData.medium,
//                         fontWeight: FontWeight.w500,
//                         color: themeChange.getThem()
//                             ? AppThemeData.grey200
//                             : AppThemeData.grey700),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     },
//     separatorBuilder: (BuildContext context, int index) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 5),
//         child: MySeparator(
//             color: themeChange.getThem()
//                 ? AppThemeData.grey700
//                 : AppThemeData.grey200),
//       );
//     },
//   );
// }
//
// transactionCard(DeliveryAmountWalletController controller, themeChange,
//     DriverAmountWalletTransactionModel transactionModel) {
//   return InkWell(
//     onTap: () async {},
//     child: Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         children: [
//           Container(
//             decoration: ShapeDecoration(
//               shape: RoundedRectangleBorder(
//                 side: BorderSide(
//                     width: 1,
//                     color: themeChange.getThem()
//                         ? AppThemeData.grey800
//                         : AppThemeData.grey100),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: transactionModel.bonus == false
//                   ? SvgPicture.asset(
//                 "assets/icons/ic_debit.svg",
//                 height: 16,
//                 width: 16,
//               )
//                   : SvgPicture.asset(
//                 "assets/icons/ic_credit.svg",
//                 height: 16,
//                 width: 16,
//               ),
//             ),
//           ),
//           const SizedBox(
//             width: 10,
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         transactionModel.type.toString(),
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontFamily: AppThemeData.semiBold,
//                           fontWeight: FontWeight.w600,
//                           color: themeChange.getThem()
//                               ? AppThemeData.grey100
//                               : AppThemeData.grey800,
//                         ),
//                       ),
//                     ),
//                     Text(
//                       transactionModel.bonus == false
//                           ? "-${Constant.amountShow(amount: transactionModel.totalEarnings.toString())}"
//                           : Constant.amountShow(
//                           amount: transactionModel.totalEarnings.toString()),
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontFamily: AppThemeData.medium,
//                         color: transactionModel.bonus == true
//                             ? AppThemeData.success400
//                             : AppThemeData.danger300,
//                       ),
//                     )
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 2,
//                 ),
//                 Text(
//                   Constant.timestampToDateTime(transactionModel.date!),
//                   style: TextStyle(
//                       fontSize: 12,
//                       fontFamily: AppThemeData.medium,
//                       fontWeight: FontWeight.w500,
//                       color: themeChange.getThem()
//                           ? AppThemeData.grey200
//                           : AppThemeData.grey700),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }