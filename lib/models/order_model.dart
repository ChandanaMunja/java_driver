import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippydriver_driver/models/cart_product_model.dart';
import 'package:jippydriver_driver/models/tax_model.dart';
import 'package:jippydriver_driver/models/user_model.dart';
import 'package:jippydriver_driver/models/vendor_model.dart';

class OrderModel {
  ShippingAddress? address;
  String? status;
  String? couponId;
  String? vendorID;
  String? driverID;
  num? discount;
  String? authorID;
  String? estimatedTimeToPrepare;
  Timestamp? createdAt;
  Timestamp? triggerDelivery;
  List<TaxModel>? taxSetting;
  String? paymentMethod;
  List<CartProductModel>? products;
  String? adminCommissionType;
  VendorModel? vendor;
  String? id;
  String? adminCommission;
  String? couponCode;
  Map<String, dynamic>? specialDiscount;
  String? deliveryCharge;
  Timestamp? scheduleTime;
  String? tipAmount;
  String? notes;
  UserModel? author;
  UserModel? driver;
  bool? takeAway;
  List<dynamic>? rejectedByDrivers;
  String? toPay;
  Map<String, dynamic>? calculatedCharges;

  OrderModel({
    this.address,
    this.status,
    this.couponId,
    this.vendorID,
    this.driverID,
    this.discount,
    this.authorID,
    this.estimatedTimeToPrepare,
    this.createdAt,
    this.triggerDelivery,
    this.taxSetting,
    this.paymentMethod,
    this.products,
    this.adminCommissionType,
    this.vendor,
    this.id,
    this.adminCommission,
    this.couponCode,
    this.specialDiscount,
    this.deliveryCharge,
    this.scheduleTime,
    this.tipAmount,
    this.notes,
    this.author,
    this.driver,
    this.takeAway,
    this.rejectedByDrivers,
    this.toPay,
    this.calculatedCharges,
  });

  OrderModel.fromJson(Map<String, dynamic> json) {
    address = json['address'] != null ? ShippingAddress.fromJson(json['address']) : null;
    status = json['status'];
    couponId = json['couponId'];
    vendorID = json['vendorID']?.toString();
    driverID = json['driverID']?.toString();
    // Handle discount coming as string, int, double or null from API
    discount = _parseNum(json['discount']);
    authorID = json['authorID']?.toString();
    estimatedTimeToPrepare = json['estimatedTimeToPrepare'];
    // Handle createdAt coming from Firestore Timestamp, milliseconds, or null
    createdAt = _parseTimestamp(json['createdAt']);
    // Some APIs/collections use "triggerDelevery" (typo) – keep backward compatible
    triggerDelivery = _parseTimestamp(json['triggerDelevery'] ?? json['triggerDelivery']) ?? Timestamp.now();
    if (json['taxSetting'] != null) {
      taxSetting = <TaxModel>[];
      json['taxSetting'].forEach((v) {
        taxSetting!.add(TaxModel.fromJson(v));
      });
    }
    paymentMethod = json['payment_method'];
    if (json['products'] != null) {
      products = <CartProductModel>[];
      json['products'].forEach((v) {
        products!.add(CartProductModel.fromJson(v));
      });
    }
    adminCommissionType = json['adminCommissionType'];
    // vendor = json['vendor'] != null ? VendorModel.fromJson(json['vendor']) : null;
    if (json['vendor'] is Map<String, dynamic>) {
      vendor = VendorModel.fromJson(json['vendor']);
    } else {
      vendorID = json['vendor']?.toString();
      vendor = null;
    }
    id = json['id']?.toString();
    adminCommission = json['adminCommission']?.toString();
    couponCode = json['couponCode']?.toString();
    specialDiscount = json['specialDiscount'];
    // Safely parse deliveryCharge (can be num, string, null)
    deliveryCharge = _parseNum(json['deliveryCharge'])?.toString() ?? '0.0';
    // Handle scheduleTime from Timestamp or milliseconds
    scheduleTime = _parseTimestamp(json['scheduleTime']);
    // Safely parse tip amount (can be num, string, null)
    tipAmount = _parseNum(json['tip_amount'])?.toString() ?? '0.0';
    notes = json['notes'];
    author = json['author'] != null ? UserModel.fromJson(json['author']) : null;
    driver = json['driver'] != null ? UserModel.fromJson(json['driver']) : null;
    takeAway = _parseBool(json['takeAway']);
    rejectedByDrivers = _parseList(json['rejectedByDrivers']);
    toPay = json['ToPay']?.toString();
    calculatedCharges = json['calculatedCharges'] != null
        ? Map<String, dynamic>.from(json['calculatedCharges'])
        : null;
  }
  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value == 1;
    }
    return null;
  }

  /// Safely parse a numeric value that may come as int, double, String or null.
  num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  /// Safely parse a timestamp that may come as:
  /// - Firestore [Timestamp]
  /// - millisecondsSinceEpoch (int or String)
  /// - ISO8601 String
  /// - or null
  Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is int) {
      return Timestamp.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      // Try parsing as milliseconds string (e.g., "1764675379043")
      final milliseconds = int.tryParse(value);
      if (milliseconds != null) {
        return Timestamp.fromMillisecondsSinceEpoch(milliseconds);
      }
      // Try parsing as ISO8601 string
      try {
        final dt = DateTime.tryParse(value);
        if (dt != null) {
          return Timestamp.fromDate(dt);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
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

    if (address != null) {
      data['address'] = address!.toJson();
    }

    data['status'] = status;
    data['couponId'] = couponId;
    data['vendorID'] = vendorID;
    data['driverID'] = driverID;
    data['discount'] = discount;
    data['authorID'] = authorID;
    data['estimatedTimeToPrepare'] = estimatedTimeToPrepare;

    // Convert Timestamp to milliseconds
    data['createdAt'] = createdAt?.millisecondsSinceEpoch;
    data['triggerDelivery'] = triggerDelivery?.millisecondsSinceEpoch;

    if (taxSetting != null) {
      data['taxSetting'] = taxSetting!.map((v) => v.toJson()).toList();
    }

    data['payment_method'] = paymentMethod;

    if (products != null) {
      data['products'] = products!.map((e) => e.toJson()).toList();
    }

    data['adminCommissionType'] = adminCommissionType;

    if (vendor != null) {
      // Get vendor JSON and handle GeoPoint serialization
      final vendorJson = vendor!.toJson();

      // Convert any GeoPoint objects in vendor JSON
      _convertGeoPointsInMap(vendorJson);
      data['vendor'] = vendorJson;
    }

    data['id'] = id;
    data['adminCommission'] = adminCommission;
    data['couponCode'] = couponCode;
    data['specialDiscount'] = specialDiscount;
    data['deliveryCharge'] = deliveryCharge;

    // Convert scheduleTime to milliseconds
    data['scheduleTime'] = scheduleTime?.millisecondsSinceEpoch;

    data['tip_amount'] = tipAmount;
    data['notes'] = notes;

    if (author != null) {
      data['author'] = author!.toJson();
    }

    if (driver != null) {
      data['driver'] = driver!.toJson();
    }

    data['takeAway'] = takeAway;
    data['rejectedByDrivers'] = rejectedByDrivers;
    data['ToPay'] = toPay;
    data['calculatedCharges'] = calculatedCharges;

    return data;
  }

  // Helper method to convert GeoPoint objects in a map
  void _convertGeoPointsInMap(Map<String, dynamic> map) {
    for (final key in map.keys.toList()) {
      final value = map[key];

      if (value is GeoPoint) {
        map[key] = {
          'latitude': value.latitude,
          'longitude': value.longitude,
          '_type': 'geopoint' // Optional: Add a type indicator
        };
      } else if (value is Map<String, dynamic>) {
        _convertGeoPointsInMap(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            _convertGeoPointsInMap(value[i]);
          } else if (value[i] is GeoPoint) {
            value[i] = {
              'latitude': value[i].latitude,
              'longitude': value[i].longitude,
              '_type': 'geopoint'
            };
          }
        }
      }
    }
  }
}