import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/models/subscription_plan_model.dart';

class UserModel {
  String? id;
  String? firebaseId;
  String? firstName;
  String? lastName;
  String? email;
  String? profilePictureURL;
  String? fcmToken;
  String? countryCode;
  String? phoneNumber;
  num? walletAmount;
  bool? active;
  bool? isActive;
  bool? isDocumentVerify;
  Timestamp? createdAt;
  String? role;
  UserLocation? location;
  UserBankDetails? userBankDetails;
  List<ShippingAddress>? shippingAddress;
  String? carName;
  String? carNumber;
  String? carPictureURL;
  List<dynamic>? inProgressOrderID;
  List<dynamic>? orderRequestData;
  String? vendorID;
  String? zoneId;
  num? rotation;
  String? appIdentifier;
  String? provider;
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  SubscriptionPlanModel? subscriptionPlan;
  num? deliveryAmount;

  UserModel({
    this.id,
    this.firebaseId,
    this.firstName,
    this.lastName,
    this.active,
    this.isActive,
    this.isDocumentVerify,
    this.email,
    this.profilePictureURL,
    this.fcmToken,
    this.countryCode,
    this.phoneNumber,
    this.walletAmount,
    this.createdAt,
    this.role,
    this.location,
    this.shippingAddress,
    this.carName,
    this.carNumber,
    this.carPictureURL,
    this.inProgressOrderID,
    this.orderRequestData,
    this.vendorID,
    this.zoneId,
    this.rotation,
    this.appIdentifier,
    this.provider,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionPlan,
    this.deliveryAmount
  });

  String fullName() {
    return "${firstName ?? ''} ${lastName ?? ''}";
  }

  UserModel.fromJson(Map<String, dynamic> json) {
    // Safely convert id from int or String to String?
    if (json['id'] != null) {
      id = json['id'] is String ? json['id'] : json['id'].toString();
    }
    firebaseId = json['firebase_id']?.toString() ?? json['id']?.toString();
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    profilePictureURL = json['profile_pic'];
    fcmToken = json['fcmToken'];
    countryCode = json['countryCode'];
    phoneNumber = (json['phoneNumber'] ?? json['phone'])?.toString();
    walletAmount = json['wallet_amount'] ?? 0;
    deliveryAmount = json['deliveryAmount'] ?? 0;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        createdAt = json['createdAt'];
      } else if (json['createdAt'] is int) {
        createdAt = Timestamp.fromMillisecondsSinceEpoch(json['createdAt']);
      } else if (json['createdAt'] is String) {
        // Try parsing as milliseconds string first (e.g., "1764675379043")
        final milliseconds = int.tryParse(json['createdAt']);
        if (milliseconds != null) {
          createdAt = Timestamp.fromMillisecondsSinceEpoch(milliseconds);
        } else {
          // Try parsing as ISO8601 string
          try {
            final dateTime = DateTime.parse(json['createdAt']);
            createdAt = Timestamp.fromDate(dateTime);
          } catch (e) {
            createdAt = null;
          }
        }
      } else if (json['createdAt'] is Map) {
        try {
          createdAt = Timestamp(
            json['createdAt']['seconds'] ?? 0,
            json['createdAt']['nanoseconds'] ?? 0,
          );
        } catch (e) {
          createdAt = null;
        }
      }
    } else {
      createdAt = null;
    }

    active = json['active'] == 1 || json['active'] == true;
    isActive = json['isActive'] == 1 || json['isActive'] == true;
    isDocumentVerify = json['isDocumentVerify'] == "1" || json['isDocumentVerify'] == true || json['isDocumentVerify'] == 1;
    print("isDocumentVerify  ${isDocumentVerify}");
    role = json['role'] ?? 'user';

    // Fix for location handling
    if (json['location'] != null && json['location'] is List) {
      final locationList = json['location'] as List;
      if (locationList.isNotEmpty) {
        final firstItem = locationList.first;
        if (firstItem is Map<String, dynamic>) {
          location = UserLocation.fromJson(firstItem);
        } else {
          location = null;
        }
      } else {
        location = null;
      }
    } else if (json['location'] != null && json['location'] is Map<String, dynamic>) {
      location = UserLocation.fromJson(json['location'] as Map<String, dynamic>);
    } else {
      location = null;
    }

    // Fix for userBankDetails handling
    if (json['userBankDetails'] != null && json['userBankDetails'] is List) {
      final list = json['userBankDetails'] as List;
      if (list.isNotEmpty) {
        final firstItem = list.first;
        if (firstItem is Map<String, dynamic>) {
          userBankDetails = UserBankDetails.fromJson(firstItem);
        } else {
          userBankDetails = null;
        }
      } else {
        userBankDetails = null;
      }
    } else if (json['userBankDetails'] != null && json['userBankDetails'] is Map<String, dynamic>) {
      userBankDetails = UserBankDetails.fromJson(json['userBankDetails'] as Map<String, dynamic>);
    } else {
      userBankDetails = null;
    }

    // Fix for shippingAddress handling
    if (json['shippingAddress'] != null) {
      if (json['shippingAddress'] is List) {
        final list = json['shippingAddress'] as List;
        shippingAddress = <ShippingAddress>[];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            shippingAddress!.add(ShippingAddress.fromJson(item));
          }
        }
      } else if (json['shippingAddress'] is Map<String, dynamic>) {
        shippingAddress = <ShippingAddress>[];
        shippingAddress!.add(ShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>));
      } else {
        shippingAddress = null;
      }
    } else {
      shippingAddress = null;
    }

    carName = json['carName'];
    carNumber = json['carNumber'];
    carPictureURL = json['carPictureURL'];
    inProgressOrderID = _parseList(json['inProgressOrderID']);
    orderRequestData = _parseList(json['orderRequestData']);
    vendorID = json['vendorID'] ?? '';
    zoneId = json['zoneId'] ?? '';
    rotation = json['rotation'];
    appIdentifier = json['appIdentifier'];
    provider = json['provider'];
    subscriptionPlanId = json['subscriptionPlanId'];

    // Handle subscriptionExpiryDate
    if (json['subscriptionExpiryDate'] != null) {
      if (json['subscriptionExpiryDate'] is Timestamp) {
        subscriptionExpiryDate = json['subscriptionExpiryDate'];
      } else if (json['subscriptionExpiryDate'] is int) {
        subscriptionExpiryDate = Timestamp.fromMillisecondsSinceEpoch(json['subscriptionExpiryDate']);
      } else if (json['subscriptionExpiryDate'] is String) {
        // Try parsing as milliseconds string first (e.g., "1764675379043")
        final milliseconds = int.tryParse(json['subscriptionExpiryDate']);
        if (milliseconds != null) {
          subscriptionExpiryDate = Timestamp.fromMillisecondsSinceEpoch(milliseconds);
        } else {
          // Try parsing as ISO8601 string
          try {
            final dateTime = DateTime.parse(json['subscriptionExpiryDate']);
            subscriptionExpiryDate = Timestamp.fromDate(dateTime);
          } catch (e) {
            subscriptionExpiryDate = null;
          }
        }
      } else if (json['subscriptionExpiryDate'] is Map) {
        try {
          subscriptionExpiryDate = Timestamp(
            json['subscriptionExpiryDate']['seconds'] ?? 0,
            json['subscriptionExpiryDate']['nanoseconds'] ?? 0,
          );
        } catch (e) {
          subscriptionExpiryDate = null;
        }
      }
    } else {
      subscriptionExpiryDate = null;
    }

    // Handle subscription_plan
    if (json['subscription_plan'] != null) {
      if (json['subscription_plan'] is Map<String, dynamic>) {
        subscriptionPlan = SubscriptionPlanModel.fromJson(json['subscription_plan'] as Map<String, dynamic>);
      } else if (json['subscription_plan'] is String) {
        // If it's just a string, create a basic SubscriptionPlanModel
        subscriptionPlan = SubscriptionPlanModel(
          id: 'temp_id',
          name: json['subscription_plan'] as String,
          // Add other default values as needed
        );
      } else {
        subscriptionPlan = null;
      }
    } else {
      subscriptionPlan = null;
    }
  }

  /// Safely parse a list that may come as:
  /// - List
  /// - JSON String (e.g., "[]" or "[1,2,3]")
  /// - or null
  List<dynamic>? _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is String) {
      try {
        // Try to parse as JSON string
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {
        // If parsing fails, return empty list
        return [];
      }
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['firebase_id'] = firebaseId;
    data['email'] = email;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['profilePictureURL'] = profilePictureURL;
    data['fcmToken'] = fcmToken;
    data['countryCode'] = countryCode;
    data['phoneNumber'] = phoneNumber;
    data['wallet_amount'] = walletAmount ?? 0;
    data['deliveryAmount'] = deliveryAmount ?? 0;
    data['createdAt'] = createdAt;
    data['active'] = active;
    data['isActive'] = isActive;
    data['role'] = role;
    data['isDocumentVerify'] = isDocumentVerify;
    data['zoneId'] = zoneId;
    if (location != null) {
      data['location'] = location!.toJson();
    }

    if (userBankDetails != null) {
      data['userBankDetails'] = userBankDetails!.toJson();
    }

    if (shippingAddress != null) {
      data['shippingAddress'] = shippingAddress!.map((v) => v.toJson()).toList();
    }

    if (role == Constant.userRoleDriver) {
      data['vendorID'] = vendorID;
      data['carName'] = carName;
      data['carNumber'] = carNumber;
      data['carPictureURL'] = carPictureURL;
      data['inProgressOrderID'] = inProgressOrderID;
      data['orderRequestData'] = orderRequestData;
      data['rotation'] = rotation;
    }

    if (role == Constant.userRoleVendor) {
      data['vendorID'] = vendorID;
      data['subscriptionPlanId'] = subscriptionPlanId;
      data['subscriptionExpiryDate'] = subscriptionExpiryDate;
      data['subscription_plan'] = subscriptionPlan?.toJson();
    }

    data['appIdentifier'] = appIdentifier;
    data['provider'] = provider;

    return data;
  }
}

class UserLocation {
  double? latitude;
  double? longitude;

  UserLocation({this.latitude, this.longitude});

  UserLocation.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class ShippingAddress {
  String? id;
  String? address;
  String? addressAs;
  String? landmark;
  String? locality;
  UserLocation? location;
  bool? isDefault;

  ShippingAddress({
    this.address,
    this.landmark,
    this.locality,
    this.location,
    this.isDefault,
    this.addressAs,
    this.id
  });

  ShippingAddress.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    address = json['address'];
    landmark = json['landmark'];
    locality = json['locality'];
    isDefault = json['isDefault'];
    addressAs = json['addressAs'];
    location = json['location'] == null
        ? null
        : UserLocation.fromJson(json['location']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['address'] = address;
    data['landmark'] = landmark;
    data['locality'] = locality;
    data['isDefault'] = isDefault;
    data['addressAs'] = addressAs;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    return data;
  }

  String getFullAddress() {
    return '${address == null || address!.isEmpty ? "" : address} $locality ${landmark == null || landmark!.isEmpty ? "" : landmark.toString()}';
  }
}

class UserBankDetails {
  String bankName;
  String branchName;
  String holderName;
  String accountNumber;
  String otherDetails;

  UserBankDetails({
    this.bankName = '',
    this.otherDetails = '',
    this.branchName = '',
    this.accountNumber = '',
    this.holderName = '',
  });

  factory UserBankDetails.fromJson(Map<String, dynamic> parsedJson) {
    return UserBankDetails(
      bankName: parsedJson['bankName'] ?? '',
      branchName: parsedJson['branchName'] ?? '',
      holderName: parsedJson['holderName'] ?? '',
      accountNumber: parsedJson['accountNumber'] ?? '',
      otherDetails: parsedJson['otherDetails'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'branchName': branchName,
      'holderName': holderName,
      'accountNumber': accountNumber,
      'otherDetails': otherDetails,
    };
  }
}