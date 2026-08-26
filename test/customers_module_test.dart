import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/customers/data/database/customers_database.dart';
import 'package:stock_count/modules/customers/data/datasources/customer_excel_import_datasource.dart';
import 'package:stock_count/modules/customers/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/domain/entities/customer_data_source.dart';
import 'package:stock_count/modules/customers/domain/models/customer_exception.dart';
import 'package:stock_count/modules/customers/domain/services/customer_code_generator.dart';
import 'package:stock_count/modules/customers/domain/services/customer_validator.dart';

Uint8List _encodeSheet(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  for (final row in rows) {
    sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
  }
  return Uint8List.fromList(excel.encode()!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  late CustomersDatabase db;
  late CustomerRepositoryImpl repository;
  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue syncQueue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('customers_mod_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    syncQueue = SyncQueue(box: syncBox);
    db = CustomersDatabase.memory();
    repository = CustomerRepositoryImpl(db, syncQueue: syncQueue);
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CustomerValidator', () {
    const validator = CustomerValidator();

    test('rejects empty name and code', () {
      expect(
        () => validator.validate(
          const CustomerDraft(customerCode: '', name: 'A'),
        ),
        throwsA(
          isA<CustomerException>().having(
            (e) => e.code,
            'code',
            CustomerException.invalidCustomerCode,
          ),
        ),
      );
      expect(
        () => validator.validate(
          const CustomerDraft(customerCode: 'CUS-0001', name: ' '),
        ),
        throwsA(
          isA<CustomerException>().having(
            (e) => e.code,
            'code',
            CustomerException.invalidName,
          ),
        ),
      );
    });

    test('requires external id for external source', () {
      expect(
        () => validator.validate(
          const CustomerDraft(
            customerCode: 'CUS-0001',
            name: 'Ahmed',
            dataSource: CustomerDataSource.external,
          ),
        ),
        throwsA(
          isA<CustomerException>().having(
            (e) => e.code,
            'code',
            CustomerException.externalIdRequired,
          ),
        ),
      );
    });
  });

  group('CustomerCodeGenerator', () {
    test('generates sequential codes from parent CoA account code', () async {
      final generator = CustomerCodeGenerator(repository);
      final first = await generator.generate(parentAccountCode: '1221');
      expect(first, '12210001');

      await repository.insert(CustomerDraft(customerCode: first, name: 'One'));
      final second = await generator.generate(parentAccountCode: '1221');
      expect(second, '12210002');

      await repository.insert(
        const CustomerDraft(customerCode: '12210010', name: 'Ten'),
      );
      final next = await generator.generate(parentAccountCode: '1221');
      expect(next, '12210011');
    });
  });

  group('CustomerRepositoryImpl', () {
    test(
      'creates local customer with pending sync and optional account link',
      () async {
        final created = await repository.insert(
          const CustomerDraft(
            customerCode: 'CUS-0001',
            name: 'Ahmed Ali',
            phone: '0500000000',
            accountId: 'account-uuid-example-0001-000000000001',
          ),
        );

        expect(created.customerCode, 'CUS-0001');
        expect(created.name, 'Ahmed Ali');
        expect(created.dataSource, CustomerDataSource.local);
        expect(created.externalId, isNull);
        expect(created.accountId, 'account-uuid-example-0001-000000000001');
        expect(created.syncStatus, SyncStatus.pending);
        expect(
          await syncQueue.countByStatus(SyncStatus.pending),
          greaterThan(0),
        );
      },
    );

    test('rejects duplicate customer codes', () async {
      await repository.insert(
        const CustomerDraft(customerCode: 'CUS-0001', name: 'A'),
      );
      expect(
        () => repository.insert(
          const CustomerDraft(customerCode: 'cus-0001', name: 'B'),
        ),
        throwsA(
          isA<CustomerException>().having(
            (e) => e.code,
            'code',
            CustomerException.duplicateCustomerCode,
          ),
        ),
      );
    });

    test('upserts external customer by external id', () async {
      final first = await repository.upsertFromExternal(
        const CustomerDraft(
          customerCode: 'EXT-9',
          name: 'ERP Customer',
          externalId: 'erp-42',
          dataSource: CustomerDataSource.external,
        ),
      );
      expect(first.dataSource, CustomerDataSource.external);
      expect(first.externalId, 'erp-42');

      final second = await repository.upsertFromExternal(
        const CustomerDraft(
          customerCode: 'EXT-9',
          name: 'ERP Customer Updated',
          externalId: 'erp-42',
          dataSource: CustomerDataSource.external,
        ),
      );
      expect(second.id, first.id);
      expect(second.name, 'ERP Customer Updated');
      final all = await repository.getAll(includeInactive: true);
      expect(all, hasLength(1));
    });

    test('soft delete hides customer from getById', () async {
      final created = await repository.insert(
        const CustomerDraft(customerCode: 'CUS-0003', name: 'Temp'),
      );
      await repository.softDelete(created.id);
      expect(await repository.getById(created.id), isNull);
    });

    test('search matches name and code', () async {
      await repository.insert(
        const CustomerDraft(customerCode: 'CUS-0100', name: 'Sara'),
      );
      await repository.insert(
        const CustomerDraft(customerCode: 'CUS-0200', name: 'Omar'),
      );
      final byName = await repository.search('sar');
      expect(byName, hasLength(1));
      expect(byName.first.name, 'Sara');
      final byCode = await repository.search('0200');
      expect(byCode.single.customerCode, 'CUS-0200');
    });

    test('search limit is applied in SQL and ranks exact code first', () async {
      await repository.insert(
        const CustomerDraft(customerCode: 'AHMED', name: 'Walk-in'),
      );
      await repository.insert(
        const CustomerDraft(customerCode: 'CUS-A1', name: 'Ahmed Ali'),
      );
      await repository.insert(
        const CustomerDraft(customerCode: 'CUS-A2', name: 'Ahmed Saleh'),
      );
      await repository.insert(
        const CustomerDraft(customerCode: 'CUS-A3', name: 'Ahmed Omar'),
      );

      final limited = await repository.search('ahmed', limit: 2);
      expect(limited, hasLength(2));
      expect(limited.first.customerCode, 'AHMED');
    });

    test('empty search with limit returns capped browse list', () async {
      for (var i = 0; i < 5; i++) {
        await repository.insert(
          CustomerDraft(customerCode: 'CUS-B$i', name: 'Buyer $i'),
        );
      }
      final limited = await repository.search('', limit: 3);
      expect(limited, hasLength(3));
    });

    test('upsertAll inserts then updates by customer code', () async {
      final first = await repository.upsertAll([
        const CustomerDraft(
          customerCode: '12210001',
          name: 'Ahmed',
          phone: '777',
          accountId: 'acc-1',
        ),
      ]);
      expect(first.insertedCount, 1);
      expect(first.updatedCount, 0);

      final second = await repository.upsertAll([
        const CustomerDraft(
          customerCode: '12210001',
          name: 'Ahmed Updated',
          phone: '888',
        ),
      ]);
      expect(second.insertedCount, 0);
      expect(second.updatedCount, 1);

      final row = await repository.getByCustomerCode('12210001');
      expect(row?.name, 'Ahmed Updated');
      expect(row?.phone, '888');
      expect(row?.accountId, 'acc-1');
    });
  });

  group('CustomerExcelImportDatasource', () {
    const datasource = CustomerExcelImportDatasource();

    test('parses required and optional columns', () {
      final bytes = _encodeSheet([
        [
          'Customer Code',
          'Name',
          'Phone',
          'Email',
          'Address',
          'Notes',
          'External ID',
        ],
        [
          '12210001',
          'Ahmed Ali',
          '777123456',
          'a@ex.com',
          'Sanaa',
          'VIP',
          'erp-1',
        ],
        ['', 'Ignored', '', '', '', '', ''],
      ]);

      final result = datasource.importBytes(bytes);
      expect(result.importedCount, 1);
      expect(result.ignoredCount, 1);
      expect(result.drafts.single.customerCode, '12210001');
      expect(result.drafts.single.name, 'Ahmed Ali');
      expect(result.drafts.single.phone, '777123456');
      expect(result.drafts.single.email, 'a@ex.com');
      expect(result.drafts.single.externalId, 'erp-1');
      expect(result.drafts.single.dataSource, CustomerDataSource.external);
    });

    test('dedupes duplicate codes keeping last row', () {
      final bytes = _encodeSheet([
        ['Code', 'Name'],
        ['12210001', 'First'],
        ['12210001', 'Second'],
      ]);

      final result = datasource.importBytes(bytes);
      expect(result.importedCount, 1);
      expect(result.duplicateCount, 1);
      expect(result.drafts.single.name, 'Second');
    });

    test('normalizes numeric Excel codes without trailing .0', () {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        TextCellValue('Code'),
        TextCellValue('Name'),
      ]);
      sheet.appendRow([
        DoubleCellValue(12210001),
        TextCellValue('Numeric Code'),
      ]);
      final bytes = Uint8List.fromList(excel.encode()!);

      final result = datasource.importBytes(bytes);
      expect(result.drafts.single.customerCode, '12210001');
    });
  });
}
