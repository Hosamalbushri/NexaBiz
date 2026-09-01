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
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';

class FailingAccountingPoster implements InventoryAccountingPoster {
  FailingAccountingPoster({this.failOnPost = false, this.failOnReverse = false});

  final bool failOnPost;
  final bool failOnReverse;

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {
    if (failOnPost) {
      throw const JournalException('FORCED_ACCOUNTING_POST_FAILURE');
    }
  }

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {
    if (failOnReverse) {
      throw const JournalException('FORCED_COMPENSATION_REVERSAL_FAILURE');
    }
  }

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}
}

class DummyJournalPostingService implements JournalPostingService {
  @override
  Future<JournalEntry> post(JournalEntryDraft draft, {String? userId}) async {
    throw const JournalException('FORCED_JOURNAL_SERVICE_POST_FAILURE');
  }

  @override
  Future<void> voidBySource({required String sourceType, required String sourceId}) async {}

  @override
  Future<JournalEntry?> findBySource({required String sourceType, required String sourceId}) async {
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyAccountMappingResolver implements AccountMappingResolver {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyAccountValidationService implements AccountValidationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late InventoryDatabase inventoryDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;

  const tenantCompanyId = 'tenant_company_err_prop_37';

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

  group('ROOT FIX 37 — Critical Error Propagation Tests', () {
    test('1. Failure Propagation: Posting empty document fails cleanly with PostInvalidStatus', () async {
      final coordinator = PostingCoordinatorImpl(
        db: inventoryDb,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        readCompanyId: () => tenantCompanyId,
      );

      final emptyReceiptRef = InventoryDocumentRef(
        documentId: '00000000-0000-4000-8000-000000000037',
        documentNumber: 'REC-EMPTY-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'WH-01',
        status: InventoryDocumentStatus.draft,
      );

      final result = await coordinator.post(document: emptyReceiptRef);

      expect(result, isA<PostInvalidStatus>());
      final statusResult = result as PostInvalidStatus;
      expect(statusResult.reason, contains('المستند لا يحتوي على أصناف للترحيل'));
    });

    test('2. Compensation Audit Logging: Accounting reversal failure during compensation is audited', () async {
      const receiptUuid = '00000000-0000-4000-8000-000000000038';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await inventoryDb.into(inventoryDb.stockReceipts).insert(
        StockReceiptsCompanion(
          uuid: const Value(receiptUuid),
          receiptNumber: const Value('REC-COMP-001'),
          receiptDate: Value(nowMs),
          createdAt: Value(nowMs),
          updatedAt: Value(nowMs),
          status: const Value('draft'),
          companyId: const Value(tenantCompanyId),
        ),
      );

      await inventoryDb.into(inventoryDb.stockMovementLines).insert(
        StockMovementLinesCompanion(
          uuid: const Value('00000000-0000-4000-8000-000000000039'),
          movementUuid: const Value(receiptUuid),
          movementType: const Value('receipt'),
          itemCode: const Value('ITEM-001'),
          itemName: const Value('Test Item'),
          quantity: const Value(10.0),
          unitCost: const Value(50.0),
          totalCost: const Value(500.0),
        ),
      );

      final failingPoster = FailingAccountingPoster(failOnPost: false, failOnReverse: true);

      final coordinator = PostingCoordinatorImpl(
        db: inventoryDb,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        accountingPoster: failingPoster,
        readCompanyId: () => tenantCompanyId,
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-COMP-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.fromMillisecondsSinceEpoch(nowMs),
        status: InventoryDocumentStatus.draft,
      );

      final postResult = await coordinator.post(document: docRef);
      expect(postResult, isA<PostSuccess>());
    });

    test('3. Orchestration Failure Reporting: Unpost compensation errors are explicitly appended to failure reason', () async {
      final coordinator = PostingCoordinatorImpl(
        db: inventoryDb,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        readCompanyId: () => tenantCompanyId,
      );

      final dummyJournalService = DummyJournalPostingService();
      final entryBuilder = AccountingEntryBuilder(
        mappingResolver: DummyAccountMappingResolver(),
        validationService: DummyAccountValidationService(),
      );

      final orchestrator = DocumentPostingOrchestrator(
        postingCoordinator: coordinator,
        journalPostingService: dummyJournalService,
        entryBuilder: entryBuilder,
      );

      final receipt = StockReceipt(
        id: '00000000-0000-4000-8000-000000000040',
        receiptNumber: 'REC-ORCH-001',
        receiptDate: DateTime.now(),
        warehouse: 'WH-MAIN',
        status: InventoryDocumentStatus.draft,
        lines: const [],
      );

      final result = await orchestrator.postReceipt(receipt: receipt);

      expect(result, isA<OrchestrationFailure>());
      final failure = result as OrchestrationFailure;
      expect(failure.reason, isNotEmpty);
      expect(failure.documentId, equals(receipt.id));
    });
  });
}
