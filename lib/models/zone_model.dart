import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  List<GeoPoint>? area;
  bool? publish;
  double? latitude;
  String? name;
  String? id;
  double? longitude;
  String? pickupCharges;
  String? userDeliveryCharge;
  ZoneModel(
      {this.area,
        this.publish,
        this.latitude,
        this.name,
        this.id,
        this.longitude,this.pickupCharges,this.userDeliveryCharge});

  ZoneModel.fromJson(Map<String, dynamic> json) {
    if (json['area'] != null) {
      area = <GeoPoint>[];
      json['area'].forEach((v) {
        area!.add(v);
      });
    }
    publish = json['publish'];
    latitude = json['latitude'];
    name = json['name'];
    id = json['id'];
    longitude = json['longitude'];
    pickupCharges = json['pickup_charges'];
    userDeliveryCharge = json['user_delivery_charge'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (area != null) {
      data['area'] = area!.map((v) => v).toList();
    }
    data['publish'] = publish;
    data['latitude'] = latitude;
    data['name'] = name;
    data['id'] = id;
    data['longitude'] = longitude;
     data['pickup_charges'] = pickupCharges;
  data['user_delivery_charge'] = userDeliveryCharge;
    return data;
  }
}
