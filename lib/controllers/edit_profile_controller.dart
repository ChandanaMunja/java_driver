import 'dart:io';

import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/zone_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;

  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  Rx<TextEditingController> countryCodeController =
      TextEditingController(text: "+91").obs;

  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _applyUserData(Constant.userModel);
    getData();
  }

  Future<void> getData() async {
    print("EditProfileController");
    try {
      final zones = await FireStoreUtils.getZone();
      if (zones != null) {
        zoneList.assignAll(zones);
      }

      String userId = await LoginController.getFirebaseId();
      if (userId.trim().isEmpty) {
        userId = Constant.userModel?.id?.toString() ?? '';
      }

      final profile = userId.trim().isEmpty
          ? null
          : await FireStoreUtils.getUserProfile(userId, forceRefresh: true);
      _applyUserData(profile ?? Constant.userModel);
      _syncSelectedZone();
    } finally {
      isLoading.value = false;
    }
  }

  void _applyUserData(UserModel? data) {
    if (data == null) return;
    userModel.value = data;
    firstNameController.value.text = data.firstName ?? '';
    lastNameController.value.text = data.lastName ?? '';
    emailController.value.text = data.email ?? '';
    phoneNumberController.value.text = data.phoneNumber ?? '';
    countryCodeController.value.text = data.countryCode ?? '+91';
    profileImage.value = data.profilePictureURL ?? '';
    _syncSelectedZone();
  }

  void _syncSelectedZone() {
    if (zoneList.isEmpty) return;
    final zoneId = userModel.value.zoneId;
    if (zoneId == null) return;
    for (final element in zoneList) {
      if (element.id == zoneId) {
        selectedZone.value = element;
        break;
      }
    }
  }

  saveData() async {
    ShowToastDialog.showLoader("Please wait...".tr);
    if (Constant().hasValidUrl(profileImage.value) == false &&
        profileImage.value.isNotEmpty) {
      profileImage.value = await Constant.uploadUserImageToFireStorage(
        File(profileImage.value),
        "profileImage/${FireStoreUtils.getCurrentUid()}",
        File(profileImage.value).path.split('/').last,
      );
    }

    userModel.value.firstName = firstNameController.value.text;
    userModel.value.lastName = lastNameController.value.text;
    userModel.value.profilePictureURL = profileImage.value;
    userModel.value.zoneId = selectedZone.value.id;

    await FireStoreUtils.updateUser(userModel.value).then((value) {
      ShowToastDialog.closeLoader();
      Get.back(result: true);
    });
  }

  final ImagePicker _imagePicker = ImagePicker();
  RxString profileImage = "".obs;

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      profileImage.value = image.path;
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }

  @override
  void onClose() {
    firstNameController.value.dispose();
    lastNameController.value.dispose();
    emailController.value.dispose();
    phoneNumberController.value.dispose();
    countryCodeController.value.dispose();
    super.onClose();
  }
}
