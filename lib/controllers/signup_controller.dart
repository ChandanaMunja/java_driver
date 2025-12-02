import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippydriver_driver/app/auth_screen/login_screen.dart';
import 'package:jippydriver_driver/app/dash_board_screen/dash_board_screen.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/zone_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  Rx<TextEditingController> firstNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> lastNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> emailEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> phoneNUmberEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> countryCodeEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> passwordEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> conformPasswordEditingController =
      TextEditingController().obs;

  RxBool passwordVisible = true.obs;
  RxBool conformPasswordVisible = true.obs;

  RxString type = "".obs;

  Rx<UserModel> userModel = UserModel().obs;

  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  @override
  void onInit() {
    getArgument();
    super.onInit();
  }
  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      type.value = argumentData['type'];
      userModel.value = argumentData['userModel'];
      if (type.value == "mobileNumber") {
        phoneNUmberEditingController.value.text =
            userModel.value.phoneNumber ?? "";
        countryCodeEditingController.value.text =
            userModel.value.countryCode ?? "+1";
      } else if (type.value == "google" || type.value == "apple") {
        emailEditingController.value.text = userModel.value.email ?? "";
        firstNameEditingController.value.text = userModel.value.firstName ?? "";
        lastNameEditingController.value.text = userModel.value.lastName ?? "";
      }
    }

    await FireStoreUtils.getZone().then((value) {
      if (value != null && value.isNotEmpty) {
        zoneList.value = value;
        print("FireStoreUtils.getZone ${value.length} zones loaded");
        if (value.isNotEmpty) {
          print("First zone: ${value[0].id} ${value[0].name}");
        }
      } else {
        print("No zones found or error loading zones");
        zoneList.value = [];
      }
    }).catchError((error) {
      print("Error getting zones: $error");
      zoneList.value = [];
    });
  }

  signUpWithEmailAndPassword() async {
    ShowToastDialog.showLoader("Please wait");
    if (type.value == "google" ||
        type.value == "apple" ||
        type.value == "mobileNumber") {
      userModel.value.firstName =
          firstNameEditingController.value.text.toString();
      userModel.value.lastName =
          lastNameEditingController.value.text.toString();
      userModel.value.email =
          emailEditingController.value.text.toString().toLowerCase();
      userModel.value.phoneNumber =
          phoneNUmberEditingController.value.text.toString();
      userModel.value.role = Constant.userRoleDriver;
      userModel.value.fcmToken = await NotificationService.getToken();
      userModel.value.active =
      Constant.autoApproveDriver == true ? true : false;
      userModel.value.isDocumentVerify =
      Constant.isDriverVerification == true ? false : true;
      userModel.value.countryCode = countryCodeEditingController.value.text;
      userModel.value.createdAt = Timestamp.now();
      userModel.value.zoneId = selectedZone.value.id;
      userModel.value.appIdentifier = Platform.isAndroid ? 'android' : 'ios';
      await FireStoreUtils.updateUser(userModel.value).then(
            (value) {
          if (Constant.autoApproveDriver == true) {
            Get.offAll(const DashBoardScreen());
            ShowToastDialog.showToast("Account create successfully".tr);
          } else {
            ShowToastDialog.showToast(
                "Thank you for sign up, your application is under approval so please wait till that approve."
                    .tr);
            Get.offAll(const LoginScreen());
          }
        },
      );
    } else {
      try {
        var bodySignup = {
          "type": "email",
          "first_name": firstNameEditingController.value.text.toString(),
          "last_name": lastNameEditingController.value.text.toString(),
          "email": emailEditingController.value.text.trim().toLowerCase(),
          "password": passwordEditingController.value.text.trim(),
          "phone_number": phoneNUmberEditingController.value.text.toString(),
          "country_code": "+91",
          "zone_id": selectedZone.value.id,
          "fcm_token": await NotificationService.getToken(),
          "app_identifier": Platform.isAndroid ? 'android' : 'ios',
        };
        String prettyJson = const JsonEncoder.withIndent('  ').convert(bodySignup);
        log("🚀 Signup Request Body:\n$prettyJson");
        // Replace Firebase Auth with API call
        final response = await http.post(
          Uri.parse('${Constant.baseUrl}driver/signup'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(bodySignup),
        );
print("signupsignup ${response.body}");
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            userModel.value.id = responseData['data']['id'].toString() ;
            userModel.value.firstName =
                firstNameEditingController.value.text.toString();
            userModel.value.lastName =
                lastNameEditingController.value.text.toString();
            userModel.value.email =
                emailEditingController.value.text.toString().toLowerCase();
            userModel.value.phoneNumber =
                phoneNUmberEditingController.value.text.toString();
            userModel.value.role = Constant.userRoleDriver;
            userModel.value.fcmToken = await NotificationService.getToken();
            userModel.value.active =
            Constant.autoApproveDriver == true ? true : false;
            userModel.value.isDocumentVerify =
            Constant.isDriverVerification == true ? false : true;
            userModel.value.countryCode = countryCodeEditingController.value.text;
            userModel.value.createdAt = Timestamp.now();
            userModel.value.zoneId = selectedZone.value.id;
            userModel.value.appIdentifier =
            Platform.isAndroid ? 'android' : 'ios';
            userModel.value.provider = 'email';
            await FireStoreUtils.updateUser(userModel.value).then(
                  (value) async {
                if (Constant.autoApproveDriver == true) {
                  Get.offAll(const DashBoardScreen());
                } else {
                  ShowToastDialog.showToast(
                      "Thank you for sign up, your application is under approval so please wait till that approve."
                          .tr);
                  Get.offAll(const LoginScreen());
                }
              },
            );
          } else {
            ShowToastDialog.showToast(responseData['message'] ?? "Signup failed".tr);
          }
        } else {
          final errorData = json.decode(response.body);
          ShowToastDialog.showToast(errorData['message'] ?? "Signup failed".tr);
        }
      } on http.ClientException catch (e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Network error: ${e.message}".tr);
      } on FormatException catch (e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Invalid response format".tr);
      } catch (e) {
        print(" signupsignup ${e}");
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(e.toString());
      }
    }
    ShowToastDialog.closeLoader();
  }
  // signUp() async {
  //   ShowToastDialog.showLoader("Please wait");
  //   if (type.value == "google" ||
  //       type.value == "apple" ||
  //       type.value == "mobileNumber") {
  //     userModel.value.firstName =
  //         firstNameEditingController.value.text.toString();
  //     userModel.value.lastName =
  //         lastNameEditingController.value.text.toString();
  //     userModel.value.email =
  //         emailEditingController.value.text.toString().toLowerCase();
  //     userModel.value.phoneNumber =
  //         phoneNUmberEditingController.value.text.toString();
  //     userModel.value.role = Constant.userRoleDriver;
  //     userModel.value.fcmToken = await NotificationService.getToken();
  //     userModel.value.active =
  //         Constant.autoApproveDriver == true ? true : false;
  //     userModel.value.isDocumentVerify =
  //         Constant.isDriverVerification == true ? false : true;
  //     userModel.value.countryCode = countryCodeEditingController.value.text;
  //     userModel.value.createdAt = Timestamp.now();
  //     userModel.value.zoneId = selectedZone.value.id;
  //     userModel.value.appIdentifier = Platform.isAndroid ? 'android' : 'ios';
  //     await FireStoreUtils.updateUser(userModel.value).then(
  //       (value) {
  //         if (Constant.autoApproveDriver == true) {
  //           Get.offAll(const DashBoardScreen());
  //           ShowToastDialog.showToast("Account create successfully".tr);
  //         } else {
  //           ShowToastDialog.showToast(
  //               "Thank you for sign up, your application is under approval so please wait till that approve."
  //                   .tr);
  //           Get.offAll(const LoginScreen());
  //         }
  //       },
  //     );
  //   } else {
  //     try {
  //       final credential =
  //           await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //         email: emailEditingController.value.text.trim(),
  //         password: passwordEditingController.value.text.trim(),
  //       );
  //       if (credential.user != null) {
  //         userModel.value.id = credential.user!.uid;
  //         userModel.value.firstName =
  //             firstNameEditingController.value.text.toString();
  //         userModel.value.lastName =
  //             lastNameEditingController.value.text.toString();
  //         userModel.value.email =
  //             emailEditingController.value.text.toString().toLowerCase();
  //         userModel.value.phoneNumber =
  //             phoneNUmberEditingController.value.text.toString();
  //         userModel.value.role = Constant.userRoleDriver;
  //         userModel.value.fcmToken = await NotificationService.getToken();
  //         userModel.value.active =
  //             Constant.autoApproveDriver == true ? true : false;
  //         userModel.value.isDocumentVerify =
  //             Constant.isDriverVerification == true ? false : true;
  //         userModel.value.countryCode = countryCodeEditingController.value.text;
  //         userModel.value.createdAt = Timestamp.now();
  //         userModel.value.zoneId = selectedZone.value.id;
  //         userModel.value.appIdentifier =
  //             Platform.isAndroid ? 'android' : 'ios';
  //         userModel.value.provider = 'email';
  //         await FireStoreUtils.updateUser(userModel.value).then(
  //           (value) async {
  //             if (Constant.autoApproveDriver == true) {
  //               Get.offAll(const DashBoardScreen());
  //             } else {
  //               ShowToastDialog.showToast(
  //                   "Thank you for sign up, your application is under approval so please wait till that approve."
  //                       .tr);
  //               Get.offAll(const LoginScreen());
  //             }
  //           },
  //         );
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       if (e.code == 'weak-password') {
  //         ShowToastDialog.showToast("The password provided is too weak.".tr);
  //       } else if (e.code == 'email-already-in-use') {
  //         ShowToastDialog.showToast(
  //             "The account already exists for that email.".tr);
  //       } else if (e.code == 'invalid-email') {
  //         ShowToastDialog.showToast("Enter email is Invalid".tr);
  //       }
  //     } catch (e) {
  //       ShowToastDialog.showToast(e.toString());
  //     }
  //   }
  //
  //   ShowToastDialog.closeLoader();
  // }
}
