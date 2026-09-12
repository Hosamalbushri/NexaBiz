import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';

void main() {
  const guard = LocalAuthorizationGuard();

  group('Phase 3M — Canonical Security & Authorization Baseline Tests', () {
    test('LocalAuthorizationGuard rejects null or unauthenticated authorization context', () {
      expect(
        () => guard.requirePermission(
          context: null,
          requiredPermission: 'sales:create',
        ),
        throwsA(isA<MissingAuthorizationContextException>()),
      );

      final unauthContext = AuthorizationContext(
        userId: '',
        userStatus: 'active',
        companyId: 'company-a',
        companyMembershipStatus: 'active',
        permissions: const {'sales:create'},
        entitlement: Entitlement.freeLocal('company-a'),
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: unauthContext,
          requiredPermission: 'sales:create',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('LocalAuthorizationGuard rejects inactive user status or company membership', () {
      final inactiveUserContext = AuthorizationContext(
        userId: 'user-1',
        userStatus: 'suspended',
        companyId: 'company-a',
        companyMembershipStatus: 'active',
        permissions: const {'sales:create'},
        entitlement: Entitlement.freeLocal('company-a'),
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: inactiveUserContext,
          requiredPermission: 'sales:create',
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      final inactiveMemberContext = AuthorizationContext(
        userId: 'user-1',
        userStatus: 'active',
        companyId: 'company-a',
        companyMembershipStatus: 'revoked',
        permissions: const {'sales:create'},
        entitlement: Entitlement.freeLocal('company-a'),
        authenticationMode: AuthenticationMode.local,
      );

      expect(
        () => guard.requirePermission(
          context: inactiveMemberContext,
          requiredPermission: 'sales:create',
        ),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('LocalAuthorizationGuard enforces target company matching and permission presence', () {
      final context = AuthorizationContext(
        userId: 'user-1',
        userStatus: 'active',
        companyId: 'company-active-3m',
        companyMembershipStatus: 'active',
        permissions: const {'sales:create'},
        entitlement: Entitlement.freeLocal('company-active-3m'),
        authenticationMode: AuthenticationMode.local,
      );

      // Target company mismatch
      expect(
        () => guard.requirePermission(
          context: context,
          requiredPermission: 'sales:create',
          targetCompanyId: 'company-other-3m',
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );

      // Missing required permission
      expect(
        () => guard.requirePermission(
          context: context,
          requiredPermission: 'accounting:post',
        ),
        throwsA(isA<UnauthorizedException>()),
      );

      // Valid execution
      expect(
        () => guard.requirePermission(
          context: context,
          requiredPermission: 'sales:create',
          targetCompanyId: 'company-active-3m',
        ),
        returnsNormally,
      );
    });

    test('MultiTenantRepositoryGuard enforces strict tenant isolation on database operations', () {
      // Null or empty companyId
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: '',
          activeCompanyId: 'company-active-3m',
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );

      // Mismatched active company context
      expect(
        () => MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: 'company-a',
          activeCompanyId: 'company-b',
        ),
        throwsA(isA<CompanyContextMismatchException>()),
      );

      // Authorized match
      expect(
        MultiTenantRepositoryGuard.enforceCompanyContext(
          companyId: 'company-active-3m',
          activeCompanyId: 'company-active-3m',
        ),
        equals('company-active-3m'),
      );
    });

    test('SQLCipher key escaping prevents SQL injection in database connections', () {
      final inputKey = "key'with'quotes";
      final escaped = escapeSqlString(inputKey);

      expect(escaped, equals("key''with''quotes"));
    });
  });
}
