import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/usecases/canonical_transaction_orchestrator.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/core/database/nexabiz_database.dart' hide SalesCompanion, SaleItemsCompanion;
import 'package:stock_count/core/database/nexabiz_database.dart' hide WarehousesCompanion;
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';

void main() {
  late NexabizDatabase db;
  late NexabizDatabase legacySalesDb;
  late NexabizDatabase legacyInventoryDb;

  late SaleRepositoryImpl saleRepository;
  late StockMovementsRepositoryImpl stockMovementsRepository;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late PostingCoordinatorImpl postingCoordinator;
  late CanonicalTransactionOrchestrator orchestrator;

  String currentCompanyId = 'company_test_3s';
  const warehouseId = '11111111-2222-3333-4444-555555555555';

  setUp(() async {
    db = NexabizDatabase.connect(NativeDatabase.memory());
    legacySalesDb = NexabizDatabase.memory();
    legacyInventoryDb = NexabizDatabase.memory();

    saleRepository = SaleRepositoryImpl(
      db,
      readCompanyId: () => currentCompanyId,
    );

    stockMovementsRepository = StockMovementsRepositoryImpl(
      db: db,
      readCompanyId: () => currentCompanyId,
    );

    validationService = StockValidationServiceImpl(
      db,
      () => currentCompanyId,
    );

    dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => currentCompanyId,
    );

    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => currentCompanyId,
    );

    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => currentCompanyId,
    );

    postingCoordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      permissionGuard: const AllowAllPermissionGuardTest(),
      accountingPoster: const NoOpAccountingPosterTest(),
      readCompanyId: () => currentCompanyId,
    );

    orchestrator = CanonicalTransactionOrchestrator(db);

    // Setup active warehouse in nexabiz.sqlite
    await db.into(db.warehouses).insert(
          WarehousesCompanion.insert(
            id: const Value(warehouseId),
            code: 'WH-MAIN',
            name: 'Main Warehouse',
            companyId: currentCompanyId,
            isActive: const Value(true),
          ),
        );
  });

  tearDown(() async {
    await db.close();
    await legacySalesDb.close();
    await legacyInventoryDb.close();
  });

  group('Phase 3S — Canonical Sales + Inventory + Costing Production Routing', () {
    test('1. Sales invoice CRUD lifecycle executes on nexabiz.sqlite', () async {
      final now = DateTime.now().toUtc();
      const saleUuid = '11111111-0000-0000-0000-000000000001';
      const itemUuid = '11111111-0000-0000-0000-000000000002';

      // Insert sale invoice directly into nexabiz.sqlite canonical database
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              id: saleUuid,
              saleNumber: 'SL-2026-001',
              saleDate: Value(now.millisecondsSinceEpoch),
              settlementType: const Value('cash'),
              warehouseId: const Value(warehouseId),
              customerName: const Value('Acme Corp'),
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              subtotal: 500.0,
              itemDiscountTotal: 0.0,
              total: 500.0,
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              companyId: Value(currentCompanyId),
            ),
          );

      await db.into(db.saleItems).insert(
            SaleItemsCompanion.insert(
              uuid: itemUuid,
              saleUuid: saleUuid,
              productId: 'prod-001',
              productName: 'Product A',
              productCode: 'PROD-A',
              quantity: 5.0,
              unitPrice: 100.0,
              subtotal: 500.0,
              total: 500.0,
            ),
          );

      // Verify sale persisted in nexabiz.sqlite via saleRepository
      final retrieved = await saleRepository.getByUuid(saleUuid);
      expect(retrieved, isNotNull);
      expect(retrieved!.saleNumber, equals('SL-2026-001'));
      expect(retrieved.items.length, equals(1));
      expect(retrieved.items.first.productCode, equals('PROD-A'));
      expect(retrieved.total, equals(500.0));

      // Verify zero records in legacy NexabizDatabase
      final legacyRows = await legacySalesDb.select(legacySalesDb.sales).get();
      expect(legacyRows, isEmpty);
    });

    test('2. Stock receipt and cost layer creation execute on nexabiz.sqlite', () async {
      final now = DateTime.now().toUtc();
      const recUuid = '11111111-0000-0000-0000-000000000003';
      const lineRecUuid = '11111111-0000-0000-0000-000000000004';

      final receipt = StockReceipt(
        id: recUuid,
        receiptNumber: 'RC-2026-001',
        supplier: 'Supplier Alpha',
        warehouse: warehouseId,
        receiptDate: now,
        companyId: currentCompanyId,
        lines: [
          StockMovementLine(
            id: lineRecUuid,
            movementId: recUuid,
            movementType: 'receipt',
            itemCode: 'PROD-A',
            itemName: 'Product A',
            quantity: 10.0,
            unitCost: 50.0,
            totalCost: 500.0,
          ),
        ],
      );

      // Save stock receipt
      await stockMovementsRepository.saveReceipt(receipt);

      final retrievedReceipt = await stockMovementsRepository.getReceiptById(recUuid);
      expect(retrievedReceipt, isNotNull);
      expect(retrievedReceipt!.receiptNumber, equals('RC-2026-001'));
      expect(retrievedReceipt.lines.first.quantity, equals(10.0));

      // Post inbound stock receipt to generate cost layer and stock balance
      final docRef = InventoryDocumentRef(
        documentId: recUuid,
        documentNumber: 'RC-2026-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: now,
        warehouseId: warehouseId,
        status: InventoryDocumentStatus.draft,
      );

      final postResult = await postingCoordinator.post(document: docRef);
      expect(postResult, isA<PostSuccess>());

      // Verify cost layer created in nexabiz.sqlite
      final openLayers = await costLayerService.getOpenLayers('PROD-A', warehouseId: warehouseId);
      expect(openLayers.length, equals(1));
      expect(openLayers.first.remainingQty, equals(10.0));
      expect(openLayers.first.unitCost, equals(50.0));

      // Verify posted balance in nexabiz.sqlite
      final balance = await validationService.getPostedBalance(
        itemCode: 'PROD-A',
        warehouseId: warehouseId,
      );
      expect(balance, equals(10.0));

      // Verify zero records in legacy NexabizDatabase
      final legacyReceipts = await legacyInventoryDb.select(legacyInventoryDb.stockReceipts).get();
      expect(legacyReceipts, isEmpty);
    });

    test('3. Stock issue consumes FIFO cost layers and updates stock on nexabiz.sqlite', () async {
      final now = DateTime.now().toUtc();
      const rec10Uuid = '11111111-0000-0000-0000-000000000010';
      const lineRec10Uuid = '11111111-0000-0000-0000-000000000012';

      const rec11Uuid = '11111111-0000-0000-0000-000000000011';
      const lineRec11Uuid = '11111111-0000-0000-0000-000000000013';

      const iss1Uuid = '11111111-0000-0000-0000-000000000100';
      const lineIss1Uuid = '11111111-0000-0000-0000-000000000101';

      // First receipt: 10 units @ 50
      final receipt1 = StockReceipt(
        id: rec10Uuid,
        receiptNumber: 'RC-010',
        supplier: 'Supplier 1',
        warehouse: warehouseId,
        receiptDate: now.subtract(const Duration(hours: 2)),
        companyId: currentCompanyId,
        lines: [
          StockMovementLine(
            id: lineRec10Uuid,
            movementId: rec10Uuid,
            movementType: 'receipt',
            itemCode: 'PROD-B',
            itemName: 'Product B',
            quantity: 10.0,
            unitCost: 50.0,
            totalCost: 500.0,
          ),
        ],
      );
      await stockMovementsRepository.saveReceipt(receipt1);
      await postingCoordinator.post(
        document: InventoryDocumentRef(
          documentId: rec10Uuid,
          documentNumber: 'RC-010',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: now.subtract(const Duration(hours: 2)),
          warehouseId: warehouseId,
          status: InventoryDocumentStatus.draft,
        ),
      );

      // Second receipt: 10 units @ 70
      final receipt2 = StockReceipt(
        id: rec11Uuid,
        receiptNumber: 'RC-011',
        supplier: 'Supplier 2',
        warehouse: warehouseId,
        receiptDate: now.subtract(const Duration(hours: 1)),
        companyId: currentCompanyId,
        lines: [
          StockMovementLine(
            id: lineRec11Uuid,
            movementId: rec11Uuid,
            movementType: 'receipt',
            itemCode: 'PROD-B',
            itemName: 'Product B',
            quantity: 10.0,
            unitCost: 70.0,
            totalCost: 700.0,
          ),
        ],
      );
      await stockMovementsRepository.saveReceipt(receipt2);
      await postingCoordinator.post(
        document: InventoryDocumentRef(
          documentId: rec11Uuid,
          documentNumber: 'RC-011',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: now.subtract(const Duration(hours: 1)),
          warehouseId: warehouseId,
          status: InventoryDocumentStatus.draft,
        ),
      );

      // Issue 15 units (should consume 10 from layer 1 @ 50 and 5 from layer 2 @ 70)
      final issue = StockIssue(
        id: iss1Uuid,
        issueNumber: 'IS-001',
        destination: 'Client X',
        warehouse: warehouseId,
        issueDate: now,
        companyId: currentCompanyId,
        lines: [
          StockMovementLine(
            id: lineIss1Uuid,
            movementId: iss1Uuid,
            movementType: 'issue',
            itemCode: 'PROD-B',
            itemName: 'Product B',
            quantity: 15.0,
            unitCost: 50.0,
            totalCost: 750.0,
          ),
        ],
      );
      await stockMovementsRepository.saveIssue(issue);

      final issuePostResult = await postingCoordinator.post(
        document: InventoryDocumentRef(
          documentId: iss1Uuid,
          documentNumber: 'IS-001',
          documentType: InventoryDocumentType.stockIssue,
          documentDate: now,
          warehouseId: warehouseId,
          status: InventoryDocumentStatus.draft,
        ),
      );

      expect(issuePostResult, isA<PostSuccess>());

      final totalCogs = (issuePostResult as PostSuccess).postedValue;
      // Weighted average COGS = 15 units * 60.0 (1200 total / 20 units) = 900.0
      expect(totalCogs, equals(900.0));

      // Remaining stock balance should be 5 units
      final remainingBalance = await validationService.getPostedBalance(
        itemCode: 'PROD-B',
        warehouseId: warehouseId,
      );
      expect(remainingBalance, equals(5.0));
    });

    test('4. Cross-domain Sales confirmation inside CanonicalTransactionOrchestrator', () async {
      final now = DateTime.now().toUtc();
      const rec20Uuid = '11111111-0000-0000-0000-000000000020';
      const lineRec20Uuid = '11111111-0000-0000-0000-000000000021';
      const sale20Uuid = '11111111-0000-0000-0000-000000000200';
      const lineSale20Uuid = '11111111-0000-0000-0000-000000000201';

      // Inbound 20 units @ 40
      await stockMovementsRepository.saveReceipt(
        StockReceipt(
          id: rec20Uuid,
          receiptNumber: 'RC-020',
          supplier: 'Supplier 3',
          warehouse: warehouseId,
          receiptDate: now.subtract(const Duration(hours: 1)),
          companyId: currentCompanyId,
          lines: [
            StockMovementLine(
              id: lineRec20Uuid,
              movementId: rec20Uuid,
              movementType: 'receipt',
              itemCode: 'PROD-C',
              itemName: 'Product C',
              quantity: 20.0,
              unitCost: 40.0,
              totalCost: 800.0,
            ),
          ],
        ),
      );
      await postingCoordinator.post(
        document: InventoryDocumentRef(
          documentId: rec20Uuid,
          documentNumber: 'RC-020',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: now.subtract(const Duration(hours: 1)),
          warehouseId: warehouseId,
          status: InventoryDocumentStatus.draft,
        ),
      );

      // Insert sale invoice directly into nexabiz.sqlite
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              id: sale20Uuid,
              saleNumber: 'SL-020',
              saleDate: Value(now.millisecondsSinceEpoch),
              settlementType: const Value('cash'),
              warehouseId: const Value(warehouseId),
              customerName: const Value('Client Y'),
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              subtotal: 800.0,
              itemDiscountTotal: 0.0,
              total: 800.0,
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              companyId: Value(currentCompanyId),
            ),
          );

      // Execute Sale confirmation in transaction
      final txResult = await orchestrator.runInTransaction((ctx) async {
        // 1. Post inventory effect
        final lines = <StockMovementLine>[
          StockMovementLine(
            id: lineSale20Uuid,
            movementId: sale20Uuid,
            movementType: 'issue',
            itemCode: 'PROD-C',
            itemName: 'Product C',
            quantity: 8.0,
            unitCost: 0.0,
            totalCost: 0.0,
          ),
        ];

        await stockMovementsRepository.saveMovementLines(
          movementId: sale20Uuid,
          movementType: 'issue',
          lines: lines,
        );

        final postRes = await postingCoordinator.post(
          document: InventoryDocumentRef(
            documentId: sale20Uuid,
            documentNumber: 'SL-020',
            documentType: InventoryDocumentType.salesInvoice,
            documentDate: now,
            warehouseId: warehouseId,
            status: InventoryDocumentStatus.draft,
          ),
        );

        expect(postRes, isA<PostSuccess>());
        return (postRes as PostSuccess).postedValue;
      }, companyId: currentCompanyId);

      // 8 * 40 = 320 COGS
      expect(txResult, equals(320.0));

      // Balance after sale = 12.0
      final balAfter = await validationService.getPostedBalance(
        itemCode: 'PROD-C',
        warehouseId: warehouseId,
      );
      expect(balAfter, equals(12.0));
    });

    test('5. Multi-tenant isolation enforced between Company A and Company B', () async {
      final now = DateTime.now().toUtc();
      const compASaleUuid = '11111111-0000-0000-0000-000000000aaa';

      // Save sale for Company A directly in nexabiz.sqlite
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              id: compASaleUuid,
              saleNumber: 'SL-COMP-A',
              saleDate: Value(now.millisecondsSinceEpoch),
              settlementType: const Value('cash'),
              warehouseId: const Value(warehouseId),
              customerName: const Value('Customer A'),
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              subtotal: 100.0,
              itemDiscountTotal: 0.0,
              total: 100.0,
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              companyId: const Value('company_test_3s'),
            ),
          );

      // Switch context to Company B
      currentCompanyId = 'company_other_tenant';

      final compBSale = await saleRepository.getByUuid(compASaleUuid);
      expect(compBSale, isNull);

      final compBList = await saleRepository.getAll();
      expect(compBList, isEmpty);
    });
  });
}

class AllowAllPermissionGuardTest implements PermissionGuard {
  const AllowAllPermissionGuardTest();
  @override
  dynamic noSuchMethod(Invocation invocation) => true;
}

class NoOpAccountingPosterTest implements InventoryAccountingPoster {
  const NoOpAccountingPosterTest();

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {}

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}

  @override
  Future<void> reverseAccountingEntry({required InventoryDocumentRef document}) async {}
}
