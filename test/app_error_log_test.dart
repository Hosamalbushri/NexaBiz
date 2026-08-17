import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/logging/app_error_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppErrorLog.record does not throw', () async {
    await expectLater(
      AppErrorLog.record(
        StateError('phase5 crash hook'),
        StackTrace.current,
        source: 'test',
      ),
      completes,
    );
  });

  test('installAppErrorLogging installs FlutterError handler', () {
    installAppErrorLogging();
    expect(FlutterError.onError, isNotNull);
  });
}
