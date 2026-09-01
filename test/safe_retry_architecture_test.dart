import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_error_classifier.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

void main() {
  late InventoryDatabase inventoryDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;

  const tenantCompanyId = 'tenant_company_retry_38';

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

  group('ROOT FIX 38 — Safe Retry Architecture Tests', () {
    test('1. Retry Classification: Network failure is idempotentRetry and retryable', () {
      const netFailure = NetworkFailure('Connection reset by peer');
      final classification = SyncErrorClassifier.classify(netFailure);

      expect(classification.isRetryable, isTrue);
      expect(classification.retryCategory, equals(RetryCategory.idempotentRetry));
      expect(classification.quarantine, isFalse);
    });

    test('2. Non-retryable Classification: Validation failure and tenant mismatch quarantine immediately', () {
      const valFailure = ValidationFailure('Invalid line item quantity');
      final valClassification = SyncErrorClassifier.classify(valFailure);

      expect(valClassification.isRetryable, isFalse);
      expect(valClassification.retryCategory, equals(RetryCategory.nonRetryable));
      expect(valClassification.quarantine, isTrue);

      const authFailure = AuthorizationFailure.withDetails(
        message: 'Tenant mismatch: company_a vs company_b',
        code: 'tenant_mismatch',
      );
      final tenantClassification = SyncErrorClassifier.classify(authFailure);

      expect(tenantClassification.isRetryable, isFalse);
      expect(tenantClassification.retryCategory, equals(RetryCategory.nonRetryable));
      expect(tenantClassification.quarantine, isTrue);
    });

    test('3. Reconciliation Required: Sync conflicts require reconciliation rather than blind retry', () {
      const conflictFailure = SyncConflictFailure.forEntity(
        message: 'Row version mismatch',
        serverVersion: 3,
      );
      final classification = SyncErrorClassifier.classify(conflictFailure);

      expect(classification.isRetryable, isFalse);
      expect(classification.retryCategory, equals(RetryCategory.reconciliationRequired));
      expect(classification.quarantine, isFalse);
    });

    test('4. Financial Side-Effect Idempotency: Retrying posting on an already posted document is idempotent', () async {
      const receiptUuid = '00000000-0000-4000-8000-000000000088';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: const Value(receiptUuid),
          receiptNumber: const Value('REC-RETRY-001'),
          receiptDate: Value(nowMs),
          createdAt: Value(nowMs),
          updatedAt: Value(nowMs),
          status: const Value('draft'),
          companyId: const Value(tenantCompanyId),
        ),
      );

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: const Value('00000000-0000-4000-8000-000000000089'),
          movementUuid: const Value(receiptUuid),
          movementType: const Value('receipt'),
          itemCode: const Value('ITEM-001'),
          itemName: const Value('Test Item'),
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

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-RETRY-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.fromMillisecondsSinceEpoch(nowMs),
        status: InventoryDocumentStatus.draft,
      );

      // First Post
      final firstResult = await coordinator.post(document: docRef);
      expect(firstResult, isA<PostSuccess>());

      // Count movement lines and cost layers after 1st post
      final linesFirst = await (inventoryDb.select(inventoryDb.stockMovementLines)).get();
      final layersFirst = await (inventoryDb.select(inventoryDb.inventoryCostLayers)).get();

      // Retry Post on the now POSTED document
      final postedDocRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-RETRY-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.fromMillisecondsSinceEpoch(nowMs),
        status: InventoryDocumentStatus.posted,
      );

      final retryResult = await coordinator.post(document: postedDocRef);

      // Verify retry returns PostSuccess or PostInvalidStatus without duplicating records
      expect(retryResult, anyOf(isA<PostSuccess>(), isA<PostInvalidStatus>()));

      final linesSecond = await (inventoryDb.select(inventoryDb.stockMovementLines)).get();
      final layersSecond = await (inventoryDb.select(inventoryDb.inventoryCostLayers)).get();

      expect(linesSecond.length, equals(linesFirst.length));
      expect(layersSecond.length, equals(layersFirst.length));
    });
  });
}
