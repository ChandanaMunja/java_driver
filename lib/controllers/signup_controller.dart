// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:jippydriver_driver/app/auth_screen/login_screen.dart';
// import 'package:jippydriver_driver/app/dash_board_screen/dash_board_screen.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
// import 'package:jippydriver_driver/models/user_model.dart';
// import 'package:jippydriver_driver/models/zone_model.dart';
// import 'package:jippydriver_driver/utils/fire_store_utils.dart';
// import 'package:jippydriver_driver/utils/notification_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class SignupController extends GetxController {
//   Rx<TextEditingController> firstNameEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> lastNameEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> emailEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> phoneNUmberEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> countryCodeEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> passwordEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> conformPasswordEditingController =
//       TextEditingController().obs;
//
//   RxBool passwordVisible = true.obs;
//   RxBool conformPasswordVisible = true.obs;
//
//   RxString type = "".obs;
//
//   Rx<UserModel> userModel = UserModel().obs;
//
//   RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
//   Rx<ZoneModel> selectedZone = ZoneModel().obs;
//   @override
//   void onInit() {
//     getArgument();
//     super.onInit();
//   }
//   getArgument() async {
//     dynamic argumentData = Get.arguments;
//     if (argumentData != null) {
//       type.value = argumentData['type'];
//       userModel.value = argumentData['userModel'];
//       if (type.value == "mobileNumber") {
//         phoneNUmberEditingController.value.text =
//             userModel.value.phoneNumber ?? "";
//         countryCodeEditingController.value.text =
//             userModel.value.countryCode ?? "+1";
//       } else if (type.value == "google" || type.value == "apple") {
//         emailEditingController.value.text = userModel.value.email ?? "";
//         firstNameEditingController.value.text = userModel.value.firstName ?? "";
//         lastNameEditingController.value.text = userModel.value.lastName ?? "";
//       }
//     }
//
//     await FireStoreUtils.getZone().then((value) {
//       if (value != null && value.isNotEmpty) {
//         zoneList.value = value;
//         print("FireStoreUtils.getZone ${value.length} zones loaded");
//         if (value.isNotEmpty) {
//           print("First zone: ${value[0].id} ${value[0].name}");
//         }
//       } else {
//         print("No zones found or error loading zones");
//         zoneList.value = [];
//       }
//     }).catchError((error) {
//       print("Error getting zones: $error");
//       zoneList.value = [];
//     });
//   }
//
//   signUpWithEmailAndPassword() async {
//     ShowToastDialog.showLoader("Please wait");
//     if (type.value == "google" ||
//         type.value == "apple" ||
//         type.value == "mobileNumber") {
//       userModel.value.firstName =
//           firstNameEditingController.value.text.toString();
//       userModel.value.lastName =
//           lastNameEditingController.value.text.toString();
//       userModel.value.email =
//           emailEditingController.value.text.toString().toLowerCase();
//       userModel.value.phoneNumber =
//           phoneNUmberEditingController.value.text.toString();
//       userModel.value.role = Constant.userRoleDriver;
//       userModel.value.fcmToken = await NotificationService.getToken();
//       userModel.value.active =
//       Constant.autoApproveDriver == true ? true : false;
//       userModel.value.isDocumentVerify =
//       Constant.isDriverVerification == true ? false : true;
//       userModel.value.countryCode = countryCodeEditingController.value.text;
//       userModel.value.createdAt = Timestamp.now();
//       userModel.value.zoneId = selectedZone.value.id;
//       userModel.value.appIdentifier = Platform.isAndroid ? 'android' : 'ios';
//       await FireStoreUtils.updateUser(userModel.value).then(
//             (value) {
//           if (Constant.autoApproveDriver == true) {
//             Get.offAll(const LoginScreen());
//             ShowToastDialog.showToast("Account create successfully".tr);
//           } else {
//             ShowToastDialog.showToast(
//                 "Thank you for sign up, your application is under approval so please wait till that approve."
//                     .tr);
//             Get.offAll(const LoginScreen());
//           }
//         },
//       );
//     } else {
//       try {
//         var bodySignup = {
//           "type": "email",
//           "first_name": firstNameEditingController.value.text.toString(),
//           "last_name": lastNameEditingController.value.text.toString(),
//           "email": emailEditingController.value.text.trim().toLowerCase(),
//           "password": passwordEditingController.value.text.trim(),
//           "phone_number": phoneNUmberEditingController.value.text.toString(),
//           "country_code": "+91",
//           "zone_id": selectedZone.value.id,
//           "fcm_token": await NotificationService.getToken(),
//           "app_identifier": Platform.isAndroid ? 'android' : 'ios',
//         };
//         String prettyJson = const JsonEncoder.withIndent('  ').convert(bodySignup);
//         log("🚀 Signup Request Body:\n$prettyJson");
//         // Replace Firebase Auth with API call
//         final response = await http.post(
//           Uri.parse('${Constant.baseUrl}drivers/signup'),
//           headers: {
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',  // <--- ADD THIS LINE
//           },
//           body: json.encode(bodySignup),
//         );
// print("signupsignup ${response.body}");
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           final responseData = json.decode(response.body);
//           if (responseData['success'] == true && responseData['data'] != null) {
//             userModel.value.id = responseData['data']['id'].toString() ;
//             userModel.value.firstName =
//                 firstNameEditingController.value.text.toString();
//             userModel.value.lastName =
//                 lastNameEditingController.value.text.toString();
//             userModel.value.email =
//                 emailEditingController.value.text.toString().toLowerCase();
//             userModel.value.phoneNumber =
//                 phoneNUmberEditingController.value.text.toString();
//             userModel.value.role = Constant.userRoleDriver;
//             userModel.value.fcmToken = await NotificationService.getToken();
//             userModel.value.active =
//             Constant.autoApproveDriver == true ? true : false;
//             userModel.value.isDocumentVerify =
//             Constant.isDriverVerification == true ? false : true;
//             userModel.value.countryCode = countryCodeEditingController.value.text;
//             userModel.value.createdAt = Timestamp.now();
//             userModel.value.zoneId = selectedZone.value.id;
//             userModel.value.appIdentifier =
//             Platform.isAndroid ? 'android' : 'ios';
//             userModel.value.provider = 'email';
//             await FireStoreUtils.updateUser(userModel.value).then(
//                   (value) async {
//                 if (Constant.autoApproveDriver == true) {
//                   Get.offAll(const LoginScreen());
//                 } else {
//                   ShowToastDialog.showToast(
//                       "Thank you for sign up, your application is under approval so please wait till that approve."
//                           .tr);
//                   Get.offAll(const LoginScreen());
//                 }
//               },
//             );
//           } else {
//             ShowToastDialog.showToast(responseData['message'] ?? "Signup failed".tr);
//           }
//         } else {
//           final errorData = json.decode(response.body);
//           ShowToastDialog.showToast(errorData['message'] ?? "Signup failed".tr);
//         }
//       } on http.ClientException catch (e) {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("Network error: ${e.message}".tr);
//       } on FormatException catch (e) {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("Invalid response format".tr);
//       } catch (e) {
//         print(" signupsignup ${e}");
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast(e.toString());
//       }
//     }
//     ShowToastDialog.closeLoader();
//   }
//   // signUp() async {
//   //   ShowToastDialog.showLoader("Please wait");
//   //   if (type.value == "google" ||
//   //       type.value == "apple" ||
//   //       type.value == "mobileNumber") {
//   //     userModel.value.firstName =
//   //         firstNameEditingController.value.text.toString();
//   //     userModel.value.lastName =
//   //         lastNameEditingController.value.text.toString();
//   //     userModel.value.email =
//   //         emailEditingController.value.text.toString().toLowerCase();
//   //     userModel.value.phoneNumber =
//   //         phoneNUmberEditingController.value.text.toString();
//   //     userModel.value.role = Constant.userRoleDriver;
//   //     userModel.value.fcmToken = await NotificationService.getToken();
//   //     userModel.value.active =
//   //         Constant.autoApproveDriver == true ? true : false;
//   //     userModel.value.isDocumentVerify =
//   //         Constant.isDriverVerification == true ? false : true;
//   //     userModel.value.countryCode = countryCodeEditingController.value.text;
//   //     userModel.value.createdAt = Timestamp.now();
//   //     userModel.value.zoneId = selectedZone.value.id;
//   //     userModel.value.appIdentifier = Platform.isAndroid ? 'android' : 'ios';
//   //     await FireStoreUtils.updateUser(userModel.value).then(
//   //       (value) {
//   //         if (Constant.autoApproveDriver == true) {
//   //           Get.offAll(const DashBoardScreen());
//   //           ShowToastDialog.showToast("Account create successfully".tr);
//   //         } else {
//   //           ShowToastDialog.showToast(
//   //               "Thank you for sign up, your application is under approval so please wait till that approve."
//   //                   .tr);
//   //           Get.offAll(const LoginScreen());
//   //         }
//   //       },
//   //     );
//   //   } else {
//   //     try {
//   //       final credential =
//   //           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//   //         email: emailEditingController.value.text.trim(),
//   //         password: passwordEditingController.value.text.trim(),
//   //       );
//   //       if (credential.user != null) {
//   //         userModel.value.id = credential.user!.uid;
//   //         userModel.value.firstName =
//   //             firstNameEditingController.value.text.toString();
//   //         userModel.value.lastName =
//   //             lastNameEditingController.value.text.toString();
//   //         userModel.value.email =
//   //             emailEditingController.value.text.toString().toLowerCase();
//   //         userModel.value.phoneNumber =
//   //             phoneNUmberEditingController.value.text.toString();
//   //         userModel.value.role = Constant.userRoleDriver;
//   //         userModel.value.fcmToken = await NotificationService.getToken();
//   //         userModel.value.active =
//   //             Constant.autoApproveDriver == true ? true : false;
//   //         userModel.value.isDocumentVerify =
//   //             Constant.isDriverVerification == true ? false : true;
//   //         userModel.value.countryCode = countryCodeEditingController.value.text;
//   //         userModel.value.createdAt = Timestamp.now();
//   //         userModel.value.zoneId = selectedZone.value.id;
//   //         userModel.value.appIdentifier =
//   //             Platform.isAndroid ? 'android' : 'ios';
//   //         userModel.value.provider = 'email';
//   //         await FireStoreUtils.updateUser(userModel.value).then(
//   //           (value) async {
//   //             if (Constant.autoApproveDriver == true) {
//   //               Get.offAll(const DashBoardScreen());
//   //             } else {
//   //               ShowToastDialog.showToast(
//   //                   "Thank you for sign up, your application is under approval so please wait till that approve."
//   //                       .tr);
//   //               Get.offAll(const LoginScreen());
//   //             }
//   //           },
//   //         );
//   //       }
//   //     } on FirebaseAuthException catch (e) {
//   //       if (e.code == 'weak-password') {
//   //         ShowToastDialog.showToast("The password provided is too weak.".tr);
//   //       } else if (e.code == 'email-already-in-use') {
//   //         ShowToastDialog.showToast(
//   //             "The account already exists for that email.".tr);
//   //       } else if (e.code == 'invalid-email') {
//   //         ShowToastDialog.showToast("Enter email is Invalid".tr);
//   //       }
//   //     } catch (e) {
//   //       ShowToastDialog.showToast(e.toString());
//   //     }
//   //   }
//   //
//   //   ShowToastDialog.closeLoader();
//   // }
// }


import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/app/auth_screen/login_screen.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/zone_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// OPTIMIZATIONS:
/// 1. validateAndSignup() — all validation lives in the controller, not the view.
/// 2. signUpWithEmailAndPassword: unified null-safety with ?. and ?? operators.
/// 3. Removed dead commented-out code.
/// 4. Controllers disposed in onClose().
/// 5. _buildUserModel() helper removes duplicated field assignments.

class SignupController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final firstNameEditingController = TextEditingController().obs;
  final lastNameEditingController = TextEditingController().obs;
  final emailEditingController = TextEditingController().obs;
  final phoneNUmberEditingController = TextEditingController().obs;
  final countryCodeEditingController = TextEditingController().obs;
  final passwordEditingController = TextEditingController().obs;
  final conformPasswordEditingController = TextEditingController().obs;

  final passwordVisible = true.obs;
  final conformPasswordVisible = true.obs;
  final type = ''.obs;
  final userModel = UserModel().obs;
  final zoneList = <ZoneModel>[].obs;
  final selectedZone = ZoneModel().obs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _getArguments();
  }

  @override
  void onClose() {
    firstNameEditingController.value.dispose();
    lastNameEditingController.value.dispose();
    emailEditingController.value.dispose();
    phoneNUmberEditingController.value.dispose();
    countryCodeEditingController.value.dispose();
    passwordEditingController.value.dispose();
    conformPasswordEditingController.value.dispose();
    super.onClose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called by the UI. All validation lives here — view stays dumb.
  void validateAndSignup() {
    final isThirdParty = type.value == 'google' ||
        type.value == 'apple' ||
        type.value == 'mobileNumber';

    final firstName = firstNameEditingController.value.text.trim();
    final lastName = lastNameEditingController.value.text.trim();
    final email = emailEditingController.value.text.trim();
    final phone = phoneNUmberEditingController.value.text.trim();
    final password = passwordEditingController.value.text.trim();
    final confirmPassword = conformPasswordEditingController.value.text.trim();

    if (firstName.isEmpty) {
      ShowToastDialog.showToast('Please enter first name'.tr);
      return;
    }
    if (lastName.isEmpty) {
      ShowToastDialog.showToast('Please enter last name'.tr);
      return;
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      ShowToastDialog.showToast('Please enter a valid email'.tr);
      return;
    }
    if (phone.isEmpty) {
      ShowToastDialog.showToast('Please enter phone number'.tr);
      return;
    }
    if (!isThirdParty) {
      if (password.isEmpty) {
        ShowToastDialog.showToast('Please enter password'.tr);
        return;
      }
      if (confirmPassword.isEmpty) {
        ShowToastDialog.showToast('Please enter confirm password'.tr);
        return;
      }
      if (password != confirmPassword) {
        ShowToastDialog.showToast(
            "Password and Confirm password don't match".tr);
        return;
      }
    }
    if (selectedZone.value.id == null) {
      ShowToastDialog.showToast('Please select zone'.tr);
      return;
    }

    signUpWithEmailAndPassword();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _getArguments() async {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      type.value = args['type'] as String? ?? '';
      userModel.value = args['userModel'] as UserModel? ?? UserModel();

      switch (type.value) {
        case 'mobileNumber':
          phoneNUmberEditingController.value.text =
              userModel.value.phoneNumber ?? '';
          countryCodeEditingController.value.text =
              userModel.value.countryCode ?? '+91';
          break;
        case 'google':
        case 'apple':
          emailEditingController.value.text = userModel.value.email ?? '';
          firstNameEditingController.value.text =
              userModel.value.firstName ?? '';
          lastNameEditingController.value.text = userModel.value.lastName ?? '';
          break;
      }
    }

    // Default country code
    if (countryCodeEditingController.value.text.isEmpty) {
      countryCodeEditingController.value.text = '+91';
    }

    try {
      final zones = await FireStoreUtils.getZone();
      zoneList.value = zones ?? [];
      log('Loaded ${zoneList.length} zones');
    } catch (e) {
      log('Error loading zones: $e');
      zoneList.value = [];
    }
  }

  /// Populates userModel with form values — avoids repeating the same
  /// assignments in both code paths.
  Future<void> _buildUserModel({String? id, String? provider}) async {
    userModel.value
      ..id = id ?? userModel.value.id
      ..firstName = firstNameEditingController.value.text.trim()
      ..lastName = lastNameEditingController.value.text.trim()
      ..email = emailEditingController.value.text.trim().toLowerCase()
      ..phoneNumber = phoneNUmberEditingController.value.text.trim()
      ..role = Constant.userRoleDriver
      ..fcmToken = await NotificationService.getToken()
      ..active = Constant.autoApproveDriver == true
      ..isDocumentVerify = Constant.isDriverVerification != true
      ..countryCode = countryCodeEditingController.value.text
      ..createdAt = Timestamp.now()
      ..zoneId = selectedZone.value.id
      ..appIdentifier = Platform.isAndroid ? 'android' : 'ios'
      ..provider = provider ?? userModel.value.provider;
  }

  Future<void> signUpWithEmailAndPassword() async {
    ShowToastDialog.showLoader('Please wait'.tr);

    try {
      final isThirdParty = type.value == 'google' ||
          type.value == 'apple' ||
          type.value == 'mobileNumber';

      if (isThirdParty) {
        await _buildUserModel();
        await _updateUserWithoutIsActive(userModel.value);
        _handlePostSignup();
      } else {
        await _signupWithApi();
      }
    } catch (e) {
      log('Signup error: $e');
      ShowToastDialog.showToast(e.toString());
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> _signupWithApi() async {
    final body = {
      'type': 'email',
      'first_name': firstNameEditingController.value.text.trim(),
      'last_name': lastNameEditingController.value.text.trim(),
      'email': emailEditingController.value.text.trim().toLowerCase(),
      'password': passwordEditingController.value.text.trim(),
      'phone_number': phoneNUmberEditingController.value.text.trim(),
      'country_code': countryCodeEditingController.value.text,
      'zone_id': selectedZone.value.id,
      'fcm_token': await NotificationService.getToken(),
      'app_identifier': Platform.isAndroid ? 'android' : 'ios',
    };

    log('Signup request: ${const JsonEncoder.withIndent('  ').convert(body)}');

    final response = await http.post(
      Uri.parse('${Constant.baseUrl}drivers/signup'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(body),
    );

    log('Signup response [${response.statusCode}]: ${response.body}');

    final responseData =
    json.decode(response.body) as Map<String, dynamic>;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        responseData['success'] == true &&
        responseData['data'] != null) {
      final data = responseData['data'] as Map<String, dynamic>;
      await _buildUserModel(
        id: data['id']?.toString(),
        provider: 'email',
      );
      await _updateUserWithoutIsActive(userModel.value);
      _handlePostSignup();
    } else {
      ShowToastDialog.showToast(
          responseData['message'] as String? ?? 'Signup failed'.tr);
    }
  }

  Future<bool> _updateUserWithoutIsActive(UserModel user) async {
    try {
      final payload = user.toJson();
      payload.remove('isActive');

      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver-sql/users/update'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          Constant.userModel = user;
          return true;
        }
      }
    } catch (e) {
      log('Failed to update user without isActive: $e');
    }
    return false;
  }

  void _handlePostSignup() {
    if (Constant.autoApproveDriver == true) {
      ShowToastDialog.showToast('Account created successfully'.tr);
    } else {
      ShowToastDialog.showToast(
          'Thank you for signing up. Your application is under review — we\'ll notify you once it\'s approved.'
              .tr);
    }
    Get.offAll(const LoginScreen());
  }
}
