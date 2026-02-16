import 'dart:io';

import 'package:jippydriver_driver/app/auth_screen/phone_number_screen.dart';
import 'package:jippydriver_driver/app/auth_screen/signup_screen.dart';
import 'package:jippydriver_driver/app/forgot_password_screen/forgot_password_screen.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:jippydriver_driver/themes/round_button_fill.dart';
import 'package:jippydriver_driver/themes/text_field_widget.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippydriver_driver/utils/dark_theme_provider.dart' show DarkThemeProvider;
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.surfaceDark
                  : AppThemeData.surface,
            ),
            body: SingleChildScrollView(
              // Enable scrolling for smaller screens
              physics: const BouncingScrollPhysics(), // Smooth iOS-like scrolling
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated title for smooth appearance
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Log In to Your Account".tr,
                            style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                                fontSize: 22,
                                fontFamily: AppThemeData.semiBold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Sign in to access your JippyMart account and manage your deliveries seamlessly.".tr,
                            style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey500,
                                fontFamily: AppThemeData.regular),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: "Didn't Have an account?".tr,
                              style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w500,
                              )),
                          const WidgetSpan(
                              child: SizedBox(
                            width: 10,
                          )),
                          TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.to(() => const SignupScreen(),
                                      transition: Transition.rightToLeft,
                                      duration: const Duration(milliseconds: 300));
                                },
                              text: 'Sign up'.tr,
                              style: const TextStyle(
                                  color: AppThemeData.secondary300,
                                  fontFamily: AppThemeData.medium,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppThemeData.secondary300)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Email field with smooth animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: TextFieldWidget(
                        title: 'Email Address'.tr,
                        controller: controller.emailEditingController.value,
                        hintText: 'Enter email address'.tr,
                        prefix: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            "assets/icons/ic_mail.svg",
                            colorFilter: ColorFilter.mode(
                              themeChange.getThem()
                                  ? AppThemeData.grey300
                                  : AppThemeData.grey600,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password field with smooth animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Obx(() => TextFieldWidget(
                        title: 'Password'.tr,
                        controller: controller.passwordEditingController.value,
                        hintText: 'Enter password'.tr,
                        obscureText: controller.passwordVisible.value,
                        prefix: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            "assets/icons/ic_lock.svg",
                            colorFilter: ColorFilter.mode(
                              themeChange.getThem()
                                  ? AppThemeData.grey300
                                  : AppThemeData.grey600,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        suffix: Padding(
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                              onTap: () {
                                controller.passwordVisible.value =
                                    !controller.passwordVisible.value;
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: controller.passwordVisible.value
                                    ? SvgPicture.asset(
                                        "assets/icons/ic_password_show.svg",
                                        key: const ValueKey('show'),
                                        colorFilter: ColorFilter.mode(
                                          themeChange.getThem()
                                              ? AppThemeData.grey300
                                              : AppThemeData.grey600,
                                          BlendMode.srcIn,
                                        ),
                                      )
                                    : SvgPicture.asset(
                                        "assets/icons/ic_password_close.svg",
                                        key: const ValueKey('hide'),
                                        colorFilter: ColorFilter.mode(
                                          themeChange.getThem()
                                              ? AppThemeData.grey300
                                              : AppThemeData.grey600,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                              )),
                        ),
                      )),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Get.to(() => const ForgotPasswordScreen(),
                            transition: Transition.rightToLeft,
                            duration: const Duration(milliseconds: 300));
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Forgot Password".tr,
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: AppThemeData.secondary300,
                              color: themeChange.getThem()
                                  ? AppThemeData.secondary300
                                  : AppThemeData.secondary300,
                              fontSize: 14,
                              fontFamily: AppThemeData.medium),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: Platform.isAndroid ? 10 : 30, horizontal: 16),
                    child: const SizedBox(height: 12),
                  ),
                  // Login button with smooth animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (controller.emailEditingController.value.text
                              .trim()
                              .isEmpty) {
                            ShowToastDialog.showToast("Please enter valid email".tr);
                          } else if (controller.passwordEditingController.value.text
                              .trim()
                              .isEmpty) {
                            ShowToastDialog.showToast(
                                "Please enter valid password".tr);
                          } else {
                            controller.loginWithEmailAndPassword();
                          }
                        },
                        child: Container(
                          color: AppThemeData.driverApp300,
                          width: Responsive.width(100, context),
                          height: Responsive.width(16, context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              "Log in".tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey50,
                                fontSize: 16,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
