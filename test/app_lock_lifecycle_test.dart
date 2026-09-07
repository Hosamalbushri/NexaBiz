import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';

class MockAppLockBiometrics implements AppLockBiometrics {
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
      'hive_app_lock_lifecycle_test_',
    );
    Hive.init(tempDir.path);

    repository = AppLockRepositoryImpl();
    controller = AppLockController(
      repository: repository,
      biometrics: MockAppLockBiometrics(),
      onChanged: () {},
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Background / Resume Lock (AL-06)', () {
    test(
      'Policy onResume triggers lock when app returns from background',
      () async {
        await controller.enableWithPin(
          pin: '1234',
          confirmPin: '1234',
          policy: AppLockPolicy.onResume,
        );

        expect(controller.state.gate, AppLockGate.unlocked);

        // Simulate app going to background and returning
        controller.onAppPaused();
        controller.onAppResumed();

        expect(controller.state.isLocked, isTrue);
      },
    );

    test('Policy onColdStart does not lock on resume', () async {
      await controller.enableWithPin(
        pin: '1234',
        confirmPin: '1234',
        policy: AppLockPolicy.onColdStart,
      );

      expect(controller.state.gate, AppLockGate.unlocked);

      // Simulate app going to background and returning
      controller.onAppPaused();
      controller.onAppResumed();

      expect(controller.state.isLocked, isFalse);
    });
  });
}
