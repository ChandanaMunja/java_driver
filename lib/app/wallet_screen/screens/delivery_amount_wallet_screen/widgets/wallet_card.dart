import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:jippydriver_driver/themes/round_button_fill.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/export.dart';

import '../controller/delivery_amount_wallet_controller.dart' show DeliveryAmountWalletController;

Widget deliveryWalletCard({required BuildContext context,required DarkThemeProvider themeChange,required DeliveryAmountWalletController controller}){
  return     Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 10),
    child: Container(
      width: Responsive.width(100, context),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        image: DecorationImage(
          image: AssetImage("assets/images/wallet.png"),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Text(
              "My Wallet".tr,
              maxLines: 1,
              style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey900
                    : AppThemeData.grey900,
                fontSize: 16,
                overflow: TextOverflow.ellipsis,
                fontFamily: AppThemeData.regular,
              ),
            ),
            Text(
              Constant.amountShow(
                  amount: controller
                      .userModel.value.deliveryAmount
                      .toString(),),
              maxLines: 1,
              style: TextStyle(
                color: themeChange.getThem()
                    ? AppThemeData.grey900
                    : AppThemeData.grey900,
                fontSize: 40,
                overflow: TextOverflow.ellipsis,
                fontFamily: AppThemeData.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Wallet status indicator (show only if wallet is below -1000)
            // if ((controller.userModel.value.walletAmount ?? 0.0).toDouble() < -1000)
            //   Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            //     decoration: BoxDecoration(
            //       color: Colors.red.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(12),
            //       border: Border.all(
            //         color: Colors.red,
            //         width: 1,
            //       ),
            //     ),
            //     child: const Text(
            //       "Wallet balance is below minimum required amount",
            //       style: TextStyle(
            //         color: Colors.red,
            //         fontSize: 12,
            //         fontFamily: AppThemeData.medium,
            //       ),
            //     ),
            //   ),
            const SizedBox(
              height: 20,
            ),
            (Constant.isDriverVerification == false &&
                controller.userModel.value
                    .isDocumentVerify ==
                    false)
                ? const SizedBox()
                : Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              child: RoundedButtonFill(
                title: "Withdraw".tr,
                width: 24,
                height: 5.5,
                color: AppThemeData.grey50,
                textColor: AppThemeData.grey900,
                borderRadius: 200,
                onPress: () {
                  if ((Constant.userModel!
                      .userBankDetails !=
                      null &&
                      Constant
                          .userModel!
                          .userBankDetails!
                          .accountNumber
                          .isNotEmpty) ||
                      controller
                          .withdrawMethodModel
                          .value
                          .id !=
                          null) {
                    // withdrawalCardBottomSheet(
                    //     context, controller);
                  } else {
                    ShowToastDialog.showToast(
                        "Please enter payment method"
                            .tr);
                  }
                },
              ),
            )
          ],
        ),
      ),
    ),
  );

}