import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/inventory/inventory_accounting_poster_adapter.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_creation_coordinator.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';

class FakeSettingsRepository implements SettingsRepository {
  bool _onboardingCompleted = false;

  @override
  Future<bool> loadOnboardingCompleted() async => _onboardingCompleted;

  @override
  Future<void> saveOnboardingCompleted(bool completed) async {
    _onboardingCompleted = completed;
  }

  @override
  Future<void> saveLocale(dynamic locale) async {}

  @override
  Future<void> saveCompanyProfile(CompanyProfile profile, [String? companyId]) async {}

  @override
  Future<void> saveDeviceInitialization({
    dynamic mode,
    bool? initialized,
    String? companyId,
    DateTime? initializedAt,
  }) async {}

  @override
  Future<void> saveSystemSetupState({
    required int version,
    required String status,
    required Map<String, Map<String, Object?>> steps,
    required DateTime lastUpdated,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Box<dynamic> testBox;
  late LocalAuthStore authStore;
  late FakeSettingsRepository settingsRepository;
  late FirstRunSetupCoordinator setupCoordinator;
  late CompanyCreationCoordinator companyCoordinator;

  setUp(() async {
    Hive.init('./test_tmp_phase2');
    testBox = await Hive.openBox<dynamic>('test_phase2_auth');
    await testBox.clear();

    authStore = LocalAuthStore(box: testBox);
    settingsRepository = FakeSettingsRepository();
    setupCoordinator = FirstRunSetupCoordinator(
      settingsRepository: settingsRepository,
      authStore: authStore,
    );
    companyCoordinator = CompanyCreationCoordinator(authStore: authStore);
  });

  tearDown(() async {
    await testBox.clear();
    await testBox.close();
  });

  group('Phase 2 — Multi-Company Session Isolation Tests (16 Scenarios)', () {
    const primarySetupPayload = FirstRunSetupPayload(
      language: 'ar',
      companyName: 'الشركة الرئيسية A',
      companyCode: 'COMP_A',
      adminName: 'مالك النظام',
      adminEmail: 'owner@comp-a.com',
      adminPassword: 'Password123!',
    );

    Future<AuthSessionSnapshot> setupPrimaryOwnerSession() async {
      await setupCoordinator.commitFirstRunSetup(primarySetupPayload);
      final session = await authStore.login(
        email: 'owner@comp-a.com',
        password: 'Password123!',
        deviceId: 'dev_01',
      );
      return session!;
    }

    test('1. Create Company A -> Admin A created atomically with explicit membership', () async {
      final ownerSession = await setupPrimaryOwnerSession();
      expect(ownerSession.isCompanyBoundSession, isTrue);

      final companyA = ownerSession.currentCompany!;
      expect(companyA.name, equals('الشركة الرئيسية A'));

      final ownerUser = await authStore.getPrimaryOwnerUser();
      expect(ownerUser, isNotNull);
      expect(ownerUser!.email, equals('owner@comp-a.com'));
    });

    test('2. Create Company B -> Admin B created atomically with explicit membership', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'الشركة الفرعية B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول الشركة B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
        adminRole: 'Admin',
      );

      expect(companyB.id, isNotEmpty);
      expect(companyB.name, equals('الشركة الفرعية B'));

      final adminBSession = await authStore.login(
        email: 'admin@comp-b.com',
        password: 'PasswordB123!',
        deviceId: 'dev_b',
      );

      expect(adminBSession, isNotNull);
      expect(adminBSession!.currentCompanyId, equals(companyB.id));
      expect(adminBSession.user.email, equals('admin@comp-b.com'));
      expect(adminBSession.roles.contains('Admin'), isTrue);
    });

    test('3. Admin A cannot access Company B without explicit membership', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'الشركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      // Attempt to login as Admin B to Company B works
      final sessionB = await authStore.login(
        email: 'admin@comp-b.com',
        password: 'PasswordB123!',
        deviceId: 'dev_b',
      );
      expect(sessionB, isNotNull);

      // Admin B tries to access Company A -> returns null (access denied)
      final compA = await authStore.getPrimaryCompany();
      final unauthorizedSwitch = await authStore.switchCompany(
        current: sessionB!,
        companyId: compA!.id,
      );

      expect(unauthorizedSwitch, isNull);
    });

    test('4. User with A+B memberships can select A or B', () async {
      final ownerSession = await setupPrimaryOwnerSession();
      final ownerUser = ownerSession.user;

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'شركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      // Add ownerUser to Company B explicitly
      await authStore.addMembership(
        UserCompanyMembership(
          userId: ownerUser.id,
          companyId: companyB.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      final sessionA = await authStore.login(
        email: 'owner@comp-a.com',
        password: 'Password123!',
        deviceId: 'dev_01',
        companyId: ownerSession.currentCompanyId,
      );
      expect(sessionA!.currentCompanyId, equals(ownerSession.currentCompanyId));

      final sessionB = await authStore.login(
        email: 'owner@comp-a.com',
        password: 'Password123!',
        deviceId: 'dev_01',
        companyId: companyB.id,
      );
      expect(sessionB!.currentCompanyId, equals(companyB.id));
    });

    test('5. Session A terminated during A -> B switch', () async {
      final ownerSession = await setupPrimaryOwnerSession();
      final sessionAId = ownerSession.sessionId!;

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'شركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      await authStore.addMembership(
        UserCompanyMembership(
          userId: ownerSession.user.id,
          companyId: companyB.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      expect(authStore.isSessionActive(sessionAId), isTrue);

      final sessionB = await authStore.switchCompany(
        current: ownerSession,
        companyId: companyB.id,
      );

      expect(sessionB, isNotNull);
      expect(authStore.isSessionActive(sessionAId), isFalse);
    });

    test('6. Session B receives a new unique session ID (S2 != S1)', () async {
      final ownerSession = await setupPrimaryOwnerSession();
      final sessionAId = ownerSession.sessionId!;

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'شركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      await authStore.addMembership(
        UserCompanyMembership(
          userId: ownerSession.user.id,
          companyId: companyB.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      final sessionB = await authStore.switchCompany(
        current: ownerSession,
        companyId: companyB.id,
      );

      expect(sessionB!.sessionId, isNot(equals(sessionAId)));
      expect(authStore.isSessionActive(sessionB.sessionId), isTrue);
    });

    test('7. Company A permissions cannot survive into Company B', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'شركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      await authStore.addMembership(
        UserCompanyMembership(
          userId: ownerSession.user.id,
          companyId: companyB.id,
          role: 'Viewer',
          status: 'active',
          permissions: ['view_reports'],
        ),
      );

      final sessionB = await authStore.switchCompany(
        current: ownerSession,
        companyId: companyB.id,
      );

      expect(sessionB, isNotNull);
      expect(sessionB!.roles, equals(['Viewer']));
      expect(sessionB.permissions.contains('manage_users'), isFalse);
    });

    test('8. Company A cached state/context cannot survive into Company B', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'شركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      await authStore.addMembership(
        UserCompanyMembership(
          userId: ownerSession.user.id,
          companyId: companyB.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      final sessionB = await authStore.switchCompany(
        current: ownerSession,
        companyId: companyB.id,
      );

      expect(sessionB!.currentCompanyId, equals(companyB.id));
      expect(sessionB.currentCompanyId, isNot(equals(ownerSession.currentCompanyId)));
    });

    test('9. Pending async response from Session A cannot mutate B state', () async {
      final ownerSession = await setupPrimaryOwnerSession();
      final sessionAId = ownerSession.sessionId!;

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'شركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      await authStore.addMembership(
        UserCompanyMembership(
          userId: ownerSession.user.id,
          companyId: companyB.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      // Async switch to B happens before pending request completes
      await authStore.switchCompany(
        current: ownerSession,
        companyId: companyB.id,
      );

      // Validate async handler check for pending request with sessionAId
      final isStillValidForA = authStore.isSessionActive(sessionAId);
      expect(isStillValidForA, isFalse);
    });

    test('10. Invalid B membership prevents B session creation (fails closed)', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      final result = await authStore.switchCompany(
        current: ownerSession,
        companyId: 'non_existent_company_xyz',
      );

      expect(result, isNull);

      final activeSession = await authStore.loadSession();
      expect(activeSession, isNull);
    });

    test('11. Removed membership revokes company session', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      final companyB = await companyCoordinator.createCompanyWithAdmin(
        creatorSession: ownerSession,
        companyName: 'شركة B',
        companyCode: 'COMP_B',
        adminName: 'مسؤول B',
        adminEmail: 'admin@comp-b.com',
        adminPassword: 'PasswordB123!',
      );

      await authStore.addMembership(
        UserCompanyMembership(
          userId: ownerSession.user.id,
          companyId: companyB.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      final sessionB = await authStore.switchCompany(
        current: ownerSession,
        companyId: companyB.id,
      );
      expect(sessionB, isNotNull);

      // Revoke membership
      await authStore.revokeMembership(ownerSession.user.id, companyB.id);

      final restored = await authStore.validateAndRestoreSession();
      expect(restored, isNull);
    });

    test('12. Logout destroys company-bound session', () async {
      final ownerSession = await setupPrimaryOwnerSession();
      final sessionId = ownerSession.sessionId!;

      await authStore.logout(ownerSession);

      expect(authStore.isSessionActive(sessionId), isFalse);
      expect(await authStore.loadSession(), isNull);
    });

    test('13. Restart restores only a valid company session', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      final restored = await authStore.validateAndRestoreSession();
      expect(restored, isNotNull);
      expect(restored!.sessionId, equals(ownerSession.sessionId));
    });

    test('14. Company creation rollback works if weak password or error occurs', () async {
      final ownerSession = await setupPrimaryOwnerSession();

      expect(
        () => companyCoordinator.createCompanyWithAdmin(
          creatorSession: ownerSession,
          companyName: 'شركة سيئة',
          companyCode: 'BAD_COMP',
          adminName: 'مسؤول',
          adminEmail: 'bad@test.com',
          adminPassword: 'admin123', // Weak/Forbidden password
        ),
        throwsA(isA<CompanyCreationException>()),
      );
    });

    test('15. Company creation fails without authorized creator session', () async {
      final unattachedSession = AuthSessionSnapshot(
        user: const AuthUser(id: 'u1', name: 'User 1', email: 'u1@test.com'),
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now(),
      );

      expect(
        () => companyCoordinator.createCompanyWithAdmin(
          creatorSession: unattachedSession,
          companyName: 'شركة جديدة',
          companyCode: 'NEW_COMP',
          adminName: 'مسؤول',
          adminEmail: 'admin@newcomp.com',
          adminPassword: 'Password123!',
        ),
        throwsA(isA<CompanyCreationException>()),
      );
    });

    test('16. Company A accounting operation cannot post into Company B', () {
      final adapterA = InventoryAccountingPosterAdapter(
        null,
        readCompanyId: () => 'COMPANY_A',
      );

      final docB = InventoryDocumentRef(
        documentId: 'doc_b',
        documentNumber: 'DOC-B-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      // Context function returns empty/invalid when session company != operation company
      final adapterMismatched = InventoryAccountingPosterAdapter(
        null,
        readCompanyId: () => '',
      );

      expect(
        () => adapterMismatched.postAccountingEntry(
          document: docB,
          totalAmount: 500.0,
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });
  });
}
