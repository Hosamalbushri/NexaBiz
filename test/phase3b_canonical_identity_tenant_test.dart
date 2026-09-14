import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/repositories/canonical_identity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  late CanonicalIdentityRepositoryImpl repository;

  setUp(() {
    db = NexabizDatabase.connect(NativeDatabase.memory());
    repository = CanonicalIdentityRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3B Canonical Identity & Tenant Foundation Test Suite', () {
    test('1. Create user with stable 36-character UUID and verify persistence', () async {
      final user = await repository.createUser(
        UsersCompanion.insert(
          id: const Value('11111111-1111-4111-8111-111111111111'),
          email: 'admin@nexabiz.com',
          name: 'System Admin',
          passwordHash: const Value('hashed_password_secret_hash'),
        ),
      );

      expect(user.id, equals('11111111-1111-4111-8111-111111111111'));
      expect(user.email, equals('admin@nexabiz.com'));
      expect(user.passwordHash, equals('hashed_password_secret_hash'));

      final fetched = await repository.getUserByUuid('11111111-1111-4111-8111-111111111111');
      expect(fetched, isNotNull);
      expect(fetched!.email, equals('admin@nexabiz.com'));
    });

    test('2. Duplicate user email or UUID is rejected', () async {
      await repository.createUser(
        UsersCompanion.insert(
          id: const Value('11111111-1111-4111-8111-111111111111'),
          email: 'user@nexabiz.com',
          name: 'User One',
        ),
      );

      // Duplicate UUID attempt
      expect(
        () async => repository.createUser(
          UsersCompanion.insert(
            id: const Value('11111111-1111-4111-8111-111111111111'),
            email: 'other@nexabiz.com',
            name: 'User Two',
          ),
        ),
        throwsA(isA<Object>()),
      );

      // Duplicate email attempt
      expect(
        () async => repository.createUser(
          UsersCompanion.insert(
            id: const Value('22222222-2222-4222-8222-222222222222'),
            email: 'user@nexabiz.com',
            name: 'User Three',
          ),
        ),
        throwsA(isA<Object>()),
      );
    });

    test('3. Create company with stable 36-character UUID', () async {
      final company = await repository.createCompany(
        CompaniesCompanion.insert(
          id: const Value('c1111111-1111-4111-8111-111111111111'),
          code: 'ACME_HQ',
          name: 'ACME Corporation',
        ),
      );

      expect(company.id, equals('c1111111-1111-4111-8111-111111111111'));
      expect(company.code, equals('ACME_HQ'));

      final fetched = await repository.getCompanyByCode('ACME_HQ');
      expect(fetched, isNotNull);
      expect(fetched!.id, equals('c1111111-1111-4111-8111-111111111111'));
    });

    test('4. Atomic tenant + admin creation via createTenantWithAdmin', () async {
      final result = await repository.createTenantWithAdmin(
        userEmail: 'owner@acme.com',
        userName: 'ACME Owner',
        passwordHash: 'secret_hash_pwd',
        companyName: 'ACME Holding',
        companyCode: 'ACME_HOLDING',
        userUuid: 'u3333333-3333-4333-8333-333333333333',
        companyUuid: 'c3333333-3333-4333-8333-333333333333',
        membershipUuid: 'm3333333-3333-4333-8333-333333333333',
      );

      expect(result.user.id, equals('u3333333-3333-4333-8333-333333333333'));
      expect(result.company.id, equals('c3333333-3333-4333-8333-333333333333'));
      expect(result.membership.id, equals('m3333333-3333-4333-8333-333333333333'));
      expect(result.membership.role, equals('owner'));

      // Validate membership authorization
      final validMembership = await repository.validateMembership(
        userUuid: result.user.id,
        companyUuid: result.company.id,
      );
      expect(validMembership, isNotNull);
      expect(validMembership!.id, equals(result.membership.id));
    });

    test('5. Transaction Rollback — Failure in atomic creation rolls back User and Company', () async {
      // First create a conflicting company code to force error in transaction
      await repository.createCompany(
        CompaniesCompanion.insert(
          id: const Value('c5555555-5555-4555-8555-555555555555'),
          code: 'CONFLICT_CODE',
          name: 'Existing Company',
        ),
      );

      expect(
        () async => repository.createTenantWithAdmin(
          userEmail: 'fail_user@test.com',
          userName: 'Fail User',
          passwordHash: 'hash',
          companyName: 'Duplicate Company',
          companyCode: 'CONFLICT_CODE', // Will cause duplicate company code failure
          userUuid: 'u5555555-5555-4555-8555-555555555555',
        ),
        throwsA(isA<Object>()),
      );

      // Verify user was NOT persisted due to transaction rollback
      final rolledBackUser = await repository.getUserByUuid('u5555555-5555-4555-8555-555555555555');
      expect(rolledBackUser, isNull);
    });

    test('6. Membership authorization — Unauthorized user access is rejected', () async {
      final tenant = await repository.createTenantWithAdmin(
        userEmail: 'owner@corp.com',
        userName: 'Corp Owner',
        passwordHash: 'hash',
        companyName: 'Corp A',
        companyCode: 'CORP_A',
      );

      final otherUser = await repository.createUser(
        UsersCompanion.insert(
          id: const Value('u6666666-6666-4666-8666-666666666666'),
          email: 'stranger@other.com',
          name: 'Stranger',
        ),
      );

      // Other user attempt to access Corp A must be rejected
      final membership = await repository.validateMembership(
        userUuid: otherUser.id,
        companyUuid: tenant.company.id,
      );

      expect(membership, isNull);
    });

    test('7. Nonexistent foreign keys in membership creation throw ArgumentError', () async {
      expect(
        () async => repository.createMembership(
          CompanyMembershipsCompanion.insert(
            id: const Value('m7777777-7777-4777-8777-777777777777'),
            userId: '77777777-7777-4777-8777-777777777777',
            companyId: '77777777-7777-4777-8777-777777777778',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
