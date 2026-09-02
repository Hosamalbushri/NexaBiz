import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/auth/domain/services/local_access_policy.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';

void main() {
  late LocalAuthorizationGuard guard;
  late LocalAccessPolicy policy;
  late Entitlement mockEntitlement;

  setUp(() {
    guard = const LocalAuthorizationGuard();
    policy = LocalAccessPolicy(guard);
    mockEntitlement = Entitlement.freeLocal('comp_01');
  });

  group('Hardened Local Authorization (RBAC & Fail-Closed Checks)', () {
    test('Requirement 1: Owner permissions are deterministic and complete', () {
      final ownerContext = AuthorizationContext(
        userId: 'usr_owner_01',
        companyId: 'comp_01',
        permissions: {
          'accounting.journals.post',
          'accounting.journals.reverse',
          'sales.post',
          'sales.reverse',
          'users.manage',
          'companies.update',
          'settings.update',
          'accounting.config.manage',
        },
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        policy.hasLocalAccess(
          context: ownerContext,
          permission: 'accounting.journals.post',
        ),
        isTrue,
      );
      expect(
        policy.hasLocalAccess(
          context: ownerContext,
          permission: 'accounting.journals.reverse',
        ),
        isTrue,
      );
      expect(
        policy.hasLocalAccess(
          context: ownerContext,
          permission: 'users.manage',
        ),
        isTrue,
      );
    });

    test('Requirement 2: Normal user with restricted permissions cannot perform administrative actions', () {
      final normalUserContext = AuthorizationContext(
        userId: 'usr_cashier_01',
        companyId: 'comp_01',
        permissions: {
          'sales.view',
          'sales.create',
          'products.view',
        },
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      // Normal user can view sales
      expect(
        policy.hasLocalAccess(
          context: normalUserContext,
          permission: 'sales.view',
        ),
        isTrue,
      );

      // Normal user CANNOT post sales, reverse journals, or manage users
      expect(
        policy.hasLocalAccess(
          context: normalUserContext,
          permission: 'sales.post',
        ),
        isFalse,
      );
      expect(
        policy.hasLocalAccess(
          context: normalUserContext,
          permission: 'accounting.journals.reverse',
        ),
        isFalse,
      );
      expect(
        policy.hasLocalAccess(
          context: normalUserContext,
          permission: 'users.manage',
        ),
        isFalse,
      );
    });

    test('Requirement 3: Unauthorized user throws UnauthorizedException on mandatory check', () {
      final restrictedContext = AuthorizationContext(
        userId: 'usr_clerk_01',
        companyId: 'comp_01',
        permissions: {'sales.view'},
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: restrictedContext,
          requiredPermission: 'accounting.journals.post',
        ),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.permission,
            'permission',
            'accounting.journals.post',
          ),
        ),
      );
    });

    test('Requirement 4: Missing authorization session fails closed', () {
      expect(
        () => guard.requirePermission(
          context: null,
          requiredPermission: 'sales.view',
        ),
        throwsA(isA<MissingAuthorizationContextException>()),
      );
    });

    test('Requirement 5: Missing company context fails closed', () {
      final noCompanyContext = AuthorizationContext(
        userId: 'usr_clerk_01',
        companyId: '',
        permissions: {'sales.view'},
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: noCompanyContext,
          requiredPermission: 'sales.view',
        ),
        throwsA(isA<MissingAuthorizationContextException>()),
      );
    });

    test('Requirement 6: Invalid company context mismatch throws CompanyContextMismatchException', () {
      final companyAContext = AuthorizationContext(
        userId: 'usr_clerk_01',
        companyId: 'comp_A',
        permissions: {'sales.view'},
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: companyAContext,
          requiredPermission: 'sales.view',
          targetCompanyId: 'comp_B',
        ),
        throwsA(
          isA<CompanyContextMismatchException>().having(
            (e) => e.expectedCompanyId,
            'expectedCompanyId',
            'comp_A',
          ),
        ),
      );
    });

    test('Requirement 7: Unauthorized accounting posting is denied at domain boundary', () {
      final unprivilegedContext = AuthorizationContext(
        userId: 'usr_clerk_01',
        companyId: 'comp_01',
        permissions: {'accounting.journals.view'},
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: unprivilegedContext,
          requiredPermission: 'accounting.journals.post',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('Requirement 8: Unauthorized accounting reversal is denied at domain boundary', () {
      final unprivilegedContext = AuthorizationContext(
        userId: 'usr_clerk_01',
        companyId: 'comp_01',
        permissions: {'accounting.journals.view', 'accounting.journals.post'},
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: unprivilegedContext,
          requiredPermission: 'accounting.journals.reverse',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('Requirement 9: Unauthorized user management is denied at domain boundary', () {
      final unprivilegedContext = AuthorizationContext(
        userId: 'usr_clerk_01',
        companyId: 'comp_01',
        permissions: {'sales.view'},
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: unprivilegedContext,
          requiredPermission: 'users.manage',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('Requirement 10: Unauthorized configuration change is denied at domain boundary', () {
      final unprivilegedContext = AuthorizationContext(
        userId: 'usr_clerk_01',
        companyId: 'comp_01',
        permissions: {'sales.view'},
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: unprivilegedContext,
          requiredPermission: 'settings.update',
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(
        () => guard.requirePermission(
          context: unprivilegedContext,
          requiredPermission: 'accounting.config.manage',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('Requirement 11: Bypassing UI PermissionGate still fails closed at domain boundary', () {
      final unprivilegedContext = AuthorizationContext(
        userId: 'usr_hacker_01',
        companyId: 'comp_01',
        permissions: <String>{}, // No permissions granted
        entitlement: mockEntitlement,
        authenticationMode: AuthenticationMode.local,
      );

      // Even if user navigates directly to a hidden screen or calls domain code directly:
      expect(
        () => guard.requirePermission(
          context: unprivilegedContext,
          requiredPermission: 'accounting.journals.post',
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(
        () => guard.requirePermission(
          context: unprivilegedContext,
          requiredPermission: 'companies.update',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });
}
