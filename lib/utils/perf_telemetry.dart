import 'package:jippydriver_driver/utils/app_logger.dart';

/// Lightweight in-memory performance counters aggregated per minute.
///
/// This is intentionally simple (no external deps) and intended for log-driven
/// tuning of intervals/thresholds.
class PerfTelemetry {
  PerfTelemetry._();

  // Enable/disable globally without touching call sites.
  static const bool enabled = true;

  static const _minuteMs = 60 * 1000;
  static int _bucket = DateTime.now().millisecondsSinceEpoch ~/ _minuteMs;
  static final Map<String, int> _counts = {};

  static void inc(String metric, [int delta = 1]) {
    if (!enabled || delta == 0) return;

    final nowBucket = DateTime.now().millisecondsSinceEpoch ~/ _minuteMs;
    if (nowBucket != _bucket) {
      _flush();
      _bucket = nowBucket;
    }

    _counts[metric] = (_counts[metric] ?? 0) + delta;
  }

  static void _flush() {
    if (_counts.isEmpty) return;
    AppLogger.log(
      '[PerfTelemetry] bucket=$_bucket counts=$_counts',
      tag: 'Perf',
    );
    _counts.clear();
  }
}

