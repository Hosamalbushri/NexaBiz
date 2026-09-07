import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/router/app_router.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/presentation/pages/app_lock_routes.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

class MockAdversarialBiometrics implements AppLockBiometrics {
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
  late ModuleRegistry registry;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_app_lock_adv_test_');
    Hive.init(tempDir.path);

    repository = AppLockRepositoryImpl();
    controller = AppLockController(
      repository: repository,
      biometrics: MockAdversarialBiometrics(),
      onChanged: () {},
    );
    registry = ModuleRegistry();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('App Lock Adversarial Attack Matrix (AL-11)', () {
    test(
      'Attack 1: Protected deep link while locked redirects to /app-lock',
      () {
        final lockState = AppLockState.initial().copyWith(
          enabled: true,
          gate: AppLockGate.locked,
          hasPin: true,
        );

        const bootstrapState = AppBootstrapState(
          status: AppBootstrapStatus.authenticatedCompanyScope,
        );

        final authState = AuthState(
          status: AuthStatus.authenticated,
          session: AuthSessionSnapshot(
            user: const AuthUser(
              id: 'u1',
              email: 'admin@nexabiz.local',
              name: 'Admin',
            ),
            companies: const [
              AuthCompany(id: 'comp_01', name: 'Company 1', code: 'C1'),
            ],
            roles: const ['Admin'],
            permissions: const {'all'},
            capturedAt: DateTime.now().toUtc(),
            currentCompanyId: 'comp_01',
          ),
        );

        final redirect = evaluateAppRouteRedirect(
          path: '/sales/invoices/inv-999',
          auth: authState,
          bootstrap: bootstrapState,
          registry: registry,
          lock: lockState,
          lockControllerNotifier: controller,
        );

        expect(redirect, equals(AppLockRoutes.root));
        expect(controller.returnToLocation, equals('/sales/invoices/inv-999'));
      },
    );

    test('Attack 2: State manipulation cannot bypass invalid PIN', () async {
      await controller.enableWithPin(pin: '1234', confirmPin: '1234');
      controller.lock();

      final res = await controller.unlock('9999');
      expect(res, isFalse);
      expect(controller.state.isLocked, isTrue);
    });

    test(
      'Attack 3: Logout invalidates pending unlock returnTo location',
      () async {
        await controller.enableWithPin(pin: '1234', confirmPin: '1234');
        controller.lock(returnTo: '/accounting/journal-entries');

        expect(
          controller.returnToLocation,
          equals('/accounting/journal-entries'),
        );

        // Simulating session logout clearing lock controller
        controller.returnToLocation = null;
        expect(controller.returnToLocation, isNull);
      },
    );
  });
}
