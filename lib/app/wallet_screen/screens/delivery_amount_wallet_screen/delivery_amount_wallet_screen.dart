import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippydriver_driver/app/wallet_screen/payment_list_screen.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/widgets/transcation_delivery_table.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/widgets/wallet_card.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/model/delivery_amount_model.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/app/wallet_screen/controller/wallet_controller.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/wallet_transaction_model.dart';
import 'package:jippydriver_driver/models/withdrawal_model.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:jippydriver_driver/themes/round_button_fill.dart';
import 'package:jippydriver_driver/themes/text_field_widget.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:jippydriver_driver/widget/my_separator.dart';

import 'controller/delivery_amount_wallet_controller.dart';

class DeliveryAmountWalletScreen extends StatelessWidget {
  final bool? isAppBarShow;

  const DeliveryAmountWalletScreen({super.key, required this.isAppBarShow});

  @override
  Widget build(BuildContext context) {
    AppLogger.log('WalletScreen build() called', tag: 'Screen');
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: DeliveryAmountWalletController(),
        builder: (controller) {
          return Scaffold(
            appBar: isAppBarShow == true
                ? AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.grey900
                  : AppThemeData.grey50,
              centerTitle: false,
              iconTheme: IconThemeData(
                  color: themeChange.getThem()
                      ? AppThemeData.grey50
                      : AppThemeData.grey900,
                  size: 20),
              title: Text(
                "Delivery Wallet".tr,
                style: TextStyle(
                    color: themeChange.getThem()
                        ? AppThemeData.grey50
                        : AppThemeData.grey900,
                    fontSize: 18,
                    fontFamily: AppThemeData.medium),
              ),
            )
                : null,
            body: controller.isLoading.value
                ? Constant.loader()
                : Column(
              children: [
                deliveryWalletCard(context: context, themeChange: themeChange, controller: controller
                  ,),
                deliveryWalletTable(context: context, themeChange: themeChange, controller: controller,
                ),
              ],
            ),
          );
        });
  }



}
