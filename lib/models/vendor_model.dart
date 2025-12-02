import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippydriver_driver/models/admin_commission.dart';
import 'package:jippydriver_driver/models/subscription_plan_model.dart';

class VendorModel {
  String? author;
  bool? dineInActive;
  String? openDineTime;
  List<dynamic>? categoryID;
  String? id;
  String? categoryPhoto;
  List<dynamic>? restaurantMenuPhotos;
  List<WorkingHours>? workingHours;
  String? location;
  String? fcmToken;
  G? g;
  bool? hidephotos;
  bool? reststatus;
  Filters? filters;
  AdminCommission? adminCommission;
  String? photo;
  String? description;
  num? walletAmount;
  String? closeDineTime;
  String? zoneId;
  Timestamp? createdAt;
  double? longitude;
  bool? enabledDiveInFuture;
  String? restaurantCost;
  DeliveryCharge? deliveryCharge;
  String? authorProfilePic;
  String? authorName;
  String? phonenumber;
  List<SpecialDiscount>? specialDiscount;
  bool? specialDiscountEnable;
  GeoPoint? coordinates;
  num? reviewsSum;
  num? reviewsCount;
  List<dynamic>? photos;
  String? title;
  List<dynamic>? categoryTitle;
  double? latitude;
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  SubscriptionPlanModel? subscriptionPlan;
  String? subscriptionTotalOrders;
  bool? isSelfDelivery;

  VendorModel({
    this.author,
    this.dineInActive,
    this.openDineTime,
    this.categoryID,
    this.id,
    this.categoryPhoto,
    this.restaurantMenuPhotos,
    this.workingHours,
    this.location,
    this.fcmToken,
    this.g,
    this.hidephotos,
    this.reststatus,
    this.filters,
    this.reviewsCount,
    this.photo,
    this.description,
    this.walletAmount,
    this.closeDineTime,
    this.zoneId,
    this.createdAt,
    this.longitude,
    this.enabledDiveInFuture,
    this.restaurantCost,
    this.deliveryCharge,
    this.adminCommission,
    this.authorProfilePic,
    this.authorName,
    this.phonenumber,
    this.specialDiscount,
    this.specialDiscountEnable,
    this.coordinates,
    this.reviewsSum,
    this.photos,
    this.title,
    this.categoryTitle,
    this.latitude,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionPlan,
    this.subscriptionTotalOrders,
    this.isSelfDelivery,
  });

  VendorModel.fromJson(Map<String, dynamic> json) {
    author = json['author'];
    dineInActive = json['dine_in_active'];
    openDineTime = json['openDineTime'];
    categoryID = _parseList(json['categoryID']);
    id = json['id'];
    categoryPhoto = json['categoryPhoto'];
    restaurantMenuPhotos = _parseList(json['restaurantMenuPhotos']);
    if (json['workingHours'] != null) {
      workingHours = <WorkingHours>[];
      json['workingHours'].forEach((v) {
        workingHours!.add(WorkingHours.fromJson(v));
      });
    }
    location = json['location'];
    fcmToken = json['fcmToken'];
    g = json['g'] != null ? G.fromJson(json['g']) : null;
    hidephotos = json['hidephotos'];
    reststatus = json['reststatus'];
    filters =
        json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    reviewsCount = json['reviewsCount'] ?? 0.0;
    photo = json['photo'];
    description = json['description'];
    walletAmount = json['walletAmount'];
    closeDineTime = json['closeDineTime'];
    zoneId = json['zoneId'];
    createdAt = _parseTimestamp(json['createdAt']);
    longitude = double.parse(json['longitude'].toString());
    enabledDiveInFuture = json['enabledDiveInFuture'];
    restaurantCost = json['restaurantCost']?.toString();
    deliveryCharge = json['DeliveryCharge'] != null
        ? DeliveryCharge.fromJson(json['DeliveryCharge'])
        : null;
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null;
    authorProfilePic = json['authorProfilePic'];
    authorName = json['authorName'];
    phonenumber = json['phonenumber']?.toString();
    if (json['specialDiscount'] != null) {
      specialDiscount = <SpecialDiscount>[];
      json['specialDiscount'].forEach((v) {
        specialDiscount!.add(SpecialDiscount.fromJson(v));
      });
    }
    specialDiscountEnable = json['specialDiscountEnable'];
    // Handle coordinates coming as Map or GeoPoint
    if (json['coordinates'] != null) {
      if (json['coordinates'] is GeoPoint) {
        coordinates = json['coordinates'];
      } else if (json['coordinates'] is Map<String, dynamic>) {
        final coordMap = json['coordinates'] as Map<String, dynamic>;
        final lat = coordMap['latitude'] ?? coordMap['_latitude'];
        final lng = coordMap['longitude'] ?? coordMap['_longitude'];
        if (lat != null && lng != null) {
          coordinates = GeoPoint(
            lat is double ? lat : double.parse(lat.toString()),
            lng is double ? lng : double.parse(lng.toString()),
          );
        }
      }
    }
    reviewsSum = json['reviewsSum'] ?? 0.0;
    photos = _parseList(json['photos']);
    title = json['title'];
    latitude = double.parse(json['latitude'].toString());
    subscriptionPlanId = json['subscriptionPlanId'];
    subscriptionExpiryDate = _parseTimestamp(json['subscriptionExpiryDate']);
    subscriptionPlan = json['subscription_plan'] != null
        ? SubscriptionPlanModel.fromJson(json['subscription_plan'])
        : null;
    subscriptionTotalOrders = json['subscriptionTotalOrders'];
    isSelfDelivery = json['isSelfDelivery'];
    // Handle categoryTitle - can be String or List
    categoryTitle = _parseList(json['categoryTitle']);
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
    data['author'] = author;
    data['dine_in_active'] = dineInActive;
    data['openDineTime'] = openDineTime;
    data['categoryID'] = categoryID;
    data['id'] = id;
    data['categoryPhoto'] = categoryPhoto;
    data['restaurantMenuPhotos'] = restaurantMenuPhotos;
    data['subscriptionPlanId'] = subscriptionPlanId;
    data['subscriptionExpiryDate'] = subscriptionExpiryDate;
    data['subscription_plan'] = subscriptionPlan?.toJson();
    if (workingHours != null) {
      data['workingHours'] = workingHours!.map((v) => v.toJson()).toList();
    }
    data['location'] = location;
    data['fcmToken'] = fcmToken;
    if (g != null) {
      data['g'] = g!.toJson();
    }
    data['hidephotos'] = hidephotos;
    data['reststatus'] = reststatus;
    if (filters != null) {
      data['filters'] = filters!.toJson();
    }
    data['reviewsCount'] = reviewsCount;
    data['photo'] = photo;
    data['description'] = description;
    data['walletAmount'] = walletAmount;
    data['closeDineTime'] = closeDineTime;
    data['zoneId'] = zoneId;
    data['createdAt'] = createdAt;
    data['longitude'] = longitude;
    data['enabledDiveInFuture'] = enabledDiveInFuture;
    data['restaurantCost'] = restaurantCost;
    if (deliveryCharge != null) {
      data['DeliveryCharge'] = deliveryCharge!.toJson();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    data['authorProfilePic'] = authorProfilePic;
    data['authorName'] = authorName;
    data['phonenumber'] = phonenumber;
    if (specialDiscount != null) {
      data['specialDiscount'] =
          specialDiscount!.map((v) => v.toJson()).toList();
    }
    data['specialDiscountEnable'] = specialDiscountEnable;
    data['coordinates'] = coordinates;
    data['reviewsSum'] = reviewsSum;
    data['photos'] = photos;
    data['title'] = title;
    data['categoryTitle'] = categoryTitle;
    data['latitude'] = latitude;
    data['subscriptionTotalOrders'] = subscriptionTotalOrders;
    data['isSelfDelivery'] = isSelfDelivery;
    return data;
  }
}

class WorkingHours {
  String? day;
  List<Timeslot>? timeslot;

  WorkingHours({this.day, this.timeslot});

  WorkingHours.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    if (json['timeslot'] != null) {
      timeslot = <Timeslot>[];
      json['timeslot'].forEach((v) {
        timeslot!.add(Timeslot.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    if (timeslot != null) {
      data['timeslot'] = timeslot!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Timeslot {
  String? to;
  String? from;

  Timeslot({this.to, this.from});

  Timeslot.fromJson(Map<String, dynamic> json) {
    to = json['to'];
    from = json['from'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['to'] = to;
    data['from'] = from;
    return data;
  }
}

class G {
  String? geohash;
  GeoPoint? geopoint;

  G({this.geohash, this.geopoint});

  G.fromJson(Map<String, dynamic> json) {
    geohash = json['geohash'];
    // Handle geopoint coming as Map or GeoPoint
    if (json['geopoint'] != null) {
      if (json['geopoint'] is GeoPoint) {
        geopoint = json['geopoint'];
      } else if (json['geopoint'] is Map<String, dynamic>) {
        final geoMap = json['geopoint'] as Map<String, dynamic>;
        final lat = geoMap['latitude'] ?? geoMap['_latitude'];
        final lng = geoMap['longitude'] ?? geoMap['_longitude'];
        if (lat != null && lng != null) {
          geopoint = GeoPoint(
            lat is double ? lat : double.parse(lat.toString()),
            lng is double ? lng : double.parse(lng.toString()),
          );
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['geohash'] = geohash;
    data['geopoint'] = geopoint;
    return data;
  }
}

class Filters {
  String? goodForLunch;
  String? outdoorSeating;
  String? liveMusic;
  String? vegetarianFriendly;
  String? goodForDinner;
  String? goodForBreakfast;
  String? freeWiFi;
  String? takesReservations;

  Filters(
      {this.goodForLunch,
      this.outdoorSeating,
      this.liveMusic,
      this.vegetarianFriendly,
      this.goodForDinner,
      this.goodForBreakfast,
      this.freeWiFi,
      this.takesReservations});

  Filters.fromJson(Map<String, dynamic> json) {
    goodForLunch = json['Good for Lunch'];
    outdoorSeating = json['Outdoor Seating'];
    liveMusic = json['Live Music'];
    vegetarianFriendly = json['Vegetarian Friendly'];
    goodForDinner = json['Good for Dinner'];
    goodForBreakfast = json['Good for Breakfast'];
    freeWiFi = json['Free Wi-Fi'];
    takesReservations = json['Takes Reservations'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Good for Lunch'] = goodForLunch;
    data['Outdoor Seating'] = outdoorSeating;
    data['Live Music'] = liveMusic;
    data['Vegetarian Friendly'] = vegetarianFriendly;
    data['Good for Dinner'] = goodForDinner;
    data['Good for Breakfast'] = goodForBreakfast;
    data['Free Wi-Fi'] = freeWiFi;
    data['Takes Reservations'] = takesReservations;
    return data;
  }
}

class DeliveryCharge {
  num? minimumDeliveryChargesWithinKm;
  num? minimumDeliveryCharges;
  num? deliveryChargesPerKm;
  bool? vendorCanModify;

  DeliveryCharge(
      {this.minimumDeliveryChargesWithinKm,
      this.minimumDeliveryCharges,
      this.deliveryChargesPerKm,
      this.vendorCanModify});

  DeliveryCharge.fromJson(Map<String, dynamic> json) {
    minimumDeliveryChargesWithinKm = json['minimum_delivery_charges_within_km'];
    minimumDeliveryCharges = json['minimum_delivery_charges'];
    deliveryChargesPerKm = json['delivery_charges_per_km'];
    vendorCanModify = json['vendor_can_modify'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['minimum_delivery_charges_within_km'] = minimumDeliveryChargesWithinKm;
    data['minimum_delivery_charges'] = minimumDeliveryCharges;
    data['delivery_charges_per_km'] = deliveryChargesPerKm;
    data['vendor_can_modify'] = vendorCanModify;
    return data;
  }
}

class SpecialDiscount {
  String? day;
  List<SpecialDiscountTimeslot>? timeslot;

  SpecialDiscount({this.day, this.timeslot});

  SpecialDiscount.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    if (json['timeslot'] != null) {
      timeslot = <SpecialDiscountTimeslot>[];
      json['timeslot'].forEach((v) {
        timeslot!.add(SpecialDiscountTimeslot.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    if (timeslot != null) {
      data['timeslot'] = timeslot!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SpecialDiscountTimeslot {
  String? discount;
  String? discountType;
  String? to;
  String? type;
  String? from;

  SpecialDiscountTimeslot(
      {this.discount, this.discountType, this.to, this.type, this.from});

  SpecialDiscountTimeslot.fromJson(Map<String, dynamic> json) {
    discount = json['discount'];
    discountType = json['discount_type'];
    to = json['to'];
    type = json['type'];
    from = json['from'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['to'] = to;
    data['type'] = type;
    data['from'] = from;
    return data;
  }
}
