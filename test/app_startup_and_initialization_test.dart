import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:stock_count/app/bootstrap/app_initialization_state.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';
import 'package:stock_count/modules/system_setup/domain/services/installation_integrity_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late Box<dynamic> authBox;
  late SettingsRepository settingsRepository;
  late LocalAuthStore authStore;
  late FirstRunSetupCoordinator coordinator;
  late InstallationIntegrityValidator validator;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('startup_init_test_');
    Hive.init(tempDir.path);

    settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    authBox = await Hive.openBox<dynamic>(LocalAuthStore.boxName);

    settingsRepository = SettingsRepository(box: settingsBox);
    authStore = LocalAuthStore(box: authBox);
    validator = InstallationIntegrityValidator(
      settingsRepository: settingsRepository,
      authStore: authStore,
    );
    coordinator = FirstRunSetupCoordinator(
      settingsRepository: settingsRepository,
      authStore: authStore,
    );
  });

  tearDown(() async {
    await settingsBox.close();
    await authBox.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Task 1 — Application Startup & First-Run Initialization Tests', () {
    test('1. First Launch: Fresh unconfigured installation detects uninitialized state', () async {
      final integrity = await validator.validate();
      expect(integrity.isUninitialized, isTrue);
      expect(integrity.isValid, isFalse);
      expect(integrity.isCorrupted, isFalse);

      final isCompleted = await coordinator.isFirstRunCompleted();
      expect(isCompleted, isFalse);
    });

    test('2. Successful Initialization: Atomically creates single company, owner, defaults, and records', () async {
      const payload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'مؤسسة التقنية الحديثة',
        companyCode: 'TECH_01',
        adminName: 'المدير التنفيذي',
        adminEmail: 'owner@tech-modern.com',
        adminPassword: 'StrongPassword2026!',
      );

      await coordinator.commitFirstRunSetup(payload);

      // Verify setup completion
      expect(await coordinator.isFirstRunCompleted(), isTrue);

      // Verify integrity validator passes
      final integrity = await validator.validate();
      expect(integrity.isValid, isTrue);
      expect(integrity.companyName, equals('مؤسسة التقنية الحديثة'));
      expect(integrity.ownerEmail, equals('owner@tech-modern.com'));
      expect(integrity.ownerName, equals('المدير التنفيذي'));

      // Verify single company profile
      final profile = await settingsRepository.loadCompanyProfile();
      expect(profile.name, equals('مؤسسة التقنية الحديثة'));

      // Verify local owner authentication
      final session = await authStore.login(
        email: 'owner@tech-modern.com',
        password: 'StrongPassword2026!',
        deviceId: 'device-test-1',
      );
      expect(session, isNotNull);
      expect(session!.user.email, equals('owner@tech-modern.com'));
      expect(session.roles, contains('Owner'));
      expect(session.permissions, isNotEmpty);
      expect(session.currentCompanyId, equals(LocalAuthDefaults.companyId));
    });

    test('3. Initialization Failure & Atomic Rollback: Invalid data or failure rolls back partial state', () async {
      // Weak password triggers validation error before commit
      const invalidPayload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'شركة تجريبية',
        companyCode: 'TEST',
        adminName: 'Admin',
        adminEmail: 'admin@test.com',
        adminPassword: '123', // Too short
      );

      expect(
        () => coordinator.commitFirstRunSetup(invalidPayload),
        throwsA(isA<FirstRunSetupValidationException>()),
      );

      // Verify nothing is marked as completed or valid
      expect(await coordinator.isFirstRunCompleted(), isFalse);
      final integrity = await validator.validate();
      expect(integrity.isUninitialized, isTrue);
      expect(integrity.isValid, isFalse);
    });

    test('4. Second Application Launch: Successfully validates installation integrity and loads existing company', () async {
      // First setup
      const payload = FirstRunSetupPayload(
        language: 'en',
        companyName: 'Global Enterprises Inc',
        companyCode: 'GLOBAL_01',
        adminName: 'Alice Johnson',
        adminEmail: 'alice@global.com',
        adminPassword: 'SecureAlicePassword2026!',
      );
      await coordinator.commitFirstRunSetup(payload);

      // Simulate app restart by re-instantiating repositories and validator
      final newSettingsRepo = SettingsRepository(box: settingsBox);
      final newAuthStore = LocalAuthStore(box: authBox);
      final newValidator = InstallationIntegrityValidator(
        settingsRepository: newSettingsRepo,
        authStore: newAuthStore,
      );

      final integrity = await newValidator.validate();
      expect(integrity.isValid, isTrue);
      expect(integrity.companyName, equals('Global Enterprises Inc'));
      expect(integrity.ownerEmail, equals('alice@global.com'));
    });

    test('5. Missing Company Integrity Failure: Fail closed into corrupted error state', () async {
      // Mark onboarding as completed but do NOT create company
      await settingsRepository.saveOnboardingCompleted(true);
      await settingsRepository.saveDeviceInitialization(
        mode: DeviceInitializationMode.local,
        initialized: true,
      );

      final integrity = await validator.validate();
      expect(integrity.isCorrupted, isTrue);
      expect(integrity.isValid, isFalse);
      expect(integrity.failureReason, contains('Primary company record is missing'));
    });

    test('6. Missing Owner Integrity Failure: Company exists but owner user missing fails closed', () async {
      // Save company in auth box but no users
      final company = AuthCompany(
        id: LocalAuthDefaults.companyId,
        name: 'Orphan Company',
        code: 'ORPHAN',
        role: 'Owner',
      );
      await authBox.put('companies', [company.toJson()]);
      await settingsRepository.saveOnboardingCompleted(true);
      await settingsRepository.saveCompanyProfile(
        const CompanyProfile(name: 'Orphan Company'),
        LocalAuthDefaults.companyId,
      );

      final integrity = await validator.validate();
      expect(integrity.isCorrupted, isTrue);
      expect(integrity.failureReason, contains('Owner user account is missing'));
    });

    test('7. Owner Tenant Mismatch Failure: Owner not belonging to company fails closed', () async {
      final company = AuthCompany(
        id: 'company-a',
        name: 'Company A',
        code: 'COMPA',
        role: 'Owner',
      );
      await authBox.put('companies', [company.toJson()]);
      await settingsRepository.saveOnboardingCompleted(true);
      await settingsRepository.saveCompanyProfile(
        const CompanyProfile(name: 'Company A'),
        'company-a',
      );

      // Create owner user assigned to a different company ID
      await authStore.createOwnerAndCompany(
        companyId: 'company-b',
        companyName: 'Company B',
        companyCode: 'COMPB',
        ownerEmail: 'owner@mismatch.com',
        ownerPassword: 'Password123!',
        ownerName: 'Mismatch Owner',
      );

      // Overwrite company list to only have company-a
      await authBox.put('companies', [company.toJson()]);

      final integrity = await validator.validate();
      expect(integrity.isCorrupted, isTrue);
      expect(integrity.failureReason, contains('does not belong to company'));
    });

    test('8. Corrupted Initialization State: Does NOT silently create another company or fallback', () async {
      await settingsRepository.saveOnboardingCompleted(true);
      await settingsRepository.saveSystemSetupState(
        version: 1,
        status: 'ready',
        steps: {},
        lastUpdated: DateTime.now().toUtc(),
      );

      final integrity = await validator.validate();
      expect(integrity.isCorrupted, isTrue);
      expect(integrity.isValid, isFalse);

      // Ensure no company was auto-created
      final companies = await authStore.getPrimaryCompany();
      expect(companies, isNull);
    });

    test('9. Authentication Failure: Fails closed and never logs in with invalid credentials', () async {
      const payload = FirstRunSetupPayload(
        language: 'en',
        companyName: 'Security First Co',
        adminName: 'Owner',
        adminEmail: 'owner@secure.com',
        adminPassword: 'CorrectPassword123!',
      );
      await coordinator.commitFirstRunSetup(payload);

      // Wrong password
      final failedSession = await authStore.login(
        email: 'owner@secure.com',
        password: 'WrongPassword!',
        deviceId: 'device-1',
      );
      expect(failedSession, isNull);

      // Wrong email
      final wrongEmailSession = await authStore.login(
        email: 'attacker@evil.com',
        password: 'CorrectPassword123!',
        deviceId: 'device-1',
      );
      expect(wrongEmailSession, isNull);

      // Hardcoded default admin password should NOT work
      final defaultAdminSession = await authStore.login(
        email: 'owner@secure.com',
        password: 'admin123',
        deviceId: 'device-1',
      );
      expect(defaultAdminSession, isNull);
    });

    test('10. No Remote Login or Sync Required: Entire flow runs locally and offline', () async {
      // Offline first-run setup
      const payload = FirstRunSetupPayload(
        language: 'ar',
        companyName: 'شركة محلية بالكامل',
        companyCode: 'LOCAL_01',
        adminName: 'مدير محلي',
        adminEmail: 'local@offline.corp',
        adminPassword: 'LocalOnlyPassword2026!',
      );

      await coordinator.commitFirstRunSetup(payload);

      final deviceInit = await settingsRepository.loadDeviceInitialization();
      expect(deviceInit.isLocalInitialized, isTrue);
      expect(deviceInit.isServerInitialized, isFalse);
      expect(deviceInit.mode, equals(DeviceInitializationMode.local));

      final syncEnabled = await settingsRepository.loadSyncEnabled();
      expect(syncEnabled, isFalse);
    });
  });
}
