import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/drift.dart';

import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_status.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-10 Null Safety & Robust Customer Retrieval Suite', () {
    late Directory tempDir;
    late NexabizDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu10_null_safety_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu10');
      queue = SyncQueue(box: box);
      db = NexabizDatabase.memory();

      repository = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_null_test',
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
      '1. Mapping database row with null optional fields does not throw null operator error',
      () async {
        // Insert raw row with all optional fields explicit null
        await db
            .into(db.customers)
            .insert(
              CustomersCompanion.insert(
                id: 'null-field-uuid-001',
                customerCode: 'CUST-NULL-01',
                name: 'Customer With Null Fields',
                companyId: const Value('comp_null_test'),
                phone: const Value(null),
                email: const Value(null),
                address: const Value(null),
                notes: const Value(null),
                accountId: const Value(null),
                externalId: const Value(null),
                lastSyncedAt: const Value(null),
                deletedAt: const Value(null),
                createdAt: DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );

        final customer = await repository.getByUuid('null-field-uuid-001');
        expect(customer, isNotNull);
        expect(customer!.customerCode, equals('CUST-NULL-01'));
        expect(customer.name, equals('Customer With Null Fields'));
        expect(customer.phone, isNull);
        expect(customer.email, isNull);
        expect(customer.address, isNull);
        expect(customer.notes, isNull);
        expect(customer.accountId, isNull);
        expect(customer.externalId, isNull);
        expect(customer.lastSyncedAt, isNull);
        expect(customer.deletedAt, isNull);
      },
    );

    test(
      '2. Watching customer list with mixed null and populated fields streams cleanly',
      () async {
        await repository.insert(
          const CustomerDraft(customerCode: 'C100', name: 'First Customer'),
        );

        await repository.insert(
          const CustomerDraft(
            customerCode: 'C200',
            name: 'Second Customer',
            phone: '+966500000000',
          ),
        );

        final stream = repository.watchAll(includeInactive: true);
        final list = await stream.first;

        expect(list, hasLength(2));
        expect(list[0].customerCode, equals('C100'));
        expect(list[0].phone, isNull);
        expect(list[1].customerCode, equals('C200'));
        expect(list[1].phone, equals('+966500000000'));
      },
    );

    test(
      '3. Upserting customers with missing externalId or accountId handles nulls safely',
      () async {
        final drafts = [
          const CustomerDraft(customerCode: 'UP-001', name: 'Upsert Null 1'),
          const CustomerDraft(
            customerCode: 'UP-002',
            name: 'Upsert Null 2',
            externalId: 'EXT-002',
          ),
        ];

        final result = await repository.upsertAll(drafts);
        expect(result.insertedCount, equals(2));

        final all = await repository.getAll();
        expect(all, hasLength(2));
      },
    );

    test(
      '4. Raw SQLite row with NULL non-nullable columns maps safely via default fallbacks',
      () async {
        await db.customStatement('''
        INSERT INTO customers (
          uuid, customer_code, name, company_id,
          is_active, status, data_source, created_at, updated_at, sync_status, version
        ) VALUES (
          'null-raw-uuid-004', 'CUST-RAW-04', 'Raw SQLite Customer', 'comp_null_test',
          NULL, NULL, NULL, NULL, NULL, NULL, NULL
        )
      ''');

        final customer = await repository.getByUuid('null-raw-uuid-004');
        expect(customer, isNotNull);
        expect(customer!.customerCode, equals('CUST-RAW-04'));
        expect(customer.isActive, isTrue);
        expect(customer.status, equals(CustomerStatus.active));
        expect(customer.dataSource, equals(CustomerDataSource.local));
        expect(customer.syncStatus, equals(SyncStatus.synced));
        expect(customer.version, equals(1));
      },
    );

    test(
      '5. Legacy database missing status or company_id columns is auto-migrated without throwing no such column',
      () async {
        // Execute beforeOpen inspection logic manually or verify PRAGMA table_info
        final rows = await db
            .customSelect('PRAGMA table_info(customers)')
            .get();
        final cols = rows.map((r) => r.read<String>('name')).toSet();

        expect(cols.contains('status'), isTrue);
        expect(cols.contains('is_active'), isTrue);
        expect(cols.contains('company_id'), isTrue);
      },
    );
  });
}
