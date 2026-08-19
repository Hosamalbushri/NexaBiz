import 'package:sentry_flutter/sentry_flutter.dart';

import 'crash_reporting_config.dart';

/// Bridges local [AppErrorLog] to optional Sentry when configured.
class CrashReporting {
  CrashReporting._();

  static CrashReportingConfig _config = const CrashReportingConfig(
    dsn: '',
    enabled: false,
    environment: 'development',
  );

  static bool get isEnabled => _config.isEnabled;

  static void configure(CrashReportingConfig config) {
    _config = config;
  }

  static Future<void> captureException(
    Object error,
    StackTrace? stack, {
    String source = 'app',
  }) async {
    if (!_config.isEnabled) {
      return;
    }
    try {
      await Sentry.captureException(
        error,
        stackTrace: stack,
        hint: Hint.withMap({'source': source}),
      );
    } catch (_) {
      // Never throw from crash forwarding.
    }
  }
}
