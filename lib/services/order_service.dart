import 'package:cloud_functions/cloud_functions.dart';
Future<Map<String, dynamic>> assignOrderToDriverFCFS(String orderId, String driverId) async {
  try {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('assignOrderToDriverFCFS');
    final result = await callable.call({'orderId': orderId, 'driverId': driverId});
    return Map<String, dynamic>.from(result.data);
  } catch (e) {
    return {
      'success': false,
      'reason': 'Failed to assign order. Please try again.\nError: $e',
    };
  }
}