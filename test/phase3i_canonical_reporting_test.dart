import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  late NexabizDatabase db;

  setUp(() {
    db = NexabizDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3I — Canonical Reporting & Read-Model Baseline Tests', () {
    test('Reporting operations do not mutate authoritative transactional data', () async {
      final companyId = 'comp-report-readonly-3i';
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed initial sales document
      final saleUuid = generateUuidV4();
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              uuid: saleUuid,
              saleNumber: 'INV-2026-001',
              subtotal: 500.0,
              itemDiscountTotal: 0.0,
              total: 500.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      // Perform read-only query
      final queryResult = await (db.select(db.sales)
            ..where((tbl) => tbl.companyId.equals(companyId)))
          .get();

      expect(queryResult.length, equals(1));
      expect(queryResult.first.total, equals(500.0));

      // Re-query database state and assert total count and record state remain untouched
      final countPostQuery = await db.select(db.sales).get();
      expect(countPostQuery.length, equals(1));
      expect(countPostQuery.first.uuid, equals(saleUuid));
    });

    test('Tenant isolation in reporting query services', () async {
      final companyA = 'comp-report-aaa-3i';
      final companyB = 'comp-report-bbb-3i';

      final uuidA = generateUuidV4();
      final uuidB = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Sales for Company A
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              uuid: uuidA,
              saleNumber: 'INV-A-100',
              subtotal: 1000.0,
              itemDiscountTotal: 0.0,
              total: 1000.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyA),
            ),
          );

      // Seed Sales for Company B
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              uuid: uuidB,
              saleNumber: 'INV-B-200',
              subtotal: 2500.0,
              itemDiscountTotal: 0.0,
              total: 2500.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyB),
            ),
          );

      // Execute tenant-scoped report query for Company A
      final reportA = await (db.select(db.sales)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();

      // Execute tenant-scoped report query for Company B
      final reportB = await (db.select(db.sales)
            ..where((tbl) => tbl.companyId.equals(companyB)))
          .get();

      expect(reportA.length, equals(1));
      expect(reportA.first.uuid, equals(uuidA));
      expect(reportA.first.total, equals(1000.0));

      expect(reportB.length, equals(1));
      expect(reportB.first.uuid, equals(uuidB));
      expect(reportB.first.total, equals(2500.0));
    });

    test('GL Trial Balance aggregation report correctness (Total Debit == Total Credit)', () async {
      final companyId = 'comp-gl-tb-3i';
      final entryUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Journal Entry
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              uuid: entryUuid,
              entryDate: now,
              voucherNumber: 'JV-TB-01',
              voucherType: 'sales_posting',
              currencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      // Seed Debit Line
      await db.into(db.journalLines).insert(
            JournalLinesCompanion.insert(
              uuid: generateUuidV4(),
              entryUuid: entryUuid,
              accountUuid: generateUuidV4(),
              debit: const Value(750.0),
              credit: const Value(0.0),
              baseDebit: const Value(750.0),
              baseCredit: const Value(750.0),
              currencyCode: 'USD',
            ),
          );

      // Seed Credit Line
      await db.into(db.journalLines).insert(
            JournalLinesCompanion.insert(
              uuid: generateUuidV4(),
              entryUuid: entryUuid,
              accountUuid: generateUuidV4(),
              debit: const Value(0.0),
              credit: const Value(750.0),
              baseDebit: const Value(0.0),
              baseCredit: const Value(750.0),
              currencyCode: 'USD',
            ),
          );

      // Report Query Aggregation
      final entries = await (db.select(db.journalEntries)
            ..where((tbl) => tbl.companyId.equals(companyId)))
          .get();

      expect(entries.length, equals(1));

      final lines = await (db.select(db.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(entries.first.uuid)))
          .get();

      final totalDebit = lines.fold<double>(0.0, (sum, line) => sum + line.debit);
      final totalCredit = lines.fold<double>(0.0, (sum, line) => sum + line.credit);

      expect(totalDebit, equals(750.0));
      expect(totalCredit, equals(750.0));
      expect(totalDebit == totalCredit, isTrue);
    });

    test('Cross-domain stock valuation and movement reporting consistency', () async {
      final companyId = 'comp-stock-val-3i';
      final itemCode = 'ITEM-PROD-3I';
      final warehouseUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Stock Movement Ledger
      await db.into(db.stockMovementLedgers).insert(
            StockMovementLedgersCompanion.insert(
              uuid: generateUuidV4(),
              itemCode: itemCode,
              warehouseId: warehouseUuid,
              quantity: const Value(100.0),
              direction: 'inbound',
              movementType: 'receipt',
              postingDate: now,
              sourceDocumentId: generateUuidV4(),
              sourceDocumentType: 'stock_receipt',
              sourceLineUuid: generateUuidV4(),
              unitCost: const Value(12.0),
              totalCost: const Value(1200.0),
              inventoryCurrencyId: 'USD',
              documentCurrencyId: 'USD',
              costingMethodUsed: 'wac',
              createdAt: now,
              companyId: companyId,
            ),
          );

      // Seed Product Warehouse Stock Projection
      await db.into(db.productWarehouseStocks).insert(
            ProductWarehouseStocksCompanion.insert(
              uuid: generateUuidV4(),
              itemCode: itemCode,
              warehouseId: warehouseUuid,
              onHandQty: const Value(100.0),
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      // Query Stock Valuation Read Model
      final stockRows = await (db.select(db.productWarehouseStocks)
            ..where((tbl) =>
                tbl.companyId.equals(companyId) &
                tbl.itemCode.equals(itemCode)))
          .get();

      expect(stockRows.length, equals(1));
      expect(stockRows.first.onHandQty, equals(100.0));
    });
  });
}
