import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/repositories/canonical_identity_repository.dart';
import 'package:stock_count/core/identity/data/repositories/canonical_company_repository_adapter.dart';
import 'package:stock_count/core/identity/data/repositories/canonical_membership_repository_adapter.dart';
import 'package:stock_count/core/identity/data/repositories/canonical_user_repository_adapter.dart';
import 'package:stock_count/core/security/data/pbkdf2_password_hasher_adapter.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';

void main() {
  group('Phase 3C — Persistence & Engine Alignment Suite', () {
    late NexabizDatabase db;
    late CanonicalIdentityRepository identityRepo;
    late CanonicalUserRepositoryAdapter userAdapter;
    late CanonicalCompanyRepositoryAdapter companyAdapter;
    late CanonicalMembershipRepositoryAdapter membershipAdapter;
    late Pbkdf2PasswordHasherAdapter passwordHasher;
    late Box<dynamic> testBox;

    setUp(() async {
      Hive.init('./test_tmp_phase3c');
      testBox = await Hive.openBox<dynamic>('test_phase3c_auth');
      await testBox.clear();

      db = NexabizDatabase.connect(NativeDatabase.memory());
      identityRepo = CanonicalIdentityRepositoryImpl(db);
      userAdapter = CanonicalUserRepositoryAdapter(identityRepo);
      companyAdapter = CanonicalCompanyRepositoryAdapter(identityRepo);
      membershipAdapter = CanonicalMembershipRepositoryAdapter(identityRepo);
      passwordHasher = const Pbkdf2PasswordHasherAdapter();
    });

    tearDown(() async {
      await testBox.clear();
      await testBox.close();
      await db.close();
    });

    test('1. User, Company, and Membership persist through canonical SQLite authority', () async {
      final result = await identityRepo.createTenantWithAdmin(
        userEmail: 'admin@nexabiz.com',
        userName: 'Admin User',
        passwordHash: passwordHasher.hashPassword('Pass1234!', 'salt123'),
        companyName: 'Acme Corp',
        companyCode: 'ACME',
      );

      expect(result.user.email, equals('admin@nexabiz.com'));
      expect(result.company.code, equals('ACME'));
      expect(result.membership.role, equals('owner'));

      final user = await userAdapter.findByEmail('admin@nexabiz.com');
      expect(user, isNotNull);
      expect(user!.id, equals(result.user.id));

      final company = await companyAdapter.findById(result.company.id);
      expect(company, isNotNull);
      expect(company!.code, equals('ACME'));

      final membership = await membershipAdapter.findByUserAndCompany(
        result.user.id,
        result.company.id,
      );
      expect(membership, isNotNull);
      expect(membership!.role, equals('owner'));

      final isValid = await membershipAdapter.validateMembership(
        result.user.id,
        result.company.id,
      );
      expect(isValid, isTrue);
    });

    test('2. PBKDF2 is canonical password hasher for new credentials and password verification', () async {
      final salt = Pbkdf2PasswordHasherAdapter.generateSalt();
      final hash = passwordHasher.hashPassword('SecurePassword123!', salt);

      expect(hash, isNotEmpty);
      expect(passwordHasher.verifyPassword('SecurePassword123!', hash, salt), isTrue);
      expect(passwordHasher.verifyPassword('WrongPassword', hash, salt), isFalse);
    });

    test('3. Session restoration against SQLite fails closed when user or membership is inactive', () async {
      final localStore = LocalAuthStore(box: testBox, identityRepository: identityRepo);

      final result = await identityRepo.createTenantWithAdmin(
        userEmail: 'testuser@nexabiz.com',
        userName: 'Test User',
        passwordHash: passwordHasher.hashPassword('Pass1234!', 'salt123'),
        companyName: 'Test Co',
        companyCode: 'TEST',
      );

      final fakeSession = AuthSessionSnapshot(
        user: AuthUser(
          id: result.user.id,
          name: result.user.name,
          email: result.user.email,
          status: 'active',
        ),
        companies: const [],
        roles: const ['owner'],
        permissions: const {},
        currentCompanyId: result.company.id,
        capturedAt: DateTime.now().toUtc(),
        sessionId: 'session-123',
      );

      await localStore.saveSession(fakeSession);

      // Deactivate user in SQLite database directly
      await db.update(db.users).write(
        const UsersCompanion(status: Value('inactive')),
      );

      // Restoration must check SQLite authority and fail closed (return null)
      final restored = await localStore.validateAndRestoreSession();
      expect(restored, isNull);
    });

    test('4. Inactive membership fails closed during session restoration', () async {
      final localStore = LocalAuthStore(box: testBox, identityRepository: identityRepo);

      final result = await identityRepo.createTenantWithAdmin(
        userEmail: 'member@nexabiz.com',
        userName: 'Member User',
        passwordHash: passwordHasher.hashPassword('Pass1234!', 'salt123'),
        companyName: 'Member Co',
        companyCode: 'MEMB',
      );

      final fakeSession = AuthSessionSnapshot(
        user: AuthUser(
          id: result.user.id,
          name: result.user.name,
          email: result.user.email,
          status: 'active',
        ),
        companies: const [],
        roles: const ['owner'],
        permissions: const {},
        currentCompanyId: result.company.id,
        capturedAt: DateTime.now().toUtc(),
        sessionId: 'session-456',
      );

      await localStore.saveSession(fakeSession);

      // Deactivate membership in SQLite database directly
      await db.update(db.companyMemberships).write(
        const CompanyMembershipsCompanion(status: Value('inactive')),
      );

      final restored = await localStore.validateAndRestoreSession();
      expect(restored, isNotNull);
      // Company context must be cleared when membership is inactive (fail closed)
      expect(restored!.currentCompanyId, isNull);
    });

    test('5. TenantContext adheres strictly to ActiveCompanyContext without implicit defaults', () {
      final resolver = const CompanyContextResolver();

      expect(
        () => resolver.resolveActiveCompanyId(
          context: null,
          requestedCompanyId: 'comp-1',
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );

      final authContext = AuthorizationContext(
        userId: 'user-uuid-123',
        companyId: 'company-uuid-123',
        permissions: const {},
        entitlement: Entitlement.freeLocal('company-uuid-123'),
        authenticationMode: AuthenticationMode.local,
      );

      final companyId = resolver.resolveActiveCompanyId(
        context: authContext,
        requestedCompanyId: 'company-uuid-123',
      );
      expect(companyId, equals('company-uuid-123'));
    });

    test('6. Company switching preserves session identity and fails closed on invalid target', () async {
      final localStore = LocalAuthStore(box: testBox, identityRepository: identityRepo);

      final result = await identityRepo.createTenantWithAdmin(
        userEmail: 'switcher@nexabiz.com',
        userName: 'Switcher',
        passwordHash: passwordHasher.hashPassword('Pass1234!', 'salt123'),
        companyName: 'Company 1',
        companyCode: 'COMP1',
      );

      final session = AuthSessionSnapshot(
        user: AuthUser(
          id: result.user.id,
          name: result.user.name,
          email: result.user.email,
          status: 'active',
        ),
        companies: const [],
        roles: const ['owner'],
        permissions: const {},
        currentCompanyId: result.company.id,
        capturedAt: DateTime.now().toUtc(),
        sessionId: 'stable-session-789',
      );

      // Idempotency: same company switch returns identical session
      final sameSwitch = await localStore.switchCompany(
        current: session,
        companyId: result.company.id,
      );
      expect(sameSwitch, equals(session));

      // Attempt switch to non-existent company fails closed (returns null, session preserved)
      final invalidSwitch = await localStore.switchCompany(
        current: session,
        companyId: 'non-existent-company-id',
      );
      expect(invalidSwitch, isNull);
    });
  });
}
