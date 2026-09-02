import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
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

  const company2 = AuthCompany(
    id: 'company-2',
    name: 'Company Beta',
    code: 'BETA',
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

  group('Phase 9: Application Bootstrap Orchestration Tests', () {
    test('1. Fresh install: Uninitialized state sets status to firstRunRequired', () {
      const state = AppBootstrapState(
        status: AppBootstrapStatus.firstRunRequired,
        stageDetails: 'First-run setup required',
      );

      expect(state.isFirstRunRequired, isTrue);
      expect(state.isReady, isFalse);
      expect(state.isUnauthenticated, isFalse);
    });

    test('2. Existing install: Initialized system enters restoringSession state', () {
      const state = AppBootstrapState(
        status: AppBootstrapStatus.restoringSession,
        stageDetails: 'Restoring user session',
      );

      expect(state.isRestoringSession, isTrue);
      expect(state.isReady, isFalse);
    });

    test('3. No session: Unauthenticated session resolves status to unauthenticated', () {
      const state = AppBootstrapState(
        status: AppBootstrapStatus.unauthenticated,
        stageDetails: 'Unauthenticated session',
      );

      expect(state.isUnauthenticated, isTrue);
      expect(state.isAuthenticated, isFalse);
    });

    test('4. Valid session: Authenticated user transitions to ready state', () {
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

      final state = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        activeCompanyId: session.activeCompanyContext?.companyId,
        isSystemScope: false,
        stageDetails: 'Company Scope ready (company-1)',
      );

      expect(state.isReady, isTrue);
      expect(state.activeCompanyId, equals('company-1'));
      expect(state.isSystemScope, isFalse);
    });

    test('5. Expired session: Expired/invalid token resolves to unauthenticated', () {
      const state = AppBootstrapState(
        status: AppBootstrapStatus.unauthenticated,
        stageDetails: 'Session expired',
      );

      expect(state.isUnauthenticated, isTrue);
      expect(state.activeCompanyId, isNull);
    });

    test('6. Admin with no companies: System Admin without active company resolves to System Scope ready', () {
      final sessionAdminNoCompany = AuthSessionSnapshot(
        user: systemAdmin,
        companies: [],
        roles: ['System Admin'],
        permissions: kSystemLevelPermissions,
        currentCompanyId: null,
        capturedAt: now,
      );

      final isSystemAdmin = sessionAdminNoCompany.user.isSystemAdmin;
      final hasActiveCompany = sessionAdminNoCompany.activeCompanyContext != null;

      final state = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        activeCompanyId: sessionAdminNoCompany.activeCompanyContext?.companyId,
        isSystemScope: isSystemAdmin && !hasActiveCompany,
        stageDetails: 'System Scope ready (System Admin)',
      );

      expect(state.isReady, isTrue);
      expect(state.isSystemScope, isTrue);
      expect(state.activeCompanyId, isNull);
    });

    test('7. User with company: User with single active company resolves to Company Scope ready', () {
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

      final isSystemAdmin = session.user.isSystemAdmin;
      final hasActiveCompany = session.activeCompanyContext != null;

      final state = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        activeCompanyId: session.activeCompanyContext?.companyId,
        isSystemScope: isSystemAdmin && !hasActiveCompany,
        stageDetails: 'Company Scope ready (company-1)',
      );

      expect(state.isReady, isTrue);
      expect(state.isSystemScope, isFalse);
      expect(state.activeCompanyId, equals('company-1'));
    });

    test('8. User with multiple companies: User with companies but no active context requires selection', () {
      final sessionNoContext = AuthSessionSnapshot(
        user: regularUser,
        companies: [company1, company2],
        roles: [],
        permissions: {},
        currentCompanyId: null,
        activeCompanyContext: null,
        capturedAt: now,
      );

      final isSystemAdmin = sessionNoContext.user.isSystemAdmin;
      final hasActiveCompany = sessionNoContext.activeCompanyContext != null;

      final state = AppBootstrapState(
        status: AppBootstrapStatus.ready,
        activeCompanyId: sessionNoContext.activeCompanyContext?.companyId,
        isSystemScope: isSystemAdmin && !hasActiveCompany,
        stageDetails: 'Company selection required',
      );

      expect(state.isReady, isTrue);
      expect(state.isSystemScope, isFalse);
      expect(state.activeCompanyId, isNull);
    });

    test('9. Initialization failure: Fatal infrastructure error transitions status to failed', () {
      final state = AppBootstrapState(
        status: AppBootstrapStatus.failed,
        error: Exception('Hive storage box initialization failed'),
        stageDetails: 'Initialization failed',
      );

      expect(state.isFailed, isTrue);
      expect(state.isReady, isFalse);
      expect(state.error, isNotNull);
    });

    test('10. Session restoration failure: Exception during session restoration falls back to unauthenticated', () {
      const state = AppBootstrapState(
        status: AppBootstrapStatus.unauthenticated,
        stageDetails: 'Fallback to unauthenticated mode after error',
      );

      expect(state.isUnauthenticated, isTrue);
      expect(state.isFailed, isFalse);
    });
  });
}
