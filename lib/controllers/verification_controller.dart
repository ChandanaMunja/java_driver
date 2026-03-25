import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/document_model.dart';
import 'package:jippydriver_driver/models/driver_document_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';

class VerificationController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isSubmittingIdentity = false.obs;
  final TextEditingController aadhaarNumberController =
      TextEditingController();
  final TextEditingController drivingLicenseController =
      TextEditingController();

  @override
  void onInit() {
    // TODO: implement onInit
    getDocument();
    super.onInit();
  }

  @override
  void onClose() {
    aadhaarNumberController.dispose();
    drivingLicenseController.dispose();
    super.onClose();
  }

  RxList<DocumentModel> documentList = <DocumentModel>[].obs;
  RxList<Documents> driverDocumentList = <Documents>[].obs;

  getDocument() async {
    isLoading.value = true;
    update();

    try {
      await FireStoreUtils.getDocumentList().then((value) {
        documentList.value = value;
      });

      await FireStoreUtils.getDocumentOfDriver().then((value) {
        if(value != null && value.documents != null){
          driverDocumentList.value = value.documents!;
          aadhaarNumberController.text = value.aadharNo ?? '';
          drivingLicenseController.text =
              value.drivingLicenseNumber ?? '';
        } else {
          driverDocumentList.value = []; // or handle empty case
        }
      });
    } catch (e) {
      print('Error in getDocument: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> submitIdentityDetails() async {
    final aadhaar = aadhaarNumberController.text.trim();
    final drivingLicense = drivingLicenseController.text.trim();

    if (aadhaar.isEmpty) {
      ShowToastDialog.showToast("Aadhaar number is required");
      return false;
    }
    if (drivingLicense.isEmpty) {
      ShowToastDialog.showToast("Driving license number is required");
      return false;
    }

    isSubmittingIdentity.value = true;
    update();
    try {
      final userId = await LoginController.getFirebaseId();
      final response = await http.post(
        Uri.parse("${Constant.baseUrl}documents/driver/identity"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "user_id": userId,
          "aadhaar_number": aadhaar,
          "driving_license_number": drivingLicense,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
    } catch (e) {
      debugPrint("submitIdentityDetails error: $e");
    } finally {
      isSubmittingIdentity.value = false;
      update();
    }
    return false;
  }
}
