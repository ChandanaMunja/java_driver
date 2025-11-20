// Centralized logging utility for the app
import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[${tag ?? "LOG"}] $timestamp -> $message');
  }
} 