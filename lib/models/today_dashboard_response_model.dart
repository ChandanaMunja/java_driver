class TodayDashboardResponse {
  final bool success;
  final TodayDashboardData? data;
  final String? message;

  const TodayDashboardResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory TodayDashboardResponse.fromJson(Map<String, dynamic> json) {
    return TodayDashboardResponse(
      success: json['success'] == true,
      data: json['data'] is Map<String, dynamic>
          ? TodayDashboardData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }
}

class TodayDashboardData {
  final int totalOrdersToday;
  final double totalEarningsToday;
  final String? currency;
  final String? date; // "YYYY-MM-DD" in server timezone

  const TodayDashboardData({
    required this.totalOrdersToday,
    required this.totalEarningsToday,
    this.currency,
    this.date,
  });

  factory TodayDashboardData.fromJson(Map<String, dynamic> json) {
    return TodayDashboardData(
      totalOrdersToday: _toInt(json['total_orders_today']),
      totalEarningsToday: _toDouble(json['total_earnings_today']),
      currency: json['currency']?.toString(),
      date: json['date']?.toString(),
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? 0;
}

