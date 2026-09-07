import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';

class MockLockoutBiometrics implements AppLockBiometrics {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppLockRepositoryImpl repository;
  late AppLockController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'hive_app_lock_failed_test_',
    );
    Hive.init(tempDir.path);

    repository = AppLockRepositoryImpl();
    controller = AppLockController(
      repository: repository,
      biometrics: MockLockoutBiometrics(),
      onChanged: () {},
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Failed Attempts & Lockout (AL-08)', () {
    test('5 consecutive failed PIN attempts trigger lockout', () async {
      await controller.enableWithPin(pin: '1234', confirmPin: '1234');
      controller.lock();

      for (var i = 0; i < 4; i++) {
        final ok = await controller.unlock('0000');
        expect(ok, isFalse);
        expect(controller.state.isLockoutActive, isFalse);
      }

      // 5th attempt triggers lockout
      final fifthOk = await controller.unlock('0000');
      expect(fifthOk, isFalse);
      expect(controller.state.isLockoutActive, isTrue);
      expect(controller.state.errorMessage, 'invalid');

      // Attempt while locked out
      final lockedOutAttempt = await controller.unlock('1234');
      expect(lockedOutAttempt, isFalse);
      expect(controller.state.errorMessage, 'lockout');
    });
  });
}
