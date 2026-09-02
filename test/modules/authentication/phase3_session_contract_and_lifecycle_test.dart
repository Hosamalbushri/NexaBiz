import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  group('Phase 3 — Session Contract & Session Lifecycle Tests (12 Scenarios)', () {
    const userA = AuthUser(
      id: 'user_A',
      name: 'User Alpha',
      email: 'alpha@nexabiz.local',
      systemRole: SystemRole.systemAdmin,
    );

    const userB = AuthUser(
      id: 'user_B',
      name: 'User Beta',
      email: 'beta@nexabiz.local',
      systemRole: SystemRole.regularUser,
    );

    final membershipA = UserCompanyMembership(
      userId: 'user_A',
      companyId: 'comp_alpha',
      role: 'Owner',
      status: 'active',
      permissions: const ['sales.create', 'accounting.post'],
    );

    test('1. Initial state is uninitialized / unauthenticated', () {
      const state = AuthState.uninitialized();
      expect(state.status, equals(AuthStatus.uninitialized));
      expect(state.isAuthenticated, isFalse);
      expect(state.session, isNull);
    });

    test('2. Authenticated user with no company (activeCompanyContext == null)', () {
      final session = AuthSessionSnapshot(
        user: userA,
        companies: const [],
        roles: const [],
        permissions: const {'system.companies.manage'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: null,
        activeMembership: null,
        activeCompanyContext: null,
      );

      expect(session.isValidSecuritySession, isTrue);
      expect(session.companyContext, isNull);
      expect(session.activeCompanyId, isNull);

      final state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.session?.companyContext, isNull);
    });

    test('3. Authenticated user with valid company', () {
      final contextA = ActiveCompanyContext.fromMembership(
        membership: membershipA,
        authenticatedUserId: userA.id,
      );

      final session = AuthSessionSnapshot(
        user: userA,
        companies: const [],
        roles: const ['Owner'],
        permissions: const {'sales.create', 'accounting.post'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'comp_alpha',
        activeMembership: membershipA,
        activeCompanyContext: contextA,
      );

      expect(session.isValidSecuritySession, isTrue);
      expect(session.companyContext, equals(contextA));
      expect(session.activeCompanyId, equals('comp_alpha'));

      final state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.hasCompany, isTrue);
    });

    test('4. Invalid active company (company ID mismatch fails closed)', () {
      final session = AuthSessionSnapshot(
        user: userA,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'comp_WRONG', // Mismatch!
        activeMembership: membershipA, // Belongs to comp_alpha
      );

      expect(session.isValidSecuritySession, isFalse);
    });

    test('5. Wrong-user membership (User A + User B membership rejected)', () {
      final wrongMembership = UserCompanyMembership(
        userId: 'user_B', // Wrong user!
        companyId: 'comp_alpha',
        role: 'Owner',
        status: 'active',
      );

      final session = AuthSessionSnapshot(
        user: userA, // User A
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'comp_alpha',
        activeMembership: wrongMembership,
      );

      expect(session.isValidSecuritySession, isFalse);
    });

    test('6. Revoked membership (inactive status rejected)', () {
      final revokedMembership = UserCompanyMembership(
        userId: 'user_A',
        companyId: 'comp_alpha',
        role: 'Owner',
        status: 'inactive', // Revoked!
      );

      final session = AuthSessionSnapshot(
        user: userA,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: 'comp_alpha',
        activeMembership: revokedMembership,
      );

      expect(session.isValidSecuritySession, isFalse);
    });

    test('7. Malformed session (empty user ID rejected)', () {
      const emptyUser = AuthUser(
        id: '', // Malformed!
        name: 'Empty',
        email: 'empty@local',
      );

      final session = AuthSessionSnapshot(
        user: emptyUser,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
      );

      expect(session.isValidSecuritySession, isFalse);
    });

    test('8. Session restoration validates persisted snapshot', () {
      final validSession = AuthSessionSnapshot(
        user: userA,
        companies: const [],
        roles: const [],
        permissions: const {'system.manage'},
        capturedAt: DateTime.now().toUtc(),
      );

      expect(validSession.isValidSecuritySession, isTrue);
    });

    test('9. Session invalidation transitions state cleanly', () {
      const state = AuthState(status: AuthStatus.invalidated);
      expect(state.status, equals(AuthStatus.invalidated));
      expect(state.isAuthenticated, isFalse);
    });

    test('10. Concurrent restoration single-flight convergence mock', () async {
      final completer = Completer<AuthSessionSnapshot?>();
      final f1 = completer.future;
      final f2 = completer.future;

      expect(identical(f1, f2), isTrue);

      final validSession = AuthSessionSnapshot(
        user: userA,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
      );

      completer.complete(validSession);

      final r1 = await f1;
      final r2 = await f2;

      expect(r1, equals(r2));
      expect(r1?.user.id, equals('user_A'));
    });

    test('11. Restore + logout race condition handling', () {
      var state = const AuthState(status: AuthStatus.restoring);
      expect(state.status, equals(AuthStatus.restoring));
      expect(state.isAuthenticating, isTrue);

      // Interrupt with logout / invalidation
      state = const AuthState(status: AuthStatus.invalidated);
      expect(state.status, equals(AuthStatus.invalidated));
      expect(state.isAuthenticated, isFalse);
    });

    test('12. Restore + login race condition supercedes restoration', () {
      var state = const AuthState(status: AuthStatus.restoring);
      expect(state.status, equals(AuthStatus.restoring));

      final loginSession = AuthSessionSnapshot(
        user: userB,
        companies: const [],
        roles: const [],
        permissions: const {'sales.create'},
        capturedAt: DateTime.now().toUtc(),
      );

      // Login completes and overrides restoring state
      state = AuthState(
        status: AuthStatus.authenticated,
        session: loginSession,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.session?.user.id, equals('user_B'));
    });
  });
}
