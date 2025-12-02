import 'dart:convert';

class CartProductModel {
  String? id;
  String? categoryId;
  String? name;
  String? photo;
  String? price;
  String? discountPrice;
  String? vendorID;
  int? quantity;
  String? extrasPrice;
  List<dynamic>? extras;
  VariantInfo? variantInfo;

  CartProductModel({
    this.id,
    this.categoryId,
    this.name,
    this.photo,
    this.price,
    this.discountPrice,
    this.vendorID,
    this.quantity,
    this.extrasPrice,
    this.variantInfo,
    this.extras,
  });

  CartProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    categoryId = json['category_id']?.toString();
    name = json['name'];
    photo = json['photo'];
    price = json['price']?.toString() ?? "0.0";
    discountPrice = json['discountPrice']?.toString() ?? "0.0";
    vendorID = json['vendorID']?.toString();
    quantity = json['quantity'];
    extrasPrice = json['extras_price']?.toString();

    extras = json['extras'] != null
        ? "String" == json['extras'].runtimeType.toString()
            ? List<dynamic>.from(jsonDecode(json['extras']))
            : List<dynamic>.from(json['extras'])
        : null;

    variantInfo = null;
    if (json['variant_info'] != null) {
      if (json['variant_info'] is String) {
        variantInfo = VariantInfo.fromJson(jsonDecode(json['variant_info']));
      } else if (json['variant_info'] is Map<String, dynamic>) {
        variantInfo = VariantInfo.fromJson(json['variant_info']);
      } else if (json['variant_info'] is List) {
        variantInfo = null;
      }
    }

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['category_id'] = categoryId;
    data['name'] = name;
    data['photo'] = photo;
    data['price'] = price;
    data['discountPrice'] = discountPrice;
    data['vendorID'] = vendorID;
    data['quantity'] = quantity;
    data['extras_price'] = extrasPrice;
    data['extras'] = extras;
    if (variantInfo != null) {
      data['variant_info'] = variantInfo?.toJson(); // Handle null value
    }
    return data;
  }
}

class VariantInfo {
  String? variantId;
  String? variantPrice;
  String? variantSku;
  String? variantImage;
  Map<String, dynamic>? variantOptions;

  VariantInfo({this.variantId, this.variantPrice, this.variantSku, this.variantImage, this.variantOptions});

  VariantInfo.fromJson(Map<String, dynamic> json) {
    variantId = json['variant_id']?.toString() ?? '';
    variantPrice = json['variant_price']?.toString() ?? '';
    variantSku = json['variant_sku']?.toString() ?? '';
    variantImage = json['variant_image']?.toString() ?? '';
    // Handle variantOptions safely
    if (json['variant_options'] is Map<String, dynamic>) {
      variantOptions = Map<String, dynamic>.from(json['variant_options']);
    } else {
      variantOptions = {}; // If it's a List or null, default to empty Map
    }
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['variant_id'] = variantId;
    data['variant_price'] = variantPrice;
    data['variant_sku'] = variantSku;
    data['variant_image'] = variantImage;
    data['variant_options'] = variantOptions;
    return data;
  }
}
