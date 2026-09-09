import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/app/reports/product_stock_movement_report_data_adapter.dart';
import 'package:stock_count/core/report_engine/data/providers/stock_movement_report_provider.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/reports/shared/domain/services/product_stock_movement_report_data_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase db;

  setUp(() async {
    db = InventoryDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Reports Multi-Company Isolation Tests', () {
    test(
      'StockMovementReportDataProvider filters out movements belonging to other companies',
      () async {
        // 1. Insert header for Company A
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                uuid: '11111111-1111-1111-1111-111111111111',
                receiptNumber: 'REC-001',
                currencyCode: 'YER',
                receiptDate: DateTime.now().millisecondsSinceEpoch,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
                companyId: const Value('company-a'),
              ),
            );

        // 2. Insert line for Company A movement
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                uuid: '22222222-2222-2222-2222-222222222222',
                movementUuid: '11111111-1111-1111-1111-111111111111',
                movementType: 'receipt',
                itemCode: 'ITEM-001',
                itemName: 'Item 1',
                quantity: const Value(10),
                postedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );

        // 3. Insert header for Company B
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                uuid: '33333333-3333-3333-3333-333333333333',
                receiptNumber: 'REC-002',
                currencyCode: 'YER',
                receiptDate: DateTime.now().millisecondsSinceEpoch,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
                companyId: const Value('company-b'),
              ),
            );

        // 4. Insert line for Company B movement
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                uuid: '44444444-4444-4444-4444-444444444444',
                movementUuid: '33333333-3333-3333-3333-333333333333',
                movementType: 'receipt',
                itemCode: 'ITEM-001',
                itemName: 'Item 1',
                quantity: const Value(20),
                postedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );

        final provider = StockMovementReportDataProvider(inventoryDb: db);

        // Query as Company A
        final contextCompanyA = ReportExecutionContext(
          companyId: 'company-a',
          userId: 'user-1',
        );
        final summaryA = await provider.fetchSummary(contextCompanyA);
        expect(summaryA.totalCount, equals(1));
        expect(summaryA.aggregates['totalQty'], equals(10.0));

        // Query as Company B
        final contextCompanyB = ReportExecutionContext(
          companyId: 'company-b',
          userId: 'user-1',
        );
        final summaryB = await provider.fetchSummary(contextCompanyB);
        expect(summaryB.totalCount, equals(1));
        expect(summaryB.aggregates['totalQty'], equals(20.0));
      },
    );

    test(
      'ProductStockMovementReportDataAdapter isolates stock movements (Receipts, Issues, Transfers, Returns) strictly by companyId',
      () async {
        const labels = ProductStockMovementReportLabels(
          companyName: 'Test Company',
          reportTitle: 'Stock Movement',
          warehouseLabel: 'Warehouse',
          productCodeLabel: 'Product Code',
          productNameLabel: 'Product Name',
          openingBalanceLabel: 'Opening Balance',
          mainCapacityLabel: 'Main Capacity',
          subCapacityLabel: 'Sub Capacity',
          cartonLabel: 'Carton',
          pieceLabel: 'Piece',
          finalQtyLabel: 'Final Qty',
          costLabel: 'Cost',
          docDateLabel: 'Doc Date',
          docTypeLabel: 'Doc Type',
          voucherBookLabel: 'Voucher Book',
          docNumLabel: 'Doc Num',
          inwardHeaderLabel: 'Inward',
          outwardHeaderLabel: 'Outward',
          endingBalanceHeaderLabel: 'Ending Balance',
          totalIncomingCostLabel: 'Total Incoming Cost',
          totalOutgoingCostLabel: 'Total Outgoing Cost',
          periodLabel: 'Period',
          periodAll: 'All Period',
          allWarehousesLabel: 'All Warehouses',
          emptyMessage: 'No Data',
        );

        final nowMs = DateTime.now().millisecondsSinceEpoch;

        // --- COMPANY A DATASET ---
        // 1. Company A Receipt
        await db.into(db.stockReceipts).insert(
              StockReceiptsCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000001',
                receiptNumber: 'REC-A-100',
                currencyCode: 'YER',
                receiptDate: nowMs,
                createdAt: nowMs,
                updatedAt: nowMs,
                companyId: const Value('company-a'),
              ),
            );
        await db.into(db.stockMovementLines).insert(
              StockMovementLinesCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000002',
                movementUuid: '10000000-0000-0000-0000-000000000001',
                movementType: 'receipt',
                itemCode: 'PROD-SHARED',
                itemName: 'Shared Product',
                quantity: const Value(100),
                unitCost: const Value(10.0),
              ),
            );

        // 2. Company A Issue
        await db.into(db.stockIssues).insert(
              StockIssuesCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000003',
                issueNumber: 'ISS-A-100',
                currencyCode: 'YER',
                issueDate: nowMs + 1000,
                createdAt: nowMs,
                updatedAt: nowMs,
                companyId: const Value('company-a'),
              ),
            );
        await db.into(db.stockMovementLines).insert(
              StockMovementLinesCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000004',
                movementUuid: '10000000-0000-0000-0000-000000000003',
                movementType: 'issue',
                itemCode: 'PROD-SHARED',
                itemName: 'Shared Product',
                quantity: const Value(30),
                unitCost: const Value(10.0),
              ),
            );

        // 3. Company A Transfer
        await db.into(db.stockTransfers).insert(
              StockTransfersCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000005',
                transferNumber: 'TR-A-100',
                fromWarehouseId: 'WH-1',
                toWarehouseId: 'WH-2',
                transferDate: nowMs + 2000,
                createdAt: nowMs,
                updatedAt: nowMs,
                companyId: const Value('company-a'),
              ),
            );
        await db.into(db.stockMovementLines).insert(
              StockMovementLinesCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000006',
                movementUuid: '10000000-0000-0000-0000-000000000005',
                movementType: 'transfer',
                itemCode: 'PROD-SHARED',
                itemName: 'Shared Product',
                quantity: const Value(15),
                unitCost: const Value(10.0),
              ),
            );

        // 4. Company A Return
        await db.into(db.stockReturns).insert(
              StockReturnsCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000007',
                returnNumber: 'RET-A-100',
                returnType: 'sales_return',
                returnDate: nowMs + 3000,
                createdAt: nowMs,
                updatedAt: nowMs,
                companyId: const Value('company-a'),
              ),
            );
        await db.into(db.stockMovementLines).insert(
              StockMovementLinesCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000008',
                movementUuid: '10000000-0000-0000-0000-000000000007',
                movementType: 'return',
                itemCode: 'PROD-SHARED',
                itemName: 'Shared Product',
                quantity: const Value(5),
                unitCost: const Value(10.0),
              ),
            );

        // --- COMPANY B DATASET (Identical product ID 'PROD-SHARED') ---
        // 1. Company B Receipt
        await db.into(db.stockReceipts).insert(
              StockReceiptsCompanion.insert(
                uuid: '20000000-0000-0000-0000-000000000001',
                receiptNumber: 'REC-B-999',
                currencyCode: 'YER',
                receiptDate: nowMs,
                createdAt: nowMs,
                updatedAt: nowMs,
                companyId: const Value('company-b'),
              ),
            );
        await db.into(db.stockMovementLines).insert(
              StockMovementLinesCompanion.insert(
                uuid: '20000000-0000-0000-0000-000000000002',
                movementUuid: '20000000-0000-0000-0000-000000000001',
                movementType: 'receipt',
                itemCode: 'PROD-SHARED',
                itemName: 'Shared Product',
                quantity: const Value(500),
                unitCost: const Value(20.0),
              ),
            );

        // 2. Company B Issue
        await db.into(db.stockIssues).insert(
              StockIssuesCompanion.insert(
                uuid: '20000000-0000-0000-0000-000000000003',
                issueNumber: 'ISS-B-999',
                currencyCode: 'YER',
                issueDate: nowMs + 1000,
                createdAt: nowMs,
                updatedAt: nowMs,
                companyId: const Value('company-b'),
              ),
            );
        await db.into(db.stockMovementLines).insert(
              StockMovementLinesCompanion.insert(
                uuid: '20000000-0000-0000-0000-000000000004',
                movementUuid: '20000000-0000-0000-0000-000000000003',
                movementType: 'issue',
                itemCode: 'PROD-SHARED',
                itemName: 'Shared Product',
                quantity: const Value(200),
                unitCost: const Value(20.0),
              ),
            );

        // Instantiate adapter
        final adapter = ProductStockMovementReportDataAdapter(
          db: db,
          loadFunctionalCurrencyCode: () async => 'YER',
        );

        // --- QUERY AS COMPANY A ---
        final filterA = const ReportQueryFilter(
          companyId: 'company-a',
          productUuid: 'PROD-SHARED',
        );
        final payloadA = await adapter.loadFromFilter(
          filter: filterA,
          labels: labels,
        );

        final docNumsA = payloadA.rows.map((r) => r.documentNumber).toSet();
        // Positive assertions: Company A documents MUST appear
        expect(docNumsA, contains('REC-A-100'));
        expect(docNumsA, contains('ISS-A-100'));
        expect(docNumsA, contains('TR-A-100'));
        expect(docNumsA, contains('RET-A-100'));

        // Negative assertions: Company B documents MUST NOT appear
        expect(docNumsA, isNot(contains('REC-B-999')));
        expect(docNumsA, isNot(contains('ISS-B-999')));

        // --- QUERY AS COMPANY B ---
        final filterB = const ReportQueryFilter(
          companyId: 'company-b',
          productUuid: 'PROD-SHARED',
        );
        final payloadB = await adapter.loadFromFilter(
          filter: filterB,
          labels: labels,
        );

        final docNumsB = payloadB.rows.map((r) => r.documentNumber).toSet();
        // Positive assertions: Company B documents MUST appear
        expect(docNumsB, contains('REC-B-999'));
        expect(docNumsB, contains('ISS-B-999'));

        // Negative assertions: Company A documents MUST NOT appear
        expect(docNumsB, isNot(contains('REC-A-100')));
        expect(docNumsB, isNot(contains('ISS-A-100')));
        expect(docNumsB, isNot(contains('TR-A-100')));
        expect(docNumsB, isNot(contains('RET-A-100')));
      },
    );
  });
}
