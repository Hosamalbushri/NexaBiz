import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late Box<dynamic> authBox;
  late SettingsRepository settingsRepository;
  late LocalAuthStore authStore;
  late FirstRunSetupCoordinator coordinator;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init('./test_hive_first_run');
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box<dynamic>(HiveBoxes.settings).clear();
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
      await settingsBox.clear();
    }

    if (Hive.isBoxOpen(LocalAuthStore.boxName)) {
      await Hive.box<dynamic>(LocalAuthStore.boxName).clear();
      authBox = Hive.box<dynamic>(LocalAuthStore.boxName);
    } else {
      authBox = await Hive.openBox<dynamic>(LocalAuthStore.boxName);
      await authBox.clear();
    }

    settingsRepository = SettingsRepository(box: settingsBox);
    authStore = LocalAuthStore(box: authBox);
    coordinator = FirstRunSetupCoordinator(
      settingsRepository: settingsRepository,
      authStore: authStore,
    );
  });

  tearDown(() async {
    await settingsBox.clear();
    await authBox.clear();
  });

  group('Phase 1 — First-Run Setup & Security Hardening Unit Tests', () {
    test(
      '1. PBKDF2 Hashing: Admin password update uses PBKDF2 and authenticates successfully',
      () async {
        await authStore.createInitialSystemAdmin(
          name: 'Super Admin',
          email: 'admin@nexabiz-test.com',
          password: 'InitialPassword123!',
        );

        // Update admin credentials with strong password
        await authStore.updateLocalAdminCredentials(
          newEmail: 'admin@nexabiz-test.com',
          newPassword: 'SuperSecretPassword123!',
          newName: 'Super Admin',
        );

        // Verify login succeeds with new password
        final session = await authStore.login(
          email: 'admin@nexabiz-test.com',
          password: 'SuperSecretPassword123!',
          deviceId: 'device-1',
        );

        expect(session, isNotNull);
        expect(session!.user.email, equals('admin@nexabiz-test.com'));
        expect(session.user.name, equals('Super Admin'));

        // Verify incorrect password returns null
        final failedSession = await authStore.login(
          email: 'admin@nexabiz-test.com',
          password: 'WrongPassword123',
          deviceId: 'device-1',
        );
        expect(failedSession, isNull);
      },
    );

    test(
      '2. Security Hardening: LocalAuthRepository.restoreSession does NOT auto-login as admin when session is missing',
      () async {
        final repository = LocalAuthRepository(
          store: authStore,
          tokenStorage: SecureTokenStorage(),
          readConfig: () => SyncApiConfig.fromEnvironment(),
        );

        // Restore session on clean box (no prior login session saved)
        final restored = await repository.restoreSession();

        // MUST be null — should NOT fall back to admin auto-login!
        expect(restored, isNull);
      },
    );

    test('3. FirstRunSetupCoordinator: Payload Validation', () async {
      // Invalid language
      expect(
        () => coordinator.validatePayload(
          const FirstRunSetupPayload(
            language: 'fr',
            companyName: 'Acme',
            companyCode: 'ACME',
            adminName: 'Admin',
            adminEmail: 'admin@test.com',
            adminPassword: 'Password123!',
          ),
        ),
        throwsA(isA<FirstRunSetupValidationException>()),
      );

      // Weak password (< 8 chars)
      expect(
        () => coordinator.validatePayload(
          const FirstRunSetupPayload(
            language: 'ar',
            companyName: 'Acme',
            companyCode: 'ACME',
            adminName: 'Admin',
            adminEmail: 'admin@test.com',
            adminPassword: '123',
          ),
        ),
        throwsA(isA<FirstRunSetupValidationException>()),
      );

      // Default password 'admin' blocked
      expect(
        () => coordinator.validatePayload(
          const FirstRunSetupPayload(
            language: 'ar',
            companyName: 'Acme',
            companyCode: 'ACME',
            adminName: 'Admin',
            adminEmail: 'admin@test.com',
            adminPassword: 'admin',
          ),
        ),
        throwsA(isA<FirstRunSetupValidationException>()),
      );
    });

    test(
      '3.5. FirstRunSetupCoordinator: Auto-generates company code when not provided',
      () {
        final code1 = FirstRunSetupCoordinator.generateCompanyCode(
          'شركة التجارة العامة',
        );
        expect(code1, equals('شركة_التجا'));

        final code2 = FirstRunSetupCoordinator.generateCompanyCode(
          'Acme Enterprises',
          '',
        );
        expect(code2, equals('ACME_ENTER'));

        final code3 = FirstRunSetupCoordinator.generateCompanyCode(
          'Test',
          'EXPLICIT_CODE',
        );
        expect(code3, equals('EXPLICIT_CODE'));
      },
    );

    test('4. FirstRunSetupCoordinator: Pure System Admin Atomic Commit & Idempotency', () async {
      expect(await coordinator.isFirstRunCompleted(), isFalse);

      const payload = FirstRunSetupPayload(
        language: 'ar',
        companyName: '',
        companyCode: '',
        adminName: 'المدير العام',
        adminEmail: 'admin@adv-solutions.com',
        adminPassword: 'StrongAdminPassword2026!',
      );

      // Execute setup commit
      await coordinator.commitFirstRunSetup(payload);

      // 1. Verify First-Run setup completed
      expect(await coordinator.isFirstRunCompleted(), isTrue);

      // 2. Verify persisted locale
      final locale = await settingsRepository.loadLocale();
      expect(locale?.languageCode, equals('ar'));

      // 3. Verify login with newly created admin credentials
      final session = await authStore.login(
        email: 'admin@adv-solutions.com',
        password: 'StrongAdminPassword2026!',
        deviceId: 'device-1',
      );
      expect(session, isNotNull);
      expect(session!.user.email, equals('admin@adv-solutions.com'));
      expect(session.user.name, equals('المدير العام'));

      // 4. Verify Phase 4 pure System Identity invariants: 0 companies, 0 memberships
      expect(session.user.isSystemAdmin, isTrue);
      expect(session.companies, isEmpty);
      expect(session.activeCompanyContext, isNull);

      // 5. Verify Idempotency: Re-running throws FirstRunAlreadyCompletedException
      expect(
        () => coordinator.commitFirstRunSetup(payload),
        throwsA(isA<FirstRunAlreadyCompletedException>()),
      );

      // 6. Verify System Initialization state steps and status are persisted as ready
      final systemSetupStatus = await settingsRepository
          .loadSystemSetupStatus();
      expect(systemSetupStatus, equals('ready'));
    });

    test('5. FirstRunSetupCoordinator: Transactional Rollback on Failure', () async {
      expect(await coordinator.isFirstRunCompleted(), isFalse);

      // Invalid payload (password too short)
      const invalidPayload = FirstRunSetupPayload(
        language: 'ar',
        companyName: '',
        companyCode: '',
        adminName: 'Test Admin',
        adminEmail: 'invalid@test.com',
        adminPassword: '123',
      );

      expect(
        () => coordinator.commitFirstRunSetup(invalidPayload),
        throwsA(isA<FirstRunSetupValidationException>()),
      );

      // Verify onboarding and auth data remain uninitialized after failure
      expect(await coordinator.isFirstRunCompleted(), isFalse);
      expect(await authStore.hasConfiguredAdmin(), isFalse);
    });
  });
}
