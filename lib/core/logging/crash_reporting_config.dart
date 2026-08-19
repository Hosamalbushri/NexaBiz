import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Optional Sentry crash reporting (fail-closed until explicitly configured).
///
/// Production example:
/// ```bash
/// flutter build appbundle --release \
///   --dart-define=SENTRY_ENABLED=true \
///   --dart-define=SENTRY_DSN=https://xxx@o0.ingest.sentry.io/0 \
///   --dart-define=SENTRY_ENVIRONMENT=production
/// ```
class CrashReportingConfig {
  const CrashReportingConfig({
    required this.dsn,
    required this.enabled,
    required this.environment,
    this.tracesSampleRate = 0,
  });

  /// Reads compile-time dart-defines with production-safe defaults.
  factory CrashReportingConfig.fromEnvironment() {
    const enabledFlag = bool.fromEnvironment(
      'SENTRY_ENABLED',
      defaultValue: false,
    );
    const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    const environment = String.fromEnvironment(
      'SENTRY_ENVIRONMENT',
      defaultValue: '',
    );
    return CrashReportingConfig.resolve(
      enabledFlag: enabledFlag,
      dsn: dsn,
      environment: environment,
    );
  }

  /// Pure resolver used by [fromEnvironment] and unit tests.
  factory CrashReportingConfig.resolve({
    required bool enabledFlag,
    required String dsn,
    String environment = '',
  }) {
    final trimmedDsn = dsn.trim();
    final resolvedEnvironment = environment.trim().isEmpty
        ? (kReleaseMode ? 'production' : 'development')
        : environment.trim();
    return CrashReportingConfig(
      dsn: trimmedDsn,
      enabled: enabledFlag && trimmedDsn.isNotEmpty,
      environment: resolvedEnvironment,
    );
  }

  final String dsn;
  final bool enabled;
  final String environment;

  /// Error events only — no performance tracing by default.
  final double tracesSampleRate;

  bool get isEnabled => enabled;

  void applyTo(SentryFlutterOptions options) {
    options.dsn = dsn;
    options.environment = environment;
    options.tracesSampleRate = tracesSampleRate;
    options.sendDefaultPii = false;
    options.attachScreenshot = false;
    options.debug = kDebugMode;
  }
}
