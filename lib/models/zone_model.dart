class ZoneModel {
  List<LatLng>? area; // Change from GeoPoint to LatLng
  bool? publish;
  double? latitude;
  String? name;
  String? id;
  double? longitude;
  String? pickupCharges;
  String? userDeliveryCharge;

  ZoneModel({
    this.area,
    this.publish,
    this.latitude,
    this.name,
    this.id,
    this.longitude,
    this.pickupCharges,
    this.userDeliveryCharge
  });

  ZoneModel.fromJson(Map<String, dynamic> json) {
    if (json['area'] != null) {
      area = <LatLng>[];
      json['area'].forEach((v) {
        // Parse latitude and longitude from the area object
        area!.add(LatLng(
            v['latitude'] ?? 0.0,
            v['longitude'] ?? 0.0
        ));
      });
    }
    publish = json['publish'] == 1 || json['publish'] == true; // Handle int/bool
    latitude = json['latitude']?.toDouble() ?? 0.0;
    name = json['name'];
    id = json['id'];
    longitude = json['longitude']?.toDouble() ?? 0.0;
    pickupCharges = json['pickup_charges'];
    userDeliveryCharge = json['user_delivery_charge'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (area != null) {
      data['area'] = area!.map((v) => {
        'latitude': v.latitude,
        'longitude': v.longitude
      }).toList();
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

// Add this LatLng model if you don't have it
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}