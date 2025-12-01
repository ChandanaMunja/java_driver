import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/models/document_model.dart';
import 'package:jippydriver_driver/models/driver_document_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';

class DetailsUploadController extends GetxController {
  Rx<DocumentModel> documentModel = DocumentModel().obs;

  Rx<DateTime?> selectedDate = DateTime.now().obs;

  RxString frontImage = "".obs;
  RxString backImage = "".obs;

  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      documentModel.value = argumentData['documentModel'];
    }
    getDocument();
    update();
  }

  Rx<Documents> documents = Documents().obs;

  getDocument() async {
    isLoading.value = true;
    try {
      await FireStoreUtils.getDocumentOfDriver().then((value) {
        if (value != null && value.documents != null) {
          var contain = value.documents!
              .where((element) => element.documentId == documentModel.value.id);

          if (contain.isNotEmpty) {
            documents.value = value.documents!.firstWhere((itemToCheck) =>
            itemToCheck.documentId == documentModel.value.id);

            // Safe null checks instead of assertion operators
            if (documents.value.frontImage != null) {
              frontImage.value = documents.value.frontImage!;
            } else {
              frontImage.value = ""; // or some default value
            }

            if (documents.value.backImage != null) {
              backImage.value = documents.value.backImage!;
            } else {
              backImage.value = ""; // or some default value
            }
          } else {
            // Handle case where no matching document is found
            frontImage.value = "";
            backImage.value = "";
          }
        } else {
          // Handle case where value or value.documents is null
          frontImage.value = "";
          backImage.value = "";
        }
      });
    } catch (e) {
      print('Error in getDocument: $e');
      // Handle error appropriately
      frontImage.value = "";
      backImage.value = "";
    } finally {
      isLoading.value = false;
    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future pickFile({required ImageSource source, required String type}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();

      if (type == "front") {
        frontImage.value = image.path;
      } else {
        backImage.value = image.path;
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to Pick : \n $e");
    }
  }

  uploadDocument() async {
    String frontImageFileName = File(frontImage.value).path.split('/').last;
    String backImageFileName = File(backImage.value).path.split('/').last;

    if (frontImage.value.isNotEmpty &&
        Constant().hasValidUrl(frontImage.value) == false) {
      frontImage.value = await Constant.uploadUserImageToFireStorage(
          File(frontImage.value),
          "driverDocument/${FireStoreUtils.getCurrentUid()}",
          frontImageFileName);
    }

    if (backImage.value.isNotEmpty &&
        Constant().hasValidUrl(backImage.value) == false) {
      backImage.value = await Constant.uploadUserImageToFireStorage(
          File(backImage.value),
          "driverDocument/${FireStoreUtils.getCurrentUid()}",
          backImageFileName);
    }
    documents.value.frontImage = frontImage.value;
    documents.value.backImage = backImage.value;
    documents.value.documentId = documentModel.value.id;
    documents.value.status = "uploaded";
    await FireStoreUtils.uploadDriverDocument(documents.value).then((value) {
      if (value) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Document upload successfully".tr);

        Get.back(result: true);
      }
    });
  }
}
