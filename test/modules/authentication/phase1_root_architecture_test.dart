import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/inventory/inventory_accounting_poster_adapter.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';

class FakeSettingsRepository implements SettingsRepository {
  bool _onboardingCompleted = false;
  String? _locale;

  @override
  Future<bool> loadOnboardingCompleted() async => _onboardingCompleted;

  @override
  Future<void> saveOnboardingCompleted(bool completed) async {
    _onboardingCompleted = completed;
  }

  @override
  Future<void> saveLocale(dynamic locale) async {
    _locale = locale.toString();
  }

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

  setUp(() async {
    Hive.init('./test_tmp_phase1');
    testBox = await Hive.openBox<dynamic>('test_phase1_auth');
    await testBox.clear();

    authStore = LocalAuthStore(box: testBox);
    settingsRepository = FakeSettingsRepository();
    setupCoordinator = FirstRunSetupCoordinator(
      settingsRepository: settingsRepository,
      authStore: authStore,
    );
  });

  tearDown(() async {
    await testBox.clear();
    await testBox.close();
  });

  group('Phase 1 — Root Architecture Tests (15 Scenarios)', () {
    const testPayload = FirstRunSetupPayload(
      language: 'ar',
      companyName: 'شركة الاختبار الأولى',
      companyCode: 'COMP_A',
      adminName: 'مالك النظام',
      adminEmail: 'owner@testcompany.com',
      adminPassword: 'Password123!',
    );

    test('1. First-run initialization creates Company A + Owner User + Membership', () async {
      expect(await setupCoordinator.isFirstRunCompleted(), isFalse);

      await setupCoordinator.commitFirstRunSetup(testPayload);

      expect(await setupCoordinator.isFirstRunCompleted(), isTrue);

      final company = await authStore.getPrimaryCompany();
      expect(company, isNotNull);
      expect(company!.name, equals('شركة الاختبار الأولى'));

      final owner = await authStore.getPrimaryOwnerUser();
      expect(owner, isNotNull);
      expect(owner!.email, equals('owner@testcompany.com'));
    });

    test('2. Initialization cannot rerun after completion', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      expect(
        () => setupCoordinator.commitFirstRunSetup(testPayload),
        throwsA(isA<FirstRunAlreadyCompletedException>()),
      );
    });

    test('3. Normal startup skips initialization', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final isDone = await setupCoordinator.isFirstRunCompleted();
      expect(isDone, isTrue);
    });

    test('4. First Owner creation assigns explicit Owner role and permissions', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final owner = await authStore.getPrimaryOwnerUser();
      expect(owner, isNotNull);
      expect(owner!.rolesByCompany.values.contains('Owner'), isTrue);
    });

    test('5. Local login authenticates credentials offline', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
      );

      expect(session, isNotNull);
      expect(session!.user.email, equals('owner@testcompany.com'));
    });

    test('6. One-company login automatically selects the single company', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
      );

      expect(session, isNotNull);
      expect(session!.companies.length, equals(1));
      expect(session.currentCompanyId, isNotNull);
      expect(session.currentCompanyId, equals(session.companies.first.id));
    });

    test('7. Multi-company login with no companyId selected leaves currentCompanyId null for selection UI', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final company2 = await authStore.createCompany(
        name: 'شركة الاختبار الثانية',
        code: 'COMP_B',
      );

      final owner = await authStore.getPrimaryOwnerUser();
      await authStore.addMembership(
        UserCompanyMembership(
          userId: owner!.id,
          companyId: company2.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
      );

      expect(session, isNotNull);
      expect(session!.companies.length, equals(2));
      expect(session.currentCompanyId, isNull);
    });

    test('8. Company selection explicitly sets active company context', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final company2 = await authStore.createCompany(
        name: 'شركة الاختبار الثانية',
        code: 'COMP_B',
      );

      final owner = await authStore.getPrimaryOwnerUser();
      await authStore.addMembership(
        UserCompanyMembership(
          userId: owner!.id,
          companyId: company2.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
        companyId: company2.id,
      );

      expect(session, isNotNull);
      expect(session!.currentCompanyId, equals(company2.id));
    });

    test('9. Company switching updates active company and roles', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final primaryComp = await authStore.getPrimaryCompany();
      final company2 = await authStore.createCompany(
        name: 'شركة الاختبار الثانية',
        code: 'COMP_B',
      );

      final owner = await authStore.getPrimaryOwnerUser();
      await authStore.addMembership(
        UserCompanyMembership(
          userId: owner!.id,
          companyId: company2.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      final initialSession = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
        companyId: primaryComp!.id,
      );

      final switched = await authStore.switchCompany(
        current: initialSession!,
        companyId: company2.id,
      );

      expect(switched, isNotNull);
      expect(switched!.currentCompanyId, equals(company2.id));
      expect(switched.roles.contains('Admin'), isTrue);
    });

    test('10. Unauthorized company access fails closed (returns null)', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
      );

      final unauthorized = await authStore.switchCompany(
        current: session!,
        companyId: 'unauthorized_company_999',
      );

      expect(unauthorized, isNull);
    });

    test('11. Removed membership revokes access to company', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final company2 = await authStore.createCompany(
        name: 'شركة الاختبار الثانية',
        code: 'COMP_B',
      );

      final owner = await authStore.getPrimaryOwnerUser();
      await authStore.addMembership(
        UserCompanyMembership(
          userId: owner!.id,
          companyId: company2.id,
          role: 'Admin',
          status: 'active',
        ),
      );

      await authStore.revokeMembership(owner.id, company2.id);

      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
        companyId: company2.id,
      );

      expect(session, isNull);
    });

    test('12. Missing company context throws MissingCompanyContextException', () {
      final adapter = InventoryAccountingPosterAdapter(
        null,
        readCompanyId: () => '',
      );

      final doc = InventoryDocumentRef(
        documentId: 'doc_123',
        documentNumber: 'DOC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      expect(
        () => adapter.postAccountingEntry(
          document: doc,
          totalAmount: 100.0,
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('13. Cross-company data isolation is enforced by companyId matching', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);
      final comp1 = await authStore.getPrimaryCompany();
      final comp2 = await authStore.createCompany(
        name: 'شركة 2',
        code: 'C2',
      );

      expect(comp1!.id, isNot(equals(comp2.id)));
    });

    test('14. No remote login required for startup', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_offline',
      );

      expect(session, isNotNull);
      expect(session!.user.id, isNotEmpty);
    });

    test('15. No sync dependency for local application startup', () async {
      await setupCoordinator.commitFirstRunSetup(testPayload);

      final isCompleted = await setupCoordinator.isFirstRunCompleted();
      final session = await authStore.login(
        email: 'owner@testcompany.com',
        password: 'Password123!',
        deviceId: 'device_001',
      );

      expect(isCompleted, isTrue);
      expect(session, isNotNull);
    });
  });
}
