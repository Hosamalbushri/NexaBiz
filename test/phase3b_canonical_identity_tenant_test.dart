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
          uuid: '11111111-1111-4111-8111-111111111111',
          email: 'admin@nexabiz.com',
          name: 'System Admin',
          passwordHash: const Value('hashed_password_secret_hash'),
        ),
      );

      expect(user.uuid, equals('11111111-1111-4111-8111-111111111111'));
      expect(user.email, equals('admin@nexabiz.com'));
      expect(user.passwordHash, equals('hashed_password_secret_hash'));

      final fetched = await repository.getUserByUuid('11111111-1111-4111-8111-111111111111');
      expect(fetched, isNotNull);
      expect(fetched!.email, equals('admin@nexabiz.com'));
    });

    test('2. Duplicate user email or UUID is rejected', () async {
      await repository.createUser(
        UsersCompanion.insert(
          uuid: '11111111-1111-4111-8111-111111111111',
          email: 'user@nexabiz.com',
          name: 'User One',
        ),
      );

      // Duplicate UUID attempt
      expect(
        () async => repository.createUser(
          UsersCompanion.insert(
            uuid: '11111111-1111-4111-8111-111111111111',
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
            uuid: '22222222-2222-4222-8222-222222222222',
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
          uuid: 'c1111111-1111-4111-8111-111111111111',
          code: 'ACME_HQ',
          name: 'ACME Corporation',
        ),
      );

      expect(company.uuid, equals('c1111111-1111-4111-8111-111111111111'));
      expect(company.code, equals('ACME_HQ'));

      final fetched = await repository.getCompanyByCode('ACME_HQ');
      expect(fetched, isNotNull);
      expect(fetched!.uuid, equals('c1111111-1111-4111-8111-111111111111'));
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

      expect(result.user.uuid, equals('u3333333-3333-4333-8333-333333333333'));
      expect(result.company.uuid, equals('c3333333-3333-4333-8333-333333333333'));
      expect(result.membership.uuid, equals('m3333333-3333-4333-8333-333333333333'));
      expect(result.membership.role, equals('owner'));

      // Validate membership authorization
      final validMembership = await repository.validateMembership(
        userUuid: result.user.uuid,
        companyUuid: result.company.uuid,
      );
      expect(validMembership, isNotNull);
      expect(validMembership!.uuid, equals(result.membership.uuid));
    });

    test('5. Transaction Rollback — Failure in atomic creation rolls back User and Company', () async {
      // First create a conflicting company code to force error in transaction
      await repository.createCompany(
        CompaniesCompanion.insert(
          uuid: 'c_existing_000',
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
          userUuid: 'u_should_rollback',
        ),
        throwsA(isA<Object>()),
      );

      // Verify user was NOT persisted due to transaction rollback
      final rolledBackUser = await repository.getUserByUuid('u_should_rollback');
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
          uuid: 'u_unauthorized_999',
          email: 'stranger@other.com',
          name: 'Stranger',
        ),
      );

      // Other user attempt to access Corp A must be rejected
      final membership = await repository.validateMembership(
        userUuid: otherUser.uuid,
        companyUuid: tenant.company.uuid,
      );

      expect(membership, isNull);
    });

    test('7. Nonexistent foreign keys in membership creation throw ArgumentError', () async {
      expect(
        () async => repository.createMembership(
          CompanyMembershipsCompanion.insert(
            uuid: 'm_invalid_1',
            userUuid: 'nonexistent_user',
            companyUuid: 'nonexistent_company',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
