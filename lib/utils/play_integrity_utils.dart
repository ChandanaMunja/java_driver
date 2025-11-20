import 'dart:developer';
import 'package:jippydriver_driver/controllers/play_integrity_controller.dart';
import 'package:jippydriver_driver/services/play_integrity_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlayIntegrityUtils {
  /// Verify integrity before performing any sensitive operation
  static Future<bool> verifyBeforeSensitiveOperation(String operationName) async {
    print('🔐 [Play Integrity Utils] Verifying before sensitive operation: $operationName');
    
    try {
      print('🔐 [Play Integrity Utils] Looking for PlayIntegrityController...');
      final controller = Get.find<PlayIntegrityController>();
      print('🔐 [Play Integrity Utils] ✅ Controller found, calling verifyBeforeOperation...');
      return await controller.verifyBeforeOperation(operationName);
    } catch (e) {
      print('🔐 [Play Integrity Utils] ❌ Controller not found or error occurred');
      print('🔐 [Play Integrity Utils] Error: $e');
      print('🔐 [Play Integrity Utils] Error type: ${e.runtimeType}');
      log('Play Integrity: Error in verifyBeforeSensitiveOperation - $e');
      
      print('🔐 [Play Integrity Utils] Falling back to direct service call...');
      // If controller is not found, use service directly
      final result = await PlayIntegrityService.verifyDeviceIntegrity();
      print('🔐 [Play Integrity Utils] Direct service call result: $result');
      return result;
    }
  }

  /// Verify integrity before payment operations
  static Future<bool> verifyBeforePayment() async {
    return await verifyBeforeSensitiveOperation('Payment');
  }

  /// Verify integrity before authentication operations
  static Future<bool> verifyBeforeAuth() async {
    return await verifyBeforeSensitiveOperation('Authentication');
  }

  /// Verify integrity before order operations
  static Future<bool> verifyBeforeOrder() async {
    return await verifyBeforeSensitiveOperation('Order');
  }

  /// Verify integrity before wallet operations
  static Future<bool> verifyBeforeWallet() async {
    return await verifyBeforeSensitiveOperation('Wallet');
  }

  /// Verify integrity before profile operations
  static Future<bool> verifyBeforeProfile() async {
    return await verifyBeforeSensitiveOperation('Profile');
  }

  /// Get current integrity status
  static bool get isIntegrityVerified {
    try {
      final controller = Get.find<PlayIntegrityController>();
      return controller.isIntegrityVerified.value;
    } catch (e) {
      return PlayIntegrityService.isIntegrityVerified;
    }
  }

  /// Get current integrity token
  static String? get currentToken {
    try {
      final controller = Get.find<PlayIntegrityController>();
      return controller.currentToken.isNotEmpty ? controller.currentToken : null;
    } catch (e) {
      return PlayIntegrityService.lastIntegrityToken;
    }
  }

  /// Show integrity status in a snackbar
  static void showIntegrityStatus() {
    try {
      final controller = Get.find<PlayIntegrityController>();
      final status = controller.isIntegrityVerified.value ? 'Verified' : 'Failed';
      final color = controller.isIntegrityVerified.value ? Colors.green : Colors.red;
      
      Get.snackbar(
        'Device Integrity',
        'Status: $status',
        backgroundColor: color.withOpacity(0.1),
        colorText: color,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      log('Play Integrity: Error showing status - $e');
    }
  }

  /// Force refresh integrity and show result
  static Future<void> refreshAndShowStatus() async {
    try {
      final controller = Get.find<PlayIntegrityController>();
      await controller.refreshIntegrity();
      showIntegrityStatus();
    } catch (e) {
      log('Play Integrity: Error refreshing status - $e');
    }
  }

  /// Check if integrity check is required for the current operation
  static bool isIntegrityRequired(String operationType) {
    // Define which operations require integrity checks
    const sensitiveOperations = [
      'payment',
      'auth',
      'order',
      'wallet',
      'profile',
      'withdraw',
      'bank_details',
    ];
    
    return sensitiveOperations.contains(operationType.toLowerCase());
  }

  /// Log integrity check for debugging
  static void logIntegrityCheck(String operation, bool isVerified) {
    print('🔐 [Play Integrity Utils] Integrity Check Log: $operation - ${isVerified ? "✅ ALLOWED" : "❌ BLOCKED"}');
    log('Play Integrity: $operation - ${isVerified ? "ALLOWED" : "BLOCKED"}');
  }
} 