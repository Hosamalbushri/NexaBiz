import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  late Directory testDir;

  const testConfig = SyncApiConfig(
    baseUrl: '',
    apiToken: '',
    companyId: '',
    userId: '',
    deviceId: 'dev_1',
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testDir = await Directory.systemTemp.createTemp('session_mc10_test_hive_');
    Hive.init(testDir.path);
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
  });

  tearDownAll(() async {
    await Hive.close();
    if (testDir.existsSync()) {
      await testDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Hive.deleteFromDisk();
  });

  Future<void> setupDefaultOwner(LocalAuthStore store) async {
    await store.ensureSeeded();
    await store.createOwnerAndCompany(
      companyId: LocalAuthDefaults.companyId,
      companyName: LocalAuthDefaults.companyName,
      companyCode: LocalAuthDefaults.companyCode,
      ownerEmail: LocalAuthDefaults.adminEmail,
      ownerPassword: 'password',
      ownerName: LocalAuthDefaults.adminName,
    );
  }

  group('Phase MC-10 — Session Restore & Bootstrap Consistency Tests', () {
    test('SCENARIO 1 — Login Matrix: Generates new Session ID and establishes active company', () async {
      final store = LocalAuthStore();
      await setupDefaultOwner(store);

      final localRepo = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      final session = await localRepo.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'dev_1',
        deviceName: 'Test Phone',
        platform: 'android',
      );

      expect(session.sessionId, isNotNull);
      expect(session.sessionId, isNotEmpty);
      expect(session.user.email, equals(LocalAuthDefaults.adminEmail));
      expect(session.currentCompanyId, equals(LocalAuthDefaults.companyId));
      expect(session.companyContext, isNotNull);
    });

    test('SCENARIO 2 — Switch Matrix: Preserves Session ID and updates ActiveCompanyContext', () async {
      final store = LocalAuthStore();
      await setupDefaultOwner(store);

      final companyB = await store.createCompany(name: 'Company Beta', code: 'BETA');

      final localRepo = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      final sessionA = await localRepo.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: LocalAuthDefaults.companyId,
        deviceId: 'dev_1',
        deviceName: 'Test Phone',
        platform: 'android',
      );

      final initialSessionId = sessionA.sessionId;
      expect(sessionA.currentCompanyId, equals(LocalAuthDefaults.companyId));

      // Switch to Company B
      final sessionB = await localRepo.switchCompany(companyB.id);

      // REQUIRED TEST MATRIX: Session ID MUST be Same, Company MUST Change
      expect(sessionB.sessionId, equals(initialSessionId));
      expect(sessionB.currentCompanyId, equals(companyB.id));
      expect(sessionB.companyContext?.companyId, equals(companyB.id));
      expect(sessionB.companyContext?.companyName, equals('Company Beta'));
    });

    test('SCENARIO 3 — Session Restore Matrix: Restores same persisted Session ID and company context', () async {
      final store = LocalAuthStore();
      await setupDefaultOwner(store);

      final localRepo1 = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      final originalSession = await localRepo1.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: LocalAuthDefaults.companyId,
        deviceId: 'dev_1',
        deviceName: 'Test Phone',
        platform: 'android',
      );

      final persistedSessionId = originalSession.sessionId;

      // Simulate App Restart by instantiating new repository instance
      final localRepo2 = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      final restoredSession = await localRepo2.restoreSession();

      // REQUIRED TEST MATRIX: Restore MUST return same persisted Session ID & company
      expect(restoredSession, isNotNull);
      expect(restoredSession!.sessionId, equals(persistedSessionId));
      expect(restoredSession.currentCompanyId, equals(LocalAuthDefaults.companyId));
      expect(restoredSession.companyContext?.companyId, equals(LocalAuthDefaults.companyId));
    });

    test('SCENARIO 4 — Invalid Restored Company Handling: Clears company context without silent fallback to first company', () async {
      final store = LocalAuthStore();
      await setupDefaultOwner(store);

      final companyX = await store.createCompany(name: 'Company X', code: 'COMPX');
      final companyY = await store.createCompany(name: 'Company Y', code: 'COMPY');

      final localRepo = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      final session = await localRepo.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: companyX.id,
        deviceId: 'dev_1',
        deviceName: 'Test Phone',
        platform: 'android',
      );

      expect(session.currentCompanyId, equals(companyX.id));

      // Simulate company deletion by removing companyX from storage
      final box = await Hive.openBox<dynamic>(HiveBoxes.localAuthEncrypted);
      final rawCompanies = box.get('companies') as List?;
      if (rawCompanies != null) {
        final updated = rawCompanies.where((c) => (c as Map)['id'] != companyX.id).toList();
        await box.put('companies', updated);
      }

      // Restore session after target company deletion
      final restored = await localRepo.restoreSession();

      // TASK 4 VERIFICATION:
      // 1. Session MUST remain authenticated (user is intact)
      // 2. MUST NOT silently choose companyY (first company)
      // 3. currentCompanyId and companyContext MUST be cleared to null (safe state)
      expect(restored, isNotNull);
      expect(restored!.user.email, equals(LocalAuthDefaults.adminEmail));
      expect(restored.currentCompanyId, isNull, reason: 'Must NOT silently choose first company');
      expect(restored.companyContext, isNull, reason: 'Company context MUST be cleared safely');
    });

    test('SCENARIO 5 — Logout Matrix: Terminates session and clears persisted state', () async {
      final store = LocalAuthStore();
      await setupDefaultOwner(store);

      final localRepo = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      final session = await localRepo.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'dev_1',
        deviceName: 'Test Phone',
        platform: 'android',
      );

      final loggedOutSessionId = session.sessionId;

      await localRepo.logout();

      // REQUIRED TEST MATRIX: Logout MUST terminate session and clear company
      final restoredAfterLogout = await localRepo.restoreSession();
      expect(restoredAfterLogout, isNull);
      expect(store.isSessionActive(loggedOutSessionId), isFalse);
    });

    test('SCENARIO 6 — Bootstrap & Company Switch Separation: Switching company does NOT restart bootstrap', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = container.read(localAuthStoreProvider);
      await setupDefaultOwner(store);

      // Mark onboarding as completed so bootstrap proceeds past firstRunRequired
      await SettingsRepository().saveOnboardingCompleted(true);

      final company2 = await store.createCompany(name: 'Company Two', code: 'TWO');

      final coordinator = container.read(appBootstrapCoordinatorProvider.notifier);

      // 1. Start initial application bootstrap
      await coordinator.startBootstrap();
      expect(container.read(appBootstrapCoordinatorProvider).isUnauthenticated, isTrue);

      // 2. Authenticate user
      await container.read(authStateProvider.notifier).loginLocal(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: LocalAuthDefaults.companyId,
        deviceId: 'dev_1',
        deviceName: 'Test Phone',
        platform: 'android',
      );

      expect(container.read(appBootstrapCoordinatorProvider).isAuthenticated, isTrue);

      // 3. Perform company switch on AuthController
      await container.read(authStateProvider.notifier).switchCompany(company2.id);

      // Verification: Coordinator status remains stable (authenticatedCompanyScope) and does not re-enter initializing
      final postSwitchStatus = container.read(appBootstrapCoordinatorProvider).status;
      expect(postSwitchStatus, isNot(equals(AppBootstrapStatus.initializing)));
      expect(postSwitchStatus, equals(AppBootstrapStatus.authenticatedCompanyScope));
    });
  });
}
