import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/document_model.dart';
import 'package:jippydriver_driver/models/driver_document_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:path_provider/path_provider.dart';

class DetailsUploadController extends GetxController {
  Rx<DocumentModel> documentModel = DocumentModel().obs;
  RxString frontImage = "".obs;
  RxString backImage = "".obs;
  RxBool isLoading = true.obs;
  Rx<Documents> documents = Documents().obs;

  final ImagePicker imagePicker = ImagePicker();

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  getArgument() async {
    if (Get.arguments != null) {
      documentModel.value = Get.arguments["documentModel"];
    }
    getDocument();
  }

  /// fetch previously saved images (URL)
  getDocument() async {
    isLoading(true);
    try {
      var value = await FireStoreUtils.getDocumentOfDriver();
      if (value != null && value.documents != null) {
        var matched = value.documents!.where((e) => e.documentId == documentModel.value.id);
        if (matched.isNotEmpty) {
          documents.value = matched.first;
          frontImage.value = documents.value.frontImage ?? "";
          backImage.value = documents.value.backImage ?? "";
        }
      }
    } catch (_) {}
    isLoading(false);
  }

  /// Pick Image
  pickFile({required ImageSource source, required String type}) async {
    XFile? img = await imagePicker.pickImage(source: source);
    if (img == null) return;
    Get.back();

    if (type == "front") frontImage(img.path);
    else backImage(img.path);
  }

  /// ========== FINAL UPLOAD FUNCTION (NO FIREBASE) ==========
  uploadDocument() async {
    try {
      if (frontImage.value.isEmpty && backImage.value.isEmpty) {
        ShowToastDialog.showToast("Please select images first");
        return;
      }

      ShowToastDialog.showLoader("Uploading...");

      String front = await _getLocalImage(frontImage.value);
      String back = await _getLocalImage(backImage.value);

      documents.value.frontImage = front;
      documents.value.backImage = back;
      documents.value.documentId = documentModel.value.id;
      documents.value.status = "uploaded";

      bool success = await uploadDriverDocument(documents.value);
      ShowToastDialog.closeLoader();

      if (success) {
        ShowToastDialog.showToast("Uploaded Successfully");
        Get.back(result: true);
      } else {
        ShowToastDialog.showToast("Upload Failed");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: $e");
    }
  }

  /// ========== MULTIPART REQUEST UPLOAD ==========
  static Future<bool> uploadDriverDocument(Documents doc) async {
    var uid = await LoginController.getFirebaseId();
    if (uid == null) return false;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("${Constant.baseUrl}documents/driver/upload"),
    );

    request.fields.addAll({
      "user_id": uid,
      "documentId": doc.documentId ?? "",
      "type": "driver",
      "status": doc.status ?? "uploaded",
    });

    if (doc.frontImage != null && File(doc.frontImage!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath("front_image", doc.frontImage!));
    }
    if (doc.backImage != null && File(doc.backImage!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath("back_image", doc.backImage!));
    }

    var res = await request.send();
    var resp = await res.stream.bytesToString();

    print("STATUS : ${res.statusCode}");
    print("RESPONSE: $resp");

    if (res.statusCode == 200) {
      return json.decode(resp)["success"] == true;
    }
    return false;
  }

  /// If url → download to local, else return original
  Future<String> _getLocalImage(String path) async {
    if (!path.startsWith("http")) return path;

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg");

    final r = await http.get(Uri.parse(path));
    await file.writeAsBytes(r.bodyBytes);
    return file.path;
  }
}


// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
//
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
// import 'package:jippydriver_driver/controllers/login_controller.dart';
// import 'package:jippydriver_driver/models/document_model.dart';
// import 'package:jippydriver_driver/models/driver_document_model.dart';
// import 'package:jippydriver_driver/utils/fire_store_utils.dart';
// import 'package:path_provider/path_provider.dart';
//
// class DetailsUploadController extends GetxController {
//   Rx<DocumentModel> documentModel = DocumentModel().obs;
//
//   Rx<DateTime?> selectedDate = DateTime.now().obs;
//
//   RxString frontImage = "".obs;
//   RxString backImage = "".obs;
//
//   RxBool isLoading = true.obs;
//
//   @override
//   void onInit() {
//     // TODO: implement onInit
//     getArgument();
//     super.onInit();
//   }
//
//   getArgument() async {
//     dynamic argumentData = Get.arguments;
//     if (argumentData != null) {
//       documentModel.value = argumentData['documentModel'];
//     }
//     getDocument();
//     update();
//   }
//
//   Rx<Documents> documents = Documents().obs;
//
//   getDocument() async {
//     isLoading.value = true;
//     try {
//       await FireStoreUtils.getDocumentOfDriver().then((value) {
//         if (value != null && value.documents != null) {
//           var contain = value.documents!
//               .where((element) => element.documentId == documentModel.value.id);
//
//           if (contain.isNotEmpty) {
//             documents.value = value.documents!.firstWhere((itemToCheck) =>
//             itemToCheck.documentId == documentModel.value.id);
//
//             // Safe null checks instead of assertion operators
//             if (documents.value.frontImage != null) {
//               frontImage.value = documents.value.frontImage!;
//             } else {
//               frontImage.value = ""; // or some default value
//             }
//
//             if (documents.value.backImage != null) {
//               backImage.value = documents.value.backImage!;
//             } else {
//               backImage.value = ""; // or some default value
//             }
//           } else {
//             // Handle case where no matching document is found
//             frontImage.value = "";
//             backImage.value = "";
//           }
//         } else {
//           // Handle case where value or value.documents is null
//           frontImage.value = "";
//           backImage.value = "";
//         }
//       });
//     } catch (e) {
//       print('Error in getDocument: $e');
//       // Handle error appropriately
//       frontImage.value = "";
//       backImage.value = "";
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   final ImagePicker _imagePicker = ImagePicker();
//
//   Future pickFile({required ImageSource source, required String type}) async {
//     try {
//       XFile? image = await _imagePicker.pickImage(source: source);
//       if (image == null) return;
//       Get.back();
//
//       if (type == "front") {
//         frontImage.value = image.path;
//       } else {
//         backImage.value = image.path;
//       }
//     } on PlatformException catch (e) {
//       ShowToastDialog.showToast("Failed to Pick : \n $e");
//     }
//   }
//   uploadDocument() async {
//     try {
//       // Show loader while processing
//       ShowToastDialog.showLoader('Processing images...');
//
//       // Download Firebase images to local files before uploading
//       String frontImagePath = frontImage.value;
//       String backImagePath = backImage.value;
//
//       // Check if images are Firebase Storage URLs and download them
//       if (frontImagePath.isNotEmpty && frontImagePath.startsWith('https://')) {
//         print('📥 Downloading front image from Firebase...');
//         frontImagePath = await downloadImageToTempFile(frontImagePath);
//         print('✅ Front image downloaded to: $frontImagePath');
//       }
//
//       if (backImagePath.isNotEmpty && backImagePath.startsWith('https://')) {
//         print('📥 Downloading back image from Firebase...');
//         backImagePath = await downloadImageToTempFile(backImagePath);
//         print('✅ Back image downloaded to: $backImagePath');
//       }
//
//       // Set the local file paths to documents
//       documents.value.frontImage = frontImagePath;
//       documents.value.backImage = backImagePath;
//       documents.value.documentId = documentModel.value.id;
//       documents.value.status = "uploaded";
//
//       // Print debug info
//       print('documents.value: ${documents.value}');
//       print('documents.value.frontImage: ${documents.value.frontImage}');
//       print('documents.value.backImage: ${documents.value.backImage}');
//       print('documents.value.documentId: ${documents.value.documentId}');
//       print('documents.value.status: ${documents.value.status}');
//
//       // Upload to your backend
//       await uploadDriverDocument(documents.value).then((value) {
//         ShowToastDialog.closeLoader();
//         if (value) {
//           ShowToastDialog.showToast("Document uploaded successfully".tr);
//           Get.back(result: true);
//         } else {
//           ShowToastDialog.showToast("Failed to upload document".tr);
//         }
//       });
//     } catch (e) {
//       ShowToastDialog.closeLoader();
//       ShowToastDialog.showToast("Error uploading document: $e".tr);
//       print('❌ Error in uploadDocument: $e');
//     }
//   }
//   static Future<bool> uploadDriverDocument(Documents documents) async {
//     String? userId = await LoginController.getFirebaseId();
//     bool isAdded = false;
//     try {
//       // Log before creating request
//       print('\n📤 === STARTING DOCUMENT UPLOAD ===');
//       print('📋 Document Details:');
//       print('  - User ID: $userId');
//       print('  - Document ID: ${documents.documentId}');
//       print('  - Status: ${documents.status}');
//       print('  - Front Image Path: ${documents.frontImage}');
//       print('  - Back Image Path: ${documents.backImage}');
//       // Create multipart request
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${Constant.baseUrl}documents/driver/upload'),
//       );
//
//       // Add headers (if any)
//       print('\n🔑 Headers:');
//       request.headers.forEach((key, value) {
//         print('  $key: $value');
//       });
//
//       // Add fields
//       request.fields['user_id'] = userId ?? '';
//       request.fields['documentId'] = documents.documentId.toString();
//       request.fields['type'] = 'driver';
//       request.fields['status'] = documents.status ?? '';
//
//       // Print request fields
//       print('\n📝 === REQUEST FIELDS ===');
//       request.fields.forEach((key, value) {
//         print('  $key: $value');
//       });
//       print('=============================');
//       // Add image files if they exist
//       if (documents.frontImage != null && documents.frontImage!.isNotEmpty) {
//         var frontImageFile = File(documents.frontImage!);
//         if (await frontImageFile.exists()) {
//           var fileSize = await frontImageFile.length();
//           var multipartFile = await http.MultipartFile.fromPath(
//             'front_image',
//             frontImageFile.path,
//           );
//           request.files.add(multipartFile);
//           print('\n🖼️ Added front_image:');
//           print('  - Path: ${frontImageFile.path}');
//           print('  - Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
//           print('  - Exists: ${await frontImageFile.exists()}');
//         } else {
//           print('\n❌ Front image file does not exist at: ${frontImageFile.path}');
//         }
//       } else {
//         print('\n⚠️ Front image is null or empty');
//       }
//
//       if (documents.backImage != null && documents.backImage!.isNotEmpty) {
//         var backImageFile = File(documents.backImage!);
//         if (await backImageFile.exists()) {
//           var fileSize = await backImageFile.length();
//           var multipartFile = await http.MultipartFile.fromPath(
//             'back_image',
//             backImageFile.path,
//           );
//           request.files.add(multipartFile);
//           print('\n🖼️ Added back_image:');
//           print('  - Path: ${backImageFile.path}');
//           print('  - Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
//           print('  - Exists: ${await backImageFile.exists()}');
//         } else {
//           print('\n❌ Back image file does not exist at: ${backImageFile.path}');
//         }
//       } else {
//         print('\n⚠️ Back image is null or empty');
//       }
//
//       // Print files info
//       print('\n📎 === REQUEST FILES SUMMARY ===');
//       for (var file in request.files) {
//         print('  Field: ${file.field}');
//         print('  Filename: ${file.filename}');
//         print('  Content-Type: ${file.contentType}');
//         print('  ---');
//       }
//       print('Files count: ${request.files.length}');
//       print('==================================');
//
//       // Print complete request details
//       print('\n🌐 === COMPLETE REQUEST DETAILS ===');
//       print('  URL: ${request.url}');
//       print('  Method: ${request.method}');
//       print('  Content-Type: multipart/form-data');
//       print('  Total Fields: ${request.fields.length}');
//       print('  Total Files: ${request.files.length}');
//       print('  Timestamp: ${DateTime.now()}');
//       print('====================================\n');
//
//       // Send request with timing
//       print('🚀 Sending request...');
//       var startTime = DateTime.now();
//
//       var response = await request.send();
//       var endTime = DateTime.now();
//       var duration = endTime.difference(startTime);
//
//       print('⏱️ Request completed in: ${duration.inMilliseconds}ms');
//       print('📥 Response Status Code: ${response.statusCode}');
//
//       var responseData = await response.stream.bytesToString();
//       print('📄 Response Body: $responseData');
//
//       if (response.statusCode == 200) {
//         var jsonResponse = json.decode(responseData);
//         isAdded = jsonResponse['success'] == true;
//
//         print('\n✅ === UPLOAD RESULT ===');
//         print('  Success: $isAdded');
//         print('  Message: ${jsonResponse['message'] ?? 'No message'}');
//         print('  Response: $jsonResponse');
//         print('========================\n');
//       } else {
//         isAdded = false;
//         print('\n❌ === UPLOAD FAILED ===');
//         print('  Status Code: ${response.statusCode}');
//         print('  Response: $responseData');
//         print('========================\n');
//         log('Error: ${response.statusCode} - $responseData');
//       }
//     } catch (error, stackTrace) {
//       isAdded = false;
//       print('\n💥 === EXCEPTION OCCURRED ===');
//       print('  Error: $error');
//       print('  StackTrace: $stackTrace');
//       print('=============================\n');
//       log('Exception: $error\n$stackTrace');
//     }
//
//     print('\n🏁 === UPLOAD PROCESS COMPLETED ===');
//     print('  Final Result: $isAdded');
//     print('===============================\n');
//
//     return isAdded;
//   }
//
//   Future<String> downloadImageToTempFile(String imageUrl) async {
//     try {
//       // Create a temp directory
//       final tempDir = await getTemporaryDirectory();
//       final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       final filePath = '${tempDir.path}/$fileName';
//
//       // Download the file
//       final response = await http.get(Uri.parse(imageUrl));
//
//       if (response.statusCode == 200) {
//         // Save to local file
//         final file = File(filePath);
//         await file.writeAsBytes(response.bodyBytes);
//         // Verify file exists
//         if (await file.exists()) {
//           final fileSize = await file.length();
//           print('✅ Downloaded file: $filePath, Size: ${fileSize} bytes');
//           return filePath;
//         } else {
//           throw Exception('File not created');
//         }
//       } else {
//         throw Exception('Failed to download image: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error downloading image: $e');
//       throw e;
//     }
//   }
//   // uploadDocument() async {
//   //   String frontImageFileName = File(frontImage.value).path.split('/').last;
//   //   String backImageFileName = File(backImage.value).path.split('/').last;
//   //
//   //   if (frontImage.value.isNotEmpty &&
//   //       Constant().hasValidUrl(frontImage.value) == false) {
//   //     frontImage.value = await Constant.uploadUserImageToFireStorage(
//   //         File(frontImage.value),
//   //         "driverDocument/${FireStoreUtils.getCurrentUid()}",
//   //         frontImageFileName);
//   //   }
//   //   print("uploadDocument ${FireStoreUtils.getCurrentUid()}");
//   //   if (backImage.value.isNotEmpty &&
//   //       Constant().hasValidUrl(backImage.value) == false) {
//   //     backImage.value = await Constant.uploadUserImageToFireStorage(
//   //         File(backImage.value),
//   //         "driverDocument/${FireStoreUtils.getCurrentUid()}",
//   //         backImageFileName);
//   //   }
//   //   documents.value.frontImage = frontImage.value;
//   //   documents.value.backImage = backImage.value;
//   //   documents.value.documentId = documentModel.value.id;
//   //   documents.value.status = "uploaded";
//   //   print('documents.value: ${documents.value}');
//   //   developer.  log('documents.value.frontImage: ${documents.value.frontImage}');
//   //   developer. log('documents.value.backImage: ${documents.value.backImage}');
//   //   print('documents.value.documentId: ${documents.value.documentId}');
//   //   print('documents.value.status: ${documents.value.status}');
//   //   await FireStoreUtils.uploadDriverDocument(documents.value).then((value) {
//   //     if (value) {
//   //       ShowToastDialog.closeLoader();
//   //       ShowToastDialog.showToast("Document upload successfully".tr);
//   //       Get.back(result: true);
//   //     }
//   //   });
//   // }
// }
