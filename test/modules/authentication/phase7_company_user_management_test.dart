import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalAuthStore authStore;

  setUp(() async {
    Hive.init('./test_hive_phase7');
    authStore = LocalAuthStore();
    await authStore.clearAuthData();
  });

  tearDown(() async {
    await authStore.clearAuthData();
    await Hive.deleteFromDisk();
  });

  group('Phase 7 — Company & User Management Tests', () {
    test('1. Create Company — Creates AuthCompany without mutating AuthUser identities', () async {
      final admin = await authStore.createInitialSystemAdmin(
        name: 'System Admin',
        email: 'sysadmin@nexabiz.system',
        password: 'AdminPassword123!',
      );

      final company = await authStore.createCompany(
        name: 'Alpha Enterprise',
        code: 'ALPHA',
      );

      expect(company.name, equals('Alpha Enterprise'));
      expect(company.code, equals('ALPHA'));

      // Verify that System Admin identity was NOT mutated and has 0 memberships
      final session = await authStore.login(
        email: 'sysadmin@nexabiz.system',
        password: 'AdminPassword123!',
        deviceId: 'dev_test',
      );

      expect(session, isNotNull);
      expect(session!.user.id, equals(admin.id));
      expect(session.user.systemRole, equals(SystemRole.systemAdmin));
      // System Admin has zero company memberships
      expect(session.activeCompanyContext, isNull);
    });

    test('2. Create User — Creates AuthUser identity without auto-creating a company', () async {
      final newUser = await authStore.createUser(
        name: 'John Doe',
        email: 'john@nexabiz.local',
        password: 'UserPassword123!',
        systemRole: SystemRole.regularUser,
      );

      expect(newUser.id, isNotEmpty);
      expect(newUser.name, equals('John Doe'));
      expect(newUser.email, equals('john@nexabiz.local'));
      expect(newUser.systemRole, equals(SystemRole.regularUser));

      // Attempt login with newly created user
      final session = await authStore.login(
        email: 'john@nexabiz.local',
        password: 'UserPassword123!',
        deviceId: 'dev_test',
      );

      expect(session, isNotNull);
      expect(session!.companies, isEmpty);
      expect(session.activeCompanyContext, isNull);
    });

    test('Duplicate User & Duplicate Company creation are rejected', () async {
      await authStore.createCompany(name: 'Alpha Corp', code: 'ALPHA');
      expect(
        () => authStore.createCompany(name: 'Alpha Corp', code: 'ALPHA'),
        throwsStateError,
      );

      await authStore.createUser(
        name: 'Jane Doe',
        email: 'jane@nexabiz.local',
        password: 'Password123!',
      );
      expect(
        () => authStore.createUser(
          name: 'Jane Clone',
          email: 'jane@nexabiz.local',
          password: 'Password123!',
        ),
        throwsStateError,
      );
    });

    test('3. Create Membership — Binds User and Company with specific role and permissions', () async {
      final user = await authStore.createUser(
        name: 'Alice Manager',
        email: 'alice@nexabiz.local',
        password: 'Password123!',
      );

      final company = await authStore.createCompany(
        name: 'Beta Trading',
        code: 'BETA',
      );

      final membership = await authStore.createMembership(
        userId: user.id,
        companyId: company.id,
        role: 'SalesManager',
        permissions: const [LocalPermissions.salesCreate, LocalPermissions.salesView],
      );

      expect(membership.userId, equals(user.id));
      expect(membership.companyId, equals(company.id));
      expect(membership.role, equals('SalesManager'));
      expect(membership.permissions, contains(LocalPermissions.salesCreate));

      // Login to verify membership & active context binding
      final session = await authStore.login(
        email: 'alice@nexabiz.local',
        password: 'Password123!',
        companyId: company.id,
        deviceId: 'dev_test',
      );

      expect(session, isNotNull);
      expect(session!.activeCompanyId, equals(company.id));
      expect(session.activeCompanyContext, isNotNull);
      expect(session.hasPermission(LocalPermissions.salesCreate), isTrue);
      expect(session.hasPermission(LocalPermissions.accountingJournalsPost), isFalse);
    });

    test('4, 5, 6. Membership Security Validation (Duplicate, Invalid User, Invalid Company)', () async {
      final user = await authStore.createUser(
        name: 'Bob Staff',
        email: 'bob@nexabiz.local',
        password: 'Password123!',
      );

      final company = await authStore.createCompany(
        name: 'Gamma Logistics',
        code: 'GAMMA',
      );

      // Invalid user ID
      expect(
        () => authStore.createMembership(
          userId: 'nonexistent_user',
          companyId: company.id,
          role: 'Member',
        ),
        throwsArgumentError,
      );

      // Invalid company ID
      expect(
        () => authStore.createMembership(
          userId: user.id,
          companyId: 'nonexistent_company',
          role: 'Member',
        ),
        throwsArgumentError,
      );

      // Successful membership creation
      await authStore.createMembership(
        userId: user.id,
        companyId: company.id,
        role: 'Member',
      );

      // Duplicate membership creation
      expect(
        () => authStore.createMembership(
          userId: user.id,
          companyId: company.id,
          role: 'Member',
        ),
        throwsStateError,
      );
    });

    test('7, 8, 9. Multi-Company Membership & Strict Permission Isolation', () async {
      final user = await authStore.createUser(
        name: 'Multi-Company User',
        email: 'multi@nexabiz.local',
        password: 'Password123!',
      );

      final companyA = await authStore.createCompany(name: 'Retail Store', code: 'RETAIL');
      final companyB = await authStore.createCompany(name: 'HQ Holding', code: 'HQ');

      // Membership A: Sales Manager in Retail Store
      final memA = await authStore.createMembership(
        userId: user.id,
        companyId: companyA.id,
        role: 'SalesManager',
        permissions: const [LocalPermissions.salesCreate, LocalPermissions.salesView],
      );

      // Membership B: Accountant in HQ Holding
      final memB = await authStore.createMembership(
        userId: user.id,
        companyId: companyB.id,
        role: 'Accountant',
        permissions: const [LocalPermissions.accountingJournalsPost, LocalPermissions.accountingView],
      );

      expect(memA.role, equals('SalesManager'));
      expect(memB.role, equals('Accountant'));

      // Validate Context A
      final contextA = ActiveCompanyContext.fromMembership(
        membership: memA,
        authenticatedUserId: user.id,
      );
      expect(contextA.hasPermission(LocalPermissions.salesCreate), isTrue);
      expect(contextA.hasPermission(LocalPermissions.accountingJournalsPost), isFalse);

      // Validate Context B
      final contextB = ActiveCompanyContext.fromMembership(
        membership: memB,
        authenticatedUserId: user.id,
      );
      expect(contextB.hasPermission(LocalPermissions.salesCreate), isFalse);
      expect(contextB.hasPermission(LocalPermissions.accountingJournalsPost), isTrue);
    });

    test('10. Membership Deactivation — Inactive membership cannot activate company context', () async {
      final user = await authStore.createUser(
        name: 'Inactive User',
        email: 'inactive@nexabiz.local',
        password: 'Password123!',
      );

      final company = await authStore.createCompany(name: 'Delta Services', code: 'DELTA');

      final mem = await authStore.createMembership(
        userId: user.id,
        companyId: company.id,
        role: 'Member',
        status: 'active',
      );

      // Deactivate membership
      final deactivatedMem = await authStore.updateMembershipStatus(
        userId: user.id,
        companyId: company.id,
        status: 'inactive',
      );

      expect(deactivatedMem.status, equals('inactive'));

      // ActiveCompanyContext constructor must throw StateError on inactive membership
      expect(
        () => ActiveCompanyContext.fromMembership(
          membership: deactivatedMem,
          authenticatedUserId: user.id,
        ),
        throwsStateError,
      );
    });
  });
}
