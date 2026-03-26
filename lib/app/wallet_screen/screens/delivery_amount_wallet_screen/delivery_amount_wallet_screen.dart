// import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/widgets/transcation_delivery_table.dart';
// import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/widgets/wallet_card.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/themes/app_them_data.dart';
// import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
// import 'package:jippydriver_driver/utils/app_logger.dart';
//
// import 'controller/delivery_amount_wallet_controller.dart';
//
// class DeliveryAmountWalletScreen extends StatelessWidget {
//   final bool? isAppBarShow;
//
//   const DeliveryAmountWalletScreen({super.key, required this.isAppBarShow});
//
//   @override
//   Widget build(BuildContext context) {
//     AppLogger.log('WalletScreen build() called', tag: 'Screen');
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     return GetX(
//         init: DeliveryAmountWalletController(),
//         builder: (controller) {
//           return Scaffold(
//             appBar: isAppBarShow == true
//                 ? AppBar(
//               backgroundColor: themeChange.getThem()
//                   ? AppThemeData.grey900
//                   : AppThemeData.grey50,
//               centerTitle: false,
//               iconTheme: IconThemeData(
//                   color: themeChange.getThem()
//                       ? AppThemeData.grey50
//                       : AppThemeData.grey900,
//                   size: 20),
//               title: Text(
//                 "Delivery Wallet".tr,
//                 style: TextStyle(
//                     color: themeChange.getThem()
//                         ? AppThemeData.grey50
//                         : AppThemeData.grey900,
//                     fontSize: 18,
//                     fontFamily: AppThemeData.medium),
//               ),
//             )
//                 : null,
//             body: controller.isLoading.value
//                 ? Constant.loader()
//                 : Column(
//               children: [
//                 deliveryWalletCard(context: context, themeChange: themeChange, controller: controller
//                   ,),
//                 deliveryWalletTable(context: context, themeChange: themeChange, controller: controller,
//                 ),
//               ],
//             ),
//           );
//         });
//   }
//
//
//
// }



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/controller/delivery_amount_wallet_controller.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/widgets/transcation_delivery_table.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/delivery_amount_wallet_screen/widgets/wallet_card.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';

class DeliveryAmountWalletScreen extends StatelessWidget {
  final bool isAppBarShow;

  const DeliveryAmountWalletScreen({super.key, this.isAppBarShow = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
    Provider.of<DarkThemeProvider>(context).getThem();

    return GetX<DeliveryAmountWalletController>(
      init: DeliveryAmountWalletController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return Scaffold(
            backgroundColor:
            isDark ? AppThemeData.grey900 : AppThemeData.grey50,
            appBar: isAppBarShow ? _buildAppBar(isDark) : null,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor:
          isDark ? AppThemeData.grey900 : AppThemeData.grey50,
          appBar: isAppBarShow ? _buildAppBar(isDark) : null,
          body: RefreshIndicator(
            onRefresh: controller.refresh,
            // Column keeps the wallet card fixed while the tab views scroll.
            child: Column(
              children: [
                // Wallet balance card (fixed, non-scrolling)
                DeliveryWalletCard(controller: controller),

                // Tab bar + paginated lists (fills remaining space)
                DeliveryWalletTable(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(bool isDark) => AppBar(
    backgroundColor:
    isDark ? AppThemeData.grey900 : AppThemeData.grey50,
    centerTitle: false,
    elevation: 0,
    iconTheme: IconThemeData(
      color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
      size: 20,
    ),
    title: Text(
      'Delivery Wallet'.tr,
      style: TextStyle(
        color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
        fontSize: 18,
        fontFamily: AppThemeData.medium,
      ),
    ),
  );
}