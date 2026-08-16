import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/data/local_auth_app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late AppLockRepositoryImpl repository;
  late AppLockController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_lock_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>(HiveBoxes.appLock);
    repository = AppLockRepositoryImpl(box: box);
    controller = AppLockController(
      repository: repository,
      biometrics: const UnavailableAppLockBiometrics(),
      onChanged: () {},
    );
  });

  tearDown(() async {
    controller.dispose();
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppLockRepositoryImpl', () {
    test('stores hash only and verifies PIN offline', () async {
      await repository.setPin('1234');
      expect(await repository.hasPin(), isTrue);
      expect(box.get('pin_hash'), isNotNull);
      expect(box.get('pin_hash'), isNot(equals('1234')));
      expect(await repository.verifyPin('1234'), isTrue);
      expect(await repository.verifyPin('9999'), isFalse);
    });
  });

  group('AppLockController', () {
    test('enable / unlock / disable flow', () async {
      await controller.hydrate(lockOnColdStart: false);
      expect(controller.state.gate, AppLockGate.disabled);

      final enableError = await controller.enableWithPin(
        pin: '2580',
        confirmPin: '2580',
        policy: AppLockPolicy.onResume,
      );
      expect(enableError, isNull);
      expect(controller.state.enabled, isTrue);
      expect(controller.state.gate, AppLockGate.unlocked);

      controller.lock();
      expect(controller.state.isLocked, isTrue);

      expect(await controller.unlock('0000'), isFalse);
      expect(controller.state.isLocked, isTrue);

      expect(await controller.unlock('2580'), isTrue);
      expect(controller.state.gate, AppLockGate.unlocked);

      final disableError = await controller.disable(pin: '2580');
      expect(disableError, isNull);
      expect(controller.state.enabled, isFalse);
    });

    test('rejects mismatched confirmation and short PIN', () async {
      expect(
        await controller.enableWithPin(pin: '12', confirmPin: '12'),
        'length',
      );
      expect(
        await controller.enableWithPin(pin: '1234', confirmPin: '4321'),
        'mismatch',
      );
    });

    test('change PIN requires current PIN', () async {
      await controller.enableWithPin(
        pin: '1111',
        confirmPin: '1111',
      );
      expect(
        await controller.changePin(
          currentPin: '0000',
          newPin: '2222',
          confirmPin: '2222',
        ),
        'invalid',
      );
      expect(
        await controller.changePin(
          currentPin: '1111',
          newPin: '2222',
          confirmPin: '2222',
        ),
        isNull,
      );
      expect(await repository.verifyPin('2222'), isTrue);
    });

    test('duplicate lock is ignored', () async {
      await controller.enableWithPin(
        pin: '4444',
        confirmPin: '4444',
        policy: AppLockPolicy.onResume,
      );
      controller.lock();
      controller.lock();
      expect(controller.state.gate, AppLockGate.locked);
    });

    test('resume policy locks after pause/resume', () async {
      await controller.enableWithPin(
        pin: '5555',
        confirmPin: '5555',
        policy: AppLockPolicy.onResume,
      );
      await controller.hydrate(lockOnColdStart: false);
      // Re-enable after hydrate from storage
      expect(controller.state.enabled, isTrue);

      controller.onAppPaused();
      controller.onAppResumed();
      expect(controller.state.isLocked, isTrue);

      // Second resume without pause must not re-lock spam while already locked
      controller.onAppResumed();
      expect(controller.state.isLocked, isTrue);
    });

    test('cold-start policy does not lock on resume', () async {
      await controller.enableWithPin(
        pin: '6666',
        confirmPin: '6666',
        policy: AppLockPolicy.onColdStart,
      );
      controller.onAppPaused();
      controller.onAppResumed();
      expect(controller.state.isLocked, isFalse);
    });

    test('hydrate locks on cold start when policy requires it', () async {
      await repository.setPin('7777');
      await repository.setEnabled(true);
      await repository.setPolicy(AppLockPolicy.onResume);

      await controller.hydrate(lockOnColdStart: true);
      expect(controller.state.isLocked, isTrue);
    });
  });
}
