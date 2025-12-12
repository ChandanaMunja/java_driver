import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  Rx<TextEditingController> emailEditingController =
      TextEditingController().obs;
  forgotPassword() async {
    try {
      ShowToastDialog.showLoader("Please wait".tr);
      final body = {
        "email": emailEditingController.value.text.trim(),
      };
      final response = await http.post(
        Uri.parse("${Constant.baseUrl}restaurant/forgot-password"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      ShowToastDialog.closeLoader();
      if (response.statusCode == 200) {
        ShowToastDialog.showToast(
          "Reset password link sent to ${emailEditingController.value.text}",
        );
        Get.back();
      } else {
        ShowToastDialog.showToast(
          "Failed: ${response.body}",
        );
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Something went wrong: $e");
    }
  }

  // forgotPassword() async {
  //   try {
  //     ShowToastDialog.showLoader("Please wait".tr);
  //     await FirebaseAuth.instance.sendPasswordResetEmail(
  //       email: emailEditingController.value.text,
  //     );
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast(
  //         '${'Reset Password link sent your'.tr} ${emailEditingController.value.text} ${'email'.tr}');
  //     Get.back();
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'user-not-found') {
  //       ShowToastDialog.showToast('No user found for that email.'.tr);
  //     }
  //   }
  // }
}
