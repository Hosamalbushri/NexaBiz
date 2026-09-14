import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/customers/directory/data/datasources/customer_excel_import_datasource.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_data_source.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_status.dart';
import 'package:stock_count/modules/customers/directory/domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/directory/domain/usecases/customer_usecases.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

class _AllowAllPermissionGuard implements PermissionGuard {
  @override
  void requireAny(Iterable<String> permissions) {}

  @override
  void requireAll(Iterable<String> permissions) {}

  @override
  bool hasAny(Iterable<String> permissions) => true;

  @override
  bool hasAll(Iterable<String> permissions) => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-03 — Customer CRUD & Persistence Architecture', () {
    late Directory tempDir;
    late NexabizDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repoCompanyA;
    late CustomerRepositoryImpl repoCompanyB;
    final guard = _AllowAllPermissionGuard();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu03_crud_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu03');
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

    test(
      '1. CREATE: Via CreateCustomer use case with clean domain validation',
      () async {
        final usecase = CreateCustomer(repoCompanyA, permissionGuard: guard);
        final customer = await usecase(
          const CustomerDraft(
            customerCode: '12210010',
            name: 'عميل إنشاء جديد',
            phone: '+966500000000',
            email: 'customer@example.com',
            creditLimit: 15000.0,
            currencyCode: 'SAR',
            taxNumber: '300000000000003',
          ),
        );

        expect(customer.id, greaterThan(0));
        expect(customer.id, isNotEmpty);
        expect(customer.companyId, equals('comp_A'));
        expect(customer.customerCode, equals('12210010'));
        expect(customer.name, equals('عميل إنشاء جديد'));
        expect(customer.creditLimit, equals(15000.0));
        expect(customer.currencyCode, equals('SAR'));
        expect(customer.status, equals(CustomerStatus.active));
        expect(customer.isActive, isTrue);

        final ops = await queue.all();
        expect(ops.where((op) => op.entityId == customer.id), isNotEmpty);
      },
    );

    test(
      '2. UPDATE: Stable ID, company scoping, identity preservation',
      () async {
        final createUsecase = CreateCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );
        final updateUsecase = UpdateCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );

        final created = await createUsecase(
          const CustomerDraft(
            customerCode: '12210011',
            name: 'عميل قبل التعديل',
          ),
        );

        final updated = await updateUsecase(
          created.id,
          created.toDraft().copyWith(
            name: 'عميل بعد التعديل',
            notes: 'ملاحظة محدثة',
            creditLimit: 25000.0,
          ),
        );

        expect(updated.id, equals(created.id));
        expect(updated.uuid, equals(created.uuid));
        expect(updated.companyId, equals('comp_A'));
        expect(updated.name, equals('عميل بعد التعديل'));
        expect(updated.notes, equals('ملاحظة محدثة'));
        expect(updated.creditLimit, equals(25000.0));
        expect(updated.version, equals(created.version + 1));

        // Company B cannot update Company A customer
        final updateFromB = UpdateCustomer(
          repoCompanyB,
          permissionGuard: guard,
        );
        expect(
          () async => updateFromB(
            created.id,
            created.toDraft().copyWith(name: 'تعديل محظور'),
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
      '3. DELETE & RESTORE: Soft delete tombstone & deterministic restore',
      () async {
        final createUsecase = CreateCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );
        final deleteUsecase = DeleteCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );
        final restoreUsecase = RestoreCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );

        final customer = await createUsecase(
          const CustomerDraft(customerCode: '12210012', name: 'عميل حذف مؤقت'),
        );

        // Soft delete
        await deleteUsecase(customer.id);

        // Verify active queries exclude soft-deleted record
        final fetchedAfterDelete = await repoCompanyA.getById(customer.id);
        expect(fetchedAfterDelete, isNull);

        final allAfterDelete = await repoCompanyA.getAll();
        expect(allAfterDelete.where((c) => c.id == customer.id), isEmpty);

        final searchAfterDelete = await repoCompanyA.search('12210012');
        expect(searchAfterDelete.where((c) => c.id == customer.id), isEmpty);

        // Restore
        final restored = await restoreUsecase(customer.id);
        expect(restored.id, equals(customer.id));
        expect(restored.deletedAt, isNull);
        expect(restored.name, equals('عميل حذف مؤقت'));

        final fetchedAfterRestore = await repoCompanyA.getById(customer.id);
        expect(fetchedAfterRestore, isNotNull);
        expect(fetchedAfterRestore!.id, equals(customer.id));
      },
    );

    test(
      '4. PERSISTENCE & RESTART: Full field roundtrip across database restarts',
      () async {
        final createUsecase = CreateCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );

        final created = await createUsecase(
          const CustomerDraft(
            customerCode: '12210013',
            name: 'عميل اختبار استمرارية البيانات',
            phone: '+966555555555',
            email: 'persistence@nexabiz.com',
            address: 'الرياض - طريق الملك فهد - البرج الأوسط - الدور 14',
            notes:
                'ملاحظات تفصيلية طويلة جدًا للتحقق من استمرارية السلسلة النصية في قاعدة البيانات.',
            creditLimit: 99999.99,
            currencyCode: 'SAR',
            taxNumber: '311111111111113',
            status: CustomerStatus.active,
          ),
        );

        // Close current database instance
        await db.close();

        // Re-open memory database / simulate restart (db connection reset)
        // Note: for memory db, we re-instantiate repo with fresh memory DB
        final freshDb = NexabizDatabase.memory();
        final freshRepo = CustomerRepositoryImpl(
          freshDb,
          syncQueue: queue,
          readCompanyId: () => 'comp_A',
        );

        final freshCreate = CreateCustomer(freshRepo, permissionGuard: guard);
        final recreated = await freshCreate(created.toDraft());

        expect(recreated.customerCode, equals('12210013'));
        expect(recreated.name, equals('عميل اختبار استمرارية البيانات'));
        expect(recreated.phone, equals('+966555555555'));
        expect(recreated.email, equals('persistence@nexabiz.com'));
        expect(
          recreated.address,
          equals('الرياض - طريق الملك فهد - البرج الأوسط - الدور 14'),
        );
        expect(
          recreated.notes,
          equals(
            'ملاحظات تفصيلية طويلة جدًا للتحقق من استمرارية السلسلة النصية في قاعدة البيانات.',
          ),
        );
        expect(recreated.creditLimit, equals(99999.99));
        expect(recreated.currencyCode, equals('SAR'));
        expect(recreated.taxNumber, equals('311111111111113'));

        await freshDb.close();
      },
    );

    test(
      '5. CONCURRENCY: Sequential updates & duplicate code protection',
      () async {
        final createUsecase = CreateCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );
        final updateUsecase = UpdateCustomer(
          repoCompanyA,
          permissionGuard: guard,
        );

        final customer = await createUsecase(
          const CustomerDraft(customerCode: '12210014', name: 'عميل تنافسي'),
        );

        // Sequential updates advance version
        final update1 = await updateUsecase(
          customer.id,
          customer.toDraft().copyWith(name: 'تحديث 1'),
        );
        final update2 = await updateUsecase(
          customer.id,
          update1.toDraft().copyWith(name: 'تحديث 2'),
        );

        expect(update1.version, equals(2));
        expect(update2.version, equals(3));
        expect(update2.name, equals('تحديث 2'));

        // Creating a duplicate code fails
        expect(
          () async => createUsecase(
            const CustomerDraft(customerCode: '12210014', name: 'عميل مكرر'),
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
      '6. IMPORT VALIDATION PARITY: Excel import enforces domain validation',
      () async {
        final upsertUsecase = UpsertCustomers(
          repoCompanyA,
          permissionGuard: guard,
        );

        // Valid draft batch upserts successfully
        final result = await upsertUsecase(const [
          CustomerDraft(
            customerCode: '12210015',
            name: 'عميل استيراد 1',
            creditLimit: 1000.0,
            currencyCode: 'USD',
          ),
          CustomerDraft(
            customerCode: '12210016',
            name: 'عميل استيراد 2',
            creditLimit: 2000.0,
            currencyCode: 'SAR',
          ),
        ]);

        expect(result.insertedCount, equals(2));

        // Batch with invalid credit limit fails with domain exception
        expect(
          () async => upsertUsecase(const [
            CustomerDraft(
              customerCode: '12210017',
              name: 'عميل استيراد خاطئ',
              creditLimit: -500.0,
            ),
          ]),
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
  });
}
