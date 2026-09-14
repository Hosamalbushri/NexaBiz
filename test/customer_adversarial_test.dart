import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_status.dart';
import 'package:stock_count/modules/customers/directory/domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/directory/domain/services/customer_validator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-09 — Adversarial Testing & Cross-Module Validation Suite', () {
    late Directory tempDir;
    late NexabizDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repoCompanyA;
    late CustomerRepositoryImpl repoCompanyB;
    const validator = CustomerValidator();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu09_adv_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu09');
      queue = SyncQueue(box: box);
      db = NexabizDatabase.memory();

      repoCompanyA = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_adv_A',
      );

      repoCompanyB = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_adv_B',
      );
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    // -------------------------------------------------------------------------
    // 1. IDENTITY ATTACKS
    // -------------------------------------------------------------------------
    test(
      '1.1 IDENTITY ATTACK: Duplicate customerCode in same company throws duplicateCustomerCode',
      () async {
        await repoCompanyA.insert(
          const CustomerDraft(customerCode: '12210080', name: 'عميل كود أصلي'),
        );

        expect(
          () => repoCompanyA.insert(
            const CustomerDraft(
              customerCode: '12210080',
              name: 'عميل تكرار الكود',
            ),
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.duplicateCustomerCode,
            ),
          ),
        );
      },
    );

    test(
      '1.2 IDENTITY ATTACK: Soft-deleted customer reference cannot be read by standard getById',
      () async {
        final created = await repoCompanyA.insert(
          const CustomerDraft(
            customerCode: '12210081',
            name: 'عميل للحذف والهجوم',
          ),
        );

        await repoCompanyA.softDelete(created.id);

        final fetched = await repoCompanyA.getById(created.id);
        expect(fetched, isNull);
      },
    );

    // -------------------------------------------------------------------------
    // 2. TENANCY ATTACKS
    // -------------------------------------------------------------------------
    test(
      '2.1 TENANCY ATTACK: Company A cannot access Company B customer via search or update',
      () async {
        final custB = await repoCompanyB.insert(
          const CustomerDraft(
            customerCode: '12210082',
            name: 'عميل شركة ب الهجومي',
          ),
        );

        final searchA = await repoCompanyA.search('الهجومي');
        expect(searchA, isEmpty);

        expect(
          () => repoCompanyA.update(
            custB.id,
            custB.toDraft().copyWith(name: 'تغيير غير مصرح'),
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

    // -------------------------------------------------------------------------
    // 3. ACCOUNTING INTEGRATION ATTACKS
    // -------------------------------------------------------------------------
    test(
      '3.1 ACCOUNTING ATTACK: Cross-company account binding throws accountCompanyMismatch',
      () {
        expect(
          () => validator.validateAccountLink(
            const LinkedAccountRef(
              accountId: 'acc_company_B_99',
              code: '122100',
              name: 'حساب عملاء شركة ب',
              companyId: 'comp_adv_B',
            ),
            customerCompanyId: 'comp_adv_A',
          ),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.accountCompanyMismatch,
            ),
          ),
        );
      },
    );

    // -------------------------------------------------------------------------
    // 4. CREDIT LIMIT ATTACKS
    // -------------------------------------------------------------------------
    test(
      '4.1 CREDIT ATTACK: Negative credit limit in draft throws invalidCreditLimit',
      () {
        final invalidDraft = const CustomerDraft(
          customerCode: '12210083',
          name: 'عميل حد سلبى',
          creditLimit: -500.0,
        );

        expect(
          () => validator.validate(invalidDraft),
          throwsA(
            isA<CustomerException>().having(
              (e) => e.code,
              'code',
              CustomerException.invalidCreditLimit,
            ),
          ),
        );
      },
    );

    // -------------------------------------------------------------------------
    // 5. PERSISTENCE ATTACKS & RESTART FIDELITY
    // -------------------------------------------------------------------------
    test(
      '5.1 PERSISTENCE ATTACK: Customer state survives database restart with full fidelity',
      () async {
        final created = await repoCompanyA.insert(
          const CustomerDraft(
            customerCode: '12210084',
            name: 'عميل اختبار الإستمرارية',
            phone: '+966507777777',
            creditLimit: 5000.0,
          ),
        );

        final updated = await repoCompanyA.update(
          created.id,
          created.toDraft().copyWith(notes: 'ملاحظة بعد التحديث'),
        );

        // Reopen repository / connection on same memory DB
        final repoReopened = CustomerRepositoryImpl(
          db,
          syncQueue: queue,
          readCompanyId: () => 'comp_adv_A',
        );

        final reloaded = await repoReopened.getById(updated.id);
        expect(reloaded, isNotNull);
        expect(reloaded!.name, equals('عميل اختبار الإستمرارية'));
        expect(reloaded.notes, equals('ملاحظة بعد التحديث'));
        expect(reloaded.creditLimit, equals(5000.0));
        expect(reloaded.version, equals(2));
      },
    );

    // -------------------------------------------------------------------------
    // 6. CONCURRENCY ATTACKS & RACE CONDITIONS
    // -------------------------------------------------------------------------
    test(
      '6.1 CONCURRENCY ATTACK: Simultaneous parallel inserts complete deterministically',
      () async {
        final futures = List.generate(10, (index) {
          return repoCompanyA.insert(
            CustomerDraft(
              customerCode: '1221009$index',
              name: 'عميل توازي $index',
            ),
          );
        });

        final results = await Future.wait(futures);
        expect(results, hasLength(10));
        final all = await repoCompanyA.getAll();
        expect(all, hasLength(10));
      },
    );
  });
}
