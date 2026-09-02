import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';

void main() {
  group('Phase 2 — Identity Model & SystemRole Invariants', () {
    test('Test 1: System Admin Identity can exist without any company context', () {
      const admin = AuthUser(
        id: 'admin_sys_01',
        name: 'System Admin',
        email: 'sysadmin@nexabiz.local',
        systemRole: SystemRole.systemAdmin,
      );

      expect(admin.isSystemAdmin, isTrue);
      expect(admin.systemRole, equals(SystemRole.systemAdmin));

      final session = AuthSessionSnapshot(
        user: admin,
        companies: const [],
        roles: const [],
        permissions: const {'system.companies.manage', 'system.users.manage'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: null,
        activeMembership: null,
        activeCompanyContext: null,
      );

      expect(session.systemRole, equals(SystemRole.systemAdmin));
      expect(session.companyContext, isNull);
      expect(session.activeCompanyId, isNull);
      expect(session.isUnattachedSession, isTrue);
    });

    test('Test 2: Regular User Identity exists independently of company', () {
      const user = AuthUser(
        id: 'user_reg_01',
        name: 'Regular User',
        email: 'user@nexabiz.local',
        systemRole: SystemRole.regularUser,
      );

      expect(user.isSystemAdmin, isFalse);
      expect(user.systemRole, equals(SystemRole.regularUser));
    });

    test('Test 3 & 4: Multiple Memberships with Different Roles per Company', () {
      const userId = 'user_multi_01';
      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: 'comp_alpha',
        role: 'Owner',
        status: 'active',
        permissions: const ['sales.create', 'sales.view', 'accounting.post'],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: 'comp_beta',
        role: 'Cashier',
        status: 'active',
        permissions: const ['sales.create'],
      );

      expect(membershipA.role, equals('Owner'));
      expect(membershipB.role, equals('Cashier'));
      expect(membershipA.companyId, isNot(equals(membershipB.companyId)));
    });

    test('Test 5: Permissions are strictly isolated per company ActiveCompanyContext', () {
      const userId = 'user_multi_01';
      final membershipA = UserCompanyMembership(
        userId: userId,
        companyId: 'comp_alpha',
        role: 'Accountant',
        status: 'active',
        permissions: const ['accounting.view', 'accounting.post'],
      );

      final membershipB = UserCompanyMembership(
        userId: userId,
        companyId: 'comp_beta',
        role: 'Cashier',
        status: 'active',
        permissions: const ['sales.create'],
      );

      final contextA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: userId,
      );

      final contextB = ActiveCompanyContext.fromMembership(
        membership: membershipB,
        authenticatedUserId: userId,
      );

      expect(contextA.hasPermission('accounting.post'), isTrue);
      expect(contextA.hasPermission('sales.create'), isFalse);

      expect(contextB.hasPermission('sales.create'), isTrue);
      expect(contextB.hasPermission('accounting.post'), isFalse);
    });

    test('Test 8: ActiveContext consistency (companyId matches membership)', () {
      const userId = 'user_01';
      const companyId = 'comp_delta';
      final membership = UserCompanyMembership(
        userId: userId,
        companyId: companyId,
        role: 'Manager',
        status: 'active',
        permissions: const ['inventory.view'],
      );

      final context = ActiveCompanyContext.fromMembership(
        membership: membership,
        authenticatedUserId: userId,
      );

      expect(context.companyId, equals(companyId));
      expect(context.membershipId, equals('${userId}_$companyId'));
      expect(context.companyRole, equals('Manager'));
    });

    test('Test 9: User identity remains immutable across active company changes', () {
      const user = AuthUser(
        id: 'user_stable_01',
        name: 'Stable Identity',
        email: 'stable@nexabiz.local',
        systemRole: SystemRole.regularUser,
      );

      final membershipA = UserCompanyMembership(
        userId: user.id,
        companyId: 'comp_1',
        role: 'Owner',
        status: 'active',
      );

      final membershipB = UserCompanyMembership(
        userId: user.id,
        companyId: 'comp_2',
        role: 'Auditor',
        status: 'active',
      );

      final contextA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: user.id,
      );

      final contextB = ActiveCompanyContext.fromMembership(
        membership: membershipB,
        authenticatedUserId: user.id,
      );

      expect(user.id, equals('user_stable_01'));
      expect(user.email, equals('stable@nexabiz.local'));

      // Context changes, identity remains unchanged
      expect(contextA.companyId, equals('comp_1'));
      expect(contextB.companyId, equals('comp_2'));
      expect(user.id, equals('user_stable_01'));
    });

    test('Test 10: SystemAdmin without company membership does NOT automatically receive company context', () {
      const sysAdmin = AuthUser(
        id: 'sysadmin_01',
        name: 'Pure System Admin',
        email: 'sysadmin@nexabiz.local',
        systemRole: SystemRole.systemAdmin,
      );

      final session = AuthSessionSnapshot(
        user: sysAdmin,
        companies: const [],
        roles: const [],
        permissions: const {'system.companies.manage'},
        capturedAt: DateTime.now().toUtc(),
      );

      expect(session.companyContext, isNull);
      expect(session.isCompanyBoundSession, isFalse);
    });
  });

  group('Phase 2 — Negative Security Tests', () {
    test('Test 6 / Negative Test 1: Cross-user membership activation is REJECTED', () {
      const currentUserId = 'user_victim_01';
      const attackerUserId = 'user_attacker_99';

      final attackerMembership = UserCompanyMembership(
        userId: attackerUserId,
        companyId: 'comp_target',
        role: 'Owner',
        status: 'active',
      );

      expect(
        () => ActiveCompanyContext.fromMembership(
          membership: attackerMembership,
          authenticatedUserId: currentUserId,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Test 7 / Negative Test 2: Inactive/revoked membership activation is REJECTED', () {
      const userId = 'user_01';
      final revokedMembership = UserCompanyMembership(
        userId: userId,
        companyId: 'comp_revoked',
        role: 'FormerOwner',
        status: 'inactive',
      );

      expect(
        () => ActiveCompanyContext.fromMembership(
          membership: revokedMembership,
          authenticatedUserId: userId,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Negative Test 3: Session fallback rejects membership with mismatched userId', () {
      const userA = AuthUser(
        id: 'user_A',
        name: 'User A',
        email: 'usera@nexabiz.local',
      );

      final membershipB = UserCompanyMembership(
        userId: 'user_B', // Mismatched!
        companyId: 'comp_shared',
        role: 'Owner',
        status: 'active',
      );

      final session = AuthSessionSnapshot(
        user: userA,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'comp_shared',
        activeMembership: membershipB,
      );

      // Session context fallback must reject the mismatched membership
      expect(session.companyContext, isNull);
      expect(session.activeCompanyId, isNull);
    });
  });
}
