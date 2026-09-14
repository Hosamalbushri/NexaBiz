import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/repositories/canonical_identity_repository.dart';
import 'package:stock_count/core/database/repositories/canonical_identity_migrator.dart';
import 'package:stock_count/core/database/repositories/canonical_master_data_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/active_company_context.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/user_company_membership.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  late CanonicalIdentityRepository identityRepo;
  late CanonicalMasterDataRepository masterDataRepo;
  late Box<dynamic> hiveBox;
  late LocalAuthStore localAuthStore;

  setUp(() async {
    Hive.init('./test_hive_phase3r');
    hiveBox = await Hive.openBox<dynamic>('test_local_auth_phase3r');
    await hiveBox.clear();

    db = NexabizDatabase.connect(NativeDatabase.memory());
    identityRepo = CanonicalIdentityRepositoryImpl(db);
    masterDataRepo = CanonicalMasterDataRepositoryImpl(db);
    localAuthStore = LocalAuthStore(
      box: hiveBox,
      identityRepository: identityRepo,
    );
  });

  tearDown(() async {
    await db.close();
    await hiveBox.clear();
    await hiveBox.close();
    await Hive.deleteFromDisk();
  });

  group('Phase 3R — Canonical Identity & Master Data Production Routing', () {
    test('1. Idempotent Identity Migration from legacy Hive storage', () async {
      // Seed legacy Hive box directly
      await hiveBox.put('users', [
        {
          'id': 'legacy-user-1',
          'name': 'Legacy User',
          'email': 'legacy@nexabiz.com',
          'passwordSalt': 'salt123',
          'passwordHash': 'hash123',
          'status': 'active',
          'isSuperAdmin': false,
          'companyIds': ['company-1'],
          'rolesByCompany': {'company-1': 'Owner'},
          'permissionsByCompany': {'company-1': ['manage_all']},
        }
      ]);
      await hiveBox.put('companies', [
        {
          'id': 'company-1',
          'name': 'Legacy Company',
          'code': 'LEG01',
          'role': 'Owner',
        }
      ]);
      await hiveBox.put('memberships', [
        {
          'userId': 'legacy-user-1',
          'companyId': 'company-1',
          'role': 'Owner',
          'status': 'active',
          'permissions': ['manage_all'],
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }
      ]);

      // Run migrator
      final migrator = CanonicalIdentityMigrator(
        identityRepository: identityRepo,
        localAuthStore: localAuthStore,
      );
      await migrator.migrateIfNeeded();

      // Verify records in nexabiz.sqlite
      final users = await identityRepo.getAllUsers();
      final companies = await identityRepo.getAllCompanies();
      final memberships = await identityRepo.getAllMemberships();

      expect(users.length, equals(1));
      expect(users.first.uuid, equals('legacy-user-1'));
      expect(users.first.email, equals('legacy@nexabiz.com'));

      expect(companies.length, equals(1));
      expect(companies.first.uuid, equals('company-1'));
      expect(companies.first.name, equals('Legacy Company'));

      expect(memberships.length, equals(1));
      expect(memberships.first.userUuid, equals('legacy-user-1'));
      expect(memberships.first.companyId, equals('company-1'));

      // Re-run migrator to test idempotency (no duplication)
      await migrator.migrateIfNeeded();
      final usersAfter = await identityRepo.getAllUsers();
      expect(usersAfter.length, equals(1));
    });

    test('2. User Creation & Password Authentication via Canonical Repository', () async {
      final createdUser = await identityRepo.createUser(
        UsersCompanion.insert(
          id: 'user-uuid-100',
          email: 'admin@nexabiz.com',
          name: 'Admin User',
          passwordHash: const Value('hashed_secret_password'),
          status: const Value('active'),
          isSuperAdmin: const Value(true),
        ),
      );

      expect(createdUser.uuid, equals('user-uuid-100'));
      expect(createdUser.email, equals('admin@nexabiz.com'));

      final fetched = await identityRepo.getUserByEmail('admin@nexabiz.com');
      expect(fetched, isNotNull);
      expect(fetched!.passwordHash, equals('hashed_secret_password'));
    });

    test('3. Company & Owner Membership Atomic Creation', () async {
      final tenant = await identityRepo.createTenantWithAdmin(
        userEmail: 'owner@nexabiz.com',
        userName: 'Owner Name',
        passwordHash: 'owner_hash',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        userUuid: 'owner-uuid-1',
        companyId: 'acme-uuid-1',
        membershipUuid: 'mem-uuid-1',
      );

      expect(tenant.user.uuid, equals('owner-uuid-1'));
      expect(tenant.company.id, equals('acme-uuid-1'));
      expect(tenant.company.code, equals('ACME'));
      expect(tenant.membership.role, equals('owner'));
      expect(tenant.membership.status, equals('active'));
    });

    test('4. Membership Validation against Canonical Database', () async {
      await identityRepo.createTenantWithAdmin(
        userEmail: 'member@nexabiz.com',
        userName: 'Member User',
        passwordHash: 'pass',
        companyName: 'Beta Inc',
        companyCode: 'BETA',
        userUuid: 'user-beta-1',
        companyId: 'comp-beta-1',
      );

      final valid = await identityRepo.validateMembership(
        userUuid: 'user-beta-1',
        companyId: 'comp-beta-1',
      );
      expect(valid, isNotNull);
      expect(valid!.role, equals('owner'));

      final invalid = await identityRepo.validateMembership(
        userUuid: 'user-beta-1',
        companyId: 'non-existent-company',
      );
      expect(invalid, isNull);
    });

    test('5. Same-Company Switch Idempotency (Rule 11)', () async {
      const membership = UserCompanyMembership(
        userId: 'user-id-1',
        companyId: 'comp-1',
        role: 'Owner',
        status: 'active',
        permissions: ['manage'],
      );

      final session = AuthSessionSnapshot(
        user: const AuthUser(
          id: 'user-id-1',
          name: 'User 1',
          email: 'u1@test.com',
          status: 'active',
        ),
        currentCompanyId: 'comp-1',
        activeMembership: membership,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membership,
          authenticatedUserId: 'user-id-1',
          companyName: 'Comp 1',
          companyCode: 'C1',
        ),
        permissions: const {'manage'},
        roles: const ['Owner'],
        companies: const [
          AuthCompany(id: 'comp-1', name: 'Comp 1', code: 'C1', role: 'Owner'),
        ],
        capturedAt: DateTime.now().toUtc(),
        sessionId: 'stable-session-id-999',
      );

      await localAuthStore.saveSession(session);

      // Switching to same companyId 'comp-1'
      final switched = await localAuthStore.switchCompany(
        current: session,
        companyId: 'comp-1',
      );

      expect(switched, isNotNull);
      expect(switched!.currentCompanyId, equals('comp-1'));
      expect(switched.sessionId, equals('stable-session-id-999'));
    });

    test('6. Failed Switch Context Preservation (Rule 12)', () async {
      await hiveBox.put('users', [
        {
          'id': 'user-id-2',
          'name': 'User 2',
          'email': 'u2@test.com',
          'passwordSalt': 'salt2',
          'passwordHash': 'hash2',
          'status': 'active',
          'isSuperAdmin': false,
          'companyIds': ['comp-active'],
          'rolesByCompany': {'comp-active': 'Admin'},
          'permissionsByCompany': {'comp-active': ['manage']},
        }
      ]);
      await hiveBox.put('companies', [
        {
          'id': 'comp-active',
          'name': 'Active Comp',
          'code': 'ACT',
          'role': 'Admin',
        }
      ]);
      await hiveBox.put('memberships', [
        {
          'userId': 'user-id-2',
          'companyId': 'comp-active',
          'role': 'Admin',
          'status': 'active',
          'permissions': ['manage'],
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }
      ]);



      const membership = UserCompanyMembership(
        userId: 'user-id-2',
        companyId: 'comp-active',
        role: 'Admin',
        status: 'active',
        permissions: ['manage'],
      );


      final session = AuthSessionSnapshot(
        user: const AuthUser(
          id: 'user-id-2',
          name: 'User 2',
          email: 'u2@test.com',
          status: 'active',
        ),
        currentCompanyId: 'comp-active',
        activeMembership: membership,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: membership,
          authenticatedUserId: 'user-id-2',
          companyName: 'Active Comp',
          companyCode: 'ACT',
        ),
        permissions: const {'manage'},
        roles: const ['Admin'],
        companies: const [
          AuthCompany(id: 'comp-active', name: 'Active Comp', code: 'ACT', role: 'Admin'),
        ],
        capturedAt: DateTime.now().toUtc(),
        sessionId: 'active-session-id-777',
      );

      await localAuthStore.saveSession(session);

      // Switch to non-existent company without membership
      final switched = await localAuthStore.switchCompany(
        current: session,
        companyId: 'non-existent-company',
      );

      // Failed switch returns null, but existing session in store remains unchanged
      expect(switched, isNull);

      final preservedSession = await localAuthStore.loadSession();
      expect(preservedSession, isNotNull);
      expect(preservedSession!.currentCompanyId, equals('comp-active'));
      expect(preservedSession.sessionId, equals('active-session-id-777'));
    });

    test('7. Session ID Stability Across Company Switch', () async {
      // Seed user with 2 companies
      await identityRepo.createTenantWithAdmin(
        userEmail: 'multi@nexabiz.com',
        userName: 'Multi User',
        passwordHash: 'pass',
        companyName: 'Comp A',
        companyCode: 'CA',
        userUuid: 'multi-user-id',
        companyId: 'comp-a-id',
      );
      await identityRepo.createCompany(
        CompaniesCompanion.insert(
          id: 'comp-b-id',
          code: 'CB',
          name: 'Comp B',
        ),
      );
      await identityRepo.createMembership(
        CompanyMembershipsCompanion.insert(
          id: 'mem-b-id',
          userUuid: 'multi-user-id',
          companyId: 'comp-b-id',
          role: const Value('member'),
        ),
      );

      const memA = UserCompanyMembership(
        userId: 'multi-user-id',
        companyId: 'comp-a-id',
        role: 'Owner',
        status: 'active',
      );

      // Save initial session
      final initialSession = AuthSessionSnapshot(
        user: const AuthUser(
          id: 'multi-user-id',
          name: 'Multi User',
          email: 'multi@nexabiz.com',
          status: 'active',
        ),
        currentCompanyId: 'comp-a-id',
        activeMembership: memA,
        activeCompanyContext: ActiveCompanyContext.fromMembership(
          membership: memA,
          authenticatedUserId: 'multi-user-id',
          companyName: 'Comp A',
          companyCode: 'CA',
        ),
        permissions: const {'manage'},
        roles: const ['Owner'],
        companies: const [
          AuthCompany(id: 'comp-a-id', name: 'Comp A', code: 'CA', role: 'Owner'),
          AuthCompany(id: 'comp-b-id', name: 'Comp B', code: 'CB', role: 'Member'),
        ],
        capturedAt: DateTime.now().toUtc(),
        sessionId: 'stable-session-uuid-12345',
      );
      await localAuthStore.saveSession(initialSession);

      // Switch to Comp B
      final switched = await localAuthStore.switchCompany(
        current: initialSession,
        companyId: 'comp-b-id',
      );
      expect(switched, isNotNull);
      expect(switched!.currentCompanyId, equals('comp-b-id'));
      // Invariant: Session ID remains identical
      expect(switched.sessionId, equals('stable-session-uuid-12345'));
    });

    test('8. Master Data Company Scoping Enforcement', () async {
      // Calling getCategories with null or empty companyId must throw ArgumentError
      expect(
        () => masterDataRepo.getCategories(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => masterDataRepo.getWarehouses('   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => masterDataRepo.getAccounts(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => masterDataRepo.getProducts(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('9. Password Change Persistence in Canonical Database', () async {
      final initialHash = LocalAuthStore.hashPassword('OldPass123!', 'salt-1');
      // Seed user in canonical db
      final user = await identityRepo.createUser(
        UsersCompanion.insert(
          id: 'pwd-user-1',
          email: 'change@nexabiz.com',
          name: 'Change User',
          passwordHash: Value(initialHash),
        ),
      );

      // Seed local user record in Hive
      await hiveBox.put('users', [
        {
          'id': 'pwd-user-1',
          'name': 'Change User',
          'email': 'change@nexabiz.com',
          'passwordSalt': 'salt-1',
          'passwordHash': initialHash,
          'status': 'active',
          'isSuperAdmin': false,
          'companyIds': ['c1'],
          'rolesByCompany': {'c1': 'Owner'},
          'permissionsByCompany': {'c1': ['manage']},
        }
      ]);

      await localAuthStore.saveSession(
        AuthSessionSnapshot(
          user: const AuthUser(
            id: 'pwd-user-1',
            name: 'Change User',
            email: 'change@nexabiz.com',
            status: 'active',
          ),
          currentCompanyId: 'c1',
          permissions: const {'manage'},
          roles: const ['Owner'],
          companies: const [
            AuthCompany(id: 'c1', name: 'Company 1', code: 'C1', role: 'Owner'),
          ],
          capturedAt: DateTime.now().toUtc(),
        ),
      );


      // Change password via LocalAuthStore
      await localAuthStore.changePassword(
        userId: 'pwd-user-1',
        currentPassword: 'OldPass123!',
        newPassword: 'NewSecurePass123!',
      );

      // Verify password updated in canonical Users table
      final updatedUser = await identityRepo.getUserByUuid('pwd-user-1');
      expect(updatedUser, isNotNull);
      expect(updatedUser!.passwordHash, isNot(equals(user.passwordHash)));
    });

    test('10. Fail-Closed Session Validation', () async {
      // Valid user session with inactive user status
      await identityRepo.createUser(
        UsersCompanion.insert(
          id: 'disabled-user-id',
          email: 'disabled@nexabiz.com',
          name: 'Disabled User',
          passwordHash: const Value('hash'),
          status: const Value('disabled'),
        ),
      );

      final user = await identityRepo.getUserByUuid('disabled-user-id');
      expect(user, isNotNull);
      expect(user!.status, equals('disabled'));

      // Validate membership for non-existent membership
      final membership = await identityRepo.validateMembership(
        userUuid: 'disabled-user-id',
        companyId: 'company-x',
      );
      expect(membership, isNull);
    });
  });
}
