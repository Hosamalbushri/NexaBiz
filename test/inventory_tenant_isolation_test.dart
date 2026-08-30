import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';

void main() {
  late InventoryDatabase db;
  late String activeCompanyId;

  setUp(() async {
    db = InventoryDatabase(NativeDatabase.memory());
    activeCompanyId = 'company_A';
  });

  tearDown(() async {
    await db.close();
  });

  group('NexaBiz Inventory Multi-Tenant Isolation Tests', () {
    test('Company B cannot consume cost layers owned by Company A', () async {
      activeCompanyId = 'company_A';
      final costLayerServiceA = CostLayerServiceImpl(
        db: db,
        readCompanyId: () => activeCompanyId,
      );

      // Company A creates an inbound cost layer of 100 units @ $50
      await costLayerServiceA.createLayer(
        CostLayer(
          id: 'layer_comp_a',
          itemCode: 'ITEM-100',
          warehouseId: 'WH-A',
          movementUuid: 'REC-001',
          movementType: 'stock_receipt',
          receivedDate: DateTime.now().toUtc(),
          receivedQty: 100,
          remainingQty: 100,
          unitCost: 50.0,
          totalCost: 5000.0,
          companyId: 'company_A',
        ),
      );

      // Switch context to Company B
      activeCompanyId = 'company_B';
      final costLayerServiceB = CostLayerServiceImpl(
        db: db,
        readCompanyId: () => activeCompanyId,
      );

      // Company B attempts to consume 10 units of ITEM-100
      final resultB = await costLayerServiceB.consumeLayers(
        itemCode: 'ITEM-100',
        quantity: 10,
        method: CostValuationMethod.fifo,
        issueLineUuid: 'issue_line_b',
        movementType: 'stock_issue',
        companyId: 'company_B',
      );

      // Expect shortage because Company A's layer is invisible to Company B
      expect(resultB.isShortage, true);
      expect(resultB.consumptions.isEmpty, true);
      expect(resultB.effectiveUnitCost, 0.0);
    });

    test('WarehouseRepository isolates warehouses between Company A and Company B', () async {
      activeCompanyId = 'company_A';
      final whRepoA = WarehouseRepositoryImpl(
        db,
        null,
        () => activeCompanyId,
      );

      final whA = await whRepoA.ensureDefaultWarehouse();
      expect(whA.code, 'WH-MAIN');

      // Switch to Company B
      activeCompanyId = 'company_B';
      final whRepoB = WarehouseRepositoryImpl(
        db,
        null,
        () => activeCompanyId,
      );

      final warehousesB = await whRepoB.getAllWarehouses();
      // Company B should not see Company A's warehouse
      expect(warehousesB.any((w) => w.id == whA.id), false);
    });

    test('PostingCoordinator blocks document posting across mismatched company contexts', () async {
      activeCompanyId = 'company_A';
      final costLayerServiceA = CostLayerServiceImpl(
        db: db,
        readCompanyId: () => activeCompanyId,
      );
      final validationServiceA = StockValidationServiceImpl(
        db,
        () => activeCompanyId,
      );
      final dependencyDetectorA = InventoryDependencyDetectorImpl(
        db,
        () => activeCompanyId,
      );
      final postingEngineA = PostingEngineImpl(
        db,
        costLayerServiceA,
        null,
        () => activeCompanyId,
      );
      final coordinatorA = PostingCoordinatorImpl(
        db: db,
        stockValidationService: validationServiceA,
        dependencyDetector: dependencyDetectorA,
        postingEngine: postingEngineA,
        readCompanyId: () => activeCompanyId,
      );

      // Create a document belonging to Company B
      final docRefCompanyB = InventoryDocumentRef(
        documentId: 'doc_b_001',
        documentNumber: 'REC-B-1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.draft,
        companyId: 'company_B',
      );

      // Attempt to post doc of Company B while authenticated under Company A
      final postResult = await coordinatorA.post(document: docRefCompanyB);

      // Must return invalid status due to company mismatch
      expect(postResult, isA<PostInvalidStatus>());
      final invalid = postResult as PostInvalidStatus;
      expect(invalid.reason, contains('مستند تابع لشركة أخرى'));
    });
  });
}
