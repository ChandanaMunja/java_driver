import 'package:cloud_firestore/cloud_firestore.dart';

class DriverAmountWalletTransactionModel {
  String? id;
  String? driverId;
  String? zoneId;
  double? totalEarnings;
  double? credit;
  double? debit;
  bool? bonus;
  String? type;
  Timestamp? date;
  int? bonusAmount;

  DriverAmountWalletTransactionModel({
    this.id,
    this.driverId,
    this.zoneId,
    this.totalEarnings,
    this.credit,
    this.debit,
    this.bonus,
    this.type,
    this.date,
    this.bonusAmount
  });

  DriverAmountWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    driverId = json['driverId'];
    zoneId = json['zoneId'];
    credit = _toDouble(json['credit']);
    debit = _toDouble(json['debit']);
    final dynamic rawTotal = json['totalEarnings'] ?? json['total_earnings'];
    if (rawTotal != null) {
      totalEarnings = _toDouble(rawTotal);
    } else {
      // New COD API sends split values; keep old field compatible.
      totalEarnings = (debit ?? 0.0) - (credit ?? 0.0);
    }
    bonus = json['bonus'];
    type = json['type'];
    date = _parseTimestamp(json['date']);
    bonusAmount = json['bonusAmount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['driverId'] = driverId;
    data['zoneId'] = zoneId;
    data['totalEarnings'] = totalEarnings;
    data['credit'] = credit;
    data['debit'] = debit;
    data['bonus'] = bonus;
    data['type'] = type;
    data['date'] = date;
    data['bonusAmount'] = bonusAmount;
    return data;
  }

  bool get isCredit {
    if ((credit ?? 0.0) > 0) return true;
    return (totalEarnings ?? 0.0) > 0;
  }

  bool get isDebit {
    if ((debit ?? 0.0) > 0) return true;
    return (totalEarnings ?? 0.0) < 0;
  }

  double get displayAmount {
    if ((credit ?? 0.0) > 0) return credit ?? 0.0;
    if ((debit ?? 0.0) > 0) return debit ?? 0.0;
    return (totalEarnings ?? 0.0).abs();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return Timestamp.fromDate(parsed);
    }
    return null;
  }
}

class DriverAmountWalletSummary {
  final double totalCodAmount;

  DriverAmountWalletSummary({required this.totalCodAmount});

  factory DriverAmountWalletSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DriverAmountWalletSummary(totalCodAmount: 0.0);
    }
    final raw = json['total_cod_amount'];
    final amount = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0.0;
    return DriverAmountWalletSummary(totalCodAmount: amount);
  }
}

class DriverAmountWalletPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  DriverAmountWalletPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
  });

  factory DriverAmountWalletPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DriverAmountWalletPagination(
        total: 0,
        perPage: 10,
        currentPage: 1,
        lastPage: 1,
        hasMore: false,
      );
    }
    return DriverAmountWalletPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      perPage: (json['per_page'] as num?)?.toInt() ?? 10,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      hasMore: json['has_more'] == true,
    );
  }
}

class DriverAmountWalletApiResponse {
  final bool success;
  final List<DriverAmountWalletTransactionModel> data;
  final DriverAmountWalletSummary summary;
  final DriverAmountWalletPagination pagination;
  final String? message;

  DriverAmountWalletApiResponse({
    required this.success,
    required this.data,
    required this.summary,
    required this.pagination,
    this.message,
  });

  factory DriverAmountWalletApiResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final records = <DriverAmountWalletTransactionModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          records.add(DriverAmountWalletTransactionModel.fromJson(item));
        }
      }
    }
    records.sort((a, b) {
      final dateA = a.date;
      final dateB = b.date;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return DriverAmountWalletApiResponse(
      success: json['success'] == true,
      data: records,
      summary: DriverAmountWalletSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      pagination: DriverAmountWalletPagination.fromJson(json['pagination'] as Map<String, dynamic>?),
      message: json['message']?.toString(),
    );
  }
}
