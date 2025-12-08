class AdminCommission {
  String? amount;
  bool? isEnabled;
  String? commissionType;

  AdminCommission({this.amount, this.isEnabled, this.commissionType});

  AdminCommission.fromJson(Map<String, dynamic> json) {
    amount = json['fix_commission']?.toString();

    // Handle bool / int / string cases safely
    final enableValue = json['isEnabled'];

    if (enableValue is bool) {
      isEnabled = enableValue;
    } else if (enableValue is int) {
      isEnabled = enableValue == 1;
    } else if (enableValue is String) {
      isEnabled = enableValue == "1" || enableValue.toLowerCase() == "true";
    } else {
      isEnabled = false;
    }

    commissionType = json['commissionType']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fix_commission'] = amount;
    data['isEnabled'] = isEnabled;
    data['commissionType'] = commissionType;
    return data;
  }
}
