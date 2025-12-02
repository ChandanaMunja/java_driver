import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/app/wallet_screen/screens/model/delivery_amount_model.dart';
import 'package:jippydriver_driver/constant/collection_name.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';

import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';
import 'package:jippydriver_driver/models/withdraw_method_model.dart';
import 'package:jippydriver_driver/models/withdrawal_model.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';

class DeliveryAmountWalletController extends GetxController {
  RxBool isLoading = true.obs;



  Rx<UserModel> userModel = UserModel().obs;
  RxList<DriverAmountWalletTransactionModel> walletTopTransactionList =
      <DriverAmountWalletTransactionModel>[].obs;
  RxList<WithdrawalModel> withdrawalList = <WithdrawalModel>[].obs;

  RxList<DriverAmountWalletTransactionModel> dailyEarningList = <DriverAmountWalletTransactionModel>[].obs;
  RxList<DriverAmountWalletTransactionModel> monthlyEarningList = <DriverAmountWalletTransactionModel>[].obs;
  RxList<DriverAmountWalletTransactionModel> yearlyEarningList = <DriverAmountWalletTransactionModel>[].obs;

  RxList<String> dropdownValue = ["Daily", "Monthly", "Yearly"].obs;
  RxString selectedDropDownValue = "Daily".obs;

  RxInt selectedTabIndex = 0.obs;
  RxInt selectedValue = 0.obs;

  Rx<WithdrawMethodModel> withdrawMethodModel = WithdrawMethodModel().obs;

  @override
  void onInit() {
    getWalletTransaction();
    super.onInit();
  }
  @override
  void onClose() {
    AppLogger.log('WalletController onClose() called', tag: 'Controller');
    super.onClose();
  }


  // getWalletTransaction() async {
  //   try {
  //     isLoading.value = true;
  //     dailyEarningList.clear();
  //     monthlyEarningList.clear();
  //     yearlyEarningList.clear();
  //     String? userId = await LoginController.getFirebaseId();
  //     if (Constant.userModel == null || Constant.userModel!.id == null) {
  //       Constant.userModel = await FireStoreUtils.getUserProfile(userId);
  //     }
  //     final driverId = Constant.userModel!.id.toString();
  //     DateTime nowDate = DateTime.now();
  //     // Top transactions & withdrawals
  //     walletTopTransactionList.value =
  //         await FireStoreUtils.getDriverAmountWalletTransaction() ?? [];
  //     withdrawalList.value =
  //         await FireStoreUtils.getWithdrawHistory() ?? [];
  //     // === DAILY ===
  //     DateTime todayStart = DateTime(nowDate.year, nowDate.month, nowDate.day);
  //     DateTime tomorrowStart = todayStart.add(const Duration(days: 1));
  //     var dailySnap = await FireStoreUtils.fireStore
  //         .collection(CollectionName.deliveryWalletRecord)
  //         .where('driverId', isEqualTo: driverId)
  //         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
  //         .where('date', isLessThan: Timestamp.fromDate(tomorrowStart))
  //         .orderBy('date', descending: true)
  //         .get();
  //     for (var doc in dailySnap.docs) {
  //       dailyEarningList.add(DriverAmountWalletTransactionModel.fromJson(doc.data()));
  //     }
  //     // === MONTHLY ===
  //     DateTime monthStart = DateTime(nowDate.year, nowDate.month, 1);
  //     DateTime monthEnd = (nowDate.month == 12)
  //         ? DateTime(nowDate.year + 1, 1, 1)
  //         : DateTime(nowDate.year, nowDate.month + 1, 1);
  //     var monthSnap = await FireStoreUtils.fireStore
  //         .collection(CollectionName.deliveryWalletRecord)
  //         .where('driverId', isEqualTo: driverId)
  //         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
  //         .where('date', isLessThan: Timestamp.fromDate(monthEnd))
  //         .orderBy('date', descending: true)
  //         .get();
  //     for (var doc in monthSnap.docs) {
  //       monthlyEarningList.add(DriverAmountWalletTransactionModel.fromJson(doc.data()));
  //     }
  //
  //     // === YEARLY ===
  //     DateTime yearStart = DateTime(nowDate.year, 1, 1);
  //     DateTime yearEnd = DateTime(nowDate.year + 1, 1, 1);
  //     var yearSnap = await FireStoreUtils.fireStore
  //         .collection(CollectionName.deliveryWalletRecord)
  //         .where('driverId', isEqualTo: driverId)
  //         .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
  //         .where('date', isLessThan: Timestamp.fromDate(yearEnd))
  //         .orderBy('date', descending: true)
  //         .get();
  //     for (var doc in yearSnap.docs) {
  //       yearlyEarningList.add(DriverAmountWalletTransactionModel.fromJson(doc.data()));
  //     }
  //     // === USER PROFILE ===
  //     userModel.value =
  //         await FireStoreUtils.getUserProfile(userId) ??
  //             UserModel();
  //   } catch (e, st) {
  //     log("getWalletTransaction() failed: $e\n$st");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  getWalletTransaction() async {
    try {
      isLoading.value = true;

      dailyEarningList.clear();
      monthlyEarningList.clear();
      yearlyEarningList.clear();

      String? firebaseId = await LoginController.getFirebaseId();

      // Fetch user profile & wallet transactions from API
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver/wallet-transactions'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"driver_id": firebaseId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // === USER PROFILE ===
          Constant.userModel = UserModel.fromJson(data['user']);
          userModel.value = Constant.userModel!;

          // === DAILY EARNINGS ===
          dailyEarningList.value = (data['dailyEarnings'] as List<dynamic>)
              .map((e) => DriverAmountWalletTransactionModel.fromJson(e))
              .toList();

          // === MONTHLY EARNINGS ===
          monthlyEarningList.value = (data['monthlyEarnings'] as List<dynamic>)
              .map((e) => DriverAmountWalletTransactionModel.fromJson(e))
              .toList();

          // === YEARLY EARNINGS ===
          yearlyEarningList.value = (data['yearlyEarnings'] as List<dynamic>)
              .map((e) => DriverAmountWalletTransactionModel.fromJson(e))
              .toList();

          // === TOP TRANSACTIONS ===
          walletTopTransactionList.value = (data['topTransactions'] as List<dynamic>)
              .map((e) => DriverAmountWalletTransactionModel.fromJson(e))
              .toList();
          // === WITHDRAWALS ===
          withdrawalList.value = await FireStoreUtils.getWithdrawHistory() ?? [];
              userModel.value =
                  await FireStoreUtils.getUserProfile(firebaseId) ??
                      UserModel();
        } else {
          log("getWalletTransaction() failed: API returned success=false");
        }
      } else {
        log("getWalletTransaction() failed: HTTP ${response.statusCode}");
      }
    } catch (e, st) {
      log("getWalletTransaction() failed: $e\n$st");
    } finally {
      isLoading.value = false;
    }
  }




}
