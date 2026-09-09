import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/app/reports/product_stock_movement_report_data_adapter.dart';
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

  group('ProductStockMovementReportDataAdapter Tenant Isolation Tests', () {
    test(
      'Report for Company A does not contain stock movement data for Company B',
      () async {
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        // 1. Company A - Receipts, Issues, Transfers, Returns
        await db.into(db.stockReceipts).insert(
              StockReceiptsCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000001',
                receiptNumber: 'REC-A-101',
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
                itemCode: 'ITEM-SHARED',
                itemName: 'Shared Product Item',
                quantity: const Value(100),
                unitCost: const Value(10.0),
              ),
            );

        await db.into(db.stockIssues).insert(
              StockIssuesCompanion.insert(
                uuid: '10000000-0000-0000-0000-000000000003',
                issueNumber: 'ISS-A-101',
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
                itemCode: 'ITEM-SHARED',
                itemName: 'Shared Product Item',
                quantity: const Value(30),
                unitCost: const Value(10.0),
              ),
            );

        // 2. Company B - Receipts, Issues
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
                itemCode: 'ITEM-SHARED',
                itemName: 'Shared Product Item',
                quantity: const Value(500),
                unitCost: const Value(20.0),
              ),
            );

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
                itemCode: 'ITEM-SHARED',
                itemName: 'Shared Product Item',
                quantity: const Value(200),
                unitCost: const Value(20.0),
              ),
            );

        final adapter = ProductStockMovementReportDataAdapter(
          db: db,
          loadFunctionalCurrencyCode: () async => 'YER',
        );

        // Fetch report for Company A
        final filterA = const ReportQueryFilter(
          companyId: 'company-a',
          productUuid: 'ITEM-SHARED',
        );
        final payloadA = await adapter.loadFromFilter(
          filter: filterA,
          labels: labels,
        );

        final docNumbersA = payloadA.rows.map((r) => r.documentNumber).toSet();

        // Company A documents MUST exist
        expect(docNumbersA, contains('REC-A-101'));
        expect(docNumbersA, contains('ISS-A-101'));

        // Company B documents MUST NOT exist in Company A report
        expect(docNumbersA, isNot(contains('REC-B-999')));
        expect(docNumbersA, isNot(contains('ISS-B-999')));

        // Fetch report for Company B
        final filterB = const ReportQueryFilter(
          companyId: 'company-b',
          productUuid: 'ITEM-SHARED',
        );
        final payloadB = await adapter.loadFromFilter(
          filter: filterB,
          labels: labels,
        );

        final docNumbersB = payloadB.rows.map((r) => r.documentNumber).toSet();

        // Company B documents MUST exist
        expect(docNumbersB, contains('REC-B-999'));
        expect(docNumbersB, contains('ISS-B-999'));

        // Company A documents MUST NOT exist in Company B report
        expect(docNumbersB, isNot(contains('REC-A-101')));
        expect(docNumbersB, isNot(contains('ISS-A-101')));
      },
    );
  });
}
