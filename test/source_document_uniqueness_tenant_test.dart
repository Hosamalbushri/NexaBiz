import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';

void main() {
  late InventoryDatabase invDb;
  late AccountingDatabase accDb;

  setUp(() {
    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
  });

  group('ROOT FIX 18 — Tenant-Scoped Source Document Uniqueness', () {
    test('1. Same receipt number for different companies MUST succeed (Multi-Tenant Isolation)', () async {
      // Insert REC-001 for Company A
      await invDb.into(invDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: '11111111-1111-4111-8111-111111111111',
          receiptNumber: 'REC-001',
          receiptDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-A'),
        ),
      );

      // Insert REC-001 for Company B -> MUST SUCCEED because unique index is (company_id, receipt_number)
      await invDb.into(invDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: '22222222-2222-4222-8222-222222222222',
          receiptNumber: 'REC-001',
          receiptDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-B'),
        ),
      );

      final rows = await invDb.select(invDb.stockReceipts).get();
      expect(rows.length, 2);
    });

    test('2. Same receipt number for SAME company MUST fail (Unique Constraint)', () async {
      await invDb.into(invDb.stockReceipts).insert(
        StockReceiptsCompanion.insert(
          uuid: '33333333-3333-4333-8333-333333333333',
          receiptNumber: 'REC-001',
          receiptDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-A'),
        ),
      );

      // Duplicate receipt number for Company A MUST fail
      expect(
        () async => await invDb.into(invDb.stockReceipts).insert(
          StockReceiptsCompanion.insert(
            uuid: '44444444-4444-4444-8444-444444444444',
            receiptNumber: 'REC-001',
            receiptDate: DateTime.now().millisecondsSinceEpoch,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            companyId: const Value('Company-A'),
          ),
        ),
        throwsA(isA<Object>()),
      );
    });

    test('3. Same issue number for different companies MUST succeed, same company MUST fail', () async {
      await invDb.into(invDb.stockIssues).insert(
        StockIssuesCompanion.insert(
          uuid: '55555555-5555-4555-8555-555555555555',
          issueNumber: 'ISS-100',
          issueDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-A'),
        ),
      );

      await invDb.into(invDb.stockIssues).insert(
        StockIssuesCompanion.insert(
          uuid: '66666666-6666-4666-8666-666666666666',
          issueNumber: 'ISS-100',
          issueDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-B'),
        ),
      );

      final rows = await invDb.select(invDb.stockIssues).get();
      expect(rows.length, 2);

      // Duplicate for Company-A
      expect(
        () async => await invDb.into(invDb.stockIssues).insert(
          StockIssuesCompanion.insert(
            uuid: '77777777-7777-4777-8777-777777777777',
            issueNumber: 'ISS-100',
            issueDate: DateTime.now().millisecondsSinceEpoch,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            companyId: const Value('Company-A'),
          ),
        ),
        throwsA(isA<Object>()),
      );
    });

    test('4. Same transfer number for different companies MUST succeed, same company MUST fail', () async {
      await invDb.into(invDb.stockTransfers).insert(
        StockTransfersCompanion.insert(
          uuid: '88888888-8888-4888-8888-888888888888',
          transferNumber: 'TR-500',
          fromWarehouseId: 'WH-1',
          toWarehouseId: 'WH-2',
          transferDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-A'),
        ),
      );

      await invDb.into(invDb.stockTransfers).insert(
        StockTransfersCompanion.insert(
          uuid: '99999999-9999-4999-8999-999999999999',
          transferNumber: 'TR-500',
          fromWarehouseId: 'WH-1',
          toWarehouseId: 'WH-2',
          transferDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-B'),
        ),
      );

      final rows = await invDb.select(invDb.stockTransfers).get();
      expect(rows.length, 2);

      // Duplicate for Company A
      expect(
        () async => await invDb.into(invDb.stockTransfers).insert(
          StockTransfersCompanion.insert(
            uuid: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            transferNumber: 'TR-500',
            fromWarehouseId: 'WH-1',
            toWarehouseId: 'WH-2',
            transferDate: DateTime.now().millisecondsSinceEpoch,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            companyId: const Value('Company-A'),
          ),
        ),
        throwsA(isA<Object>()),
      );
    });

    test('5. Same journal voucher number for different companies MUST succeed, same company MUST fail', () async {
      await accDb.into(accDb.journalEntries).insert(
        JournalEntriesCompanion.insert(
          uuid: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          voucherType: 'general',
          currencyCode: 'YER',
          voucherNumber: 'VOUCH-001',
          entryDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-A'),
        ),
      );

      await accDb.into(accDb.journalEntries).insert(
        JournalEntriesCompanion.insert(
          uuid: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          voucherType: 'general',
          currencyCode: 'YER',
          voucherNumber: 'VOUCH-001',
          entryDate: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          companyId: const Value('Company-B'),
        ),
      );

      final rows = await accDb.select(accDb.journalEntries).get();
      expect(rows.length, 2);

      // Duplicate for Company A
      expect(
        () async => await accDb.into(accDb.journalEntries).insert(
          JournalEntriesCompanion.insert(
            uuid: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
            voucherType: 'general',
            currencyCode: 'YER',
            voucherNumber: 'VOUCH-001',
            entryDate: DateTime.now().millisecondsSinceEpoch,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            companyId: const Value('Company-A'),
          ),
        ),
        throwsA(isA<Object>()),
      );
    });
  });
}
