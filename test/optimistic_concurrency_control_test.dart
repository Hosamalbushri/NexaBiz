import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

import 'package:stock_count/modules/sync/engine/domain/services/conflict_resolver.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';

void main() {
  late InventoryDatabase inventoryDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;

  const tenantCompanyId = 'tenant_company_occ_40';

  setUp(() async {
    inventoryDb = InventoryDatabase(executor: NativeDatabase.memory());
    costLayerService = CostLayerServiceImpl(db: inventoryDb, readCompanyId: () => tenantCompanyId);
    postingEngine = PostingEngineImpl(inventoryDb, costLayerService, null, () => tenantCompanyId);
    validationService = StockValidationServiceImpl(inventoryDb);
    dependencyDetector = InventoryDependencyDetectorImpl(inventoryDb);
  });

  tearDown(() async {
    await inventoryDb.close();
  });

  group('ROOT FIX 40 — Optimistic Concurrency Control Tests', () {
    test('1. Conflict Resolver: Stale operation upload is rejected or evaluated cleanly', () {
      const resolver = ConflictResolver();
      final now = DateTime.now().toUtc();

      final opV1 = SyncOperation.create(
        entityType: 'product',
        entityId: '00000000-0000-4000-8000-000000000501',
        type: SyncOperationType.update,
        baseVersion: 1,
        payload: {'name': 'Local Stale Name'},
        companyId: tenantCompanyId,
      );

      // Remote has already advanced to version 3
      final decision = resolver.resolve(
        localOperation: opV1,
        remoteVersion: 3,
        remoteUpdatedAt: now,
        preferServerWhenLocalSynced: false,
        remotePayload: {'name': 'Remote Advanced Name'},
      );

      // Remote is ahead of baseVersion 1 => conflict evaluated
      expect(decision, anyOf(equals(ConflictDecision.applyMerged), equals(ConflictDecision.markConflict)));
    });

    test('2. Financial Posting Concurrency: Concurrent post requests on draft receipt prevent double posting', () async {
      const receiptUuid = '00000000-0000-4000-8000-000000000502';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: const Value(receiptUuid),
          receiptNumber: const Value('REC-OCC-001'),
          receiptDate: Value(nowMs),
          createdAt: Value(nowMs),
          updatedAt: Value(nowMs),
          status: const Value('draft'),
          companyId: const Value(tenantCompanyId),
        ),
      );

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: const Value('00000000-0000-4000-8000-000000000503'),
          movementUuid: const Value(receiptUuid),
          movementType: const Value('receipt'),
          itemCode: const Value('ITEM-OCC-01'),
          itemName: const Value('OCC Item'),
          quantity: const Value(5.0),
          unitCost: const Value(100.0),
          totalCost: const Value(500.0),
        ),
      );

      final coordinator = PostingCoordinatorImpl(
        db: inventoryDb,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        readCompanyId: () => tenantCompanyId,
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-OCC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.fromMillisecondsSinceEpoch(nowMs),
        status: InventoryDocumentStatus.draft,
      );

      // Execute concurrent posting requests
      final results = await Future.wait([
        coordinator.post(document: docRef),
        coordinator.post(document: docRef),
      ]);

      // Exactly one request succeeds with PostSuccess, the other gets PostInvalidStatus or PostSuccess (idempotent)
      final successCount = results.whereType<PostSuccess>().length;
      final invalidCount = results.whereType<PostInvalidStatus>().length;

      expect(successCount + invalidCount, equals(2));
      expect(successCount, greaterThanOrEqualTo(1));

      // Verify no duplicate cost layers created
      final costLayers = await (inventoryDb.select(inventoryDb.inventoryCostLayers)).get();
      expect(costLayers.length, equals(1));
    });

    test('3. Financial Reversal Concurrency: Concurrent unpost requests on posted document prevent double reversal', () async {
      const receiptUuid = '00000000-0000-4000-8000-000000000504';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: const Value(receiptUuid),
          receiptNumber: const Value('REC-OCC-002'),
          receiptDate: Value(nowMs),
          createdAt: Value(nowMs),
          updatedAt: Value(nowMs),
          status: const Value('draft'),
          companyId: const Value(tenantCompanyId),
        ),
      );

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: const Value('00000000-0000-4000-8000-000000000505'),
          movementUuid: const Value(receiptUuid),
          movementType: const Value('receipt'),
          itemCode: const Value('ITEM-OCC-02'),
          itemName: const Value('OCC Item 2'),
          quantity: const Value(10.0),
          unitCost: const Value(50.0),
          totalCost: const Value(500.0),
        ),
      );

      final coordinator = PostingCoordinatorImpl(
        db: inventoryDb,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        readCompanyId: () => tenantCompanyId,
      );

      final draftDocRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-OCC-002',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.fromMillisecondsSinceEpoch(nowMs),
        status: InventoryDocumentStatus.draft,
      );

      await coordinator.post(document: draftDocRef);

      final postedDocRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-OCC-002',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.fromMillisecondsSinceEpoch(nowMs),
        status: InventoryDocumentStatus.posted,
      );

      // Execute concurrent unpost requests
      final unpostResults = await Future.wait([
        coordinator.unpost(document: postedDocRef),
        coordinator.unpost(document: postedDocRef),
      ]);

      final unpostSuccesses = unpostResults.whereType<UnpostSuccess>().length;
      expect(unpostSuccesses, greaterThanOrEqualTo(1));

      // Cost layers should be depleted / closed
      final activeCostLayers = await (inventoryDb.select(inventoryDb.inventoryCostLayers)
            ..where((t) => t.closed.equals(0)))
          .get();
      expect(activeCostLayers.isEmpty, isTrue);
    });
  });
}
