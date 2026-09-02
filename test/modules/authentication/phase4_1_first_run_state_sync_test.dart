import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SettingsRepository settingsRepository;
  late LocalAuthStore authStore;
  late FirstRunSetupCoordinator firstRunCoordinator;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('phase4_1_state_sync_test_');
    Hive.init(tempDir.path);
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 1),
    );

    settingsRepository = SettingsRepository();
    authStore = LocalAuthStore();
    firstRunCoordinator = FirstRunSetupCoordinator(
      settingsRepository: settingsRepository,
      authStore: authStore,
    );
  });

  tearDown(() async {
    HiveEncryptionKeyStore.debugFixedKey = null;
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 4.1 — First-Run Completion State Synchronization Tests', () {
    test('FR-SYNC-01: Successful setup commit updates live AppBootstrapCoordinator state from firstRunRequired to unauthenticated/ready', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          localAuthStoreProvider.overrideWithValue(authStore),
          firstRunSetupCoordinatorProvider.overrideWithValue(firstRunCoordinator),
        ],
      );
      addTearDown(container.dispose);

      final bootstrapNotifier = container.read(appBootstrapCoordinatorProvider.notifier);

      // 1. Set initial state to firstRunRequired
      bootstrapNotifier.state = const AppBootstrapState(
        status: AppBootstrapStatus.firstRunRequired,
        stageDetails: 'First-run setup required',
      );
      expect(container.read(appBootstrapCoordinatorProvider).isFirstRunRequired, isTrue);

      // 2. Perform setup commit
      const payload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'شركة المتجر الذهبي',
        companyCode: 'GOLD-01',
        adminName: 'المدير العام',
        adminEmail: 'admin@goldstore.com',
        adminPassword: 'SuperSecurePassword2026!',
      );

      await firstRunCoordinator.commitFirstRunSetup(payload);
      expect(await firstRunCoordinator.isFirstRunCompleted(), isTrue);

      // 3. Notify bootstrap coordinator (as FirstRunSetupWizardPage now does)
      await bootstrapNotifier.onFirstRunCompleted();

      // 4. Assert live in-memory state transitioned OUT of firstRunRequired
      final updatedState = container.read(appBootstrapCoordinatorProvider);
      expect(updatedState.isFirstRunRequired, isFalse);
      expect(
        updatedState.status == AppBootstrapStatus.unauthenticated ||
            updatedState.status == AppBootstrapStatus.ready,
        isTrue,
      );
    });

    test('FR-SYNC-02: Failed setup commit keeps AppBootstrapCoordinator in firstRunRequired state and setup remains retryable', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          localAuthStoreProvider.overrideWithValue(authStore),
          firstRunSetupCoordinatorProvider.overrideWithValue(firstRunCoordinator),
        ],
      );
      addTearDown(container.dispose);

      final bootstrapNotifier = container.read(appBootstrapCoordinatorProvider.notifier);
      bootstrapNotifier.state = const AppBootstrapState(
        status: AppBootstrapStatus.firstRunRequired,
        stageDetails: 'First-run setup required',
      );

      // Invalid payload (weak password) -> should throw validation exception
      const invalidPayload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'شركة المتجر',
        companyCode: 'STORE',
        adminName: 'Admin',
        adminEmail: 'admin@store.com',
        adminPassword: '123', // Invalid weak password
      );

      expect(
        () => firstRunCoordinator.commitFirstRunSetup(invalidPayload),
        throwsA(isA<FirstRunSetupValidationException>()),
      );

      // Verify state was NOT updated and remains firstRunRequired
      expect(container.read(appBootstrapCoordinatorProvider).isFirstRunRequired, isTrue);
      expect(await firstRunCoordinator.isFirstRunCompleted(), isFalse);
    });

    test('FR-SYNC-03 & FR-SYNC-04: No redirect loop — Live in-memory transition allows router to clear setup redirect guard', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          localAuthStoreProvider.overrideWithValue(authStore),
          firstRunSetupCoordinatorProvider.overrideWithValue(firstRunCoordinator),
        ],
      );
      addTearDown(container.dispose);

      final bootstrapNotifier = container.read(appBootstrapCoordinatorProvider.notifier);
      bootstrapNotifier.state = const AppBootstrapState(
        status: AppBootstrapStatus.firstRunRequired,
        stageDetails: 'First-run setup required',
      );

      // Router guard logic simulation
      String? evaluateRedirect(AppBootstrapState bootstrap, String path) {
        if (bootstrap.isFirstRunRequired) {
          if (path != '/setup/first-run') return '/setup/first-run';
          return null;
        }
        return null; // Route allowed
      }

      // Prior to completion: /login is redirected back to /setup/first-run
      expect(evaluateRedirect(container.read(appBootstrapCoordinatorProvider), '/login'), equals('/setup/first-run'));

      // Perform commit and notify live notifier
      const payload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'شركة التقنية الحادّة',
        companyCode: 'TECH-01',
        adminName: 'المدير التنفيذي',
        adminEmail: 'ceo@tech.com',
        adminPassword: 'SuperSecurePassword2026!',
      );

      await firstRunCoordinator.commitFirstRunSetup(payload);
      await bootstrapNotifier.onFirstRunCompleted();

      // Post completion: live state updated, /login redirect guard is cleared!
      final liveBootstrapState = container.read(appBootstrapCoordinatorProvider);
      expect(liveBootstrapState.isFirstRunRequired, isFalse);
      expect(evaluateRedirect(liveBootstrapState, '/login'), isNull);
    });

    test('FR-SYNC-05: Persistence of admin identity remains intact after state sync', () async {
      const payload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'شركة الأمان المالي',
        companyCode: 'SECURE-01',
        adminName: 'مدير النظام',
        adminEmail: 'admin@secure-financial.com',
        adminPassword: 'SuperSecurePassword2026!',
      );

      await firstRunCoordinator.commitFirstRunSetup(payload);

      // Verify persisted admin in LocalAuthStore
      final savedEmail = await authStore.getAdminEmail();
      expect(savedEmail, equals('admin@secure-financial.com'));

      final hasAdmin = await authStore.hasConfiguredAdmin();
      expect(hasAdmin, isTrue);

      // Phase 4 pure System Identity: First Run creates System Admin without mandatory company
      final company = await authStore.getPrimaryCompany();
      expect(company, isNull);
    });
  });
}
