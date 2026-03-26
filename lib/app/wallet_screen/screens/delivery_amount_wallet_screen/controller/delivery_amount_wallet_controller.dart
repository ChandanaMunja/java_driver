// import 'dart:developer';
//
// import 'package:get/get.dart';
// import 'package:jippydriver_driver/app/wallet_screen/screens/model/delivery_amount_model.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/controllers/login_controller.dart';
// import 'package:jippydriver_driver/models/user_model.dart';
// import 'package:jippydriver_driver/models/withdraw_method_model.dart';
// import 'package:jippydriver_driver/models/withdrawal_model.dart';
// import 'package:jippydriver_driver/utils/fire_store_utils.dart';
//
// class DeliveryAmountWalletController extends GetxController {
//   RxBool isLoading = true.obs;
//   RxBool isLoadingMore = false.obs;
//   RxBool hasMore = false.obs;
//
//   RxInt currentPage = 1.obs;
//   RxInt lastPage = 1.obs;
//   final int perPage = 10;
//
//   RxInt selectedTabIndex = 0.obs;
//   RxList<String> dropdownValue = ["All", "Credit", "Debit"].obs;
//   RxString selectedDropDownValue = "All".obs;
//
//   RxDouble totalCodAmount = 0.0.obs;
//   Rx<UserModel> userModel = UserModel().obs;
//   Rx<WithdrawMethodModel> withdrawMethodModel = WithdrawMethodModel().obs;
//
//   RxList<DriverAmountWalletTransactionModel> walletTopTransactionList = <DriverAmountWalletTransactionModel>[].obs;
//   RxList<WithdrawalModel> withdrawalList = <WithdrawalModel>[].obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     getWalletTransaction();
//   }
//
//   List<DriverAmountWalletTransactionModel> get filteredTransactions {
//     if (selectedDropDownValue.value == "Credit") {
//       return walletTopTransactionList.where((e) => e.isCredit).toList();
//     }
//     if (selectedDropDownValue.value == "Debit") {
//       return walletTopTransactionList.where((e) => e.isDebit).toList();
//     }
//     return walletTopTransactionList;
//   }
//
//   Future<void> getWalletTransaction() async {
//     try {
//       isLoading.value = true;
//       await Future.wait([
//         _fetchCodTransactions(reset: true),
//         _fetchWithdrawals(),
//         _fetchProfileAndPaymentMethod(),
//       ]);
//     } catch (e, st) {
//       log("getWalletTransaction() failed: $e\n$st");
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   Future<void> loadMoreCodTransactions() async {
//     if (!hasMore.value || isLoadingMore.value) return;
//     await _fetchCodTransactions(page: currentPage.value + 1, reset: false);
//   }
//
//   Future<void> _fetchCodTransactions({int page = 1, bool reset = false}) async {
//     if (reset) {
//       walletTopTransactionList.clear();
//       currentPage.value = 1;
//       lastPage.value = 1;
//       hasMore.value = false;
//     }
//
//     isLoadingMore.value = !reset;
//     try {
//       final response = await FireStoreUtils.getDriverAmountWalletTransactionsPage(
//         page: page,
//         perPage: perPage,
//       );
//       if (response == null) return;
//
//       if (reset) {
//         walletTopTransactionList.assignAll(response.data);
//       } else {
//         walletTopTransactionList.addAll(response.data);
//       }
//
//       totalCodAmount.value = response.summary.totalCodAmount;
//       currentPage.value = response.pagination.currentPage;
//       lastPage.value = response.pagination.lastPage;
//       hasMore.value = response.pagination.hasMore;
//     } catch (e, st) {
//       log("_fetchCodTransactions() failed: $e\n$st");
//     } finally {
//       isLoadingMore.value = false;
//     }
//   }
//
//   Future<void> _fetchWithdrawals() async {
//     withdrawalList.value = await FireStoreUtils.getWithdrawHistory() ?? [];
//   }
//
//   Future<void> _fetchProfileAndPaymentMethod() async {
//     final firebaseId = await LoginController.getFirebaseId();
//     final profile = await FireStoreUtils.getUserProfile(firebaseId);
//     if (profile != null) {
//       userModel.value = profile;
//       Constant.userModel = profile;
//     }
//
//     final paymentData = await FireStoreUtils.getPaymentSettingsData();
//     if (paymentData != null && paymentData['withdrawMethod'] != null) {
//       withdrawMethodModel.value = WithdrawMethodModel.fromJson(paymentData['withdrawMethod']);
//     }
//   }
// }



import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/model/delivery_amount_model.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/withdraw_method_model.dart';
import 'package:jippydriver_driver/models/withdrawal_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';

/// How long cached data is considered fresh before a background re-fetch
/// is triggered on next view.
const Duration _kCacheTtl = Duration(minutes: 5);

class DeliveryAmountWalletController extends GetxController {
  // ─── Loading flags ──────────────────────────────────────────────────────────
  final RxBool isLoading = true.obs;
  final RxBool isFetchingMore = false.obs;

  // ─── Pagination ─────────────────────────────────────────────────────────────
  final RxBool hasMore = false.obs;
  int _currentPage = 1;
  static const int _perPage = 20;

  // ─── UI state ───────────────────────────────────────────────────────────────
  final RxInt selectedTabIndex = 0.obs;
  final RxList<String> filterOptions = ['All'].obs;
  final RxString selectedFilter = 'All'.obs;

  // ─── Data ───────────────────────────────────────────────────────────────────
  final RxDouble totalCodAmount = 0.0.obs;
  final Rx<UserModel> userModel = UserModel().obs;
  final Rx<WithdrawMethodModel> withdrawMethodModel = WithdrawMethodModel().obs;
  final RxList<DriverAmountWalletTransactionModel> transactions =
      <DriverAmountWalletTransactionModel>[].obs;
  final RxList<WithdrawalModel> withdrawalList = <WithdrawalModel>[].obs;

  // ─── Scroll controller (owned here, passed to view) ─────────────────────────
  final ScrollController earningsScrollController = ScrollController();
  final ScrollController withdrawalScrollController = ScrollController();

  // ─── Cache metadata ─────────────────────────────────────────────────────────
  DateTime? _lastFetchedAt;

  // ─── Computed ───────────────────────────────────────────────────────────────
  List<DriverAmountWalletTransactionModel> get filteredTransactions {
    switch (selectedFilter.value) {
      case 'Credit':
        return transactions.where((e) => e.isCredit).toList();
      case 'Debit':
        return transactions.where((e) => e.isDebit).toList();
      default:
        return transactions;
    }
  }

  bool get _isCacheValid =>
      _lastFetchedAt != null &&
          DateTime.now().difference(_lastFetchedAt!) < _kCacheTtl;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    earningsScrollController.addListener(_onEarningsScroll);
    _initialLoad();
  }

  @override
  void onClose() {
    earningsScrollController
      ..removeListener(_onEarningsScroll)
      ..dispose();
    withdrawalScrollController.dispose();
    super.onClose();
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Hard refresh — invalidates cache, clears list, fetches page 1.
  Future<void> refresh() async {
    _lastFetchedAt = null;
    await _initialLoad(forceRefresh: true);
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  Future<void> _initialLoad({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      // Run profile + payment load in parallel with transactions.
      await Future.wait([
        _fetchTransactions(reset: true, force: forceRefresh),
        _fetchWithdrawals(force: forceRefresh),
        _loadProfileAndPaymentMethod(),
      ]);
      _lastFetchedAt = DateTime.now();
    } catch (e, st) {
      log('DeliveryAmountWalletController._initialLoad error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  void _onEarningsScroll() {
    final pos = earningsScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 &&
        !isFetchingMore.value &&
        hasMore.value) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (isFetchingMore.value || !hasMore.value) return;
    isFetchingMore.value = true;
    await _fetchTransactions(reset: false, page: _currentPage + 1);
    isFetchingMore.value = false;
  }

  Future<void> _fetchTransactions({
    required bool reset,
    int page = 1,
    bool force = false,
  }) async {
    // Use cache if valid and not a forced reset.
    if (!reset && !force && _isCacheValid && transactions.isNotEmpty) return;

    if (reset) {
      _currentPage = 1;
      hasMore.value = false;
    }

    try {
      final response = await FireStoreUtils.getDriverAmountWalletTransactionsPage(
        page: page,
        perPage: _perPage,
      );
      if (response == null) return;

      if (reset) {
        transactions.assignAll(response.data);
      } else {
        transactions.addAll(response.data);
      }

      totalCodAmount.value = response.summary.totalCodAmount;
      _currentPage = response.pagination.currentPage;
      hasMore.value = response.pagination.hasMore;
    } catch (e, st) {
      log('_fetchTransactions error: $e\n$st');
    }
  }

  Future<void> _fetchWithdrawals({bool force = false}) async {
    if (!force && _isCacheValid && withdrawalList.isNotEmpty) return;
    try {
      final result = await FireStoreUtils.getWithdrawHistory();
      withdrawalList.assignAll(result ?? []);
    } catch (e, st) {
      log('_fetchWithdrawals error: $e\n$st');
    }
  }

  Future<void> _loadProfileAndPaymentMethod() async {
    try {
      final firebaseId = await LoginController.getFirebaseId();
      final profile = await FireStoreUtils.getUserProfile(firebaseId);
      if (profile != null) {
        userModel.value = profile;
        Constant.userModel = profile;
      }
      final paymentData = await FireStoreUtils.getPaymentSettingsData();
      if (paymentData?['withdrawMethod'] != null) {
        withdrawMethodModel.value =
            WithdrawMethodModel.fromJson(paymentData!['withdrawMethod']);
      }
    } catch (e, st) {
      log('_loadProfileAndPaymentMethod error: $e\n$st');
    }
  }
}