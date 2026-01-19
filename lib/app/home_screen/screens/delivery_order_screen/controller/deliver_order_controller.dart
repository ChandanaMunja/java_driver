import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/app/home_screen/controller/home_controller.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/send_notification.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/app/wallet_screen/controller/wallet_controller.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/wallet_transaction_model.dart';
import 'package:jippydriver_driver/services/audio_player_service.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliverOrderController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool conformPickup = false.obs;
  RxBool isCompletingOrder = false.obs; // Guard to prevent duplicate calls


  void confirmPickupFunction(){
    print("${conformPickup.value} conformPickup " );
 if(   conformPickup.value
 ){
  conformPickup.value =false;
  }else{
  conformPickup.value =true;
  }
  }

  @override
  void onInit() {
    AppLogger.log('DeliverOrderController onInit() called', tag: 'Controller');
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  @override
  void onClose() {
    AppLogger.log('DeliverOrderController onClose() called', tag: 'Controller');
    super.onClose();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  RxInt totalQuantity = 0.obs;

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
      for (var element in orderModel.value.products!) {
        totalQuantity.value += (element.quantity ?? 0);
      }
    }
    isLoading.value = false;
  }


  Future<int> getTodayCompletedOrdersCount() async {
    int todayCount = 0;
    try {
      // 确保用户已登录
      if (Constant.userModel == null || Constant.userModel!.id == null) {
        log("User not logged in");
        return 0;
      }
      final driverID = Constant.userModel!.id.toString();
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}orders/completed/today/$driverID'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          todayCount = data['count'] ?? 0;
        } else {
          log("API returned error: ${data['message'] ?? 'Unknown error'}");
        }
      } else {
        log("API request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      log("Error getting today's completed orders: $e");
    }
    return todayCount;
  }


  Future<Map<String, dynamic>?> getZoneBonusByZoneId(String zoneId) async {
    try {
      final response = await http.post(
        Uri.parse("${Constant.baseUrl}zone/bonus/byZoneId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"zone_id": zoneId}),
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);

        if (res['success'] == true && res['data'] != null) {
          return res['data'];
        } else {
          print("No bonus found for zone id: $zoneId");
          return null;
        }
      } else {
        print("API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching zone bonus: $e");
      return null;
    }
  }



  WalletController walletController =
  Get.put(WalletController());
  // HomeController homeController =
  // Get.put(HomeController());
  void deliveryAmountBonusAmount()async{
    try{
      print("totalCalculatedCharge and zone id ${Constant.userModel?.zoneId.toString()} ");
      int orderCount = await getTodayCompletedOrdersCount();
      // UserModel? userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      Map<String, dynamic>? docData = await getZoneBonusByZoneId(Constant.userModel?.zoneId??'');
      OrderModel? orderModelNew = await FireStoreUtils.getOrderById(
          orderModel.value.id??"");
      // await FireStoreUtils.getOrderById(
      //     homeController.currentOrder.value.id!);
      double totalCalculatedCharge = double.tryParse(
          orderModelNew?.calculatedCharges?['totalCalculatedCharge']?.toString() ?? '0'
      ) ?? 0.0;
      print("totalCalculatedCharge order Count  $orderCount");
      print("totalCalculatedCharge and zone id ${Constant.userModel?.zoneId.toString()} $totalCalculatedCharge");
      print("totalCalculatedCharge currentOrder Value id ${orderModel.value.id} ${orderModelNew?.calculatedCharges?['totalCalculatedCharge']}");
      if(docData!=null){
        int requiredOrdersForBonus = int.tryParse(docData['requiredOrdersForBonus'].toString()) ?? 0;
        int bonusAmount = int.tryParse(docData['bonusAmount'].toString()) ?? 0;
        if(orderCount==requiredOrdersForBonus ){
        //   if(orderCount>1 ){
          final totalAmount = totalCalculatedCharge + bonusAmount;
          walletController.driverRecordAmountController.value.text = totalAmount.toStringAsFixed(2);
          walletController.addWalletBonusSave(bonus:true, zoneId: Constant.userModel?.zoneId??'',bonusAmount: bonusAmount,orderModel: orderModel.value,
          );
          Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("🎉 Congratulations!"),
              content: Text("You’ve received a bonus of ₹$bonusAmount for completing $requiredOrdersForBonus orders today!"),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
          print("Bonus given: $bonusAmount");
          print("bonusAmount ${bonusAmount}");
          print("bonusAmount ${requiredOrdersForBonus}");
        }
        else{
          print("totalCalculatedCharge  1 $totalCalculatedCharge");
          walletController.driverRecordAmountController.value.text = totalCalculatedCharge.toString();
          walletController.addWalletBonusSave(bonus:false, zoneId: Constant.userModel?.zoneId??'',orderModel: orderModel.value
          );
        }
      }else{
        print("totalCalculatedCharge  2 $totalCalculatedCharge");
        walletController.driverRecordAmountController.value.text = totalCalculatedCharge.toString();
        walletController.addWalletBonusSave(bonus:false, zoneId: Constant.userModel?.zoneId??'',orderModel: orderModel.value
        );
      }}catch(e){
      print("totalCalculatedCharge deliveryAmountBonusAmount ${e.toString()} ");
    }
  }

  Future<double?> fetchToPay(String orderId) async {
    final url = Uri.parse('${Constant.baseUrl}mobile/orders/$orderId/billing/to-pay');
    print("[ToPay] Fetching ToPay for order: $orderId");

    try {
      final response = await http.get(url).timeout(Duration(seconds: 10));

      // Check if response is successful
      if (response.statusCode == 200) {
        // Check if response body is valid JSON (not HTML)
        final responseBody = response.body.trim();
        if (responseBody.startsWith('<!') || responseBody.startsWith('<html')) {
          print("[ToPay] ❌ API returned HTML instead of JSON. Status: ${response.statusCode}");
          return null;
        }

        try {
          final Map<String, dynamic> jsonResponse = json.decode(responseBody);
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            if (jsonResponse['data']['found'] == true) {
              final toPay = (jsonResponse['data']['to_pay'] as num).toDouble();
              print("[ToPay] ✅ Successfully fetched ToPay: $toPay");
              return toPay;
            } else {
              print("[ToPay] ⚠️ Order billing not found (found: false)");
              return null;
            }
          } else {
            print("[ToPay] ⚠️ API returned success: false");
            return null;
          }
        } catch (jsonError) {
          print("[ToPay] ❌ Error parsing ToPay JSON: $jsonError");
          print("[ToPay] Response body: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}");
          return null;
        }
      } else {
        print("[ToPay] ❌ API returned status ${response.statusCode}");
        print("[ToPay] Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}");
      }

      return null;
    } catch (e) {
      print("[ToPay] ❌ Error fetching ToPay: $e");
      return null;
    }
  }
  final controller = Get.find<HomeController>();
  completedOrder() async {
    // Prevent duplicate calls
    if (isCompletingOrder.value) {
      print("[DeliverOrderController] Order completion already in progress, ignoring duplicate call");
      return;
    }
    isCompletingOrder.value = true;
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      // Extract totalCalculatedCharge from calculatedCharges
      // Try orderModel first (from arguments), then controller.currentOrder, then controller's observable
      dynamic chargeValue = orderModel.value.calculatedCharges?['totalCalculatedCharge'] ??
                           controller.currentOrder.value.calculatedCharges?['totalCalculatedCharge'];
      num? parsedCharge;
      if (chargeValue == null) {
        // If calculatedCharges doesn't exist, try to use HomeController's totalCalculatedCharge
        parsedCharge = controller.totalCalculatedCharge.value;
        print("[DeliverOrderController] calculatedCharges not found, using HomeController totalCalculatedCharge: $parsedCharge");
      } else if (chargeValue is num) {
        parsedCharge = chargeValue;
      } else {
        // Try parsing as string
        parsedCharge = num.tryParse(chargeValue.toString());
      }
      print("[DeliverOrderController] Set orderModel.deliveryCharge: ${orderModel.value.deliveryCharge}  ${orderModel.value.toPay} ");
      print("[DeliverOrderController] Playing sound");
      await AudioPlayerService.playSound(false);
      print("[DeliverOrderController] Setting status to completed");
      orderModel.value.status = Constant.orderCompleted;
      // Ensure driverID is set
      if (orderModel.value.driverID == null) {
        orderModel.value.driverID = Constant.userModel?.id;
        print("[DeliverOrderController] driverID was null, set to: ${orderModel.value.driverID}");
      }
      print("driverID:   ${orderModel.value.driverID}");
      print("paymentMethod: ${orderModel.value.paymentMethod}");
      print("deliveryCharge: ${orderModel.value.deliveryCharge}");
      print("tipAmount: ${orderModel.value.tipAmount}");
      if (orderModel.value.driverID == null ||
          orderModel.value.paymentMethod == null ||
          orderModel.value.deliveryCharge == null ||
          orderModel.value.tipAmount == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Order data is incomplete. Cannot complete order.");
        return;
      }
      print("[DeliverOrderController] Updating wallet amount");
      try {
        // Try to fetch toPay from API, but fallback to order model value if available
        double? toPay = await fetchToPay(orderModel.value.id ?? '0');
        // If API fetch failed, try to use existing toPay value from order model
        if (toPay == null && orderModel.value.toPay != null && orderModel.value.toPay!.isNotEmpty) {
          try {
            toPay = double.tryParse(orderModel.value.toPay!);
            print('[DeliverOrderController] Using existing ToPay from order model: $toPay');
          } catch (e) {
            print('[DeliverOrderController] Failed to parse existing ToPay: ${orderModel.value.toPay}');
          }
        }
        
        if (toPay == null) {
          print('[DeliverOrderController][ERROR] ToPay is null in order_Billing for order: ${orderModel.value.id}');
          print('[DeliverOrderController] Order model toPay value: ${orderModel.value.toPay}');
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Order billing info missing. Cannot complete order.");
          return;
        }
        orderModel.value.toPay = toPay.toString();
        print('[DeliverOrderController] Set ToPay: ${orderModel.value.toPay}');
      } catch (e) {
        print('[DeliverOrderController][ERROR] Failed to fetch ToPay from order_Billing: $e');
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to fetch billing info. Cannot complete order.");
        return;
      }
      // Update wallet and delivery amount via separate APIs first
      await FireStoreUtils.updateWallateAmount(orderModel.value);
      print("[DeliverOrderController] Setting order in Firestore");
      await FireStoreUtils.setOrder(orderModel.value);
      deliveryAmountBonusAmount();
      // Remove order from other drivers' orderRequestData
      await FireStoreUtils.removeOrderFromOtherDrivers(
        orderId: orderModel.value.id??'',
        assignedDriverId: orderModel.value.driverID!,
      );
      // IMPORTANT: Fetch latest user data from API AFTER wallet/delivery amount updates
      // This ensures we have the correct accumulated values from the separate APIs
      // Use updateUserWithoutWalletDelivery to avoid sending wallet/delivery amounts
      // which are managed by separate APIs (driver-sql/wallet/update and driver-sql/delivery-amount/update)
      print("[DeliverOrderController] Fetching latest user data after wallet/delivery updates");
      UserModel? latestUserData = await FireStoreUtils.getUserProfile(Constant.userModel?.id ?? '');
      if (latestUserData != null) {
        // Update only the order lists
        if (latestUserData.vendorID?.isNotEmpty == true) {
          print("[DeliverOrderController] Removing order from user lists");
          latestUserData.orderRequestData?.remove(orderModel.value.id);
          latestUserData.inProgressOrderID?.remove(orderModel.value.id);
        }
        // IMPORTANT: Use updateUserWithoutWalletDelivery to exclude wallet/delivery amounts
        // The actual wallet and delivery amount updates are handled by separate APIs:
        // - driver-sql/wallet/update (called in updateWallateAmount) - handles walletAmount
        // - driver-sql/delivery-amount/update (called in updateWallateAmount) - handles deliveryAmount
        // By excluding these fields from users/update, we prevent overwriting the correct accumulated values
        print("[DeliverOrderController] Updating user without wallet/delivery amounts");
        await FireStoreUtils.updateUserWithoutWalletDelivery(latestUserData);
        // Refresh user data to get the correct wallet/delivery amounts from database
        UserModel? refreshedUser = await FireStoreUtils.getUserProfile(Constant.userModel?.id ?? '');
        if (refreshedUser != null) {
          Constant.userModel = refreshedUser;
          print("[DeliverOrderController] Refreshed user data - walletAmount: ${refreshedUser.walletAmount}, deliveryAmount: ${refreshedUser.deliveryAmount}");
        }
      } else {
        // Fallback: Update user lists in Constant.userModel if API fetch failed
        if (Constant.userModel?.vendorID?.isNotEmpty == true) {
          print("[DeliverOrderController] Removing order from user lists (fallback)");
          Constant.userModel?.orderRequestData?.remove(orderModel.value.id);
          Constant.userModel?.inProgressOrderID?.remove(orderModel.value.id);
        }
        // Use updateUserWithoutWalletDelivery to exclude wallet/delivery amounts
        await FireStoreUtils.updateUserWithoutWalletDelivery(Constant.userModel!);
      }
      print("[DeliverOrderController] Checking if first order");
      await FireStoreUtils.getFirestOrderOrNOt(orderModel.value)
          .then((value) async {
        if (value == true) {
          print("[DeliverOrderController] Updating referral amount");
          await FireStoreUtils.updateReferralAmount(orderModel.value);
        }
      });
      print("[DeliverOrderController] Sending notification to customer");
      if (orderModel.value.author?.fcmToken != null) {
        await SendNotification.sendFcmMessage(
          Constant.driverCompleted,
          orderModel.value.author?.fcmToken.toString() ??'',
          {},
        );
      }
      ShowToastDialog.closeLoader();
      print("[DeliverOrderController] Order completed, closing loader and going back");
      isCompletingOrder.value = false;
      Get.back(result: true);
    } catch (e) {
      print("[DeliverOrderController] Error in completedOrder: $e");
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to complete order");
      isCompletingOrder.value = false; // Reset flag on error
    }
  }
  // completedOrder() async {
  //   ShowToastDialog.showLoader("Please wait".tr);
  //   await AudioPlayerService.playSound(false);
  //   orderModel.value.status = Constant.orderCompleted;
  //   await FireStoreUtils.updateWallateAmount(orderModel.value);
  //   await FireStoreUtils.setOrder(orderModel.value);
  //   if (Constant.userModel?.vendorID?.isNotEmpty == true) {
  //     Constant.userModel?.orderRequestData?.remove(orderModel.value.id);
  //     Constant.userModel?.inProgressOrderID?.remove(orderModel.value.id);
  //     await FireStoreUtils.updateUser(Constant.userModel!);
  //   }
  //   await FireStoreUtils.getFirestOrderOrNOt(orderModel.value)
  //       .then((value) async {
  //     if (value == true) {
  //       await FireStoreUtils.updateReferralAmount(orderModel.value);
  //     }
  //   });
  //
  //   await SendNotification.sendFcmMessage(Constant.driverCompleted,
  //       orderModel.value.author!.fcmToken.toString(), {});
  //   ShowToastDialog.closeLoader();
  //   Get.back(result: true);
  // }
}
