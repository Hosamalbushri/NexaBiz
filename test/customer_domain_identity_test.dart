import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_status.dart';
import 'package:stock_count/modules/customers/directory/domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/directory/domain/services/customer_validator.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-02 — Customer Domain Model & Identity Integrity', () {
    late Directory tempDir;
    late NexabizDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repoCompanyA;
    late CustomerRepositoryImpl repoCompanyB;
    const validator = CustomerValidator();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu02_identity_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu02');
      queue = SyncQueue(box: box);
      db = NexabizDatabase.memory();
      repoCompanyA = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_A',
      );
      repoCompanyB = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_B',
      );
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('1. Identity: UUID is auto-generated and immutable', () async {
      final customer = await repoCompanyA.insert(
        const CustomerDraft(customerCode: '12210001', name: 'عميل اختبار'),
      );

      expect(customer.id, isNotEmpty);
      expect(customer.id.length, equals(36));
      expect(customer.companyId, equals('comp_A'));

      final updated = await repoCompanyA.update(
        customer.id,
        customer.toDraft().copyWith(name: 'عميل معدل'),
      );

      expect(updated.uuid, equals(customer.id));
      expect(updated.name, equals('عميل معدل'));
    });

    test(
      '2. Tenancy: Company isolation prevents cross-tenant access and mutation',
      () async {
        final customerA = await repoCompanyA.insert(
          const CustomerDraft(customerCode: '12210001', name: 'شركة أ عميل'),
        );

        // Company B cannot read Company A customer by ID or UUID
        final byIdFromB = await repoCompanyB.getById(customerA.id);
        expect(byIdFromB, isNull);

        final byUuidFromB = await repoCompanyB.getByUuid(customerA.uuid);
        expect(byUuidFromB, isNull);

        final listB = await repoCompanyB.getAll();
        expect(listB.where((c) => c.uuid == customerA.uuid), isEmpty);

        // Company B update attempt fails
        expect(
          () async => repoCompanyB.update(
            customerA.id,
            customerA.toDraft().copyWith(name: 'اختراق'),
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.notFound,
            ),
          ),
        );
      },
    );

    test(
      '3. Credit Limit: Negative limits are rejected with invalidCreditLimit',
      () {
        expect(
          () => validator.validate(
            const CustomerDraft(
              customerCode: '12210001',
              name: 'عميل خطة ائتمان',
              creditLimit: -100.0,
            ),
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.invalidCreditLimit,
            ),
          ),
        );

        // Zero and positive limits pass validation
        expect(
          () => validator.validate(
            const CustomerDraft(
              customerCode: '12210001',
              name: 'عميل خطة ائتمان',
              creditLimit: 0.0,
            ),
          ),
          returnsNormally,
        );

        expect(
          () => validator.validate(
            const CustomerDraft(
              customerCode: '12210001',
              name: 'عميل خطة ائتمان',
              creditLimit: 5000.0,
            ),
          ),
          returnsNormally,
        );
      },
    );

    test(
      '4. Currency: Invalid currency codes are rejected with invalidCurrencyCode',
      () {
        expect(
          () => validator.validate(
            const CustomerDraft(
              customerCode: '12210001',
              name: 'عميل عملة',
              currencyCode: 'US',
            ),
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.invalidCurrencyCode,
            ),
          ),
        );

        expect(
          () => validator.validate(
            const CustomerDraft(
              customerCode: '12210001',
              name: 'عميل عملة',
              currencyCode: 'USDD',
            ),
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.invalidCurrencyCode,
            ),
          ),
        );

        // Valid 3-letter currency code passes
        expect(
          () => validator.validate(
            const CustomerDraft(
              customerCode: '12210001',
              name: 'عميل عملة',
              currencyCode: 'SAR',
            ),
          ),
          returnsNormally,
        );
      },
    );

    test(
      '5. Account Linking: Enforces company match, active status, and posting requirements',
      () {
        // 5a. Company mismatch
        expect(
          () => validator.validateAccountLink(
            const LinkedAccountRef(
              accountId: 'acc_1',
              code: '1221',
              name: 'حساب شركة ب',
              companyId: 'comp_B',
            ),
            customerCompanyId: 'comp_A',
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.accountCompanyMismatch,
            ),
          ),
        );

        // 5b. Inactive account
        expect(
          () => validator.validateAccountLink(
            const LinkedAccountRef(
              accountId: 'acc_2',
              code: '1221',
              name: 'حساب غير مفعّل',
              companyId: 'comp_A',
              isActive: false,
            ),
            customerCompanyId: 'comp_A',
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.accountInactive,
            ),
          ),
        );

        // 5c. Group account (not posting)
        expect(
          () => validator.validateAccountLink(
            const LinkedAccountRef(
              accountId: 'acc_3',
              code: '1220',
              name: 'حساب تجميعي',
              companyId: 'comp_A',
              isActive: true,
              isPosting: false,
              isGroup: true,
            ),
            customerCompanyId: 'comp_A',
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.accountNotPosting,
            ),
          ),
        );

        // 5d. Valid account link passes
        expect(
          () => validator.validateAccountLink(
            const LinkedAccountRef(
              accountId: 'acc_4',
              code: '12210001',
              name: 'حساب فرعي صالحة',
              companyId: 'comp_A',
              isActive: true,
              isPosting: true,
              isGroup: false,
            ),
            customerCompanyId: 'comp_A',
          ),
          returnsNormally,
        );
      },
    );

    test('6. Status: CustomerStatus lifecycle and mapping integrity', () async {
      final customer = await repoCompanyA.insert(
        const CustomerDraft(
          customerCode: '12210005',
          name: 'عميل حالة',
          status: CustomerStatus.blocked,
        ),
      );

      expect(customer.status, equals(CustomerStatus.blocked));
      expect(customer.isActive, isFalse);

      final fetched = await repoCompanyA.getById(customer.id);
      expect(fetched!.status, equals(CustomerStatus.blocked));

      final updated = await repoCompanyA.update(
        customer.id,
        customer.toDraft().copyWith(status: CustomerStatus.active),
      );
      expect(updated.status, equals(CustomerStatus.active));
      expect(updated.isActive, isTrue);
    });
  });
}
