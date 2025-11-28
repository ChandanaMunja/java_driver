import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';

class BankDetailsController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> bankNameController = TextEditingController().obs;
  Rx<TextEditingController> branchNameController = TextEditingController().obs;
  Rx<TextEditingController> holderNameController = TextEditingController().obs;
  Rx<TextEditingController> accountNoController = TextEditingController().obs;
  Rx<TextEditingController> otherInfoController = TextEditingController().obs;

  Rx<UserModel> userModel = UserModel().obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getCurrentUser();
    super.onInit();
  }

  saveBank() async {
    ShowToastDialog.showLoader("Please wait".tr);
    userModel.value.userBankDetails ??= UserBankDetails();
    userModel.value.userBankDetails!.accountNumber =
        accountNoController.value.text;
    userModel.value.userBankDetails!.bankName = bankNameController.value.text;
    userModel.value.userBankDetails!.branchName =
        branchNameController.value.text;
    userModel.value.userBankDetails!.holderName =
        holderNameController.value.text;
    userModel.value.userBankDetails!.otherDetails =
        otherInfoController.value.text;

    await FireStoreUtils.updateUser(userModel.value).then(
      (value) {
        ShowToastDialog.closeLoader();
        Get.back();
      },
    );
  }

  getCurrentUser() async {
    String? userId = await LoginController.getFirebaseId();
    await FireStoreUtils.getUserProfile(userId).then(
      (value) {
        if (value != null) {
          userModel.value = value;
          if (userModel.value.userBankDetails != null) {
            bankNameController.value.text =
                userModel.value.userBankDetails!.bankName.toString();
            branchNameController.value.text =
                userModel.value.userBankDetails!.branchName.toString();
            holderNameController.value.text =
                userModel.value.userBankDetails!.holderName.toString();
            accountNoController.value.text =
                userModel.value.userBankDetails!.accountNumber.toString();
            otherInfoController.value.text =
                userModel.value.userBankDetails!.otherDetails.toString();
          }
        }
      },
    );
    isLoading.value = false;
  }
}
