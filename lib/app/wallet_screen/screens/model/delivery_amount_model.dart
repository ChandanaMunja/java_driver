import 'package:cloud_firestore/cloud_firestore.dart';

class DriverAmountWalletTransactionModel {
  String? id;
  String? driverId;
  String? zoneId;
  double? totalEarnings;
  bool? bonus;
  String? type;
  Timestamp? date;
  int? bonusAmount;

  DriverAmountWalletTransactionModel({
    this.id,
    this.driverId,
    this.zoneId,
    this.totalEarnings,
    this.bonus,
    this.type,
    this.date,
    this.bonusAmount
  });

  DriverAmountWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driverId = json['driverId'];
    zoneId = json['zoneId'];
    totalEarnings = double.parse("${json['totalEarnings'] ?? 0.0}");
    bonus = json['bonus'];
    type = json['type'];
    date = json['date'];
    bonusAmount = json['bonusAmount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['driverId'] = driverId;
    data['zoneId'] = zoneId;
    data['totalEarnings'] = totalEarnings;
    data['bonus'] = bonus;
    data['type'] = type;
    data['date'] = date;
    data['bonusAmount'] = bonusAmount;
    return data;
  }
}
