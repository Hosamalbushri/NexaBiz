import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/app/reports/product_stock_movement_report_data_adapter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/report_engine/data/providers/stock_movement_report_provider.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
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
      'ProductStockMovementReportDataAdapter isolates stock movements by tenant',
      () async {
        // 1. Insert header for Company A
        await db
            .into(db.stockReceipts)
            .insert(
              StockReceiptsCompanion.insert(
                uuid: '55555555-5555-5555-5555-555555555555',
                receiptNumber: 'REC-100',
                receiptDate: DateTime.now().millisecondsSinceEpoch,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
                companyId: const Value('company-a'),
              ),
            );

        // 2. Insert line for Company A
        await db
            .into(db.stockMovementLines)
            .insert(
              StockMovementLinesCompanion.insert(
                uuid: '66666666-6666-6666-6666-666666666666',
                movementUuid: '55555555-5555-5555-5555-555555555555',
                movementType: 'receipt',
                itemCode: 'PROD-A',
                itemName: 'Product A',
                quantity: const Value(50),
                postedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );

        final adapterCompanyA = ProductStockMovementReportDataAdapter(
          db: db,
          loadCompanyProfile: () async =>
              const CompanyProfile(name: 'Company A'),
        );

        final labels = const ProductStockMovementReportLabels(
          companyName: 'Company A',
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

        final payload = await adapterCompanyA.load(
          productId: 'PROD-A',
          labels: labels,
        );

        expect(payload.rows, hasLength(1));
        expect(payload.rows.first.documentNumber, equals('REC-100'));
        expect(payload.rows.first.inTotalQty, equals(50.0));
      },
    );
  });
}
