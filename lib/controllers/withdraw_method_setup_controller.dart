import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/payment_model/flutter_wave_model.dart';
import 'package:jippydriver_driver/models/payment_model/paypal_model.dart';
import 'package:jippydriver_driver/models/payment_model/razorpay_model.dart';
import 'package:jippydriver_driver/models/payment_model/stripe_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/withdraw_method_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';

class WithdrawMethodSetupController extends GetxController {
  Rx<TextEditingController> accountNumberFlutterWave = TextEditingController().obs;
  Rx<TextEditingController> bankCodeFlutterWave = TextEditingController().obs;
  Rx<TextEditingController> emailPaypal = TextEditingController().obs;
  Rx<TextEditingController> accountIdRazorPay = TextEditingController().obs;
  Rx<TextEditingController> accountIdStripe = TextEditingController().obs;

  Rx<UserBankDetails> userBankDetails = UserBankDetails().obs;
  Rx<WithdrawMethodModel> withdrawMethodModel = WithdrawMethodModel().obs;

  RxBool isBankDetailsAdded = false.obs;

  RxBool isLoading = true.obs;
  Rx<RazorPayModel> razorPayModel = RazorPayModel().obs;
  Rx<PayPalModel> paypalDataModel = PayPalModel().obs;
  Rx<StripeModel> stripeSettingData = StripeModel().obs;
  Rx<FlutterWaveModel> flutterWaveSettingData = FlutterWaveModel().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getPaymentMethod();
    getPaymentSettings();
    super.onInit();
  }

  getPaymentMethod() async {
    isLoading.value = true;
    accountNumberFlutterWave.value.clear();
    bankCodeFlutterWave.value.clear();
    emailPaypal.value.clear();
    accountIdRazorPay.value.clear();
    accountIdStripe.value.clear();

    await FireStoreUtils.getWithdrawMethod().then(
      (value) {
        if (value != null) {
          withdrawMethodModel.value = value;

          if (withdrawMethodModel.value.flutterWave != null) {
            accountNumberFlutterWave.value.text = withdrawMethodModel.value.flutterWave!.accountNumber.toString();
            bankCodeFlutterWave.value.text = withdrawMethodModel.value.flutterWave!.bankCode.toString();
          }

          if (withdrawMethodModel.value.paypal != null) {
            emailPaypal.value.text = withdrawMethodModel.value.paypal!.email.toString();
          }

          if (withdrawMethodModel.value.razorpay != null) {
            accountIdRazorPay.value.text = withdrawMethodModel.value.razorpay!.accountId.toString();
          }
          if (withdrawMethodModel.value.stripe != null) {
            accountIdStripe.value.text = withdrawMethodModel.value.stripe!.accountId.toString();
          }
        }
      },
    );
    isLoading.value = false;
  }


  getPaymentSettings() async {
    try {
      // 1. Set user bank details if available
      if (Constant.userModel!.userBankDetails != null) {
        userBankDetails.value = Constant.userModel!.userBankDetails!;
        isBankDetailsAdded.value = userBankDetails.value.accountNumber.isNotEmpty;
      }

      // 2. Make API call
      final response = await http.get(Uri.parse("${Constant.baseUrl}settings/payment"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];

          // Parse each payment method
          razorPayModel.value = RazorPayModel.fromJson(data['razorpaySettings'] ?? {});
          paypalDataModel.value = PayPalModel.fromJson(data['paypalSettings'] ?? {});
          stripeSettingData.value = StripeModel.fromJson(data['stripeSettings'] ?? {});
          flutterWaveSettingData.value = FlutterWaveModel.fromJson(data['flutterWave'] ?? {});

          // You can also parse other payment methods as needed
          // e.g. midtransSettings, payStack, xenditSettings, etc.
        }
      } else {
        debugPrint('Failed to load payment settings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching payment settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

}
