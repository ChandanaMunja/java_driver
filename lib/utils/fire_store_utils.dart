import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/app/chat_screens/ChatVideoContainer.dart';
import 'package:jippydriver_driver/app/wallet_screen/screens/model/delivery_amount_model.dart';
import 'package:jippydriver_driver/constant/collection_name.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/conversation_model.dart';
import 'package:jippydriver_driver/models/document_model.dart';
import 'package:jippydriver_driver/models/driver_document_model.dart';
import 'package:jippydriver_driver/models/email_template_model.dart';
import 'package:jippydriver_driver/models/inbox_model.dart';
import 'package:jippydriver_driver/models/mail_setting.dart';
import 'package:jippydriver_driver/models/notification_model.dart';
import 'package:jippydriver_driver/models/on_boarding_model.dart';
import 'package:jippydriver_driver/models/order_model.dart';
import 'package:jippydriver_driver/models/payment_model/cod_setting_model.dart';
import 'package:jippydriver_driver/models/payment_model/flutter_wave_model.dart';
import 'package:jippydriver_driver/models/payment_model/mercado_pago_model.dart';
import 'package:jippydriver_driver/models/payment_model/mid_trans.dart';
import 'package:jippydriver_driver/models/payment_model/orange_money.dart';
import 'package:jippydriver_driver/models/payment_model/pay_fast_model.dart';
import 'package:jippydriver_driver/models/payment_model/pay_stack_model.dart';
import 'package:jippydriver_driver/models/payment_model/paypal_model.dart';
import 'package:jippydriver_driver/models/payment_model/paytm_model.dart';
import 'package:jippydriver_driver/models/payment_model/razorpay_model.dart';
import 'package:jippydriver_driver/models/payment_model/stripe_model.dart';
import 'package:jippydriver_driver/models/payment_model/wallet_setting_model.dart';
import 'package:jippydriver_driver/models/payment_model/xendit.dart';
import 'package:jippydriver_driver/models/referral_model.dart';
import 'package:jippydriver_driver/models/tax_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/vendor_model.dart';
import 'package:jippydriver_driver/models/wallet_transaction_model.dart';
import 'package:jippydriver_driver/models/withdraw_method_model.dart';
import 'package:jippydriver_driver/models/withdrawal_model.dart';
import 'package:jippydriver_driver/models/zone_model.dart';
import 'package:jippydriver_driver/services/audio_player_service.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jippydriver_driver/utils/preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static Future<String> getCurrentUid() async{
    return await LoginController.getFirebaseId();
  }
  static Future<bool> isLogin() async {
    bool isLogin = false;
    String? userId =await  LoginController.getFirebaseId();
    try {
      isLogin = await userExistOrNot(userId)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        log("isLogin timeout - returning false");
        return false;
      });
    } catch (e) {
      log("isLogin error: $e - returning false");
      isLogin = false;
    }
      return isLogin;
  }
  static Future<bool> userExistOrNot(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/users/$uid/exists'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] == true;
        } else {
          log("API returned success: false");
          return false;
        }
      } else {
        log("Failed to check user exist: ${response.statusCode} - ${response.body}");
        return false;
      }
    } on TimeoutException catch (e) {
      log("userExistOrNot timeout: $e");
      return false;
    } catch (e) {
      log("userExistOrNot error: $e");
      return false;
    }
  }
  static Future<UserModel?> getUserProfile(String uuid) async {
    UserModel? userModel;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}users/$uuid'),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        log("getUserProfile timeout");
        throw TimeoutException('getUserProfile timeout', const Duration(seconds: 10));
      });
      print("getUserProfile ${Constant.baseUrl}users/$uuid ");
      print("getUserProfile ${response.body} ");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the API call was successful and extract the user data
        if (data['success'] == true && data['data'] != null) {
          userModel = UserModel.fromJson(data['data']); // Pass only the 'data' part
        } else {
          log("API returned success=false or null data");
          userModel = null;
        }
      } else if (response.statusCode == 404) {
        userModel = null;
      } else {
        log("Failed to get user profile: ${response.statusCode} - ${response.body}");
        userModel = null;
      }
    } on TimeoutException catch (e) {
      log("getUserProfile timeout: $e");
      userModel = null;
    } catch (e) {
      log("getUserProfile error: $e");
      userModel = null;
    }
    return userModel;
  }

  static Future<bool?> updateUserWallet({
    required String amount,
    required String userId
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver-sql/wallet/update'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'amount': double.parse(amount),
        }),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assuming API returns success status
        return responseData['success'] ?? true;
      } else {
        // Handle error response
        print('API Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating wallet: $e');
      return false;
    }
  }
  static Future<bool?> updateUserDeliveryAmount(
      {required String amount, required String userId}) async {
    bool isAdded = false;
    await getUserProfile(userId).then((value) async {
      if (value != null) {
        UserModel userModel = value;
        userModel.deliveryAmount =
            double.parse(userModel.deliveryAmount.toString()) +
                double.parse(amount);
        await FireStoreUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }
  static Future<bool> updateUser(UserModel userModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver-sql/users/update'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userModel.toJson()),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          Constant.userModel = userModel;
          log("User updated successfully: ${responseData['message']}");
          return true;
        } else {
          log("Failed to update user: ${responseData['message'] ?? 'Unknown error'}");
          return false;
        }
      } else {
        log("Failed to update user: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Failed to update user: $error");
      return false;
    }
  }
  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/onboarding'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          // Filter by type "driverApp" as in the original Firebase query
          final filteredData = data.where((item) => item['type'] == 'driverApp').toList();
          List<OnBoardingModel> onBoardingModel = filteredData
              .map((item) => OnBoardingModel.fromJson(item))
              .toList();
          return onBoardingModel;
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw HttpException('Failed to load onboarding data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching onboarding list: $e');
      return []; // Return empty list on error to maintain compatibility
    }
  }
  static Future<List<VendorModel>> getVendors() async {
    List<VendorModel> vendorList = [];
    try {
      if (Constant.selectedZone == null) {
        debugPrint('No zone selected');
        return vendorList;
      }
      final String zoneId = Constant.selectedZone!.id.toString();
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/vendors?zone_id=$zoneId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];

          for (var element in data) {
            try {
              debugPrint(element.toString());
              vendorList.add(VendorModel.fromJson(element));
            } catch (e) {
              debugPrint('VendorModel Parse error: $e');
            }
          }
          return vendorList;
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw HttpException('Failed to load vendors. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getVendors: $e');
      return vendorList; // Return empty list on error
    }
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver/wallet/transaction'),
        headers: {
          'Content-Type': 'application/json',
          // Add any other required headers like authorization
        },
        body: jsonEncode(walletTransactionModel.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("Wallet transaction added successfully");
        return true;
      } else {
        log("Failed to add wallet transaction: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Failed to update user: $error");
      return false;
    }
  }
  static Future<bool?> setDriverWalletRecord(
      Map<String, dynamic> driverWalletTransaction) async {
    try {
      print("transactionModel id ${driverWalletTransaction['id']}");
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver/wallet/withdraw-method'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(driverWalletTransaction),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Driver wallet record added successfully");
        return true;
      } else {
        // Handle different error status codes
        print("Failed to add driver wallet record: ${response.statusCode}");
        return false;
      }
    } catch (error) {
      print("Failed to update user: $error");
      return false;
    }
  }
  Future<Map<String, dynamic>> getDriverCharges() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/charges'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse["success"] == true) {
          final data = jsonResponse["data"];
          return {
            "pickup_charges": data["pickup_charges"] ?? "0",
            "user_delivery_charge": data["user_delivery_charge"] ?? "0",
          };
        } else {
          throw Exception("API returned unsuccessful response");
        }
      } else {
        throw Exception("HTTP request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching driver charges: $e");
      rethrow;
    }
  }

  getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/settings'),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        log("getSettings timeout for API call");
        throw TimeoutException('getSettings timeout', const Duration(seconds: 15));
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          // Process globalSettings
          final globalSettings = data['globalSettings'];
          if (globalSettings != null) {
            Constant.orderRingtoneUrl = globalSettings['order_ringtone_url'] ?? '';
            Constant.isSelfDeliveryFeature = globalSettings['isSelfDelivery'] ?? false;
            Preferences.setString(Preferences.orderRingtone, Constant.orderRingtoneUrl);

            final appDriverColor = globalSettings['app_driver_color'];
            if (appDriverColor != null) {
              AppThemeData.driverApp300 = Color(int.parse(appDriverColor.replaceFirst("#", "0xff")));
            }

            if (Constant.orderRingtoneUrl.isNotEmpty) {
              await AudioPlayerService.initAudio();
            }
          }

          // Process googleMapKey
          final googleMapKey = data['googleMapKey'];
          if (googleMapKey != null) {
            Constant.mapAPIKey = googleMapKey["key"] ?? '';
          }

          // Process notification_setting
          final notificationSetting = data['notification_setting'];
          if (notificationSetting != null) {
            Constant.senderId = notificationSetting["projectId"] ?? '';
            Constant.jsonNotificationFileURL = notificationSetting["serviceJson"] ?? '';
          }
          final restaurantNearBy = data['RestaurantNearBy'];
          if (restaurantNearBy != null) {
            Constant.distanceType = restaurantNearBy["distanceType"] ?? '';
          }
          // Process privacyPolicy
          final privacyPolicy = data['privacyPolicy'];
          if (privacyPolicy != null) {
            Constant.privacyPolicy = privacyPolicy["privacy_policy"] ?? '';
          }
          // Process termsAndConditions
          final termsAndConditions = data['termsAndConditions'];
          if (termsAndConditions != null) {
            Constant.termsAndConditions = termsAndConditions["termsAndConditions"] ?? '';
          }
          // Process Version
          final version = data['Version'];
          if (version != null) {
            Constant.googlePlayLink = version["googlePlayLink"] ?? '';
            Constant.appStoreLink = version["appStoreLink"] ?? '';
            Constant.appVersion = version["app_version"] ?? '';
          }
          // Process referral_amount
          final referralAmount = data['referral_amount'];
          if (referralAmount != null) {
            Constant.referralAmount = referralAmount['referralAmount']?.toString() ?? '';
          }

          // Process emailSetting
          final emailSetting = data['emailSetting'];
          if (emailSetting != null) {
            Constant.mailSettings = MailSettings.fromJson(emailSetting);
          }
          // Process placeHolderImage
          final placeHolderImage = data['placeHolderImage'];
          if (placeHolderImage != null) {
            Constant.placeHolderImage = placeHolderImage['image'] ?? '';
          }
          // Process document_verification_settings
          final docVerification = data['document_verification_settings'];
          if (docVerification != null) {
            Constant.isDriverVerification = docVerification['isDriverVerification'] ?? false;
          }
          // Process DriverNearBy
          final driverNearBy = data['DriverNearBy'];
          if (driverNearBy != null) {
            Constant.minimumDepositToRideAccept = driverNearBy['minimumDepositToRideAccept']?.toString() ?? '';
            Constant.minimumAmountToWithdrawal = driverNearBy['minimumAmountToWithdrawal']?.toString() ?? '';
            Constant.driverLocationUpdate = driverNearBy['driverLocationUpdate']?.toString() ?? '';
            Constant.singleOrderReceive = driverNearBy['singleOrderReceive'] ?? false;
            Constant.selectedMapType = driverNearBy["selectedMapType"] ?? '';
            Constant.mapType = driverNearBy["mapType"] ?? '';
            Constant.autoApproveDriver = driverNearBy["auto_approve_driver"] ?? false;
            log("Constant.singleOrderReceive :: ${Constant.singleOrderReceive}");
          }
        } else {
          log('API returned success: false');
        }
      } else {
        log('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      log(e.toString());
    }
  }

  static Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> zoneList = [];
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/zones'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Assuming the API returns a list directly or wrapped in a 'data' field
        List<dynamic> zonesData = responseData['data'] ?? responseData;

        for (var element in zonesData) {
          // Filter for published zones if needed (equivalent to where('publish', isEqualTo: true))
          if (element['publish'] == true) {
            ZoneModel zoneModel = ZoneModel.fromJson(element);
            zoneList.add(zoneModel);
          }
        }
      } else {
        throw Exception('Failed to load zones: ${response.statusCode}');
      }
    } catch (e, s) {
      log('APIUtils.getZone $e $s');
      return null;
    }
    return zoneList;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    try {
      final String driverId = await FireStoreUtils.getCurrentUid();
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/wallet/transactions?driver_id=$driverId'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          List<WalletTransactionModel> walletTransactionList = [];

          final data = jsonResponse['data'];
          if (data is List) {
            for (var element in data) {
              WalletTransactionModel walletTransactionModel =
              WalletTransactionModel.fromJson(element);
              walletTransactionList.add(walletTransactionModel);
            }
          }

          // Sort by date in descending order with null safety
          walletTransactionList.sort((a, b) {
            // Handle null dates - consider null as the earliest possible date
            if (a.date == null && b.date == null) return 0;
            if (a.date == null) return 1; // Put null dates at the end
            if (b.date == null) return -1; // Put null dates at the end
            return b.date!.compareTo(a.date!); // Both dates are non-null
          });

          return walletTransactionList;
        } else {
          log('API returned success: false');
          return null;
        }
      } else {
        log('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      log(error.toString());
      return null;
    }
  }


  static Future<List<DriverAmountWalletTransactionModel>?> getDriverAmountWalletTransaction() async {
    List<DriverAmountWalletTransactionModel> driverAmountWalletTransactionModelList = [];

    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/wallet/delivery-records?driver_id=${FireStoreUtils.getCurrentUid()}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Assuming the API returns a list of transactions
        if (responseData is List) {
          for (var element in responseData) {
            DriverAmountWalletTransactionModel driverAmountWalletTransactionModel =
            DriverAmountWalletTransactionModel.fromJson(element);
            driverAmountWalletTransactionModelList.add(driverAmountWalletTransactionModel);
          }
        }
        // If the API returns an object with a data field containing the list
        else if (responseData is Map && responseData['data'] is List) {
          for (var element in responseData['data']) {
            DriverAmountWalletTransactionModel driverAmountWalletTransactionModel =
            DriverAmountWalletTransactionModel.fromJson(element);
            driverAmountWalletTransactionModelList.add(driverAmountWalletTransactionModel);
          }
        }

        // Sort by date descending with null safety
        driverAmountWalletTransactionModelList.sort((a, b) {
          final dateA = a.date;
          final dateB = b.date;

          // Handle null cases - put nulls at the end
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
        });

      } else {
        log("getDriverAmountWalletTransaction API error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (error) {
      log("getDriverAmountWalletTransaction ${error.toString()}");
      return null;
    }

    return driverAmountWalletTransactionModelList;
  }

  static Future getPaymentSettingsData() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}settings/payment'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final Map<String, dynamic> paymentData = responseData['data'];

          // Process each payment method
          if (paymentData['payFastSettings'] != null) {
            PayFastModel payFastModel = PayFastModel.fromJson(paymentData['payFastSettings']);
            await Preferences.setString(
                Preferences.payFastSettings,
                jsonEncode(payFastModel.toJson())
            );
          }

          if (paymentData['MercadoPago'] != null) {
            MercadoPagoModel mercadoPagoModel = MercadoPagoModel.fromJson(paymentData['MercadoPago']);
            await Preferences.setString(
                Preferences.mercadoPago,
                jsonEncode(mercadoPagoModel.toJson())
            );
          }

          if (paymentData['paypalSettings'] != null) {
            PayPalModel payPalModel = PayPalModel.fromJson(paymentData['paypalSettings']);
            await Preferences.setString(
                Preferences.paypalSettings,
                jsonEncode(payPalModel.toJson())
            );
          }

          if (paymentData['stripeSettings'] != null) {
            StripeModel stripeModel = StripeModel.fromJson(paymentData['stripeSettings']);
            await Preferences.setString(
                Preferences.stripeSettings,
                jsonEncode(stripeModel.toJson())
            );
          }

          if (paymentData['flutterWave'] != null) {
            FlutterWaveModel flutterWaveModel = FlutterWaveModel.fromJson(paymentData['flutterWave']);
            await Preferences.setString(
                Preferences.flutterWave,
                jsonEncode(flutterWaveModel.toJson())
            );
          }

          if (paymentData['payStack'] != null) {
            PayStackModel payStackModel = PayStackModel.fromJson(paymentData['payStack']);
            await Preferences.setString(
                Preferences.payStack,
                jsonEncode(payStackModel.toJson())
            );
          }

          if (paymentData['PaytmSettings'] != null) {
            PaytmModel paytmModel = PaytmModel.fromJson(paymentData['PaytmSettings']);
            await Preferences.setString(
                Preferences.paytmSettings,
                jsonEncode(paytmModel.toJson())
            );
          }

          if (paymentData['walletSettings'] != null) {
            WalletSettingModel walletSettingModel = WalletSettingModel.fromJson(paymentData['walletSettings']);
            await Preferences.setString(
                Preferences.walletSettings,
                jsonEncode(walletSettingModel.toJson())
            );
          }

          if (paymentData['razorpaySettings'] != null) {
            RazorPayModel razorPayModel = RazorPayModel.fromJson(paymentData['razorpaySettings']);
            await Preferences.setString(
                Preferences.razorpaySettings,
                jsonEncode(razorPayModel.toJson())
            );
          }

          if (paymentData['CODSettings'] != null) {
            CodSettingModel codSettingModel = CodSettingModel.fromJson(paymentData['CODSettings']);
            await Preferences.setString(
                Preferences.codSettings,
                jsonEncode(codSettingModel.toJson())
            );
          }

          if (paymentData['midtrans_settings'] != null) {
            MidTrans midTrans = MidTrans.fromJson(paymentData['midtrans_settings']);
            await Preferences.setString(
                Preferences.midTransSettings,
                jsonEncode(midTrans.toJson())
            );
          }

          if (paymentData['orange_money_settings'] != null) {
            OrangeMoney orangeMoney = OrangeMoney.fromJson(paymentData['orange_money_settings']);
            await Preferences.setString(
                Preferences.orangeMoneySettings,
                jsonEncode(orangeMoney.toJson())
            );
          }

          if (paymentData['xendit_settings'] != null) {
            Xendit xendit = Xendit.fromJson(paymentData['xendit_settings']);
            await Preferences.setString(
                Preferences.xenditSettings,
                jsonEncode(xendit.toJson())
            );
          }
        } else {
          throw Exception('Failed to load payment settings: ${responseData['message']}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching payment settings: $e');
      rethrow;
    }
  }


  static Future<OrderModel?> getOrderById(String orderId) async {
    OrderModel? orderModel;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        orderModel = OrderModel.fromJson(responseData);
      } else if (response.statusCode == 404) {
        orderModel = null;
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e, s) {
      log('APIUtils.getOrderById $e $s');
      return null;
    }
    return orderModel;
  }
  static Future<DeliveryCharge?> getDeliveryCharge() async {
    DeliveryCharge? deliveryCharge;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/delivery-charge'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          deliveryCharge = DeliveryCharge.fromJson(responseData['data']);
        }
      } else {
        throw Exception('Failed to load delivery charge: ${response.statusCode}');
      }
    } catch (e, s) {
      log('APIUtils.getDeliveryCharge $e $s');
      return null;
    }
    return deliveryCharge;
  }

  static Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];

    try {
      // Get location coordinates
      List<Placemark> placeMarks = await placemarkFromCoordinates(
          Constant.selectedLocation.location?.latitude ?? 0.0,
          Constant.selectedLocation.location?.longitude ?? 0.0);

      final String country = placeMarks.first.country ?? 'India';

      // Make API call
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/tax?country=$country'),
        headers: {
          'Content-Type': 'application/json',
          // Add any other required headers like authorization
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Assuming the API returns a list of tax records
        if (responseData is List) {
          for (var element in responseData) {
            // Filter for enabled taxes on client side since API might not support it
            if (element['enable'] == true) {
              TaxModel taxModel = TaxModel.fromJson(element);
              taxList.add(taxModel);
            }
          }
        }
        // If the API returns an object with a data field containing the list
        else if (responseData is Map && responseData['data'] is List) {
          for (var element in responseData['data']) {
            // Filter for enabled taxes on client side
            if (element['enable'] == true) {
              TaxModel taxModel = TaxModel.fromJson(element);
              taxList.add(taxModel);
            }
          }
        }
      } else {
        log("getTaxList API error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (error) {
      log("getTaxList error: ${error.toString()}");
      return null;
    }

    return taxList;
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    try {
      final Map<String, dynamic> data = orderModel.toJson()
        ..removeWhere((key, value) => value == null);
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}restaurant/orders'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isAdded = true;
      } else {
        log("🔥 Failed to update or set order: ${response.statusCode} - ${response.body}");
        isAdded = false;
      }
    } catch (error) {
      log("🔥 Failed to update or set order: $error");
      isAdded = false;
    }

    return isAdded;
  }

  static Future<EmailTemplateModel?> getEmailTemplates(String type) async {
    EmailTemplateModel? emailTemplateModel;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}restaurant/email-templates/$type'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final dynamic templateData = responseData['data'] ?? responseData;
        print("------>");
        print(templateData);
        if (templateData != null) {
          emailTemplateModel = EmailTemplateModel.fromJson(templateData);
        }
      } else if (response.statusCode == 404) {
        // Email template not found
        print("------>");
        print("Email template not found for type: $type");
        emailTemplateModel = null;
      } else {
        throw Exception('Failed to load email template: ${response.statusCode}');
      }
    } catch (e, s) {
      log('APIUtils.getEmailTemplates $e $s');
      return null;
    }
    return emailTemplateModel;
  }
  static updateWallateAmount(OrderModel orderModel) async {
    double subTotal = 0.0;
    double specialDiscount = 0.0;
    double taxAmount = 0.0;
    for (var element in orderModel.products!) {
      if (double.parse(element.discountPrice.toString()) <= 0) {
        subTotal = subTotal +
            double.parse(element.price.toString()) *
                double.parse(element.quantity.toString()) +
            (double.parse(element.extrasPrice.toString()) *
                double.parse(element.quantity.toString()));
      } else {
        subTotal = subTotal +
            double.parse(element.discountPrice.toString()) *
                double.parse(element.quantity.toString()) +
            (double.parse(element.extrasPrice.toString()) *
                double.parse(element.quantity.toString()));
      }
    }

    if (orderModel.specialDiscount != null) {
      if (orderModel.specialDiscount != null ||
          orderModel.specialDiscount!['special_discount'] != null) {
        specialDiscount = double.parse(
            orderModel.specialDiscount!['special_discount'].toString());
      }
    }

    // var totalamount = total - discount - specialDiscount;

    double basePrice =
        (subTotal / (1 + (double.parse(orderModel.adminCommission!) / 100))) -
            double.parse(orderModel.discount.toString()) -
            specialDiscount;
    if (orderModel.taxSetting != null) {
      for (var element in orderModel.taxSetting!) {
        taxAmount = taxAmount +
            Constant.calculateTax(
                amount: (subTotal -
                        double.parse(orderModel.discount.toString()) -
                        specialDiscount)
                    .toString(),
                taxModel: element);
      }
    }

    num driverAmount = 0;
    if (orderModel.paymentMethod!.toLowerCase() != "cod") {
      driverAmount += (double.parse(orderModel.deliveryCharge!) +
          double.parse(orderModel.tipAmount!));
    } else {
      //driverAmount += -(basePrice + taxAmount);
      print('[Wallet Deduction][COD] Order: ${orderModel.id}, ToPay: ${orderModel.toPay}, Deducting from wallet: -${orderModel.toPay}');
      driverAmount += -double.parse(orderModel.toPay.toString());
    }

    // Debug print: show deduction info
    final userId = orderModel.driverID!;
    final userProfile = await getUserProfile(userId);
    final oldWallet = userProfile?.walletAmount ?? 0.0;
    final newWallet = oldWallet + double.parse(driverAmount.toString());
    print('[Wallet Deduction] Order: ${orderModel.id}, Driver: $userId, Old Wallet: $oldWallet, Change: ${driverAmount.toString()}, New Wallet: $newWallet');

    await FireStoreUtils.updateUserWallet(
        userId: userId, amount: driverAmount.toString());
  }

  static sendTopUpMail(
      {required String amount,
      required String paymentMethod,
      required String tractionId}) async {
    EmailTemplateModel? emailTemplateModel =
        await FireStoreUtils.getEmailTemplates(Constant.walletTopup);

    String newString = emailTemplateModel!.message.toString();
    newString = newString.replaceAll(
        "{username}",
        (Constant.userModel?.firstName.toString() ?? '') +
            (Constant.userModel?.lastName.toString() ?? ''));
    newString = newString.replaceAll(
        "{date}", DateFormat('yyyy-MM-dd').format(Timestamp.now().toDate()));
    newString =
        newString.replaceAll("{amount}", Constant.amountShow(amount: amount));
    newString =
        newString.replaceAll("{paymentmethod}", paymentMethod.toString());
    newString = newString.replaceAll("{transactionid}", tractionId.toString());
    newString = newString.replaceAll(
        "{newwalletbalance}.",
        Constant.amountShow(
            amount: Constant.userModel?.walletAmount.toString() ?? '0'));
    await Constant.sendMail(
        subject: emailTemplateModel.subject,
        isAdmin: emailTemplateModel.isSendToAdmin,
        body: newString,
        recipients: [Constant.userModel?.email ?? '']);
  }

  static Future<List<Map<String, dynamic>>> getVendorProducts(String id) async {
    final url = "${Constant.baseUrl}restaurant/vendors/$id";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      /// Assuming API returns:
      /// {
      ///   "success": true,
      ///   "data": [ { product1 }, { product2 } ]
      /// }
      return List<Map<String, dynamic>>.from(data["data"]);
    } else {
      throw Exception("Failed to load vendor products");
    }
  }

 static Future<List<Map<String, dynamic>>> getVendorCategories() async {
    final url = "${Constant.baseUrl}restaurant/vendor-categories";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      /// Expected API format:
      /// {
      ///   "success": true,
      ///   "data": [ {...}, {...} ]
      /// }
      return List<Map<String, dynamic>>.from(data["data"]);
    } else {
      throw Exception("Failed to load vendor categories");
    }
  }

  static Future<List> getVendorCuisines(String id) async {
    List tagList = [];
    List prodTagList = [];
    List<Map<String, dynamic>> productsQuery = await getVendorProducts(id);
    for (var document in productsQuery) {
      if (document.containsKey("categoryID") &&
          document['categoryID'].toString().isNotEmpty) {
        prodTagList.add(document['categoryID']);
      }
    }
    List<Map<String, dynamic>> catData = await getVendorCategories();
    for (var document in catData) {
      if (document.containsKey("id") &&
          document["id"].toString().isNotEmpty &&
          document.containsKey("title") &&
          document["title"].toString().isNotEmpty &&
          prodTagList.contains(document["id"])) {
        tagList.add(document["title"]);
      }
    }
    return tagList;
  }


  static Future<NotificationModel?> getNotificationContent(String type) async {
    NotificationModel? notificationModel;
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}firestore/notifications/$type'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Assuming the API returns the notification data directly or wrapped in a 'data' field
        final dynamic notificationData = responseData['data'] ?? responseData;
        print("------>");
        print(notificationData);
        notificationModel = NotificationModel.fromJson(notificationData);
      } else if (response.statusCode == 404) {
        // Notification not found - return default notification
        print("------>");
        print("Notification not found, using default");
        notificationModel = NotificationModel(
          id: "",
          message: "Notification setup is pending",
          subject: "setup notification",
          type: type,
        );
      } else {
        throw Exception('Failed to load notification: ${response.statusCode}');
      }
    } catch (e, s) {
      log('APIUtils.getNotificationContent $e $s');
      // Return default notification on error
      notificationModel = NotificationModel(
        id: "",
        message: "Notification setup is pending",
        subject: "setup notification",
        type: type,
      );
    }
    return notificationModel;
  }
  static Future<bool?> deleteUser() async {
    try {
      String? userId = await LoginController.getFirebaseId();
      // Delete user from database via API
      final response = await http.delete(
        Uri.parse('${Constant.baseUrl}driver-sql/users/$userId'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return true;
        } else {
          print('API returned error: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('API Error: ${response.statusCode}');
        return false;
      }
    } catch (e, s) {
      print('deleteUser error: $e $s');
      return false;
    }
  }

  static Future<List<DocumentModel>> getDocumentList() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}documents/driver/list'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          List<DocumentModel> documentList = [];
          for (var element in jsonResponse['data']) {
            DocumentModel documentModel = DocumentModel.fromJson(element);
            documentList.add(documentModel);
          }
          return documentList;
        } else {
          throw Exception('API Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (error) {
      log(error.toString());
      rethrow; // or return an empty list: return [];
    }
  }
  static Future<DriverDocumentModel?> getDocumentOfDriver() async {
    String? userId = await LoginController.getFirebaseId();

    DriverDocumentModel? driverDocumentModel;
    print("getDocumentOfDriver ${Constant.baseUrl}driver/documents/$userId ");
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver/documents/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print("getDocumentOfDriver ${response.body} ");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if data exists in response
        if (responseData['data'] != null) {
          driverDocumentModel = DriverDocumentModel.fromJson(responseData);
        } else if (responseData['exists'] == true) {
          // Handle the case where API might return exists flag
          return null;
        }
      } else if (response.statusCode == 404) {
        // Document not found
        return null;
      } else {
        // Handle other error status codes
        throw Exception('Failed to load document: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching driver document: $e');
      throw Exception('Failed to load driver document');
    }

    return driverDocumentModel;
  }
  static Future<InboxModel> addDriverInbox(InboxModel inboxModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}chat-driver/inbox'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(inboxModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return inboxModel;
      } else {
        throw Exception('Failed to add driver inbox: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add driver inbox: $e');
    }
  }

  static Future<ConversationModel> addDriverChat(ConversationModel conversationModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}chat-driver/thread'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(conversationModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return conversationModel;
      } else {
        throw Exception('Failed to add driver chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add driver chat: $e');
    }
  }


  static Future<ConversationModel> addRestaurantChat(ConversationModel conversationModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}chat-restaurant/thread'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(conversationModel.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return conversationModel;
      } else {
        throw Exception('Failed to add chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add chat: $e');
    }
  }

  static Future<Url> uploadChatImageToFireStorage(
      File image, BuildContext context) async {
    ShowToastDialog.showLoader("Please wait");
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
        mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  // static Future<ChatVideoContainer> uploadChatVideoToFireStorage(File video, BuildContext context) async {
  //   ShowToastDialog.showLoader("Please wait");
  //   var uniqueID = const Uuid().v4();
  //   Reference upload = FirebaseStorage.instance.ref().child('videos/$uniqueID.mp4');
  //   SettableMetadata metadata = SettableMetadata(contentType: 'video');
  //   UploadTask uploadTask = upload.putFile(video, metadata);
  //   var storageRef = (await uploadTask.whenComplete(() {})).ref;
  //   var downloadUrl = await storageRef.getDownloadURL();
  //   var metaData = await storageRef.getMetadata();
  //   final uint8list = await VideoThumbnail.thumbnailFile(video: downloadUrl, thumbnailPath: (await getTemporaryDirectory()).path, imageFormat: ImageFormat.PNG);
  //   final file = File(uint8list ?? '');
  //   String thumbnailDownloadUrl = await uploadVideoThumbnailToFireStorage(file);
  //   ShowToastDialog.closeLoader();
  //   return ChatVideoContainer(videoUrl: Url(url: downloadUrl.toString(), mime: metaData.contentType ?? 'video'), thumbnailUrl: thumbnailDownloadUrl);
  // }

  static Future<ChatVideoContainer?> uploadChatVideoToFireStorage(
      BuildContext context, File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef =
          FirebaseStorage.instance.ref('videos/$uniqueID.mp4');
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      File thumbnail = await VideoCompress.getFileThumbnail(
        video.path,
        quality: 75, // 0 - 100
        position: -1, // Get the first frame
      );

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef =
          FirebaseStorage.instance.ref('thumbnails/$thumbnailID.jpg');
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnail.readAsBytesSync(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();

      return ChatVideoContainer(
          videoUrl: Url(
              url: videoUrl.toString(),
              mime: metaData.contentType ?? 'video',
              videoThumbnail: thumbnailUrl),
          thumbnailUrl: thumbnailUrl);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = const Uuid().v4();
    Reference upload =
        FirebaseStorage.instance.ref().child('thumbnails/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(file);
    var downloadUrl =
        await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }
  static Future<bool> uploadDriverDocument(Documents documents) async {
    String? userId = await LoginController.getFirebaseId();
    bool isAdded = false;

    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constant.baseUrl}documents/driver/upload'),
      );
      // Add fields
      request.fields['user_id'] = userId ?? '';
      request.fields['documentId'] = documents.documentId.toString();
      request.fields['type'] = 'driver';
      request.fields['status'] = documents.status ?? '';

      // Print request fields
      print('=== REQUEST FIELDS ===');
      request.fields.forEach((key, value) {
        print('$key: $value');
      });
      print('=====================');

      // Add image files if they exist
      if (documents.frontImage != null && documents.frontImage!.isNotEmpty) {
        var frontImageFile = File(documents.frontImage!);
        if (await frontImageFile.exists()) {
          var multipartFile = await http.MultipartFile.fromPath(
            'front_image',
            frontImageFile.path,
          );
          request.files.add(multipartFile);
          print('Added front_image: ${frontImageFile.path}');
        }
      }
      if (documents.backImage != null && documents.backImage!.isNotEmpty) {
        var backImageFile = File(documents.backImage!);
        if (await backImageFile.exists()) {
          var multipartFile = await http.MultipartFile.fromPath(
            'back_image',
            backImageFile.path,
          );
          request.files.add(multipartFile);
          print('Added back_image: ${backImageFile.path}');
        }
      }
      // Print files info
      print('=== REQUEST FILES ===');
      for (var file in request.files) {
        print('Field: ${file.field}, Filename: ${file.filename}');
      }
      print('====================');
      // Print complete request details
      print('=== COMPLETE REQUEST DETAILS ===');
      print('URL: ${request.url}');
      print('Method: ${request.method}');
      print('Fields: ${request.fields}');
      print('Files count: ${request.files.length}');
      print('==============================');

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        isAdded = jsonResponse['success'] == true;
      } else {
        isAdded = false;
        log('Error: ${response.statusCode} - $responseData');
      }
    } catch (error) {
      isAdded = false;
      log(error.toString());
    }

    return isAdded;
  }


  static Future<WithdrawMethodModel?> getWithdrawMethod() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver/wallet/withdraw-method?userId=${getCurrentUid()}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // Assuming the API returns the data directly or in a 'data' field
        if (jsonResponse is Map<String, dynamic> && jsonResponse.isNotEmpty) {
          return WithdrawMethodModel.fromJson(jsonResponse);
        } else if (jsonResponse['data'] != null) {
          return WithdrawMethodModel.fromJson(jsonResponse['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        // No data found - equivalent to empty docs in Firebase
        return null;
      } else {
        // Handle other error status codes
        throw Exception('Failed to load withdraw method: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or parsing errors
      print('Error fetching withdraw method: $e');
      return null;
    }
  }

  static Future<WithdrawMethodModel?> setWithdrawMethod(
      WithdrawMethodModel withdrawMethodModel) async {
    try {
      String? userId = await LoginController.getFirebaseId();

      // Prepare the data
      if (withdrawMethodModel.id == null) {
        withdrawMethodModel.id = const Uuid().v4();
        withdrawMethodModel.userId = userId;
      }

      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver/wallet/withdraw-method'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(withdrawMethodModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse['data'] != null) {
            return WithdrawMethodModel.fromJson(jsonResponse['data']);
          } else {
            return WithdrawMethodModel.fromJson(jsonResponse);
          }
        }
        // If API doesn't return the object, return the original with updates
        return withdrawMethodModel;
      } else {
        throw Exception('Failed to set withdraw method: ${response.statusCode}');
      }
    } catch (e) {
      print('Error setting withdraw method: $e');
      return null;
    }
  }
  static Future<List<WithdrawalModel>?> getWithdrawHistory() async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/wallet/withdraw?driverID=${Constant.userModel!.id.toString()}'),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          List<WithdrawalModel> walletTransactionList = [];
          for (var element in jsonResponse['data']) {
            WithdrawalModel walletTransactionModel = WithdrawalModel.fromJson(element);
            walletTransactionList.add(walletTransactionModel);
          }
          return walletTransactionList;
        } else {
          print('API returned error: ${jsonResponse['message']}');
          return [];
        }
      } else {
        print('API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching withdrawal history: $e');
      return [];
    }
  }

  static sendPayoutMail(
      {required String amount, required String payoutrequestid}) async {
    EmailTemplateModel? emailTemplateModel =
        await FireStoreUtils.getEmailTemplates(Constant.payoutRequest);
    String body = emailTemplateModel!.subject.toString();
    body = body.replaceAll("{userid}", Constant.userModel!.id.toString());
    String newString = emailTemplateModel.message.toString();
    newString =
        newString.replaceAll("{username}", Constant.userModel!.fullName());
    newString =
        newString.replaceAll("{userid}", Constant.userModel!.id.toString());
    newString =
        newString.replaceAll("{amount}", Constant.amountShow(amount: amount));
    newString =
        newString.replaceAll("{payoutrequestid}", payoutrequestid.toString());
    newString = newString.replaceAll("{usercontactinfo}",
        "${Constant.userModel!.email}\n${Constant.userModel!.phoneNumber}");
    await Constant.sendMail(
        subject: body,
        isAdmin: emailTemplateModel.isSendToAdmin,
        body: newString,
        recipients: [Constant.userModel!.email],);
  }


  static Future<bool> withdrawWalletAmount(WithdrawalModel userModel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver-sql/wallet/withdraw'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        log("Failed to withdraw wallet amount: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Error withdrawing wallet amount: $error");
      return false;
    }
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    try {
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/orders/${orderModel.authorID}/is-first'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']['isFirstOrder'] ?? false;
        } else {
          log("API returned error: ${responseData['message']}");
          return false;
        }
      } else {
        log("Failed to check first order: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (error) {
      log("Error checking first order: $error");
      return false;
    }
  }
  static Future updateReferralAmount(OrderModel orderModel) async {
    ReferralModel? referralModel;

    try {
      // Replace Firebase call with API call
      final response = await http.get(
        Uri.parse('${Constant.baseUrl}driver-sql/referrals/${orderModel.authorID}'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          referralModel = ReferralModel.fromJson(jsonResponse['data']);
        } else {
          return;
        }
      } else {
        print('API Error: ${response.statusCode}');
        return;
      }
    } catch (e) {
      // Handle network/parsing errors
      print('Error fetching referral data: $e');
      return;
    }

    if (referralModel.referralBy != null &&
        referralModel.referralBy!.isNotEmpty) {
      WalletTransactionModel transactionModel = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: double.parse(Constant.referralAmount.toString()),
          date: Timestamp.now(),
          paymentMethod: "Referral Amount",
          transactionUser: "user",
          userId: referralModel.referralBy,
          isTopup: true,
          note: "You referral user has complete his this order #${orderModel.id}",
          paymentStatus: "success"
      );
      await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
        if (value == true) {
          await FireStoreUtils.updateUserWallet(
              amount: Constant.referralAmount.toString(),
              userId: referralModel!.referralBy.toString()
          ).then((value) {});
        }
      });
    } else {
      return;
    }
    }

  /// Atomically assign an order to a driver using Firestore transaction (FCFS locking)
  static Future<bool> assignOrderToDriverFCFS({
    required String orderId,
    required String driverId,
    required UserModel driverModel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver-sql/orders/assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'driver_id': driverId,
          'order_id': orderId,
        }),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['success'] == true;
      } else {
        print('API Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error assigning order to driver: $e');
      return false;
    }
  }

  static Future<void> removeOrderFromOtherDrivers({
    required String orderId,
    required String assignedDriverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant.baseUrl}driver-sql/orders/remove-from-others'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assigned_driver_id': assignedDriverId,
          'order_id': orderId,
        }),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] != true) {
          print('Failed to remove order from other drivers');
        }
      } else {
        // Handle API error
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network/parsing errors
      print('Error removing order from other drivers: $e');
    }
  }
}
