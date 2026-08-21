import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/bootstrap/app_initialization_state.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_bootstrap_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SecureTokenStorage Bootstrap Isolation Tests', () {
    test('saveBootstrapToken and readBootstrapToken work independently', () async {
      final storage = SecureTokenStorage();

      await storage.saveBootstrapToken('test_bootstrap_token_123');
      final readToken = await storage.readBootstrapToken();

      expect(readToken, equals('test_bootstrap_token_123'));

      // Ensure normal access token is not polluted
      final readAccessToken = await storage.readAccessToken();
      expect(readAccessToken, isNull);

      await storage.clearBootstrapToken();
      final readAfterClear = await storage.readBootstrapToken();
      expect(readAfterClear, isNull);
    });
  });

  group('InitializationState Server Bootstrap Status Tests', () {
    test('InitializationState allows operation during mode selection and setup', () {
      const state1 = InitializationState(status: InitializationStatus.selectingMode);
      expect(state1.canOperate, isTrue);

      const state2 = InitializationState(status: InitializationStatus.ready);
      expect(state2.canOperate, isTrue);

      const state3 = InitializationState(status: InitializationStatus.serverNoData);
      expect(state3.isServerNoData, isTrue);

      const state4 = InitializationState(status: InitializationStatus.failed);
      expect(state4.canOperate, isFalse);
    });
  });
}
