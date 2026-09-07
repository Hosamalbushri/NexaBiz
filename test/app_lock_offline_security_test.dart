import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';

class MockOfflineBiometrics implements AppLockBiometrics {
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
      'hive_app_lock_offline_test_',
    );
    Hive.init(tempDir.path);

    repository = AppLockRepositoryImpl();
    controller = AppLockController(
      repository: repository,
      biometrics: MockOfflineBiometrics(),
      onChanged: () {},
    );
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Offline App Lock Security (AL-07)', () {
    test(
      'Offline local unlock verifies encrypted PIN hash without network access',
      () async {
        await controller.enableWithPin(pin: '1234', confirmPin: '1234');
        controller.lock();

        expect(controller.state.isLocked, isTrue);

        final ok = await controller.unlock('1234');
        expect(ok, isTrue);
        expect(controller.state.gate, AppLockGate.unlocked);
      },
    );

    test(
      'Invalid PIN offline fails closed without exposing application content',
      () async {
        await controller.enableWithPin(pin: '1234', confirmPin: '1234');
        controller.lock();

        final ok = await controller.unlock('0000');
        expect(ok, isFalse);
        expect(controller.state.isLocked, isTrue);
      },
    );
  });
}
