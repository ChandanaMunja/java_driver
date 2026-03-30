import 'package:jippydriver_driver/app/chat_screens/chat_screen.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/app/home_screen/screens/delivery_order_screen/controller/deliver_order_controller.dart';
import 'package:jippydriver_driver/models/cart_product_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';

const String _kPaymentQrAsset = 'assets/images/paymentqr.jpeg';

void _openPaymentQrFullscreen(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: true,
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.6,
                      maxScale: 4,
                      child: Image.asset(
                        _kPaymentQrAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Could not load payment QR'.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 220),
    ),
  );
}

class DeliverOrderScreen extends StatelessWidget {
  const DeliverOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.log('DeliverOrderScreen build() called', tag: 'Screen');
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: DeliverOrderController(),
        builder: (controller) {
          return controller.isLoading.value
              ? Constant.loader()
              : Scaffold(
                  appBar: AppBar(
                    backgroundColor: themeChange.getThem()
                        ? AppThemeData.grey900
                        : AppThemeData.grey50,
                    centerTitle: false,
                    titleSpacing: 0,
                    iconTheme: const IconThemeData(
                        color: AppThemeData.grey900, size: 20),
                    title: Text(
                      Constant.orderId(
                              orderId:
                                  controller.orderModel.value.id.toString())
                          .tr,
                      style: TextStyle(
                          color: themeChange.getThem()
                              ? AppThemeData.grey50
                              : AppThemeData.grey900,
                          fontSize: 18,
                          fontFamily: AppThemeData.medium),
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              final calculated =
                                  controller.orderModel.value.calculatedCharges;
                              final rawTotal =
                                  calculated?['totalCalculatedCharge'];
                              final rawToPay =
                                  controller.orderModel.value.toPay;

                              final double? parsedToPay = rawToPay != null
                                  ? double.tryParse(
                                      rawToPay.toString().trim())
                                  : null;

                              final double? parsedTotal = rawTotal != null
                                  ? double.tryParse(
                                      rawTotal.toString().trim())
                                  : null;

                              final double? parsedDeliveryCharge = controller
                                      .orderModel.value.deliveryCharge !=
                                  null
                                  ? double.tryParse(controller
                                      .orderModel.value.deliveryCharge
                                      .toString()
                                      .trim())
                                  : null;

                              final amount = parsedToPay ??
                                  parsedTotal ??
                                  parsedDeliveryCharge ??
                                  0.0;

                              return Container(
                                decoration: ShapeDecoration(
                                  color: themeChange.getThem()
                                      ? AppThemeData.grey900
                                      : AppThemeData.grey50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Amount to Collect'.tr,
                                            style: TextStyle(
                                              fontFamily: AppThemeData.semiBold,
                                              fontSize: 16,
                                              color: themeChange.getThem()
                                                  ? AppThemeData.grey300
                                                  : AppThemeData.grey600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '₹${amount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontFamily: AppThemeData.medium,
                                              fontSize: 20,
                                              color: themeChange.getThem()
                                                  ? AppThemeData.grey50
                                                  : AppThemeData.grey900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.money_rounded,
                                      color: AppThemeData.success400,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ShapeDecoration(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey900
                                  : AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Deliver to the".tr,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.semiBold,
                                            fontSize: 16,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey50
                                                : AppThemeData.grey900,
                                          ),
                                        ),
                                        Text(
                                          controller.orderModel.value.address!
                                              .getFullAddress(),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.medium,
                                            fontSize: 14,
                                            color: themeChange.getThem()
                                                ? AppThemeData.grey300
                                                : AppThemeData.grey600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      ShowToastDialog.showLoader(
                                          "Please wait".tr);

                                      UserModel? customer =
                                          await FireStoreUtils.getUserProfile(
                                              controller
                                                  .orderModel.value.authorID
                                                  .toString());
                                      UserModel? driver =
                                          await FireStoreUtils.getUserProfile(
                                              controller
                                                  .orderModel.value.driverID
                                                  .toString());

                                      ShowToastDialog.closeLoader();

                                      Get.to(const ChatScreen(), arguments: {
                                        "customerName":
                                            '${customer!.fullName()}',
                                        "restaurantName": driver!.fullName(),
                                        "orderId":
                                            controller.orderModel.value.id,
                                        "restaurantId": driver.id,
                                        "customerId": customer.id,
                                        "customerProfileImage":
                                            customer.profilePictureURL ?? "",
                                        "restaurantProfileImage":
                                            driver.profilePictureURL ?? "",
                                        "token": customer.fcmToken,
                                        "chatType": "Driver",
                                      });
                                    },
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: ShapeDecoration(
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              width: 1,
                                              color: themeChange.getThem()
                                                  ? AppThemeData.grey700
                                                  : AppThemeData.grey200),
                                          borderRadius:
                                              BorderRadius.circular(120),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SvgPicture.asset(
                                            "assets/icons/ic_wechat.svg"),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            decoration: ShapeDecoration(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey900
                                  : AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: controller
                                        .orderModel.value.products!.length,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      CartProductModel product = controller
                                          .orderModel.value.products![index];

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(14)),
                                                child: Stack(
                                                  children: [
                                                    NetworkImageWidget(
                                                      imageUrl: product.photo
                                                          .toString(),
                                                      height: Responsive.height(
                                                          8, context),
                                                      width: Responsive.width(
                                                          16, context),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Container(
                                                      height: Responsive.height(
                                                          8, context),
                                                      width: Responsive.width(
                                                          16, context),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              const Alignment(
                                                                  -0.00, -1.00),
                                                          end: const Alignment(
                                                              0, 1),
                                                          colors: [
                                                            Colors.black
                                                                .withOpacity(0),
                                                            const Color(
                                                                0xFF111827)
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            "${product.name}",
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  AppThemeData
                                                                      .regular,
                                                              color: themeChange
                                                                      .getThem()
                                                                  ? AppThemeData
                                                                      .grey50
                                                                  : AppThemeData
                                                                      .grey900,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          "x ${product.quantity}",
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppThemeData
                                                                    .regular,
                                                            color: themeChange
                                                                    .getThem()
                                                                ? AppThemeData
                                                                    .grey50
                                                                : AppThemeData
                                                                    .grey900,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          product.variantInfo == null ||
                                                  product.variantInfo!
                                                      .variantOptions!.isEmpty
                                              ? Container()
                                              : Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5,
                                                      vertical: 10),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Variants".tr,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              AppThemeData
                                                                  .semiBold,
                                                          color: themeChange
                                                                  .getThem()
                                                              ? AppThemeData
                                                                  .grey300
                                                              : AppThemeData
                                                                  .grey600,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Wrap(
                                                        spacing: 6.0,
                                                        runSpacing: 6.0,
                                                        children: List.generate(
                                                          product
                                                              .variantInfo!
                                                              .variantOptions!
                                                              .length,
                                                          (i) {
                                                            return Container(
                                                              decoration:
                                                                  ShapeDecoration(
                                                                color: themeChange.getThem()
                                                                    ? AppThemeData
                                                                        .grey800
                                                                    : AppThemeData
                                                                        .grey100,
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8)),
                                                              ),
                                                              child: Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        5),
                                                                child: Text(
                                                                  "${product.variantInfo!.variantOptions!.keys.elementAt(i)} : ${product.variantInfo!.variantOptions![product.variantInfo!.variantOptions!.keys.elementAt(i)]}",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        AppThemeData
                                                                            .medium,
                                                                    color: themeChange.getThem()
                                                                        ? AppThemeData
                                                                            .grey500
                                                                        : AppThemeData
                                                                            .grey400,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ).toList(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          product.extras == null ||
                                                  product.extras!.isEmpty
                                              ? const SizedBox()
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text(
                                                      "Addons".tr,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData
                                                            .semiBold,
                                                        color: themeChange
                                                                .getThem()
                                                            ? AppThemeData
                                                                .grey300
                                                            : AppThemeData
                                                                .grey600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Wrap(
                                                      spacing: 6.0,
                                                      runSpacing: 6.0,
                                                      children: List.generate(
                                                        product.extras!.length,
                                                        (i) {
                                                          return Container(
                                                            decoration:
                                                                ShapeDecoration(
                                                              color: themeChange
                                                                      .getThem()
                                                                  ? AppThemeData
                                                                      .grey800
                                                                  : AppThemeData
                                                                      .grey100,
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8)),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          5),
                                                              child: Text(
                                                                product
                                                                    .extras![i]
                                                                    .toString(),
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      AppThemeData
                                                                          .medium,
                                                                  color: themeChange.getThem()
                                                                      ? AppThemeData
                                                                          .grey500
                                                                      : AppThemeData
                                                                          .grey400,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ).toList(),
                                                    ),
                                                  ],
                                                ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  InkWell(
                                    onTap: (){
                                     controller.confirmPickupFunction();
                                    },
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          side: const BorderSide(
                                            color: AppThemeData.success400,
                                            width: 1.5,
                                          ),
                                          value: controller.conformPickup.value,
                                          activeColor: AppThemeData.success400,
                                          focusColor: AppThemeData.success400,
                                          onChanged: (value) {
                                            if (value != null) {
                                              controller.conformPickup.value =
                                                  value;
                                            }
                                          },
                                        ),
                                        Text(
                                          "${'Give'.tr} ${controller.totalQuantity.value.toString()} ${'Items to the customer'.tr}"
                                              .tr,
                                          style: TextStyle(
                                              color: themeChange.getThem()
                                                  ? AppThemeData.success400
                                                  : AppThemeData.success400,
                                              fontSize: 16,
                                              fontFamily: AppThemeData.medium),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottomNavigationBar: Material(
                    elevation: 8,
                    color: AppThemeData.driverApp300,
                    child: SafeArea(
                      top: false,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 🔵 Left Button (smaller now)
                            Expanded(
                              flex: 2, // 👈 reduce size
                              child: InkWell(
                                onTap: controller.isCompletingOrder.value
                                    ? null
                                    : () async {
                                  if (controller.conformPickup.value == false) {
                                    ShowToastDialog.showToast(
                                        "Conform Deliver order".tr);
                                  } else {
                                    await controller.completedOrder();
                                  }
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  color: controller.isCompletingOrder.value
                                      ? AppThemeData.grey400
                                      : AppThemeData.driverApp300,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  child: Text(
                                    controller.isCompletingOrder.value
                                        ? "Processing...".tr
                                        : "Make Order Delivered".tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppThemeData.grey50,
                                      fontSize: 16,
                                      fontFamily: AppThemeData.medium,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Container(
                              width: 1,
                              color: Colors.white24,
                            ),

                            // 🟢 Payment Button (bigger)
                            Expanded(
                              flex: 1, // 👈 increase this to 2 if you want equal
                              child: Material(
                                color: AppThemeData.driverApp300,
                                child: InkWell(
                                  onTap: () => _openPaymentQrFullscreen(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.qr_code_2_rounded,
                                          color: AppThemeData.grey50,
                                          size: 28, // 👈 slightly bigger icon
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Payment'.tr,
                                          style: const TextStyle(
                                            color: AppThemeData.grey50,
                                            fontSize: 14, // 👈 bigger text
                                            fontFamily: AppThemeData.medium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ),
                    ),
                  ),
                );
        });
  }
}
