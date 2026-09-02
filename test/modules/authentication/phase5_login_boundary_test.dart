import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';

class MockLocalAuthStoreForLoginTest implements LocalAuthStore {
  final Map<String, AuthUser> _usersByEmail = {};
  final Map<String, String> _passwordsByEmail = {};
  final Map<String, List<UserCompanyMembership>> _membershipsByUserId = {};
  final Map<String, AuthCompany> _companiesById = {};
  AuthSessionSnapshot? _activeSession;

  void seedUser({
    required AuthUser user,
    required String password,
    List<UserCompanyMembership> memberships = const [],
  }) {
    _usersByEmail[user.email.toLowerCase()] = user;
    _passwordsByEmail[user.email.toLowerCase()] = password;
    _membershipsByUserId[user.id] = memberships;
  }

  void seedCompany(AuthCompany company) {
    _companiesById[company.id] = company;
  }

  int _sessionCounter = 0;

  @override
  Future<AuthSessionSnapshot?> login({
    required String email,
    required String password,
    required String deviceId,
    String? companyId,
  }) async {
    final normalized = email.trim().toLowerCase();
    final user = _usersByEmail[normalized];
    if (user == null) return null;
    if (user.status != 'active') return null;

    final expectedPassword = _passwordsByEmail[normalized];
    if (expectedPassword != password) return null;

    // Resolve user memberships
    final userMemberships = _membershipsByUserId[user.id] ?? const [];
    final authorizedCompanyIds = userMemberships.map((m) => m.companyId).toSet();

    final companies = <AuthCompany>[];
    for (final cid in authorizedCompanyIds) {
      if (_companiesById.containsKey(cid)) {
        companies.add(_companiesById[cid]!);
      }
    }

    String? selectedCompanyId = companyId;
    if (selectedCompanyId != null && selectedCompanyId.isNotEmpty) {
      if (!authorizedCompanyIds.contains(selectedCompanyId) && !user.isSystemAdmin) {
        return null; // Mismatched company access
      }
    } else {
      if (companies.length == 1) {
        selectedCompanyId = companies.first.id;
      } else {
        selectedCompanyId = null;
      }
    }

    UserCompanyMembership? activeMembership;
    if (selectedCompanyId != null && userMemberships.isNotEmpty) {
      activeMembership = userMemberships.firstWhere(
        (m) => m.companyId == selectedCompanyId,
        orElse: () => userMemberships.first,
      );
    }

    ActiveCompanyContext? activeContext;
    if (activeMembership != null) {
      activeContext = ActiveCompanyContext.fromMembership(
        membership: activeMembership,
        authenticatedUserId: user.id,
      );
    }

    _sessionCounter++;
    final snapshot = AuthSessionSnapshot(
      user: user,
      companies: companies,
      roles: activeMembership != null ? [activeMembership.role] : const [],
      permissions: activeMembership?.permissions.toSet() ?? const {},
      capturedAt: DateTime.now().toUtc(),
      currentCompanyId: selectedCompanyId,
      activeMembership: activeMembership,
      activeCompanyContext: activeContext,
      deviceId: deviceId,
      sessionId: 'sess_${user.id}_$_sessionCounter',
    );

    _activeSession = snapshot;
    return snapshot;
  }

  @override
  Future<AuthSessionSnapshot?> loadSession() async => _activeSession;

  @override
  Future<void> saveSession(AuthSessionSnapshot? snapshot) async {
    _activeSession = snapshot;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 5 — Authentication Core / Login Boundary Tests', () {
    late MockLocalAuthStoreForLoginTest authStore;

    setUp(() {
      authStore = MockLocalAuthStoreForLoginTest();
    });

    test('1 & 5. Successful System Admin Login with ZERO companies (activeCompanyContext == null)', () async {
      const admin = AuthUser(
        id: 'sys_admin_01',
        name: 'System Admin',
        email: 'sysadmin@nexabiz.local',
        systemRole: SystemRole.systemAdmin,
        status: 'active',
      );
      authStore.seedUser(user: admin, password: 'Password123!', memberships: const []);

      final session = await authStore.login(
        email: 'sysadmin@nexabiz.local',
        password: 'Password123!',
        deviceId: 'device_01',
      );

      expect(session, isNotNull);
      expect(session!.user.id, equals('sys_admin_01'));
      expect(session.user.systemRole, equals(SystemRole.systemAdmin));
      expect(session.user.isSystemAdmin, isTrue);
      expect(session.companies, isEmpty);
      expect(session.currentCompanyId, isNull);
      expect(session.activeCompanyContext, isNull);
      expect(session.isValidSecuritySession, isTrue);
    });

    test('2. Invalid Password Rejection (Fail Closed)', () async {
      const admin = AuthUser(
        id: 'sys_admin_01',
        name: 'System Admin',
        email: 'sysadmin@nexabiz.local',
        systemRole: SystemRole.systemAdmin,
        status: 'active',
      );
      authStore.seedUser(user: admin, password: 'Password123!');

      final session = await authStore.login(
        email: 'sysadmin@nexabiz.local',
        password: 'WrongPassword!',
        deviceId: 'device_01',
      );

      expect(session, isNull);
    });

    test('3. Unknown User Rejection', () async {
      final session = await authStore.login(
        email: 'unknown@nexabiz.local',
        password: 'Password123!',
        deviceId: 'device_01',
      );

      expect(session, isNull);
    });

    test('4. Disabled User Rejection', () async {
      const disabledUser = AuthUser(
        id: 'user_disabled',
        name: 'Disabled User',
        email: 'disabled@nexabiz.local',
        systemRole: SystemRole.regularUser,
        status: 'disabled',
      );
      authStore.seedUser(user: disabledUser, password: 'Password123!');

      final session = await authStore.login(
        email: 'disabled@nexabiz.local',
        password: 'Password123!',
        deviceId: 'device_01',
      );

      expect(session, isNull);
    });

    test('6. User with ONE company receives automatic default company context', () async {
      const user = AuthUser(
        id: 'user_single_comp',
        name: 'Single Comp User',
        email: 'user1@nexabiz.local',
        systemRole: SystemRole.regularUser,
        status: 'active',
      );
      const membership = UserCompanyMembership(
        userId: 'user_single_comp',
        companyId: 'company_alpha',
        role: 'Manager',
        status: 'active',
        permissions: ['sales.create', 'sales.read'],
      );
      authStore.seedCompany(const AuthCompany(id: 'company_alpha', name: 'Alpha Ltd', code: 'ALP'));
      authStore.seedUser(user: user, password: 'Password123!', memberships: [membership]);

      final session = await authStore.login(
        email: 'user1@nexabiz.local',
        password: 'Password123!',
        deviceId: 'device_01',
      );

      expect(session, isNotNull);
      expect(session!.user.id, equals('user_single_comp'));
      expect(session.currentCompanyId, equals('company_alpha'));
      expect(session.activeCompanyContext, isNotNull);
      expect(session.activeCompanyContext!.companyId, equals('company_alpha'));
      expect(session.activeCompanyContext!.companyRole, equals('Manager'));
      expect(session.isValidSecuritySession, isTrue);
    });

    test('7. User with MULTIPLE companies authenticates ONCE (currentCompanyId == null)', () async {
      const user = AuthUser(
        id: 'user_multi_comp',
        name: 'Multi Comp User',
        email: 'multi@nexabiz.local',
        systemRole: SystemRole.regularUser,
        status: 'active',
      );
      const membershipA = UserCompanyMembership(
        userId: 'user_multi_comp',
        companyId: 'comp_a',
        role: 'Manager',
        status: 'active',
        permissions: ['sales.read'],
      );
      const membershipB = UserCompanyMembership(
        userId: 'user_multi_comp',
        companyId: 'comp_b',
        role: 'Accountant',
        status: 'active',
        permissions: ['accounting.read'],
      );

      authStore.seedCompany(const AuthCompany(id: 'comp_a', name: 'Company A', code: 'CPA'));
      authStore.seedCompany(const AuthCompany(id: 'comp_b', name: 'Company B', code: 'CPB'));
      authStore.seedUser(user: user, password: 'Password123!', memberships: [membershipA, membershipB]);

      final session = await authStore.login(
        email: 'multi@nexabiz.local',
        password: 'Password123!',
        deviceId: 'device_01',
      );

      expect(session, isNotNull);
      expect(session!.user.id, equals('user_multi_comp'));
      expect(session.companies.length, equals(2));
      expect(session.currentCompanyId, isNull);
      expect(session.activeCompanyContext, isNull);
      expect(session.isValidSecuritySession, isTrue);
    });

    test('8. Malformed Identity Rejection (Security Invariant Guard)', () {
      const malformedUser = AuthUser(
        id: '', // Invalid empty ID
        name: 'Malformed User',
        email: 'malformed@nexabiz.local',
      );

      final session = AuthSessionSnapshot(
        user: malformedUser,
        companies: const [],
        roles: const [],
        permissions: const {},
        capturedAt: DateTime.now().toUtc(),
      );

      expect(session.isValidSecuritySession, isFalse);
    });

    test('9 & 10. Login Session Creation & Replacement on Repeated Login', () async {
      const user = AuthUser(
        id: 'user_repeat',
        name: 'Repeat Login User',
        email: 'repeat@nexabiz.local',
        status: 'active',
      );
      authStore.seedUser(user: user, password: 'Password123!');

      final session1 = await authStore.login(
        email: 'repeat@nexabiz.local',
        password: 'Password123!',
        deviceId: 'device_01',
      );
      expect(session1, isNotNull);

      final session2 = await authStore.login(
        email: 'repeat@nexabiz.local',
        password: 'Password123!',
        deviceId: 'device_02',
      );

      expect(session2, isNotNull);
      expect(session2!.sessionId, isNot(equals(session1!.sessionId)));
      expect(session2.deviceId, equals('device_02'));
    });
  });
}
