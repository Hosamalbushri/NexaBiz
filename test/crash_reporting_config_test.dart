import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/logging/crash_reporting_config.dart';

void main() {
  group('CrashReportingConfig.resolve', () {
    test('defaults keep Sentry disabled without DSN', () {
      final config = CrashReportingConfig.resolve(enabledFlag: false, dsn: '');
      expect(config.isEnabled, isFalse);
    });

    test('rejects enabled flag when DSN is missing', () {
      final config = CrashReportingConfig.resolve(enabledFlag: true, dsn: '');
      expect(config.isEnabled, isFalse);
    });

    test('accepts enabled flag with a non-empty DSN', () {
      final config = CrashReportingConfig.resolve(
        enabledFlag: true,
        dsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
        environment: 'staging',
      );
      expect(config.isEnabled, isTrue);
      expect(config.dsn, contains('sentry.io'));
      expect(config.environment, 'staging');
      expect(config.tracesSampleRate, 0);
    });

    test('trims whitespace from DSN', () {
      final config = CrashReportingConfig.resolve(
        enabledFlag: true,
        dsn: '  https://key@o0.ingest.sentry.io/1  ',
      );
      expect(config.dsn, 'https://key@o0.ingest.sentry.io/1');
    });
  });
}
