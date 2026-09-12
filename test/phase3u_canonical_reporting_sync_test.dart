import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/reports/product_stock_movement_report_data_adapter.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/inventory/shared/data/sync/inventory_sync_handlers.dart';
import 'package:stock_count/modules/reports/providers/sales_period_report_provider.dart';
import 'package:stock_count/modules/reports/shared/domain/services/product_stock_movement_report_data_port.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_entity_handler.dart';

void main() {
  late NexabizDatabase db;
  const companyId = '00000000-0000-0000-0000-000000000001';
  const warehouseUuid = '11111111-1111-1111-1111-111111111111';
  const productUuid = '22222222-2222-2222-2222-222222222222';
  const itemCode = 'PRD-001';

  const labels = ProductStockMovementReportLabels(
    companyName: 'NexaBiz Test',
    reportTitle: 'Product Movement',
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
    voucherBookLabel: 'Book',
    docNumLabel: 'Doc Num',
    inwardHeaderLabel: 'Inward',
    outwardHeaderLabel: 'Outward',
    endingBalanceHeaderLabel: 'Ending Balance',
    totalIncomingCostLabel: 'Incoming Cost',
    totalOutgoingCostLabel: 'Outgoing Cost',
    periodLabel: 'Period',
    periodAll: 'All',
    allWarehousesLabel: 'All Warehouses',
    emptyMessage: 'No Movements',
  );

  setUp(() async {
    db = NexabizDatabase.connect(NativeDatabase.memory());

    // Seed canonical company
    await db.into(db.companies).insert(
          CompaniesCompanion.insert(
            uuid: companyId,
            code: 'COMP-001',
            name: 'Test NexaBiz ERP Company',
          ),
        );

    // Seed warehouse
    await db.into(db.warehouses).insert(
          WarehousesCompanion.insert(
            uuid: Value(warehouseUuid),
            code: 'WH-MAIN',
            name: 'Main Warehouse',
            companyId: companyId,
          ),
        );

    // Seed product
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            uuid: Value(productUuid),
            itemCode: itemCode,
            name: 'Test Canonical Product',
            price: const Value(100.0),
            companyId: companyId,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3U — Canonical Reporting Verification', () {
    test('ProductStockMovementReportDataAdapter queries canonical database successfully', () async {
      final now = DateTime.now();
      const receiptUuid = '33333333-3333-3333-3333-333333333333';

      // Insert stock receipt line into canonical database
      await db.into(db.stockReceipts).insert(
            StockReceiptsCompanion.insert(
              uuid: receiptUuid,
              receiptNumber: 'REC-001',
              currencyCode: 'SAR',
              receiptDate: now.millisecondsSinceEpoch,
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              warehouse: const Value(warehouseUuid),
              status: const Value('posted'),
              companyId: Value(companyId),
            ),
          );

      await db.into(db.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: '44444444-4444-4444-4444-444444444444',
              movementUuid: receiptUuid,
              movementType: 'stock_receipt',
              itemCode: itemCode,
              itemName: 'Test Canonical Product',
              quantity: const Value(50.0),
              unitCost: const Value(80.0),
              totalCost: const Value(4000.0),
            ),
          );

      final adapter = ProductStockMovementReportDataAdapter(
        db: db,
        loadFunctionalCurrencyCode: () async => 'SAR',
        readCompanyId: () => companyId,
      );

      final payload = await adapter.loadFromFilter(
        filter: ReportQueryFilter(
          companyId: companyId,
          productUuid: productUuid,
        ),
        labels: labels,
      );

      expect(payload.productCode, itemCode);
      expect(payload.productName, 'Test Canonical Product');
      expect(payload.rows.length, 1);
      expect(payload.rows.first.documentNumber, 'REC-001');
      expect(payload.rows.first.inTotalQty, 50.0);
    });

    test('SalesPeriodReportDataProvider queries canonical sales database successfully', () async {
      final now = DateTime.now();

      // Seed canonical sale invoice
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              uuid: '55555555-5555-5555-5555-555555555555',
              saleNumber: 'INV-2026-001',
              currencyCode: 'SAR',
              baseCurrencyCode: 'SAR',
              subtotal: 1000.0,
              itemDiscountTotal: 0.0,
              total: 1150.0,
              saleDate: Value(now.millisecondsSinceEpoch),
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              taxAmount: const Value(150.0),
              saleStatus: const Value('posted'),
              settlementType: const Value('cash'),
              companyId: Value(companyId),
            ),
          );

      final dataProvider = SalesPeriodReportDataProvider(
        salesDb: db,
        companyName: 'NexaBiz Test',
      );

      final execContext = ReportExecutionContext(
        companyId: companyId,
        postingScope: PostingScope.postedOnly,
      );

      final summary = await dataProvider.fetchSummary(execContext);
      expect(summary.totalCount, 1);
      expect(summary.aggregates['subtotal'], 1000.0);
      expect(summary.aggregates['taxAmount'], 150.0);
      expect(summary.aggregates['grandTotal'], 1150.0);

      final page = await dataProvider.fetchPage(execContext, pageSize: 10);
      expect(page.items.length, 1);
      expect(page.items.first.values['invoiceNumber'], 'INV-2026-001');
    });
  });

  group('Phase 3U — Canonical Sync Subsystem Verification', () {
    test('InventoryDocumentSyncHandler applies remote receipt directly into canonical database', () async {
      final now = DateTime.now();

      final handler = InventoryDocumentSyncHandler(
        entityType: 'stock_receipt',
        remoteProvider: () => throw UnimplementedError(),
        db: db,
        readCompanyId: () => companyId,
      );

      final remoteChange = SyncRemoteChange(
        entityId: '66666666-6666-6666-6666-666666666666',
        entityType: 'stock_receipt',
        version: 1,
        updatedAt: now,
        payload: {
          'receiptNumber': 'REC-SYNC-001',
          'warehouseId': warehouseUuid,
          'status': 'draft',
          'companyId': companyId,
          'receivedAt': now.toIso8601String(),
          'createdAt': now.toIso8601String(),
        },
      );

      await handler.applyRemoteChange(remoteChange);

      final receiptInDb = await (db.select(db.stockReceipts)
            ..where((tbl) => tbl.uuid.equals('66666666-6666-6666-6666-666666666666')))
          .getSingleOrNull();

      expect(receiptInDb, isNotNull);
      expect(receiptInDb!.receiptNumber, 'REC-SYNC-001');
      expect(receiptInDb.companyId, companyId);
    });
  });
}
