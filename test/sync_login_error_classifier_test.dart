import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/network/sync_login_error_classifier.dart';

void main() {
  group('SyncLoginErrorClassifier', () {
    test('detects TLS certificate validation failures', () {
      const error = HandshakeException('CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate');
      expect(SyncLoginErrorClassifier.isTlsCertificateFailure(error), isTrue);
      expect(
        SyncLoginErrorClassifier.uiMessageFor(error),
        contains('Certificate validation failed'),
      );
    });

    test('detects network timeout separately', () {
      final error = TimeoutException('timed out');
      expect(SyncLoginErrorClassifier.isTlsCertificateFailure(error), isFalse);
      expect(
        SyncLoginErrorClassifier.uiMessageFor(error),
        contains('timed out'),
      );
    });
  });
}
