import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/app/router/app_router.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:stock_count/modules/app_lock/presentation/pages/app_lock_routes.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/pages/company_selection_screen.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/system_setup/presentation/pages/system_setup_routes.dart';

class FakeAppLockRepository implements AppLockRepository {
  @override
  Future<bool> isEnabled() async => true;
  @override
  Future<void> setEnabled(bool enabled) async {}
  @override
  Future<bool> hasPin() async => true;
  @override
  Future<void> setPin(String pin) async {}
  @override
  Future<bool> verifyPin(String pin) async => true;
  @override
  Future<void> clearPin() async {}
  @override
  Future<AppLockPolicy> getPolicy() async => AppLockPolicy.onResume;
  @override
  Future<void> setPolicy(AppLockPolicy policy) async {}
  @override
  Future<bool> isBiometricEnabled() async => false;
  @override
  Future<void> setBiometricEnabled(bool enabled) async {}
  @override
  Future<int> loadFailedAttempts() async => 0;
  @override
  Future<void> saveFailedAttempts(int attempts) async {}
  @override
  Future<DateTime?> loadLockoutUntil() async => null;
  @override
  Future<void> saveLockoutUntil(DateTime? until) async {}
}

class FakeAppLockBiometrics implements AppLockBiometrics {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate({required String localizedReason}) async => true;
}

void main() {
  group('Phase 3E Routing & Redirect Invariants', () {
    late ModuleRegistry registry;
    final now = DateTime.now().toUtc();

    setUp(() {
      registry = ModuleRegistry();
    });

    test('I-3E-01 & State A: Fresh install redirects from splash/dashboard to first-run setup', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.firstRunRequired,
      );
      const auth = AuthState(status: AuthStatus.unauthenticated);

      final redirectSplash = evaluateAppRouteRedirect(
        path: AppRoutes.splash,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectSplash, equals(SystemSetupRoutes.firstRun));

      final redirectDashboard = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectDashboard, equals(SystemSetupRoutes.firstRun));

      final redirectLogin = evaluateAppRouteRedirect(
        path: AppRoutes.login,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectLogin, equals(SystemSetupRoutes.firstRun));
    });

    test('I-3E-02 & State B: First-run incomplete blocks protected company-scoped routes', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.firstRunRequired,
      );
      const auth = AuthState(status: AuthStatus.unauthenticated);

      final redirectAccounting = evaluateAppRouteRedirect(
        path: '/accounting/journals',
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectAccounting, equals(SystemSetupRoutes.firstRun));
    });

    test('State C: First-run complete but unauthenticated redirects to login', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.unauthenticated,
      );
      const auth = AuthState(status: AuthStatus.unauthenticated);

      final redirectSplash = evaluateAppRouteRedirect(
        path: AppRoutes.splash,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectSplash, equals(AppRoutes.login));

      final redirectDashboard = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectDashboard, equals(AppRoutes.login));
    });

    test('State D: Authenticated with no company redirects company-scoped routes to company-selection', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.ready,
      );
      const user = AuthUser(
        id: 'usr-001',
        email: 'user@nexabiz.com',
        name: 'Regular User',
      );
      final session = AuthSessionSnapshot(
        user: user,
        companies: const [
          AuthCompany(id: 'comp-01', name: 'Company 1', code: 'C1'),
          AuthCompany(id: 'comp-02', name: 'Company 2', code: 'C2'),
        ],
        roles: const [],
        permissions: const {},
        capturedAt: now,
      );
      final auth = AuthState(
        status: AuthStatus.needsCompany,
        session: session,
      );

      final redirectAccounting = evaluateAppRouteRedirect(
        path: '/accounting/journals',
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectAccounting, equals(CompanySelectionScreen.routePath));

      final redirectCompanySelection = evaluateAppRouteRedirect(
        path: CompanySelectionScreen.routePath,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectCompanySelection, isNull);
    });

    test('State D2: System admin in System Scope can access system-scoped routes without company', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.authenticatedSystemScope,
        isSystemScope: true,
      );
      const user = AuthUser(
        id: 'sys-admin-01',
        email: 'sysadmin@nexabiz.com',
        name: 'System Admin',
        isSuperAdmin: true,
      );
      final session = AuthSessionSnapshot(
        user: user,
        companies: const [],
        roles: const ['System Admin'],
        permissions: const {},
        capturedAt: now,
      );
      final auth = AuthState(
        status: AuthStatus.needsCompany,
        session: session,
      );

      final redirectDashboard = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectDashboard, isNull);
    });

    test('State E: Authenticated with active company can access permitted company-scoped routes', () {
      const activeCompany = ActiveCompanyContext(
        companyId: 'comp-01',
        membershipId: 'usr-001_comp-01',
        companyRole: 'Admin',
        companyPermissions: {'accounting.view'},
        companyName: 'Company 1',
        companyCode: 'C1',
      );
      const user = AuthUser(
        id: 'usr-001',
        email: 'user@nexabiz.com',
        name: 'Company User',
      );
      final session = AuthSessionSnapshot(
        user: user,
        companies: const [
          AuthCompany(id: 'comp-01', name: 'Company 1', code: 'C1'),
        ],
        roles: const ['Admin'],
        permissions: const {'accounting.view'},
        capturedAt: now,
        currentCompanyId: 'comp-01',
        activeCompanyContext: activeCompany,
      );
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.authenticatedCompanyScope,
        activeCompanyId: 'comp-01',
      );
      final auth = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );

      final redirectDashboard = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectDashboard, isNull);
    });

    test('I-3E-09 & Permission Gate: Redirects to access-denied when permission missing', () {
      const activeCompany = ActiveCompanyContext(
        companyId: 'comp-01',
        membershipId: 'usr-002_comp-01',
        companyRole: 'User',
        companyPermissions: {},
        companyName: 'Company 1',
        companyCode: 'C1',
      );
      const user = AuthUser(
        id: 'usr-002',
        email: 'user2@nexabiz.com',
        name: 'Restricted User',
      );
      final session = AuthSessionSnapshot(
        user: user,
        companies: const [
          AuthCompany(id: 'comp-01', name: 'Company 1', code: 'C1'),
        ],
        roles: const ['User'],
        permissions: const {}, // No permissions
        capturedAt: now,
        currentCompanyId: 'comp-01',
        activeCompanyContext: activeCompany,
      );
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.authenticatedCompanyScope,
        activeCompanyId: 'comp-01',
      );
      final auth = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );

      final redirectReports = evaluateAppRouteRedirect(
        path: AppRoutes.reports,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectReports, equals(AppRoutes.accessDenied));
    });

    test('I-3E-11 & App Lock Gate: Redirects to app-lock when locked and stores returnToLocation', () {
      const activeCompany = ActiveCompanyContext(
        companyId: 'comp-01',
        membershipId: 'usr-001_comp-01',
        companyRole: 'Admin',
        companyPermissions: {},
        companyName: 'Company 1',
        companyCode: 'C1',
      );
      const user = AuthUser(
        id: 'usr-001',
        email: 'user@nexabiz.com',
        name: 'Locked User',
      );
      final session = AuthSessionSnapshot(
        user: user,
        companies: const [
          AuthCompany(id: 'comp-01', name: 'Company 1', code: 'C1'),
        ],
        roles: const ['Admin'],
        permissions: const {},
        capturedAt: now,
        currentCompanyId: 'comp-01',
        activeCompanyContext: activeCompany,
      );
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.authenticatedCompanyScope,
        activeCompanyId: 'comp-01',
      );
      final auth = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );
      const lockState = AppLockState(
        enabled: true,
        policy: AppLockPolicy.onResume,
        gate: AppLockGate.locked,
        hasPin: true,
      );
      final lockController = AppLockController(
        repository: FakeAppLockRepository(),
        biometrics: FakeAppLockBiometrics(),
        onChanged: () {},
      );

      final redirect = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
        lock: lockState,
        lockControllerNotifier: lockController,
      );

      expect(redirect, equals(AppLockRoutes.root));
      expect(lockController.returnToLocation, equals(AppRoutes.dashboard));
    });

    test('App Lock Gate: Unlocking returns user to returnToLocation', () {
      const activeCompany = ActiveCompanyContext(
        companyId: 'comp-01',
        membershipId: 'usr-001_comp-01',
        companyRole: 'Admin',
        companyPermissions: {},
        companyName: 'Company 1',
        companyCode: 'C1',
      );
      const user = AuthUser(
        id: 'usr-001',
        email: 'user@nexabiz.com',
        name: 'Locked User',
      );
      final session = AuthSessionSnapshot(
        user: user,
        companies: const [
          AuthCompany(id: 'comp-01', name: 'Company 1', code: 'C1'),
        ],
        roles: const ['Admin'],
        permissions: const {},
        capturedAt: now,
        currentCompanyId: 'comp-01',
        activeCompanyContext: activeCompany,
      );
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.authenticatedCompanyScope,
        activeCompanyId: 'comp-01',
      );
      final auth = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );
      const lockState = AppLockState(
        enabled: true,
        policy: AppLockPolicy.onResume,
        gate: AppLockGate.unlocked,
        hasPin: true,
      );
      final lockController = AppLockController(
        repository: FakeAppLockRepository(),
        biometrics: FakeAppLockBiometrics(),
        onChanged: () {},
      );
      lockController.returnToLocation = '/settings/security';

      final redirect = evaluateAppRouteRedirect(
        path: AppLockRoutes.root,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
        lock: lockState,
        lockControllerNotifier: lockController,
      );

      expect(redirect, equals('/settings/security'));
      expect(lockController.returnToLocation, isNull);
    });

    test('I-3E-16: No redirect loops on repeated evaluateAppRouteRedirect calls', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.unauthenticated,
      );
      const auth = AuthState(status: AuthStatus.unauthenticated);

      // Step 1: User tries dashboard -> redirected to login
      final step1 = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(step1, equals(AppRoutes.login));

      // Step 2: User is now at login -> evaluates to null (stays at login)
      final step2 = evaluateAppRouteRedirect(
        path: AppRoutes.login,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(step2, isNull);
    });

    test('I-3E-14: Fail-closed on initializing or unknown bootstrap state', () {
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.initializing,
      );
      const auth = AuthState.unknown();

      final redirectProtected = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );
      expect(redirectProtected, equals(AppRoutes.splash));
    });

    test('I-3E-12: Unauthenticated state invalidates active company context and returns user to login', () {
      const auth = AuthState(status: AuthStatus.unauthenticated);
      const bootstrap = AppBootstrapState(
        status: AppBootstrapStatus.unauthenticated,
      );

      final redirect = evaluateAppRouteRedirect(
        path: AppRoutes.dashboard,
        auth: auth,
        bootstrap: bootstrap,
        registry: registry,
      );

      expect(redirect, equals(AppRoutes.login));
      expect(auth.isAuthenticated, isFalse);
      expect(auth.session, isNull);
      expect(auth.hasCompany, isFalse);
    });
  });
}
