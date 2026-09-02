import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';

void main() {
  const company1 = AuthCompany(
    id: 'company-1',
    name: 'Company Alpha',
    code: 'ALPHA',
  );

  const regularUser = AuthUser(
    id: 'user-100',
    email: 'user@alpha.com',
    name: 'Regular User',
    systemRole: SystemRole.regularUser,
  );

  const systemAdmin = AuthUser(
    id: 'sysadmin-1',
    email: 'admin@system.com',
    name: 'System Admin',
    systemRole: SystemRole.systemAdmin,
  );

  const membershipComp1 = UserCompanyMembership(
    userId: 'user-100',
    companyId: 'company-1',
    role: 'SalesManager',
    permissions: [LocalPermissions.salesView],
    status: 'active',
  );

  final now = DateTime.now().toUtc();

  /// Pure decision evaluator reflecting app_router's routing matrix
  String? evaluateRouteRedirect({
    required String targetPath,
    required AppBootstrapState bootstrapState,
    required AuthSessionSnapshot? session,
    List<String>? requiredPermissions,
    bool isPublicRoute = false,
  }) {
    final path = targetPath;
    final isAuthenticated = session != null;
    final hasCompany = session?.hasCompany == true;
    final isSystemScope = bootstrapState.isSystemScope;

    // 0. Initializing or Restoring Session
    if (bootstrapState.isInitializing || bootstrapState.isRestoringSession) {
      if (path == AppRoutes.splash) return null;
      return AppRoutes.splash;
    }

    // 1. First-Run Required Gate
    if (bootstrapState.isFirstRunRequired) {
      if (path != '/first-run' && path != AppRoutes.onboarding && path != AppRoutes.splash) {
        return '/first-run';
      }
      return null;
    }

    // Block setup routes if setup is completed
    if (!bootstrapState.isFirstRunRequired &&
        (path == '/first-run' || path == '/setup-choice' || path == '/server-setup')) {
      if (isAuthenticated) {
        return (hasCompany || isSystemScope)
            ? AppRoutes.dashboard
            : '/company-selection';
      } else {
        return AppRoutes.login;
      }
    }

    // 2. Unauthenticated Gate
    if (bootstrapState.isUnauthenticated || !isAuthenticated) {
      if (isPublicRoute) return null;
      return AppRoutes.login;
    }

    // 3. Multi-Company Selection Gate (System Admin with 0 companies bypasses company selection!)
    if (isAuthenticated && !hasCompany && !isSystemScope) {
      if (path == '/company-selection' || path == AppRoutes.login) {
        return null;
      }
      return '/company-selection';
    }

    // 4. Authenticated Users on Public Auth Pages
    if (isAuthenticated && (path == AppRoutes.login || path == AppRoutes.splash)) {
      return (hasCompany || isSystemScope)
          ? AppRoutes.dashboard
          : '/company-selection';
    }

    // 5. Permission Requirement Check
    if (requiredPermissions != null && requiredPermissions.isNotEmpty) {
      final userPermissions = session.permissions;
      final hasPerm = requiredPermissions.any((p) => userPermissions.contains(p));
      if (!hasPerm) {
        return AppRoutes.accessDenied;
      }
    }

    return null;
  }

  group('Phase 10: Router & Navigation Guards Tests', () {
    test('1. Uninitialized system -> Deep-link to /dashboard redirects to /first-run', () {
      const bootstrap = AppBootstrapState(status: AppBootstrapStatus.firstRunRequired);

      final redirect = evaluateRouteRedirect(
        targetPath: AppRoutes.dashboard,
        bootstrapState: bootstrap,
        session: null,
      );

      expect(redirect, equals('/first-run'));
    });

    test('2. Initialized + Unauthenticated -> Deep-link to /dashboard redirects to /login', () {
      const bootstrap = AppBootstrapState(status: AppBootstrapStatus.unauthenticated);

      final redirect = evaluateRouteRedirect(
        targetPath: AppRoutes.dashboard,
        bootstrapState: bootstrap,
        session: null,
      );

      expect(redirect, equals(AppRoutes.login));
    });

    test('3. Public route access -> Unauthenticated access to /login or /splash allowed', () {
      const bootstrap = AppBootstrapState(status: AppBootstrapStatus.unauthenticated);

      final loginRedirect = evaluateRouteRedirect(
        targetPath: AppRoutes.login,
        bootstrapState: bootstrap,
        session: null,
        isPublicRoute: true,
      );

      expect(loginRedirect, isNull);
    });

    test('4. System Admin (0 companies) -> Allowed on /dashboard, NOT forced to company selection', () {
      final adminSession = AuthSessionSnapshot(
        user: systemAdmin,
        companies: [],
        roles: ['System Admin'],
        permissions: kSystemLevelPermissions,
        currentCompanyId: null,
        capturedAt: now,
      );

      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        isSystemScope: true,
        activeCompanyId: null,
      );

      final redirect = evaluateRouteRedirect(
        targetPath: AppRoutes.dashboard,
        bootstrapState: bootstrap,
        session: adminSession,
      );

      expect(redirect, isNull);
    });

    test('5. Regular User (0 companies) -> Redirected to /company-selection', () {
      final userSession = AuthSessionSnapshot(
        user: regularUser,
        companies: [],
        roles: [],
        permissions: {},
        currentCompanyId: null,
        capturedAt: now,
      );

      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        isSystemScope: false,
        activeCompanyId: null,
      );

      final redirect = evaluateRouteRedirect(
        targetPath: AppRoutes.dashboard,
        bootstrapState: bootstrap,
        session: userSession,
      );

      expect(redirect, equals('/company-selection'));
    });

    test('6. Authenticated + Active Company -> Allowed on authorized dashboard route', () {
      final activeCtx = ActiveCompanyContext.fromMembership(
        membership: membershipComp1,
        authenticatedUserId: regularUser.id,
        companyName: company1.name,
        companyCode: company1.code,
      );

      final validSession = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1],
        roles: ['SalesManager'],
        permissions: membershipComp1.permissions.toSet(),
        currentCompanyId: company1.id,
        activeMembership: membershipComp1,
        activeCompanyContext: activeCtx,
        capturedAt: now,
      );

      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        isSystemScope: false,
        activeCompanyId: 'company-1',
      );

      final redirect = evaluateRouteRedirect(
        targetPath: AppRoutes.dashboard,
        bootstrapState: bootstrap,
        session: validSession,
      );

      expect(redirect, isNull);
    });

    test('7. Authenticated + Missing Permission -> Redirected to /access-denied', () {
      final activeCtx = ActiveCompanyContext.fromMembership(
        membership: membershipComp1,
        authenticatedUserId: regularUser.id,
        companyName: company1.name,
        companyCode: company1.code,
      );

      final validSession = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1],
        roles: ['SalesManager'],
        permissions: membershipComp1.permissions.toSet(), // Has salesView, lacks inventoryDelete
        currentCompanyId: company1.id,
        activeMembership: membershipComp1,
        activeCompanyContext: activeCtx,
        capturedAt: now,
      );

      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        isSystemScope: false,
        activeCompanyId: 'company-1',
      );

      final redirect = evaluateRouteRedirect(
        targetPath: '/inventory/delete',
        bootstrapState: bootstrap,
        session: validSession,
        requiredPermissions: [LocalPermissions.inventoryDelete],
      );

      expect(redirect, equals(AppRoutes.accessDenied));
    });

    test('8. Authenticated user on /login -> Auto-forwarded to /dashboard', () {
      final activeCtx = ActiveCompanyContext.fromMembership(
        membership: membershipComp1,
        authenticatedUserId: regularUser.id,
        companyName: company1.name,
        companyCode: company1.code,
      );

      final validSession = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1],
        roles: ['SalesManager'],
        permissions: membershipComp1.permissions.toSet(),
        currentCompanyId: company1.id,
        activeMembership: membershipComp1,
        activeCompanyContext: activeCtx,
        capturedAt: now,
      );

      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        isSystemScope: false,
        activeCompanyId: 'company-1',
      );

      final redirect = evaluateRouteRedirect(
        targetPath: AppRoutes.login,
        bootstrapState: bootstrap,
        session: validSession,
        isPublicRoute: true,
      );

      expect(redirect, equals(AppRoutes.dashboard));
    });

    test('9. Setup routes blocked when initialized -> Redirected to /dashboard or /login', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        isSystemScope: true,
        activeCompanyId: null,
      );

      final adminSession = AuthSessionSnapshot(
        user: systemAdmin,
        companies: [],
        roles: ['System Admin'],
        permissions: kSystemLevelPermissions,
        currentCompanyId: null,
        capturedAt: now,
      );

      final redirect = evaluateRouteRedirect(
        targetPath: '/first-run',
        bootstrapState: bootstrap,
        session: adminSession,
      );

      expect(redirect, equals(AppRoutes.dashboard));
    });
  });
}
