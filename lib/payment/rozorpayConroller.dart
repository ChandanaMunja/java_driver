import 'dart:convert';
import 'package:jippydriver_driver/models/payment_model/razorpay_model.dart';
import 'package:jippydriver_driver/payment/createRazorPayOrderModel.dart';
import 'package:jippydriver_driver/utils/play_integrity_utils.dart';
import 'package:http/http.dart' as http;

import '../constant/constant.dart';

class RazorPayController {
  Future<CreateRazorPayOrderModel?> createOrderRazorPay({required double amount, required RazorPayModel? razorpayModel}) async {
    print('💳 [RazorPay Controller] Creating Razorpay order for amount: $amount');
    
    print('💳 [RazorPay Controller] Verifying device integrity before creating order...');
    // Verify device integrity before creating order
    final isIntegrityVerified = await PlayIntegrityUtils.verifyBeforePayment();
    print('💳 [RazorPay Controller] Integrity verification result: $isIntegrityVerified');
    PlayIntegrityUtils.logIntegrityCheck('Razorpay Order Creation', isIntegrityVerified);
    
    if (!isIntegrityVerified) {
      print('💳 [RazorPay Controller] ❌ Order creation blocked due to integrity check failure');
      return null;
    }
    
    print('💳 [RazorPay Controller] ✅ Integrity check passed, proceeding with order creation...');
    
    final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    RazorPayModel razorPayData = razorpayModel!;
    print('💳 [RazorPay Controller] Razorpay Key: ${razorPayData.razorpayKey}');
    print('💳 [RazorPay Controller] Order ID: $orderId');
    
    const url = "${Constant.globalUrl}payments/razorpay/createorder";
    print('💳 [RazorPay Controller] API URL: $url');
    
    try {
      print('💳 [RazorPay Controller] Making API request to create order...');
    final response = await http.post(
      Uri.parse(url),
      body: {
        "amount": (amount.round() * 100).toString(),
        "receipt_id": orderId,
        "currency": "INR",
        "razorpaykey": razorPayData.razorpayKey,
        "razorPaySecret": razorPayData.razorpaySecret,
        "isSandBoxEnabled": razorPayData.isSandboxEnabled.toString(),
      },
    );

      print('💳 [RazorPay Controller] API Response Status: ${response.statusCode}');

    if (response.statusCode == 500) {
        print('💳 [RazorPay Controller] ❌ Server error (500) received');
      return null;
    } else {
      final data = jsonDecode(response.body);
        print('💳 [RazorPay Controller] ✅ Order created successfully');
        print('💳 [RazorPay Controller] Response data: $data');

      return CreateRazorPayOrderModel.fromJson(data);
      }
    } catch (e) {
      print('💳 [RazorPay Controller] ❌ Error creating order: $e');
      return null;
    }
  }
}
