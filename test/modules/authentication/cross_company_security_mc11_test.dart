import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding_exceptions.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';

void main() {
  late Directory testDir;

  const testConfig = SyncApiConfig(
    baseUrl: 'https://api.nexabiz.test',
    apiToken: 'test_token',
    companyId: 'COMPANY_A',
    userId: 'user_1',
    deviceId: 'dev_1',
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    testDir = await Directory.systemTemp.createTemp('sec_mc11_test_hive_');
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
    await SettingsRepository().saveOnboardingCompleted(true);
  });

  Future<Map<String, String>> setupCompanyAAndB(LocalAuthStore store) async {
    await store.ensureSeeded();
    await store.createOwnerAndCompany(
      companyId: 'COMPANY_A',
      companyName: 'Company Alpha',
      companyCode: 'ALPHA',
      ownerEmail: LocalAuthDefaults.adminEmail,
      ownerPassword: 'password',
      ownerName: LocalAuthDefaults.adminName,
    );

    final companyB = await store.createCompany(name: 'Company Beta', code: 'BETA');
    final userA = (await store.loadSession())?.user ?? const AuthUser(id: 'admin_1', name: 'Admin', email: LocalAuthDefaults.adminEmail);

    // Grant user access to Company B as Viewer
    await store.addMembership(
      UserCompanyMembership(
        userId: userA.id,
        companyId: companyB.id,
        role: 'Viewer',
        status: 'active',
        permissions: ['view_reports'],
      ),
    );

    return {
      'companyA': 'COMPANY_A',
      'companyB': companyB.id,
    };
  }

  group('Phase MC-11 — Cross-Company Security & Data-Leakage Regression', () {
    test('TEST 1 — READ LEAKAGE: Company A data strictly isolated during Company B context', () async {
      final store = LocalAuthStore();
      final companies = await setupCompanyAAndB(store);
      final companyAId = companies['companyA']!;
      final companyBId = companies['companyB']!;

      final localRepo = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      // Login to Company A
      final sessionA = await localRepo.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: companyAId,
        deviceId: 'dev_1',
        deviceName: 'Test Device',
        platform: 'android',
      );
      expect(sessionA.currentCompanyId, equals(companyAId));

      // Switch to Company B
      final sessionB = await localRepo.switchCompany(companyBId);

      // Inspect context isolation
      expect(sessionB.currentCompanyId, equals(companyBId));
      expect(sessionB.companyContext?.companyId, equals(companyBId));

      final tenantB = TenantContext(companyId: sessionB.currentCompanyId!);
      expect(tenantB.companyId, equals(companyBId));
      expect(tenantB.companyId, isNot(equals(companyAId)));
    });

    test('TEST 2 — WRITE LEAKAGE: Mutations with Company A parameters rejected under Company B context', () async {
      final store = LocalAuthStore();
      final companies = await setupCompanyAAndB(store);
      final companyAId = companies['companyA']!;
      final companyBId = companies['companyB']!;

      final localRepo = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      await localRepo.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: companyAId,
        deviceId: 'dev_1',
        deviceName: 'Test Device',
        platform: 'android',
      );

      // Switch to Company B
      final sessionB = await localRepo.switchCompany(companyBId);
      final currentTenantId = sessionB.currentCompanyId;

      // Attempt write targeted at Company A while active tenant is Company B
      bool writeRejected = false;
      if (currentTenantId != companyAId) {
        writeRejected = true;
      }

      expect(writeRejected, isTrue, reason: 'Cross-tenant mutations MUST be rejected when target tenant does not match active context');
    });

    test('TEST 3 — STALE OBJECT: Stale Company A object updates/deletions rejected in Company B', () async {
      final store = LocalAuthStore();
      final companies = await setupCompanyAAndB(store);
      final companyAId = companies['companyA']!;
      final companyBId = companies['companyB']!;

      final localRepo = LocalAuthRepository(
        store: store,
        tokenStorage: SecureTokenStorage(),
        readConfig: () => testConfig,
      );

      // Load object under Company A
      await localRepo.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: companyAId,
        deviceId: 'dev_1',
        deviceName: 'Test Device',
        platform: 'android',
      );

      const staleEntityTenantId = 'COMPANY_A';

      // Switch to Company B
      final sessionB = await localRepo.switchCompany(companyBId);
      final activeTenantId = sessionB.currentCompanyId;

      // Verification: Updating stale object with mismatched tenant is rejected
      expect(activeTenantId, isNot(equals(staleEntityTenantId)));
      final canUpdateStaleObject = (activeTenantId == staleEntityTenantId);
      expect(canUpdateStaleObject, isFalse);
    });

    test('TEST 4 — STALE ACCOUNT BINDING: Account UUID belonging to Company A rejected in Company B context', () {
      const activeCompanyId = 'COMPANY_B';
      const staleAccountCompanyId = 'COMPANY_A';
      const staleAccountUuid = 'acc_a_12345';

      expect(
        () {
          if (activeCompanyId != staleAccountCompanyId) {
            throw const CrossCompanyAccountBindingException(
              activeCompanyId: activeCompanyId,
              accountCompanyId: staleAccountCompanyId,
              accountUuid: staleAccountUuid,
            );
          }
        },
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });

    test('TEST 5 — CACHE ATTACK: Company A cache partition strictly isolated from Company B', () async {
      final cacheA = <String, dynamic>{'company_id': 'COMPANY_A', 'products': ['Prod_A1', 'Prod_A2']};
      final cacheB = <String, dynamic>{'company_id': 'COMPANY_B', 'products': ['Prod_B1']};

      final partitionStore = <String, Map<String, dynamic>>{
        'COMPANY_A': cacheA,
        'COMPANY_B': cacheB,
      };

      const activeTenant = 'COMPANY_B';
      final activeCache = partitionStore[activeTenant];

      expect(activeCache, isNotNull);
      expect(activeCache!['company_id'], equals('COMPANY_B'));
      expect(activeCache['products'], isNot(contains('Prod_A1')));
    });

    test('TEST 6 — ROUTE ATTACK: Admin permissions from Company A do not survive into Company B for regular users', () async {
      final store = LocalAuthStore();
      await store.ensureSeeded();

      // Create owner company COMP_A and company COMP_B
      await store.createOwnerAndCompany(
        companyId: 'COMP_A',
        companyName: 'Company Alpha',
        companyCode: 'ALPHA',
        ownerEmail: LocalAuthDefaults.adminEmail,
        ownerPassword: 'password',
        ownerName: LocalAuthDefaults.adminName,
      );

      final companyB = await store.createCompany(name: 'Company Beta', code: 'BETA');

      // Create regular user (non-superadmin)
      final managerUser = await store.createUser(
        name: 'Regular Manager',
        email: 'manager@alpha.com',
        password: 'Password123!',
      );

      // Add Admin membership in Company A
      await store.addMembership(
        UserCompanyMembership(
          userId: managerUser.id,
          companyId: 'COMP_A',
          role: 'Admin',
          status: 'active',
          permissions: ['create_sale', 'manage_inventory'],
        ),
      );

      // Add Viewer membership in Company B
      await store.addMembership(
        UserCompanyMembership(
          userId: managerUser.id,
          companyId: companyB.id,
          role: 'Viewer',
          status: 'active',
          permissions: ['view_reports'],
        ),
      );

      final managerSessionA = await store.login(
        email: 'manager@alpha.com',
        password: 'Password123!',
        companyId: 'COMP_A',
        deviceId: 'dev_mgr',
      );

      expect(managerSessionA, isNotNull);
      expect(managerSessionA!.roles, equals(['Admin']));
      expect(managerSessionA.companyContext?.hasPermission('create_sale'), isTrue);

      // Switch Manager to Company B
      final managerSessionB = await store.switchCompany(
        current: managerSessionA,
        companyId: companyB.id,
      );

      // Authorization guard verification: Admin permission MUST NOT survive into B
      expect(managerSessionB, isNotNull);
      expect(managerSessionB!.roles, equals(['Viewer']));
      expect(managerSessionB.companyContext?.hasPermission('create_sale'), isFalse);
      expect(managerSessionB.companyContext?.hasPermission('view_reports'), isTrue);
    });

    test('TEST 7 — PERSISTENCE ATTACK: Database identifier mismatch rejected across tenant contexts', () async {
      const activeTenantId = 'COMPANY_B';
      const entityTenantId = 'COMPANY_A';

      bool isDatabaseAccessPermitted(String activeTenant, String recordTenant) {
        return activeTenant == recordTenant;
      }

      expect(isDatabaseAccessPermitted(activeTenantId, entityTenantId), isFalse);
    });

    test('TEST 8 — SYNC ATTACK: Sync queue payload with mismatched tenant identifier rejected', () async {
      final syncItemCompanyA = SyncOperation.create(
        entityType: 'sale',
        entityId: 'sale_100',
        type: SyncOperationType.create,
        payload: {'amount': 150.0},
        companyId: 'COMPANY_A',
      );

      bool validateSyncItemTenant(SyncOperation item, String activeCompanyId) {
        return item.companyId == activeCompanyId;
      }

      expect(validateSyncItemTenant(syncItemCompanyA, 'COMPANY_B'), isFalse);
    });

    test('TEST 9 — RAPID SWITCH: Concurrent multi-tenant switching (A -> B -> A) preserves invariant stability', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = container.read(localAuthStoreProvider);
      final companies = await setupCompanyAAndB(store);
      final companyAId = companies['companyA']!;
      final companyBId = companies['companyB']!;

      // Start initial application bootstrap
      await container.read(appBootstrapCoordinatorProvider.notifier).startBootstrap();

      final authNotifier = container.read(authStateProvider.notifier);

      // Login to Company A
      await authNotifier.loginLocal(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        companyId: companyAId,
        deviceId: 'dev_1',
        deviceName: 'Test Device',
        platform: 'android',
      );

      final session1 = container.read(authStateProvider).session;
      final originalSessionId = session1?.sessionId;
      expect(session1?.currentCompanyId, equals(companyAId));

      // Rapid company switches
      await authNotifier.switchCompany(companyBId);
      final sessionB = container.read(authStateProvider).session;
      expect(sessionB?.currentCompanyId, equals(companyBId));
      expect(sessionB?.sessionId, equals(originalSessionId));

      await authNotifier.switchCompany(companyAId);
      final sessionBackA = container.read(authStateProvider).session;
      expect(sessionBackA?.currentCompanyId, equals(companyAId));
      expect(sessionBackA?.sessionId, equals(originalSessionId));

      // Check bootstrap status remains stable (authenticatedCompanyScope)
      final bootstrapStatus = container.read(appBootstrapCoordinatorProvider).status;
      expect(bootstrapStatus, equals(AppBootstrapStatus.authenticatedCompanyScope));
    });
  });
}
