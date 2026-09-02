import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';

void main() {
  group('Phase 6 — System Administrator Authority Boundary Tests', () {
    test('1 & 5. System Admin exists independently without companies (activeCompanyContext == null)', () {
      const adminUser = AuthUser(
        id: 'sys_admin_001',
        name: 'System Administrator',
        email: 'admin@nexabiz.system',
        systemRole: SystemRole.systemAdmin,
        status: 'active',
      );

      final session = AuthSessionSnapshot(
        user: adminUser,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: null,
        activeMembership: null,
        activeCompanyContext: null,
        sessionId: 'sess_admin_sys_only',
      );

      expect(session.user.systemRole, equals(SystemRole.systemAdmin));
      expect(session.user.isSystemAdmin, isTrue);
      expect(session.companies, isEmpty);
      expect(session.currentCompanyId, isNull);
      expect(session.activeCompanyContext, isNull);
      expect(session.isValidSecuritySession, isTrue);
    });

    test('2. System Admin has system-level authority (system.config.manage, platform.companies.manage, etc.)', () {
      const adminUser = AuthUser(
        id: 'sys_admin_001',
        name: 'System Administrator',
        email: 'admin@nexabiz.system',
        systemRole: SystemRole.systemAdmin,
        status: 'active',
      );

      final session = AuthSessionSnapshot(
        user: adminUser,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        activeCompanyContext: null,
      );

      expect(session.hasPermission(LocalPermissions.platformCompaniesManage), isTrue);
      expect(session.hasPermission(LocalPermissions.platformUsersManage), isTrue);
      expect(session.hasPermission(LocalPermissions.systemConfigManage), isTrue);
      expect(session.hasPermission(LocalPermissions.settingsView), isTrue);
      expect(session.hasPermission(LocalPermissions.syncExecute), isTrue);
    });

    test('3 & 4. Company permissions are NOT fabricated from system role when company context is null', () {
      const adminUser = AuthUser(
        id: 'sys_admin_001',
        name: 'System Administrator',
        email: 'admin@nexabiz.system',
        systemRole: SystemRole.systemAdmin,
        status: 'active',
      );

      final session = AuthSessionSnapshot(
        user: adminUser,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        activeCompanyContext: null,
      );

      // Verify that company-scoped operational permissions return FALSE
      expect(session.hasPermission(LocalPermissions.salesCreate), isFalse);
      expect(session.hasPermission(LocalPermissions.salesView), isFalse);
      expect(session.hasPermission(LocalPermissions.inventoryView), isFalse);
      expect(session.hasPermission(LocalPermissions.accountingJournalsPost), isFalse);
      expect(session.hasPermission(LocalPermissions.reportsSalesPeriodView), isFalse);
      expect(session.hasPermission(LocalPermissions.customersCreate), isFalse);
    });

    test('6. Company-scoped operations strictly require appropriate active company context', () {
      const adminUser = AuthUser(
        id: 'sys_admin_001',
        name: 'System Administrator',
        email: 'admin@nexabiz.system',
        systemRole: SystemRole.systemAdmin,
        status: 'active',
      );

      const salesMembership = UserCompanyMembership(
        userId: 'sys_admin_001',
        companyId: 'company_retail',
        role: 'SalesManager',
        status: 'active',
        permissions: [LocalPermissions.salesCreate, LocalPermissions.salesView],
      );

      final salesContext = ActiveCompanyContext.fromMembership(
        membership: salesMembership,
        authenticatedUserId: adminUser.id,
      );

      final sessionWithContext = AuthSessionSnapshot(
        user: adminUser,
        companies: const [],
        roles: const ['SalesManager'],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'company_retail',
        activeMembership: salesMembership,
        activeCompanyContext: salesContext,
      );

      // Inside company_retail context: sales.create is granted via explicit membership
      expect(sessionWithContext.hasPermission(LocalPermissions.salesCreate), isTrue);
      expect(sessionWithContext.hasPermission(LocalPermissions.salesView), isTrue);

      // Accounting journals post is NOT in salesMembership -> MUST FAIL CLOSED
      expect(sessionWithContext.hasPermission(LocalPermissions.accountingJournalsPost), isFalse);

      // System authority is still preserved
      expect(sessionWithContext.hasPermission(LocalPermissions.systemConfigManage), isTrue);

      // Clearing active context returns to system-only scope where sales.create is FALSE
      final sessionWithoutContext = sessionWithContext.copyWith(clearCompany: true);
      expect(sessionWithoutContext.activeCompanyContext, isNull);
      expect(sessionWithoutContext.hasPermission(LocalPermissions.salesCreate), isFalse);
    });

    test('Regular user without systemRole cannot execute system-level operations', () {
      const regularUser = AuthUser(
        id: 'user_regular_123',
        name: 'Regular Staff',
        email: 'staff@nexabiz.local',
        systemRole: SystemRole.regularUser,
        status: 'active',
      );

      const membership = UserCompanyMembership(
        userId: 'user_regular_123',
        companyId: 'company_retail',
        role: 'Cashier',
        status: 'active',
        permissions: [LocalPermissions.salesCreate],
      );

      final context = ActiveCompanyContext.fromMembership(
        membership: membership,
        authenticatedUserId: regularUser.id,
      );

      final session = AuthSessionSnapshot(
        user: regularUser,
        companies: const [],
        roles: const ['Cashier'],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'company_retail',
        activeMembership: membership,
        activeCompanyContext: context,
      );

      // Regular user gets company permission from active context
      expect(session.hasPermission(LocalPermissions.salesCreate), isTrue);

      // Regular user DOES NOT get system permissions
      expect(session.hasPermission(LocalPermissions.systemConfigManage), isFalse);
      expect(session.hasPermission(LocalPermissions.platformCompaniesManage), isFalse);
    });
  });
}
