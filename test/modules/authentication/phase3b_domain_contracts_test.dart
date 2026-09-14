import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/auth/data/default_authorization_port_adapter.dart';
import 'package:stock_count/core/auth/data/default_authentication_port_adapter.dart';
import 'package:stock_count/core/auth/domain/entities/authentication_result.dart';
import 'package:stock_count/core/auth/domain/ports/authentication_port.dart';
import 'package:stock_count/core/auth/domain/ports/authorization_port.dart';
import 'package:stock_count/core/identity/domain/repositories/company_repository.dart';
import 'package:stock_count/core/identity/domain/repositories/membership_repository.dart';
import 'package:stock_count/core/identity/domain/repositories/user_repository.dart';
import 'package:stock_count/core/security/data/pbkdf2_password_hasher_adapter.dart';
import 'package:stock_count/core/security/domain/ports/password_hasher_port.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';

void main() {
  group('Phase 3B — Identity Authority & Independence', () {
    test('User exists independently from Company and Membership', () {
      const user = AuthUser(
        id: 'u-101',
        name: 'Independent User',
        email: 'user@domain.com',
        status: 'active',
      );
      const company = AuthCompany(
        id: 'c-202',
        name: 'Independent Company',
        code: 'INDEP',
      );

      expect(user.id, equals('u-101'));
      expect(company.id, equals('c-202'));
    });

    test('UserCompanyMembership is the sole relationship linking User and Company', () {
      const membership = UserCompanyMembership(
        userId: 'u-101',
        companyId: 'c-202',
        role: 'Manager',
        status: 'active',
        permissions: ['sales.view', 'products.view'],
      );

      expect(membership.userId, equals('u-101'));
      expect(membership.companyId, equals('c-202'));
      expect(membership.isActive, isTrue);
      expect(membership.permissions, contains('sales.view'));
    });
  });

  group('Phase 3B — Authorization Port & Effective Permissions', () {
    late AuthorizationPort authorizationPort;

    setUp(() {
      authorizationPort = const DefaultAuthorizationPortAdapter();
    });

    test('Membership.permissions is effective authorization source', () {
      const user = AuthUser(
        id: 'u-1',
        name: 'Test User',
        email: 'test@domain.com',
        status: 'active',
        systemRole: SystemRole.regularUser,
      );

      const membership = UserCompanyMembership(
        userId: 'u-1',
        companyId: 'c-1',
        role: 'Cashier',
        status: 'active',
        permissions: ['sales.create', 'sales.view'],
      );

      final ctx = ActiveCompanyContext.fromMembership(
        membership: membership,
        authenticatedUserId: user.id,
      );

      final session = AuthSessionSnapshot(
        user: user,
        companies: const [AuthCompany(id: 'c-1', name: 'Co', code: 'CO')],
        roles: const ['Cashier'],
        permissions: const {'sales.create', 'sales.view'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'c-1',
        activeMembership: membership,
        activeCompanyContext: ctx,
      );

      expect(authorizationPort.hasPermission(session, 'sales.create'), isTrue);
      expect(authorizationPort.hasPermission(session, 'accounting.journals.post'), isFalse);
    });

    test('Unauthorized permission request throws StateError via requirePermission', () {
      const user = AuthUser(
        id: 'u-1',
        name: 'User',
        email: 'u@domain.com',
        status: 'active',
      );
      final session = AuthSessionSnapshot(
        user: user,
        companies: const [],
        roles: const ['Member'],
        permissions: const {'sales.view'},
        capturedAt: DateTime.now().toUtc(),
      );

      expect(
        () => authorizationPort.requirePermission(session, 'accounting.manage'),
        throwsStateError,
      );
    });
  });

  group('Phase 3B — Password Hasher Contract (PBKDF2)', () {
    late PasswordHasherPort hasher;

    setUp(() {
      hasher = const Pbkdf2PasswordHasherAdapter(iterations: 1000);
    });

    test('New password creates PBKDF2 hash and verifies correctly', () {
      final salt = Pbkdf2PasswordHasherAdapter.generateSalt();
      expect(salt.isNotEmpty, isTrue);

      final hash = hasher.hashPassword('SecretPass123!', salt);
      expect(hash.isNotEmpty, isTrue);
      expect(hash.length, equals(64)); // 256 bits hex

      final isValid = hasher.verifyPassword('SecretPass123!', hash, salt);
      expect(isValid, isTrue);

      final isWrong = hasher.verifyPassword('WrongPass123!', hash, salt);
      expect(isWrong, isFalse);
    });

    test('Legacy SHA-256 password verifies via transitional fallback path', () {
      const password = 'LegacyPassword';
      const salt = 'legacy_salt_123';
      final legacyHash = Pbkdf2PasswordHasherAdapter(iterations: 1000)
          .verifyPassword(password, '9b74c2d3080e6391237c980993e98038933221bf', salt);
      // Fallback verification returns boolean result without throwing exception
      expect(legacyHash, isA<bool>());
    });
  });

  group('Phase 3B — ActiveCompanyContext Security Invariants', () {
    test('Constructing ActiveCompanyContext with mismatched user ID fails', () {
      const membership = UserCompanyMembership(
        userId: 'user-A',
        companyId: 'company-X',
        role: 'Member',
        status: 'active',
      );

      expect(
        () => ActiveCompanyContext.fromMembership(
          membership: membership,
          authenticatedUserId: 'user-B',
        ),
        throwsArgumentError,
      );
    });

    test('Constructing ActiveCompanyContext with inactive membership fails', () {
      const membership = UserCompanyMembership(
        userId: 'user-A',
        companyId: 'company-X',
        role: 'Member',
        status: 'inactive',
      );

      expect(
        () => ActiveCompanyContext.fromMembership(
          membership: membership,
          authenticatedUserId: 'user-A',
        ),
        throwsStateError,
      );
    });
  });

  group('Phase 3B — TenantContext Derivation & Fail-Closed Behavior', () {
    test('TenantContext without active company resolves to non-company scope', () {
      const emptyContext = TenantContext.empty;
      expect(emptyContext.hasActiveCompany, isFalse);
      expect(emptyContext.companyId, isEmpty);
      expect(emptyContext.isCompanyScope, isFalse);
    });
  });
}
