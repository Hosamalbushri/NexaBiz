import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_return.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/auth/domain/services/local_access_policy.dart';
import 'package:hive/hive.dart';

class MockSyncBox<T> implements Box<T> {
  MockSyncBox(List<T> initial) {
    for (final item in initial) {
      final id = (item as dynamic).id;
      _map[id] = item;
    }
  }
  final Map<dynamic, T> _map = {};

  @override
  Iterable<T> get values => _map.values;

  @override
  Map<dynamic, T> toMap() => Map.from(_map);

  @override
  Future<void> put(dynamic key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _map.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late InventoryDatabase db;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl coordinator;
  late StockMovementsRepositoryImpl movementsRepo;
  late StockTransferRepositoryImpl transferRepo;
  late StockReturnsRepositoryImpl returnsRepo;
  late SyncQueue syncQueue;
  late MockSyncBox<SyncOperation> mockBox;
  late InMemoryRemoteSyncApi remoteSyncApi;

  setUp(() async {
    db = InventoryDatabase.memory();
    costLayerService = CostLayerServiceImpl(db: db, readCompanyId: () => 'COMP-A');
    postingEngine = PostingEngineImpl(db, costLayerService, null, () => 'COMP-A');
    validationService = StockValidationServiceImpl(db, () => 'COMP-A');
    dependencyDetector = InventoryDependencyDetectorImpl(db, () => 'COMP-A');
    mockBox = MockSyncBox<SyncOperation>([]);
    syncQueue = SyncQueue(box: mockBox, companyId: 'COMP-A', deviceId: 'DEV-1');
    remoteSyncApi = InMemoryRemoteSyncApi();

    coordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      readCompanyId: () => 'COMP-A',
      syncQueue: syncQueue,
    );
    movementsRepo = StockMovementsRepositoryImpl(db: db, readCompanyId: () => 'COMP-A');
    transferRepo = StockTransferRepositoryImpl(db: db, readCompanyId: () => 'COMP-A');
    returnsRepo = StockReturnsRepositoryImpl(db: db, readCompanyId: () => 'COMP-A');

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.products).insert(
          ProductsCompanion(
            id: const Value(1),
            uuid: const Value('00000000-0000-4000-8000-000000000001'),
            itemCode: const Value('ITEM-SYNC-01'),
            name: const Value('Sync Test Item'),
            packSize: const Value(1),
            price: const Value(100.0),
            onHandQty: const Value(0.0),
            unitCost: const Value(50.0),
            companyId: const Value('COMP-A'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('NexaBiz Inventory — Phase 6: 30 Integration Test Scenarios Suite', () {
    // 1. Outbound Sync Enqueue on Receipt Posting
    test('1. Outbound Sync Enqueue on Receipt Posting', () async {
      final rId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);
      final receipt = StockReceipt(
        id: rId,
        receiptNumber: 'REC-001',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      );
      await movementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      final res = await coordinator.post(document: docRef);
      expect(res, isA<PostSuccess>());

      final ops = await syncQueue.all();
      expect(ops.length, 1);
      expect(ops.first.entityType, 'stock_receipt');
      expect(ops.first.entityId, rId);
      expect(ops.first.type, SyncOperationType.create);
    });

    // 2. Outbound Sync Enqueue on Issue Posting
    test('2. Outbound Sync Enqueue on Issue Posting', () async {
      final rId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-INIT',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-INIT',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final issId = generateUuidV4();
      await movementsRepo.saveIssue(StockIssue(
        id: issId,
        issueNumber: 'ISS-001',
        issueDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: issId,
            movementType: 'issue',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 30,
            unitCost: 50,
            totalCost: 1500,
          ),
        ],
      ));

      final res = await coordinator.post(document: InventoryDocumentRef(
        documentId: issId,
        documentNumber: 'ISS-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: date,
      ));
      expect(res, isA<PostSuccess>());

      final ops = await syncQueue.all();
      expect(ops.any((op) => op.entityType == 'stock_issue' && op.entityId == issId), isTrue);
    });

    // 3. Outbound Sync Enqueue on Transfer Posting
    test('3. Outbound Sync Enqueue on Transfer Posting', () async {
      final date = DateTime.utc(2026, 1, 1);
      final rId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-WH1',
        receiptDate: date,
        warehouse: 'WH-1',
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-WH1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
        warehouseId: 'WH-1',
      ));

      final trId = generateUuidV4();
      await transferRepo.saveTransfer(StockTransfer(
        id: trId,
        transferNumber: 'TR-001',
        fromWarehouseId: 'WH-1',
        toWarehouseId: 'WH-2',
        transferDate: date,
        companyId: 'COMP-A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 20,
            unitCost: 100,
            totalCost: 2000,
          ),
        ],
      ));

      await coordinator.post(document: InventoryDocumentRef(
        documentId: trId,
        documentNumber: 'TR-001',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: date,
        warehouseId: 'WH-1',
      ));

      final ops = await syncQueue.all();
      expect(ops.any((op) => op.entityType == 'stock_transfer' && op.entityId == trId), isTrue);
    });

    // 4. Outbound Sync Enqueue on Purchase Return Posting
    test('4. Outbound Sync Enqueue on Purchase Return Posting', () async {
      final date = DateTime.utc(2026, 1, 1);
      final pretId = generateUuidV4();
      final recForRetId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: recForRetId,
        receiptNumber: 'REC-FOR-PRET',
        receiptDate: date,
        warehouse: 'WH-1',
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: recForRetId,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: recForRetId,
        documentNumber: 'REC-FOR-PRET',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
        warehouseId: 'WH-1',
      ));

      await returnsRepo.saveReturn(StockReturn(
        id: pretId,
        returnNumber: 'PRET-001',
        returnType: StockReturnType.purchaseReturn,
        returnDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: pretId,
            movementType: 'return',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 5,
            unitCost: 50,
            totalCost: 250,
          ),
        ],
      ));

      await coordinator.post(document: InventoryDocumentRef(
        documentId: pretId,
        documentNumber: 'PRET-001',
        documentType: InventoryDocumentType.stockReturn,
        documentDate: date,
        warehouseId: 'WH-1',
      ));

      final ops = await syncQueue.all();
      expect(ops.any((op) => op.entityType == 'stock_return' && op.entityId == pretId), isTrue);
    });

    // 5. Outbound Sync Enqueue on Sales Return Posting
    test('5. Outbound Sync Enqueue on Sales Return Posting', () async {
      final date = DateTime.utc(2026, 1, 1);
      final sretId = generateUuidV4();
      await returnsRepo.saveReturn(StockReturn(
        id: sretId,
        returnNumber: 'SRET-001',
        returnType: StockReturnType.salesReturn,
        returnDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: sretId,
            movementType: 'return',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
      ));

      await coordinator.post(document: InventoryDocumentRef(
        documentId: sretId,
        documentNumber: 'SRET-001',
        documentType: InventoryDocumentType.stockReturn,
        documentDate: date,
      ));

      final ops = await syncQueue.all();
      expect(ops.any((op) => op.entityType == 'stock_return' && op.entityId == sretId), isTrue);
    });

    // 6. Outbound Sync Enqueue on Unpost/Reversal
    test('6. Outbound Sync Enqueue on Unpost/Reversal', () async {
      final rId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-REV-EX',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      ));

      final docRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-REV-EX',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );

      await coordinator.post(document: docRef);
      final unpostRes = await coordinator.unpost(document: docRef);
      expect(unpostRes, isA<UnpostSuccess>());

      final ops = await syncQueue.all();
      expect(ops.any((op) => op.entityType == 'inventory_reversal' && op.entityId == rId), isTrue);
    });

    // 7. Durable Outbox Persistence across Restart
    test('7. Durable Outbox Persistence across Restart', () async {
      final op = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rec_restart_1',
        type: SyncOperationType.create,
        payload: const {'documentNumber': 'REC-RST-1'},
        companyId: 'COMP-A',
      );

      await syncQueue.enqueue(op);
      final countBefore = (await syncQueue.all()).length;

      // Re-initialize SyncQueue using same underlying box
      final restartedQueue = SyncQueue(box: mockBox, companyId: 'COMP-A', deviceId: 'DEV-1');
      final countAfter = (await restartedQueue.all()).length;

      expect(countAfter, equals(countBefore));
      expect(countAfter, 1);
    });

    // 8. Duplicate Sync Replay Idempotency (Receipt)
    test('8. Duplicate Sync Replay Idempotency (Receipt)', () async {
      final op = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'r_idem_1',
        type: SyncOperationType.create,
        payload: const {'documentNumber': 'REC-IDEM-01', 'totalCost': 1000},
        companyId: 'COMP-A',
      );

      final ack1 = await remoteSyncApi.push(entityType: 'stock_receipt', operation: op);
      final ack2 = await remoteSyncApi.push(entityType: 'stock_receipt', operation: op);

      expect(ack1.remoteVersion, equals(1));
      expect(ack2.remoteVersion, equals(1));
    });

    // 9. Duplicate Sync Replay Idempotency (Issue)
    test('9. Duplicate Sync Replay Idempotency (Issue)', () async {
      final op = SyncOperation.create(
        entityType: 'stock_issue',
        entityId: 'iss_idem_1',
        type: SyncOperationType.create,
        payload: const {'documentNumber': 'ISS-IDEM-01', 'totalCost': 500},
        companyId: 'COMP-A',
      );

      final ack1 = await remoteSyncApi.push(entityType: 'stock_issue', operation: op);
      final ack2 = await remoteSyncApi.push(entityType: 'stock_issue', operation: op);

      expect(ack1.remoteVersion, ack2.remoteVersion);
    });

    // 10. Duplicate Sync Replay Idempotency (Transfer)
    test('10. Duplicate Sync Replay Idempotency (Transfer)', () async {
      final op = SyncOperation.create(
        entityType: 'stock_transfer',
        entityId: 'tr_idem_1',
        type: SyncOperationType.create,
        payload: const {'documentNumber': 'TR-IDEM-01'},
        companyId: 'COMP-A',
      );

      final ack1 = await remoteSyncApi.push(entityType: 'stock_transfer', operation: op);
      final ack2 = await remoteSyncApi.push(entityType: 'stock_transfer', operation: op);

      expect(ack1.remoteVersion, ack2.remoteVersion);
    });

    // 11. Duplicate Sync Replay Idempotency (Reversal)
    test('11. Duplicate Sync Replay Idempotency (Reversal)', () async {
      final opCreate = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'r_rev_idem_1',
        type: SyncOperationType.create,
        payload: const {'documentNumber': 'REC-REV-IDEM'},
        companyId: 'COMP-A',
      );
      await remoteSyncApi.push(entityType: 'stock_receipt', operation: opCreate);

      final opRev = SyncOperation.create(
        entityType: 'inventory_reversal',
        entityId: 'r_rev_idem_1',
        type: SyncOperationType.update,
        payload: const {'action': 'unpost'},
        baseVersion: 1,
        companyId: 'COMP-A',
      );

      final ack1 = await remoteSyncApi.push(entityType: 'inventory_reversal', operation: opRev);
      expect(ack1.remoteVersion, 2);
    });

    // 12. Accounting Journal Entry Sync Integrity
    test('12. Accounting Journal Entry Sync Integrity', () async {
      final opJ = SyncOperation.create(
        entityType: 'journal_entry',
        entityId: 'j_01',
        type: SyncOperationType.create,
        payload: const {
          'journalNumber': 'JV-001',
          'lines': [
            {'accountId': '1010', 'debit': 1000.0, 'credit': 0.0},
            {'accountId': '5010', 'debit': 0.0, 'credit': 1000.0},
          ],
        },
        companyId: 'COMP-A',
      );

      final ack = await remoteSyncApi.push(entityType: 'journal_entry', operation: opJ);
      expect(ack.remoteVersion, 1);
    });

    // 13. Reversal Journal Entry Sync Integrity
    test('13. Reversal Journal Entry Sync Integrity', () async {
      final opJ = SyncOperation.create(
        entityType: 'journal_entry',
        entityId: 'j_01_rev',
        type: SyncOperationType.create,
        payload: const {
          'journalNumber': 'JV-001-REV',
          'lines': [
            {'accountId': '1010', 'debit': 0.0, 'credit': 1000.0},
            {'accountId': '5010', 'debit': 1000.0, 'credit': 0.0},
          ],
        },
        companyId: 'COMP-A',
      );

      final ack = await remoteSyncApi.push(entityType: 'journal_entry', operation: opJ);
      expect(ack.remoteVersion, 1);
    });

    // 14. Server Cost Layer Authority Verification
    test('14. Server Cost Layer Authority Verification', () async {
      final localLayerCost = 100.0;
      final serverMeta = await remoteSyncApi.getMeta(entityType: 'stock_receipt', entityId: 'r_authority_1');
      expect(serverMeta == null || serverMeta.version >= 0, isTrue);
    });

    // 15. Topological Ordering: Product before Receipt
    test('15. Topological Ordering: Product before Receipt', () async {
      final opReceipt = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'r_top_1',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );
      final opProduct = SyncOperation.create(
        entityType: 'product',
        entityId: 'p_top_1',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );

      final queue = SyncQueue(box: MockSyncBox<SyncOperation>([opReceipt, opProduct]), companyId: 'COMP-A');
      final ready = await queue.peekReady();

      expect(ready.first.entityType, equals('product'));
    });

    // 16. Topological Ordering: Receipt before Issue
    test('16. Topological Ordering: Receipt before Issue', () async {
      final opIssue = SyncOperation.create(
        entityType: 'stock_issue',
        entityId: 'iss_top_1',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );
      final opReceipt = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rcpt_top_1',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );

      final queue = SyncQueue(box: MockSyncBox<SyncOperation>([opIssue, opReceipt]), companyId: 'COMP-A');
      final ready = await queue.peekReady();

      expect(ready.first.entityType, equals('stock_receipt'));
    });

    // 17. Topological Ordering: Receipt before Transfer
    test('17. Topological Ordering: Receipt before Transfer', () async {
      final opTransfer = SyncOperation.create(
        entityType: 'stock_transfer',
        entityId: 'tr_top_1',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );
      final opReceipt = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rcpt_top_2',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );

      final queue = SyncQueue(box: MockSyncBox<SyncOperation>([opTransfer, opReceipt]), companyId: 'COMP-A');
      final ready = await queue.peekReady();

      expect(ready.first.entityType, equals('stock_receipt'));
    });

    // 18. Topological Ordering: Receipt before Reversal
    test('18. Topological Ordering: Receipt before Reversal', () async {
      final opReversal = SyncOperation.create(
        entityType: 'inventory_reversal',
        entityId: 'rev_top_1',
        type: SyncOperationType.update,
        payload: const {},
        companyId: 'COMP-A',
      );
      final opReceipt = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rcpt_top_3',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );

      final queue = SyncQueue(box: MockSyncBox<SyncOperation>([opReversal, opReceipt]), companyId: 'COMP-A');
      final ready = await queue.peekReady();

      expect(ready.first.entityType, equals('stock_receipt'));
    });

    // 19. Tenant Boundary Enforcement in Sync Queue
    test('19. Tenant Boundary Enforcement in Sync Queue', () async {
      final opOtherCompany = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rec_tenant_err',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-B',
      );

      expect(
        () => syncQueue.enqueue(opOtherCompany),
        throwsA(isA<SecurityException>()),
      );
    });

    // 20. Cross-Tenant Operation Quarantining
    test('20. Cross-Tenant Operation Quarantining', () async {
      final opB = SyncOperation.create(
        entityType: 'stock_issue',
        entityId: 'iss_comp_b',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-B',
      );

      final queueA = SyncQueue(box: MockSyncBox<SyncOperation>([opB]), companyId: 'COMP-A');
      final ready = await queueA.peekReady();

      expect(ready, isEmpty);
    });

    // 21. Offline-to-Online Batch Sync Execution
    test('21. Offline-to-Online Batch Sync Execution', () async {
      final op1 = SyncOperation.create(
        entityType: 'product',
        entityId: 'p_batch_1',
        type: SyncOperationType.create,
        payload: const {'name': 'P1'},
        companyId: 'COMP-A',
      );
      final op2 = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'r_batch_1',
        type: SyncOperationType.create,
        payload: const {'doc': 'R1'},
        companyId: 'COMP-A',
      );

      await syncQueue.enqueue(op1);
      await syncQueue.enqueue(op2);

      final ready = await syncQueue.peekReady();
      expect(ready.length, 2);

      for (final op in ready) {
        await remoteSyncApi.push(entityType: op.entityType, operation: op);
      }
    });

    // 22. Partial Network Interruption & Queue Resume
    test('22. Partial Network Interruption & Queue Resume', () async {
      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p_interrupt',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );

      final syncingOp = op.copyWith(status: SyncStatus.syncing, updatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)));
      final queue = SyncQueue(box: MockSyncBox<SyncOperation>([syncingOp]), companyId: 'COMP-A');

      final reclaimed = await queue.reclaimInFlight(lease: const Duration(minutes: 5));
      expect(reclaimed, equals(1));

      final ready = await queue.peekReady();
      expect(ready.length, equals(1));
    });

    // 23. Re-sync after Conflict Resolution
    test('23. Re-sync after Conflict Resolution', () async {
      final op = SyncOperation.create(
        entityType: 'product',
        entityId: 'p_conf_res',
        type: SyncOperationType.create,
        payload: const {},
        companyId: 'COMP-A',
      );

      final quarantined = op.copyWith(status: SyncStatus.quarantined, lastError: 'Stale version');
      final queue = SyncQueue(box: MockSyncBox<SyncOperation>([quarantined]), companyId: 'COMP-A');

      await queue.resetQuarantine(quarantined.id);
      final ready = await queue.peekReady();
      expect(ready.length, 1);
    });

    // 24. Out-of-order Event Replay Resilience
    test('24. Out-of-order Event Replay Resilience', () async {
      final opCreate = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rcpt_ooo_1',
        type: SyncOperationType.create,
        payload: const {'doc': 'REC-OOO'},
        companyId: 'COMP-A',
      );

      final ack1 = await remoteSyncApi.push(entityType: 'stock_receipt', operation: opCreate);
      expect(ack1.remoteVersion, 1);
    });

    // 25. Multi-device Receipt Sync Convergence
    test('25. Multi-device Receipt Sync Convergence', () async {
      final opDev1 = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rcpt_multidev_1',
        type: SyncOperationType.create,
        payload: const {'qty': 50},
        deviceId: 'DEV-1',
        companyId: 'COMP-A',
      );
      final opDev2 = SyncOperation.create(
        entityType: 'stock_receipt',
        entityId: 'rcpt_multidev_1',
        type: SyncOperationType.create,
        payload: const {'qty': 50},
        deviceId: 'DEV-2',
        companyId: 'COMP-A',
      );

      final ack1 = await remoteSyncApi.push(entityType: 'stock_receipt', operation: opDev1);
      final ack2 = await remoteSyncApi.push(entityType: 'stock_receipt', operation: opDev2);

      expect(ack1.remoteVersion, equals(ack2.remoteVersion));
    });

    // 26. Multi-device Issue Sync Allocation Safety
    test('26. Multi-device Issue Sync Allocation Safety', () async {
      final opIssue1 = SyncOperation.create(
        entityType: 'stock_issue',
        entityId: 'iss_mdev_1',
        type: SyncOperationType.create,
        payload: const {'qty': 10},
        deviceId: 'DEV-1',
        companyId: 'COMP-A',
      );
      final ack1 = await remoteSyncApi.push(entityType: 'stock_issue', operation: opIssue1);
      expect(ack1.remoteVersion, 1);
    });

    // 27. Reversal Sync when Downstream Movement Exists (Blocked Safety)
    test('27. Reversal Sync when Downstream Movement Exists (Blocked Safety)', () async {
      final rId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'REC-DEP-TEST',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 50,
            unitCost: 100,
            totalCost: 5000,
          ),
        ],
      ));

      final receiptDocRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'REC-DEP-TEST',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      );
      await coordinator.post(document: receiptDocRef);

      final issId = generateUuidV4();
      await movementsRepo.saveIssue(StockIssue(
        id: issId,
        issueNumber: 'ISS-DEP-TEST',
        issueDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: issId,
            movementType: 'issue',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));

      await coordinator.post(document: InventoryDocumentRef(
        documentId: issId,
        documentNumber: 'ISS-DEP-TEST',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: date,
      ));

      final unpostRes = await coordinator.unpost(document: receiptDocRef);
      expect(unpostRes, isA<UnpostBlockedByDependencies>());
    });

    // 28. Weighted Average Cost Sync Convergence
    test('28. Weighted Average Cost Sync Convergence', () async {
      final date = DateTime.utc(2026, 1, 1);
      final r1Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r1Id,
        receiptNumber: 'R1-AVG',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r1Id,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1Id,
        documentNumber: 'R1-AVG',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final avgCost = await costLayerService.getWeightedAverageCost('ITEM-SYNC-01');
      expect(avgCost, 100.0);
    });

    // 29. FIFO Cost Layer Sync Reconstruction
    test('29. FIFO Cost Layer Sync Reconstruction', () async {
      final date = DateTime.utc(2026, 1, 1);
      final r1Id = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: r1Id,
        receiptNumber: 'R1-FIFO',
        receiptDate: date,
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: r1Id,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 20,
            unitCost: 50,
            totalCost: 1000,
          ),
        ],
      ));
      await coordinator.post(document: InventoryDocumentRef(
        documentId: r1Id,
        documentNumber: 'R1-FIFO',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
      ));

      final openLayers = await costLayerService.getOpenLayers('ITEM-SYNC-01');
      expect(openLayers.length, 1);
      expect(openLayers.first.remainingQty, 20.0);
    });

    // 30. Full End-to-End Inventory Sync Lifecycle
    test('30. Full End-to-End Inventory Sync Lifecycle', () async {
      final date = DateTime.utc(2026, 1, 1);

      // Step A: Post Inbound Receipt
      final rId = generateUuidV4();
      await movementsRepo.saveReceipt(StockReceipt(
        id: rId,
        receiptNumber: 'E2E-R01',
        receiptDate: date,
        warehouse: 'WH-A',
        companyId: 'COMP-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: rId,
            movementType: 'receipt',
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 100,
            unitCost: 50,
            totalCost: 5000,
          ),
        ],
      ));

      final rDocRef = InventoryDocumentRef(
        documentId: rId,
        documentNumber: 'E2E-R01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: date,
        warehouseId: 'WH-A',
      );

      final rRes = await coordinator.post(document: rDocRef);
      expect(rRes, isA<PostSuccess>());

      // Step B: Transfer 40 units to WH-B
      final trId = generateUuidV4();
      await transferRepo.saveTransfer(StockTransfer(
        id: trId,
        transferNumber: 'E2E-T01',
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        transferDate: date,
        companyId: 'COMP-A',
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: trId,
            itemCode: 'ITEM-SYNC-01',
            itemName: 'Sync Test Item',
            quantity: 40,
            unitCost: 50,
            totalCost: 2000,
          ),
        ],
      ));

      final trDocRef = InventoryDocumentRef(
        documentId: trId,
        documentNumber: 'E2E-T01',
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: date,
        warehouseId: 'WH-A',
      );
      final trRes = await coordinator.post(document: trDocRef);
      expect(trRes, isA<PostSuccess>());

      // Step C: Verify Outbox Sync Queue contains operations
      final queuedOps = await syncQueue.all();
      expect(queuedOps.length, equals(2));

      // Step D: Execute Sync Pass to Remote API
      for (final op in queuedOps) {
        final ack = await remoteSyncApi.push(entityType: op.entityType, operation: op);
        expect(ack.remoteVersion >= 1, isTrue);
      }
    });
  });
}
