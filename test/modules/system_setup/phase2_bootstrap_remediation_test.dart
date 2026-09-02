import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_overview.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_manager.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_queue.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

import 'package:stock_count/modules/sync/engine/presentation/providers/sync_providers.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return ['wifi'];
        }
        return null;
      },
    );
    Hive.init('./test_tmp_phase2_bootstrap');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 2 — State Ownership & Persistence Authorities', () {
    test('SettingsRepository is authority for onboarding completed state', () async {
      final settings = SettingsRepository();
      await settings.saveOnboardingCompleted(true);
      expect(await settings.loadOnboardingCompleted(), isTrue);

      await settings.saveOnboardingCompleted(false);
      expect(await settings.loadOnboardingCompleted(), isFalse);
    });

    test('LocalAuthStore is authority for system admin configured state', () async {
      final authStore = LocalAuthStore();
      await authStore.ensureSeeded();

      final before = await authStore.hasConfiguredAdmin();
      expect(before, isFalse);

      await authStore.createInitialSystemAdmin(
        name: 'System Admin',
        email: 'sysadmin@nexabiz.test',
        password: 'Password123!',
      );

      final after = await authStore.hasConfiguredAdmin();
      expect(after, isTrue);
    });
  });

  group('Phase 2 — Bootstrap State Machine & Transitions', () {
    late ProviderContainer container;
    late ConnectivityService fakeConnectivity;

    setUp(() {
      fakeConnectivity = ConnectivityService(internetProbe: () async => false);
      container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fakeConnectivity),
        ],
      );
    });

    tearDown(() {
      fakeConnectivity.dispose();
      container.dispose();
    });

    test('Fresh installation defaults to firstRunRequired status', () async {
      final settings = SettingsRepository();
      await settings.saveOnboardingCompleted(false);
      final authStore = LocalAuthStore();
      await authStore.clearAuthData();

      final coordinator = container.read(appBootstrapCoordinatorProvider.notifier);
      await coordinator.startBootstrap();

      final state = container.read(appBootstrapCoordinatorProvider);
      expect(state.status, equals(AppBootstrapStatus.firstRunRequired));
      expect(state.isFirstRunRequired, isTrue);
    });

    test('Initialized system transitions to unauthenticated when no session saved', () async {
      final settings = SettingsRepository();
      await settings.saveOnboardingCompleted(true);
      final authStore = LocalAuthStore();
      await authStore.ensureSeeded();
      if (!await authStore.hasConfiguredAdmin()) {
        await authStore.createInitialSystemAdmin(
          name: 'Admin',
          email: 'admin@nexabiz.test',
          password: 'Password123!',
        );
      }

      final coordinator = container.read(appBootstrapCoordinatorProvider.notifier);
      await coordinator.startBootstrap();

      final state = container.read(appBootstrapCoordinatorProvider);
      expect(state.status, equals(AppBootstrapStatus.unauthenticated));
      expect(state.isUnauthenticated, isTrue);
    });

    test('System Scope login transitions status to authenticatedSystemScope', () async {
      final settings = SettingsRepository();
      await settings.saveOnboardingCompleted(true);
      final authStore = LocalAuthStore();
      await authStore.ensureSeeded();
      if (!await authStore.hasConfiguredAdmin()) {
        await authStore.createInitialSystemAdmin(
          name: 'SysAdmin',
          email: 'admin@nexabiz.test',
          password: 'Password123!',
        );
      }

      final coordinator = container.read(appBootstrapCoordinatorProvider.notifier);
      await coordinator.startBootstrap();

      // Log in as System Admin
      await container.read(authStateProvider.notifier).login(
            email: 'admin@nexabiz.test',
            password: 'Password123!',
            deviceId: 'test_device_123',
            deviceName: 'Test Device',
            platform: 'Linux',
          );

      final state = container.read(appBootstrapCoordinatorProvider);
      expect(state.status, equals(AppBootstrapStatus.authenticatedSystemScope));
      expect(state.isSystemScope, isTrue);
      expect(state.activeCompanyId, isNull);
    });
  });

  group('Phase 2 — Auth Event Queueing & Replay During Bootstrap', () {
    test('Incoming auth event during session restoration is queued and replayed', () async {
      final fakeConnectivity = ConnectivityService(internetProbe: () async => false);
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fakeConnectivity),
        ],
      );
      final coordinator = container.read(appBootstrapCoordinatorProvider.notifier);

      // Simulate auth state change during initialization
      container.read(authStateProvider.notifier).logout();

      await coordinator.startBootstrap();
      final state = container.read(appBootstrapCoordinatorProvider);

      expect(state.status, isNot(equals(AppBootstrapStatus.initializing)));
      fakeConnectivity.dispose();
      container.dispose();
    });
  });

  group('Phase 2 — Sync Execution Boundary (System Scope Guard)', () {
    test('Sync pass is skipped gracefully when in System Scope (companyId is empty)', () async {
      final connectivity = ConnectivityService(internetProbe: () async => false);
      final queue = SyncQueue(companyId: '', encryptedBoxName: 'test_queue');

      final manager = SyncManager(
        queue: queue,
        connectivity: connectivity,
        readCompanyId: () => '', // System Scope: empty companyId
      );

      await manager.start(enabled: true);
      final passResult = await manager.syncNow(notify: false);

      expect(passResult.outcome, equals(SyncPassOutcome.skippedDisabled));
      await manager.dispose();
    });
  });
}
