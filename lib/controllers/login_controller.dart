// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:http/http.dart' as http;
// import 'package:jippydriver_driver/app/auth_screen/login_screen.dart';
// import 'package:jippydriver_driver/app/auth_screen/signup_screen.dart';
// import 'package:jippydriver_driver/app/dash_board_screen/dash_board_screen.dart';
// import 'package:jippydriver_driver/app/mandatory_update_screen.dart';
// import 'package:jippydriver_driver/app/on_boarding_screen.dart';
// import 'package:jippydriver_driver/app/verification_screen/verification_screen.dart';
// import 'package:jippydriver_driver/constant/constant.dart';
// import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
// import 'package:jippydriver_driver/models/user_model.dart';
// import 'package:jippydriver_driver/utils/fire_store_utils.dart';
// import 'package:jippydriver_driver/utils/notification_service.dart';
// import 'package:jippydriver_driver/utils/version_utils.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:jippydriver_driver/utils/preferences.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:developer';
// import 'package:jippydriver_driver/utils/app_logger.dart';
//
// class LoginController extends GetxController {
//   Rx<TextEditingController> emailEditingController =
//       TextEditingController().obs;
//   Rx<TextEditingController> passwordEditingController =
//       TextEditingController().obs;
//   RxBool passwordVisible = true.obs;
//   redirectScreen() async {
//     String? userId = await LoginController.getFirebaseId();
//     print("redirectScreen . $userId ");
//     String fromScreen = 'SplashScreen';
//     try {
//       if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
//         log(' [32m$fromScreen -> OnBoardingScreen [0m');
//         Get.offAll(const OnBoardingScreen());
//       } else {
//         log(' [32m$fromScreen -> Checking login status... [0m');
//         bool isLogin = await FireStoreUtils.isLogin();
//         log(' [32m$fromScreen -> Login status: $isLogin [0m');
//         if (isLogin == true) {
//           log(' [32m$fromScreen -> Getting user profile... [0m');
//           UserModel? userModel = await FireStoreUtils.getUserProfile(userId);
//           await FireStoreUtils.getSettings();
//           await FireStoreUtils.getForceUpdateConfig();
//           print("FireStoreUtils.getUserProfile ${userModel?.firebaseId} ");
//           if (userModel != null) {
//             log(' [32m$fromScreen -> User profile loaded: ${userModel.toJson().toString()} [0m');
//             if (userModel.role == Constant.userRoleDriver) {
//               if (userModel.active == true) {
//                 final updateRequired = await isMandatoryUpdateRequired();
//                 if (updateRequired) {
//                   log(' [33m$fromScreen -> Mandatory update required -> MandatoryUpdateScreen [0m');
//                   Get.offAll(const MandatoryUpdateScreen());
//                   return;
//                 }
//                 log(' [32m$fromScreen -> Getting FCM token... [0m');
//                 userModel.fcmToken = await NotificationService.getToken();
//                 log(' [32m$fromScreen -> ${userModel.fcmToken} Updating user with FCM token... [0m');
//                 await FireStoreUtils.updateUser(userModel);
//                 log(' [32m$fromScreen -> DashBoardScreen [0m');
//                 Get.offAll(() => DashBoardScreen(userModel: userModel));
//                 if (userModel.isDocumentVerify != true) {
//                   Future.delayed(const Duration(milliseconds: 100), () {
//                     Get.to(() => const VerificationScreen());
//                   });
//                 }
//               } else {
//                 log(' [32m$fromScreen -> User inactive, signing out... [0m');
//                 Get.offAll(const LoginScreen());
//               }
//             } else {
//               log(' [32m$fromScreen -> User not a driver, signing out... [0m');
//               Get.offAll(const LoginScreen());
//             }
//           } else {
//             log(' [32m$fromScreen -> User profile null, signing out... [0m');
//             Get.offAll(const LoginScreen());
//           }
//         } else {
//           log(' [32m$fromScreen -> Not logged in, signing out... [0m');
//           Get.offAll(const LoginScreen());
//         }
//       }
//     } catch (e) {
//       log(' [31m$fromScreen -> Error in redirectScreen: $e [0m');
//       try {
//       } catch (signOutError) {
//         log(' [31m$fromScreen -> Error signing out: $signOutError [0m');
//       }
//       log(' [32m$fromScreen -> LoginScreen (error fallback) [0m');
//       Get.offAll(const LoginScreen());
//     }
//   }
//
//   @override
//   void onInit() {
//     AppLogger.log('LoginController onInit() called', tag: 'Controller');
//     // TODO: implement onInit
//     super.onInit();
//   }
//
//   @override
//   void onClose() {
//     AppLogger.log('LoginController onClose() called', tag: 'Controller');
//     super.onClose();
//   }
//
//   loginWithEmailAndPassword() async {
//     ShowToastDialog.showLoader("Please wait.".tr);
//     try {
//       final response = await http.post(
//         Uri.parse('${Constant.baseUrl}driver/login'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({
//           "email": emailEditingController.value.text.trim(),
//           "password": passwordEditingController.value.text.trim(),
//         }),
//       );
//       print("Login Response: ${response.body}");
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['success'] == true && responseData['data'] != null) {
//           final userData = responseData['data'];
//           UserModel userModel = UserModel.fromJson(userData);
//           await _saveUserToSharedPreferences(userData);
//           if (userModel.role == Constant.userRoleDriver) {
//             if (userModel.active == true || userModel.isActive == true) {
//               userModel.fcmToken = await NotificationService.getToken();
//               await FireStoreUtils.updateUser(userModel);
//               redirectScreen();
//               // Get.offAll(const DashBoardScreen());
//               log('\u001b[32mLoginScreen -> DashBoardScreen\u001b[0m');
//             } else {
//               ShowToastDialog.showToast(
//                   "This user is disable please contact to administrator".tr);
//             }
//           } else {
//             ShowToastDialog.showToast(
//                 "This user is not created in driver application.".tr);
//           }
//         } else {
//           ShowToastDialog.showToast(responseData['message'] ?? "Login failed".tr);
//         }
//       } else {
//         final errorData = json.decode(response.body);
//         ShowToastDialog.showToast(errorData['message'] ?? "Login failed".tr);
//       }
//     } on http.ClientException catch (e) {
//       ShowToastDialog.showToast("Network error: ${e.message}".tr);
//     } on FormatException catch (e) {
//       ShowToastDialog.showToast("Invalid response format".tr);
//     } catch (e) {
//       print("Login error: $e");
//       ShowToastDialog.showToast("An error occurred during login".tr);
//     }
//     ShowToastDialog.closeLoader();
//   }
//
// // Save ALL user data to SharedPreferences
//   Future<void> _saveUserToSharedPreferences(Map<String, dynamic> userData) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       // Save complete user data as JSON string
//       String userJson = json.encode(userData);
//       await prefs.setString('userData', userJson);
//
//       // Save individual important fields for quick access
//       await prefs.setBool('isLoggedIn', true);
//       await prefs.setString('userId', userData['id']?.toString() ?? '');
//       await prefs.setString('firebase_id', userData['firebase_id'] ?? '');
//       await prefs.setString('userEmail', userData['email'] ?? '');
//       await prefs.setString('userPassword', userData['password'] ?? ''); // Save encrypted password
//       await prefs.setString('userRole', userData['role'] ?? '');
//       await prefs.setString('firstName', userData['firstName'] ?? '');
//       await prefs.setString('lastName', userData['lastName'] ?? '');
//       await prefs.setString('phoneNumber', userData['phoneNumber'] ?? '');
//       await prefs.setString('countryCode', userData['countryCode'] ?? '');
//       await prefs.setString('fcmToken', userData['fcmToken'] ?? '');
//       await prefs.setString('appIdentifier', userData['appIdentifier'] ?? '');
//       await prefs.setString('provider', userData['provider'] ?? '');
//       await prefs.setString('zoneId', userData['zoneId'] ?? '');
//
//       // Save boolean values
//       await prefs.setBool('isActive', userData['isActive'] ?? false);
//       await prefs.setString('isDocumentVerify', userData['isDocumentVerify']?.toString() ?? '');
//       await prefs.setInt('active', userData['active'] ?? 0);
//
//       // Save numeric values
//       await prefs.setDouble('wallet_amount', userData['wallet_amount'] ?? 0.0);
//       await prefs.setDouble('deliveryAmount', userData['deliveryAmount'] ?? 0.0);
//
//       // Save timestamps and other fields
//       if (userData['createdAt'] != null) {
//         await prefs.setString('createdAt', userData['createdAt'].toString());
//       }
//
//       // Save car-related information
//       await prefs.setString('carName', userData['carName'] ?? '');
//       await prefs.setString('carNumber', userData['carNumber'] ?? '');
//       await prefs.setString('carPictureURL', userData['carPictureURL'] ?? '');
//
//       // Save location if available
//       if (userData['location'] != null) {
//         await prefs.setString('userLocation', json.encode(userData['location']));
//       }
//
//       // Save bank details if available
//       if (userData['userBankDetails'] != null) {
//         await prefs.setString('userBankDetails', json.encode(userData['userBankDetails']));
//       }
//
//       // Save subscription details
//       await prefs.setString('subscriptionPlanId', userData['subscriptionPlanId'] ?? '');
//       if (userData['subscriptionExpiryDate'] != null) {
//         await prefs.setString('subscriptionExpiryDate', userData['subscriptionExpiryDate'].toString());
//       }
//
//       print("✅ ALL user data saved to SharedPreferences successfully");
//       print("📱 Saved User ID: ${userData['id']}");
//       print("📧 Saved Email: ${userData['email']}");
//       print("🔑 Saved Firebase ID: ${userData['firebase_id']}");
//
//     } catch (e) {
//       print("❌ Error saving to SharedPreferences: $e");
//     }
//   }
//
// // Get user data from SharedPreferences
//   Future<UserModel?> getUserFromSharedPreferences() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final String? userJson = prefs.getString('userData');
//       if (userJson != null) {
//         final Map<String, dynamic> userData = json.decode(userJson);
//         return UserModel.fromJson(userData);
//       }
//       return null;
//     } catch (e) {
//       print("Error reading from SharedPreferences: $e");
//       return null;
//     }
//   }
//
// // Check if user is logged in
//   Future<bool> isUserLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool('isLoggedIn') ?? false;
//   }
//
// // Get specific user data quickly
// //   Future<String> getUserId() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     return prefs.getString('userId') ?? '';
// //   }
//
//   Future<String> getUserEmail() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('userEmail') ?? '';
//   }
//
//  static Future<String> getFirebaseId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('firebase_id') ?? '';
//   }
//
//   Future<String> getUserPassword() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('userPassword') ?? '';
//   }
//
// // Logout - Clear all user data from SharedPreferences
//   static Future<void> logout() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final uid = prefs.getString('firebase_id') ?? '';
//       if (uid.isNotEmpty) {
//         await prefs.remove('verif_id_draft_$uid');
//         await prefs.remove('verif_id_draft_aadhaar_$uid');
//         await prefs.remove('verif_id_draft_dl_$uid');
//       }
//       // Remove all user-related data
//       await prefs.remove('userData');
//       await prefs.remove('isLoggedIn');
//       await prefs.remove('userId');
//       await prefs.remove('firebase_id');
//       await prefs.remove('userEmail');
//       await prefs.remove('userPassword');
//       await prefs.remove('userRole');
//       await prefs.remove('firstName');
//       await prefs.remove('lastName');
//       await prefs.remove('phoneNumber');
//       await prefs.remove('countryCode');
//       await prefs.remove('fcmToken');
//       await prefs.remove('appIdentifier');
//       await prefs.remove('provider');
//       await prefs.remove('zoneId');
//       await prefs.remove('isActive');
//       await prefs.remove('isDocumentVerify');
//       await prefs.remove('active');
//       await prefs.remove('wallet_amount');
//       await prefs.remove('deliveryAmount');
//       await prefs.remove('createdAt');
//       await prefs.remove('carName');
//       await prefs.remove('carNumber');
//       await prefs.remove('carPictureURL');
//       await prefs.remove('userLocation');
//       await prefs.remove('userBankDetails');
//       await prefs.remove('subscriptionPlanId');
//       await prefs.remove('subscriptionExpiryDate');
//       // prefs.clear();
//       Get.offAll(const LoginScreen());
//       print("✅ All user data cleared from SharedPreferences");
//     } catch (e) {
//       print("❌ Error during logout: $e");
//     }
//   }
//   // loginWithEmailAndPassword() async {
//   //   ShowToastDialog.showLoader("Please wait.".tr);
//   //   try {
//   //     final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//   //       email: emailEditingController.value.text.trim(),
//   //       password: passwordEditingController.value.text.trim(),
//   //     );
//   //     UserModel? userModel =
//   //         await FireStoreUtils.getUserProfile(credential.user!.uid);
//   //     if (userModel?.role == Constant.userRoleDriver) {
//   //       if (userModel?.active == true) {
//   //         userModel?.fcmToken = await NotificationService.getToken();
//   //         await FireStoreUtils.updateUser(userModel!);
//   //         Get.offAll(const DashBoardScreen());
//   //         log('\u001b[32mLoginScreen -> DashBoardScreen\u001b[0m');
//   //       } else {
//   //         await FirebaseAuth.instance.signOut();
//   //         ShowToastDialog.showToast(
//   //             "This user is disable please contact to administrator".tr);
//   //       }
//   //     } else {
//   //       await FirebaseAuth.instance.signOut();
//   //       ShowToastDialog.showToast(
//   //           "This user is not created in driver application.".tr);
//   //     }
//   //   } on FirebaseAuthException catch (e) {
//   //     print(e.code);
//   //     if (e.code == 'user-not-found') {
//   //       ShowToastDialog.showToast("No user found for that email.".tr);
//   //     } else if (e.code == 'wrong-password') {
//   //       ShowToastDialog.showToast("Wrong password provided for that user.".tr);
//   //     } else if (e.code == 'invalid-email') {
//   //       ShowToastDialog.showToast("Invalid Email.".tr);
//   //     } else {
//   //       ShowToastDialog.showToast("${e.message}");
//   //     }
//   //   }
//   //   ShowToastDialog.closeLoader();
//   // }
//
//
// // ... other imports ...
//
// // 1. Get the singleton instance
//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//
//
//   // Future<UserCredential?> signInWithGoogle() async {
//   //   try {
//   //
//   //     final GoogleSignInAccount? googleUser =
//   //         await GoogleSignIn().signIn().catchError((error) {
//   //       ShowToastDialog.closeLoader();
//   //       ShowToastDialog.showToast("something_went_wrong".tr);
//   //       return null;
//   //     });
//   //
//   //     // Obtain the auth details from the request
//   //     final GoogleSignInAuthentication? googleAuth =
//   //         await googleUser?.authentication;
//   //
//   //     // Create a new credential
//   //     final credential = GoogleAuthProvider.credential(
//   //       accessToken: googleAuth?.accessToken,
//   //       idToken: googleAuth?.idToken,
//   //     );
//   //
//   //     // Once signed in, return the UserCredential
//   //     return await FirebaseAuth.instance.signInWithCredential(credential);
//   //   } catch (e) {
//   //     debugPrint(e.toString());
//   //   }
//   //   return null;
//   //   // Trigger the authentication flow
//   // }
//
//   String sha256ofString(String input) {
//     final bytes = utf8.encode(input);
//     final digest = sha256.convert(bytes);
//     return digest.toString();
//   }
//
// }



import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/app/auth_screen/login_screen.dart';
import 'package:jippydriver_driver/app/dash_board_screen/dash_board_screen.dart';
import 'package:jippydriver_driver/app/mandatory_update_screen.dart';
import 'package:jippydriver_driver/app/on_boarding_screen.dart';
import 'package:jippydriver_driver/app/verification_screen/verification_screen.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';
import 'package:jippydriver_driver/utils/driver_location_sync.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:jippydriver_driver/utils/notification_service.dart';
import 'package:jippydriver_driver/utils/preferences.dart';
import 'package:jippydriver_driver/utils/version_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OPTIMIZATIONS:
/// 1. Added validateAndLogin() — separates UI validation from business logic.
/// 2. _saveUserToSharedPreferences uses a single prefs instance and batches
///    Future.wait where possible for parallel writes.
/// 3. Removed dead commented-out code (Firebase Auth methods) — kept in
///    version control if needed.
/// 4. Static helpers (getFirebaseId, logout) remain static — they don't need
///    instance state.
/// 5. Proper resource cleanup in onClose().
class LoginController extends GetxController {
  // ── State ──────────────────────────────────────────────────────────────────
  final emailEditingController = TextEditingController().obs;
  final passwordEditingController = TextEditingController().obs;
  final passwordVisible = true.obs;

  bool _isDriverEnabled(UserModel userModel) {
    // Keep auth decision simple: only `active` controls login access.
    return userModel.active == true;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    AppLogger.log('LoginController onInit()', tag: 'Controller');
    super.onInit();
  }

  @override
  void onClose() {
    AppLogger.log('LoginController onClose()', tag: 'Controller');
    emailEditingController.value.dispose();
    passwordEditingController.value.dispose();
    super.onClose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called directly by the UI — keeps all validation here so the view stays
  /// dumb.
  void validateAndLogin() {
    final email = emailEditingController.value.text.trim();
    final password = passwordEditingController.value.text.trim();

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      ShowToastDialog.showToast('Please enter a valid email address'.tr);
      return;
    }
    if (password.isEmpty) {
      ShowToastDialog.showToast('Please enter your password'.tr);
      return;
    }
    loginWithEmailAndPassword();
  }

  Future<void> redirectScreen() async {
    final userId = await LoginController.getFirebaseId();
    log('redirectScreen userId=$userId');

    try {
      if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
        Get.offAll(const OnBoardingScreen());
        return;
      }

      final isLogin = await FireStoreUtils.isLogin();
      if (!isLogin) {
        Get.offAll(const LoginScreen());
        return;
      }

      final userModel = await FireStoreUtils.getUserProfile(userId);
      await FireStoreUtils.getSettings();
      await FireStoreUtils.getForceUpdateConfig();

      if (userModel == null) {
        Get.offAll(const LoginScreen());
        return;
      }

      if (userModel.role != Constant.userRoleDriver) {
        Get.offAll(const LoginScreen());
        return;
      }

      if (!_isDriverEnabled(userModel)) {
        Get.offAll(const LoginScreen());
        return;
      }

      if (await isMandatoryUpdateRequired()) {
        Get.offAll(const MandatoryUpdateScreen());
        return;
      }

      userModel.fcmToken = await NotificationService.getToken();
      await FireStoreUtils.updateUser(userModel);
      Get.offAll(() => DashBoardScreen(userModel: userModel));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(DriverLocationSync.syncDeviceLocationIntoUserModel());
      });

      if (userModel.isDocumentVerify != true) {
        Future.delayed(const Duration(milliseconds: 120),
                () => Get.to(() => const VerificationScreen()));
      }
    } catch (e) {
      log('redirectScreen error: $e');
      Get.offAll(const LoginScreen());
    }
  }

  Future<void> loginWithEmailAndPassword() async {
    ShowToastDialog.showLoader('Please wait'.tr);
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver/login'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailEditingController.value.text.trim(),
          'password': passwordEditingController.value.text.trim(),
        }),
      );

      log('Login response [${response.statusCode}]: ${response.body}');

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 &&
          responseData['success'] == true &&
          responseData['data'] != null) {
        final userData = responseData['data'] as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userData);

        await _saveUserToSharedPreferences(userData);

        if (userModel.role != Constant.userRoleDriver) {
          ShowToastDialog.showToast(
              'This user is not created in driver application.'.tr);
          return;
        }

        if (!_isDriverEnabled(userModel)) {
          ShowToastDialog.showToast(
              'This user is disabled. Please contact the administrator.'.tr);
          return;
        }

        userModel.fcmToken = await NotificationService.getToken();
        await FireStoreUtils.updateUser(userModel);
        redirectScreen();
      } else {
        ShowToastDialog.showToast(
            responseData['message'] as String? ?? 'Login failed'.tr);
      }
    } on http.ClientException catch (e) {
      ShowToastDialog.showToast('Network error: ${e.message}'.tr);
    } on FormatException {
      ShowToastDialog.showToast('Invalid response format'.tr);
    } catch (e) {
      log('Login error: $e');
      ShowToastDialog.showToast('An error occurred during login'.tr);
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  // ── SharedPreferences helpers ──────────────────────────────────────────────

  Future<void> _saveUserToSharedPreferences(
      Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      bool _readBool(dynamic value, {bool defaultValue = false}) {
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final v = value.trim().toLowerCase();
          if (v == '1' || v == 'true' || v == 'yes') return true;
          if (v == '0' || v == 'false' || v == 'no') return false;
        }
        return defaultValue;
      }

      int _readInt(dynamic value, {int defaultValue = 0}) {
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value.trim()) ?? defaultValue;
        return defaultValue;
      }

      double _readDouble(dynamic value, {double defaultValue = 0.0}) {
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value.trim()) ?? defaultValue;
        return defaultValue;
      }

      String _readString(dynamic value, {String defaultValue = ''}) {
        if (value == null) return defaultValue;
        return value.toString();
      }

      // Write everything in parallel using Future.wait
      await Future.wait([
        prefs.setString('userData', json.encode(userData)),
        prefs.setBool('isLoggedIn', true),
        prefs.setString('userId', userData['id']?.toString() ?? ''),
        prefs.setString('firebase_id', _readString(userData['firebase_id'])),
        prefs.setString('userEmail', _readString(userData['email'])),
        prefs.setString('userPassword', _readString(userData['password'])),
        prefs.setString('userRole', _readString(userData['role'])),
        prefs.setString('firstName', _readString(userData['firstName'])),
        prefs.setString('lastName', _readString(userData['lastName'])),
        prefs.setString('phoneNumber', _readString(userData['phoneNumber'])),
        prefs.setString('countryCode', _readString(userData['countryCode'])),
        prefs.setString('fcmToken', _readString(userData['fcmToken'])),
        prefs.setString('appIdentifier', _readString(userData['appIdentifier'])),
        prefs.setString('provider', _readString(userData['provider'])),
        prefs.setString('zoneId', _readString(userData['zoneId'])),
        prefs.setBool('isActive', _readBool(userData['isActive'])),
        prefs.setString(
            'isDocumentVerify', userData['isDocumentVerify']?.toString() ?? ''),
        prefs.setInt('active', _readInt(userData['active'])),
        prefs.setDouble('wallet_amount', _readDouble(userData['wallet_amount'])),
        prefs.setDouble('deliveryAmount', _readDouble(userData['deliveryAmount'])),
        prefs.setString('carName', _readString(userData['carName'])),
        prefs.setString('carNumber', _readString(userData['carNumber'])),
        prefs.setString('carPictureURL', _readString(userData['carPictureURL'])),
        prefs.setString('subscriptionPlanId', _readString(userData['subscriptionPlanId'])),
        if (userData['createdAt'] != null)
          prefs.setString('createdAt', userData['createdAt'].toString()),
        if (userData['location'] != null)
          prefs.setString('userLocation', json.encode(userData['location'])),
        if (userData['userBankDetails'] != null)
          prefs.setString(
              'userBankDetails', json.encode(userData['userBankDetails'])),
        if (userData['subscriptionExpiryDate'] != null)
          prefs.setString('subscriptionExpiryDate',
              userData['subscriptionExpiryDate'].toString()),
      ]);

      log('✅ User data saved — id=${userData['id']}, email=${userData['email']}');
    } catch (e) {
      log('❌ Error saving user to SharedPreferences: $e');
    }
  }

  Future<UserModel?> getUserFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('userData');
      if (userJson == null) return null;
      return UserModel.fromJson(json.decode(userJson) as Map<String, dynamic>);
    } catch (e) {
      log('Error reading user from SharedPreferences: $e');
      return null;
    }
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? '';
  }

  Future<String> getUserPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPassword') ?? '';
  }

  static Future<String> getFirebaseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_id') ?? '';
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('firebase_id') ?? '';

      final keysToRemove = [
        'userData', 'isLoggedIn', 'userId', 'firebase_id', 'userEmail',
        'userPassword', 'userRole', 'firstName', 'lastName', 'phoneNumber',
        'countryCode', 'fcmToken', 'appIdentifier', 'provider', 'zoneId',
        'isActive', 'isDocumentVerify', 'active', 'wallet_amount',
        'deliveryAmount', 'createdAt', 'carName', 'carNumber', 'carPictureURL',
        'userLocation', 'userBankDetails', 'subscriptionPlanId',
        'subscriptionExpiryDate',
        if (uid.isNotEmpty) ...[
          'verif_id_draft_$uid',
          'verif_id_draft_aadhaar_$uid',
          'verif_id_draft_dl_$uid',
        ],
      ];

      await Future.wait(keysToRemove.map(prefs.remove));
      Get.offAll(const LoginScreen());
      log('✅ All user data cleared from SharedPreferences');
    } catch (e) {
      log('❌ Logout error: $e');
    }
  }

  // ── Utility ────────────────────────────────────────────────────────────────
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // Keep singleton reference if needed elsewhere
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
}