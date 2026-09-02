import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';

void main() {
  const guard = LocalAuthorizationGuard();

  final company1 = const AuthCompany(
    id: 'company-1',
    name: 'Company Alpha',
    code: 'ALPHA',
  );

  final company2 = const AuthCompany(
    id: 'company-2',
    name: 'Company Beta',
    code: 'BETA',
  );

  final regularUser = const AuthUser(
    id: 'user-100',
    email: 'user@alpha.com',
    name: 'Regular User',
    systemRole: SystemRole.regularUser,
  );

  final systemAdmin = const AuthUser(
    id: 'sysadmin-1',
    email: 'admin@system.com',
    name: 'System Admin',
    systemRole: SystemRole.systemAdmin,
  );

  final membershipComp1 = const UserCompanyMembership(
    userId: 'user-100',
    companyId: 'company-1',
    role: 'SalesManager',
    permissions: [LocalPermissions.salesView, LocalPermissions.salesCreate],
    status: 'active',
  );

  final membershipComp2 = const UserCompanyMembership(
    userId: 'user-100',
    companyId: 'company-2',
    role: 'InventoryClerk',
    permissions: [LocalPermissions.inventoryView],
    status: 'active',
  );

  final inactiveMembership = const UserCompanyMembership(
    userId: 'user-100',
    companyId: 'company-1',
    role: 'SalesManager',
    permissions: [LocalPermissions.salesView],
    status: 'inactive',
  );

  final entitlement = Entitlement.freeLocal('company-1');
  final now = DateTime.now().toUtc();

  group('Phase 8: Authorization & RBAC Integration Tests', () {
    test('1. Allowed permission: Granted company permission passes guard', () {
      final activeCtx = ActiveCompanyContext.fromMembership(
        membership: membershipComp1,
        authenticatedUserId: regularUser.id,
        companyName: company1.name,
        companyCode: company1.code,
      );

      final session = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1, company2],
        roles: ['SalesManager'],
        permissions: membershipComp1.permissions.toSet(),
        currentCompanyId: company1.id,
        activeMembership: membershipComp1,
        activeCompanyContext: activeCtx,
        capturedAt: now,
      );

      final authContext = AuthorizationContext.fromSession(
        session: session,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: authContext,
          requiredPermission: LocalPermissions.salesView,
          targetCompanyId: company1.id,
        ),
        returnsNormally,
      );
    });

    test('2. Denied permission: Unassigned company permission throws UnauthorizedException', () {
      final activeCtx = ActiveCompanyContext.fromMembership(
        membership: membershipComp1,
        authenticatedUserId: regularUser.id,
        companyName: company1.name,
        companyCode: company1.code,
      );

      final session = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1],
        roles: ['SalesManager'],
        permissions: membershipComp1.permissions.toSet(),
        currentCompanyId: company1.id,
        activeMembership: membershipComp1,
        activeCompanyContext: activeCtx,
        capturedAt: now,
      );

      final authContext = AuthorizationContext.fromSession(
        session: session,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: authContext,
          requiredPermission: LocalPermissions.salesDelete,
          targetCompanyId: company1.id,
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('3. No active company: Company-scoped operation without active company throws MissingAuthorizationContextException', () {
      final session = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1],
        roles: [],
        permissions: {},
        currentCompanyId: null,
        capturedAt: now,
      );

      final authContext = AuthorizationContext.fromSession(
        session: session,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: authContext,
          requiredPermission: LocalPermissions.salesView,
        ),
        throwsA(isA<MissingAuthorizationContextException>()),
      );
    });

    test('4. Wrong company: Target company mismatch throws CompanyContextMismatchException', () {
      final activeCtx = ActiveCompanyContext.fromMembership(
        membership: membershipComp1,
        authenticatedUserId: regularUser.id,
        companyName: company1.name,
        companyCode: company1.code,
      );

      final session = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1, company2],
        roles: ['SalesManager'],
        permissions: membershipComp1.permissions.toSet(),
        currentCompanyId: company1.id,
        activeMembership: membershipComp1,
        activeCompanyContext: activeCtx,
        capturedAt: now,
      );

      final authContext = AuthorizationContext.fromSession(
        session: session,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: authContext,
          requiredPermission: LocalPermissions.salesView,
          targetCompanyId: company2.id,
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );
    });

    test('5. Inactive membership: Operation under inactive membership throws UnauthorizedException', () {
      final session = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1],
        roles: ['SalesManager'],
        permissions: inactiveMembership.permissions.toSet(),
        currentCompanyId: company1.id,
        activeMembership: inactiveMembership,
        activeCompanyContext: null, // Inactive membership cannot build active company context
        capturedAt: now,
      );

      final authContext = AuthorizationContext.fromSession(
        session: session,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: authContext,
          requiredPermission: LocalPermissions.salesView,
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('6. Permission isolation across companies: Permissions in Company 1 do not leak to Company 2', () {
      final activeCtx2 = ActiveCompanyContext.fromMembership(
        membership: membershipComp2,
        authenticatedUserId: regularUser.id,
        companyName: company2.name,
        companyCode: company2.code,
      );

      final sessionInCompany2 = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1, company2],
        roles: ['InventoryClerk'],
        permissions: membershipComp2.permissions.toSet(),
        currentCompanyId: company2.id,
        activeMembership: membershipComp2,
        activeCompanyContext: activeCtx2,
        capturedAt: now,
      );

      final authContext2 = AuthorizationContext.fromSession(
        session: sessionInCompany2,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: authContext2,
          requiredPermission: LocalPermissions.salesCreate,
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('7. Role isolation across companies: Roles in Company 1 do not carry over to Company 2', () {
      final activeCtx2 = ActiveCompanyContext.fromMembership(
        membership: membershipComp2,
        authenticatedUserId: regularUser.id,
        companyName: company2.name,
        companyCode: company2.code,
      );

      final sessionInCompany2 = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1, company2],
        roles: ['InventoryClerk'],
        permissions: membershipComp2.permissions.toSet(),
        currentCompanyId: company2.id,
        activeMembership: membershipComp2,
        activeCompanyContext: activeCtx2,
        capturedAt: now,
      );

      final authContext2 = AuthorizationContext.fromSession(
        session: sessionInCompany2,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(authContext2.roleId, equals('InventoryClerk'));
      expect(authContext2.roleId, isNot(equals('SalesManager')));
    });

    test('8. System Admin without company: System ops pass, company ops fail without active company', () {
      final sessionAdminNoCompany = AuthSessionSnapshot(
        user: systemAdmin,
        companies: [company1],
        roles: ['System Admin'],
        permissions: kSystemLevelPermissions,
        currentCompanyId: null,
        capturedAt: now,
      );

      final authContextAdmin = AuthorizationContext.fromSession(
        session: sessionAdminNoCompany,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      // System-level operation should pass
      expect(
        () => guard.requirePermission(
          context: authContextAdmin,
          requiredPermission: LocalPermissions.systemConfigManage,
        ),
        returnsNormally,
      );

      // Company-level operation should fail (no company context)
      expect(
        () => guard.requirePermission(
          context: authContextAdmin,
          requiredPermission: LocalPermissions.salesCreate,
        ),
        throwsA(isA<MissingAuthorizationContextException>()),
      );
    });

    test('9. Company switching: Atomically swaps context, permissions, and roles', () {
      final activeCtx1 = ActiveCompanyContext.fromMembership(
        membership: membershipComp1,
        authenticatedUserId: regularUser.id,
        companyName: company1.name,
        companyCode: company1.code,
      );

      final session1 = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1, company2],
        roles: ['SalesManager'],
        permissions: membershipComp1.permissions.toSet(),
        currentCompanyId: company1.id,
        activeMembership: membershipComp1,
        activeCompanyContext: activeCtx1,
        capturedAt: now,
      );

      final authCtx1 = AuthorizationContext.fromSession(
        session: session1,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(authCtx1.companyId, equals('company-1'));
      expect(authCtx1.permissions, contains(LocalPermissions.salesCreate));
      expect(authCtx1.permissions, isNot(contains(LocalPermissions.inventoryView)));

      final activeCtx2 = ActiveCompanyContext.fromMembership(
        membership: membershipComp2,
        authenticatedUserId: regularUser.id,
        companyName: company2.name,
        companyCode: company2.code,
      );

      final session2 = session1.copyWith(
        currentCompanyId: company2.id,
        activeMembership: membershipComp2,
        activeCompanyContext: activeCtx2,
      );

      final authCtx2 = AuthorizationContext.fromSession(
        session: session2,
        entitlement: entitlement,
        mode: AuthenticationMode.local,
      );

      expect(authCtx2.companyId, equals('company-2'));
      expect(authCtx2.permissions, contains(LocalPermissions.inventoryView));
      expect(authCtx2.permissions, isNot(contains(LocalPermissions.salesCreate)));
    });
  });
}
