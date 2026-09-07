import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';

class MockAppLockBiometrics implements AppLockBiometrics {
  bool available = true;
  bool shouldSucceed = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String localizedReason}) async =>
      shouldSucceed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppLockRepositoryImpl repository;
  late MockAppLockBiometrics biometrics;
  late AppLockController controller;
  var notifiedCount = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_app_lock_test_');
    Hive.init(tempDir.path);

    repository = AppLockRepositoryImpl();
    biometrics = MockAppLockBiometrics();
    notifiedCount = 0;

    controller = AppLockController(
      repository: repository,
      biometrics: biometrics,
      onChanged: () => notifiedCount++,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('App Lock Architecture & Verification (AL-00 to AL-04)', () {
    test('AL-01: Initial state is disabled and unlocked', () {
      expect(controller.state.enabled, isFalse);
      expect(controller.state.gate, AppLockGate.disabled);
      expect(controller.state.hasPin, isFalse);
    });

    test(
      'AL-02: Enable App Lock with valid PIN, verify PIN, change PIN',
      () async {
        final res = await controller.enableWithPin(
          pin: '1234',
          confirmPin: '1234',
          policy: AppLockPolicy.onResume,
        );

        expect(res, isNull);
        expect(controller.state.enabled, isTrue);
        expect(controller.state.hasPin, isTrue);
        expect(controller.state.gate, AppLockGate.unlocked);

        // Lock app
        controller.lock(reason: 'manual', returnTo: '/dashboard');
        expect(controller.state.isLocked, isTrue);
        expect(controller.returnToLocation, '/dashboard');

        // Wrong PIN
        final wrongOk = await controller.unlock('9999');
        expect(wrongOk, isFalse);
        expect(controller.state.isLocked, isTrue);
        expect(controller.state.failedAttempts, 1);

        // Correct PIN
        final correctOk = await controller.unlock('1234');
        expect(correctOk, isTrue);
        expect(controller.state.isLocked, isFalse);
        expect(controller.state.failedAttempts, 0);

        // Change PIN
        final changeRes = await controller.changePin(
          currentPin: '1234',
          newPin: '5678',
          confirmPin: '5678',
        );
        expect(changeRes, isNull);

        // Verify new PIN works
        controller.lock();
        final newPinOk = await controller.unlock('5678');
        expect(newPinOk, isTrue);
      },
    );

    test('AL-03: Biometric unlock restoring local session', () async {
      await controller.enableWithPin(pin: '1234', confirmPin: '1234');
      await controller.setBiometricEnabled(
        enabled: true,
        localizedReason: 'Enable biometrics test',
      );

      expect(controller.state.biometricEnabled, isTrue);

      controller.lock();
      expect(controller.state.isLocked, isTrue);

      final bioOk = await controller.unlockWithBiometrics(
        localizedReason: 'Unlock test',
      );
      expect(bioOk, isTrue);
      expect(controller.state.isLocked, isFalse);
    });

    test('AL-04: Disabling App Lock clears PIN and resets state', () async {
      await controller.enableWithPin(pin: '1234', confirmPin: '1234');
      final disableRes = await controller.disable(pin: '1234');

      expect(disableRes, isNull);
      expect(controller.state.enabled, isFalse);
      expect(controller.state.hasPin, isFalse);
      expect(controller.state.gate, AppLockGate.disabled);
    });
  });
}
