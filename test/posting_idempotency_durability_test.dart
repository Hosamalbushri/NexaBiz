import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/utils/id_generator.dart';

import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/sync/sync.dart';

import 'helpers/journal_posting_test_helper.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accDb;
  late InventoryDatabase invDb;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;
  late StockMovementsRepositoryImpl stockMovementsRepo;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl stockValidationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late InventoryAccountingPosterImpl accountingPoster;
  late PostingCoordinatorImpl postingCoordinator;
  late SyncQueue syncQueue;

  const testCompanyId = 'comp_idempotency_durability';
  late String cashAccountUuid;
  late String invAccountUuid;

  setUp(() async {
    accDb = AccountingDatabase(executor: NativeDatabase.memory());
    invDb = InventoryDatabase(executor: NativeDatabase.memory());

    accountRepo = AccountRepositoryImpl(accDb, readCompanyId: () => testCompanyId);
    final periodValidator = legacyPeriodValidator();

    journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: periodValidator,
      readCompanyId: () => testCompanyId,
    );

    journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );

    accountingPoster = InventoryAccountingPosterImpl(
      accDb,
      journalPostingService: journalPostingService,
      readCompanyId: () => testCompanyId,
    );

    syncQueue = SyncQueue(
      box: MockSyncBox<SyncOperation>([]),
      companyId: testCompanyId,
      deviceId: 'DEV-IDEM-1',
    );

    stockMovementsRepo = StockMovementsRepositoryImpl(
      db: invDb,
      syncQueue: syncQueue,
      accountingPoster: accountingPoster,
      readCompanyId: () => testCompanyId,
    );

    costLayerService = CostLayerServiceImpl(db: invDb, readCompanyId: () => testCompanyId);
    postingEngine = PostingEngineImpl(invDb, costLayerService, null, () => testCompanyId);
    stockValidationService = StockValidationServiceImpl(invDb, () => testCompanyId);
    dependencyDetector = InventoryDependencyDetectorImpl(invDb, () => testCompanyId);

    postingCoordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: stockValidationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      readCompanyId: () => testCompanyId,
      syncQueue: syncQueue,
    );

    // Seed inventory account
    final invAcc = await accountRepo.insert(
      const AccountDraft(
        accountCode: '1230',
        name: 'Inventory Account',
        accountType: AccountType.asset,
        description: 'system:inventory',
        isGroup: false,
      ),
    );
    invAccountUuid = invAcc.uuid;

    // Seed cash account
    final cashAcc = await accountRepo.insert(
      const AccountDraft(
        accountCode: '1010',
        name: 'Cash Account',
        accountType: AccountType.asset,
        isGroup: false,
      ),
    );
    cashAccountUuid = cashAcc.uuid;

    // Seed test product
    final now = DateTime.now().millisecondsSinceEpoch;
    await invDb.into(invDb.products).insert(
          ProductsCompanion(
            id: const Value(1),
            uuid: const Value('00000000-0000-4000-8000-000000000001'),
            itemCode: const Value('ITEM-IDEM-01'),
            name: const Value('Idempotency Test Item'),
            packSize: const Value(1),
            price: const Value(100.0),
            onHandQty: const Value(0.0),
            unitCost: const Value(50.0),
            companyId: const Value(testCompanyId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
  });

  group('ROOT FIX 17 — Posting Idempotency Durability Test Suite', () {
    test('1. Sequential Retry (Network Timeout Simulation) creates zero duplicate movements, cost layers, or journals', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();
      final date = DateTime.now();

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'SR-SEQ-001',
        supplier: 'Supp 1',
        accountId: cashAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        receiptDate: date,
        companyId: testCompanyId,
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-IDEM-01',
            itemName: 'Idempotency Test Item',
            mainQuantity: 10,
            subQuantity: 0,
            quantity: 10,
            unitCost: 50.0,
            totalCost: 500.0,
          ),
        ],
        createdAt: date,
        updatedAt: date,
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      );

      // FIRST POST
      final res1 = await postingCoordinator.post(document: docRef);
      expect(res1, isA<PostSuccess>());

      // SECOND POST (Simulated Network Timeout / Client Retry)
      final res2 = await postingCoordinator.post(document: docRef);
      expect(res2, isA<PostSuccess>());

      // THIRD POST (Additional Retry)
      final res3 = await postingCoordinator.post(document: docRef);
      expect(res3, isA<PostSuccess>());

      // VERIFY IDEMPOTENCY:
      // A. Product stock increased exactly ONCE (+10, not +30)
      final prod = await (invDb.select(invDb.products)..where((p) => p.itemCode.equals('ITEM-IDEM-01'))).getSingle();
      expect(prod.onHandQty, 10.0);

      // B. Cost layers in DB MUST be exactly 1
      final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(costLayers.length, 1);
      expect(costLayers.first.receivedQty, 10.0);

      // C. Journal entries MUST be exactly 1
      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries.length, 1);
      expect(journalEntries.first.voucherNumber, 'SR-SEQ-001');

      // D. Audit trail entries MUST be exactly 1
      final auditTrail = await invDb.select(invDb.inventoryAuditTrail).get();
      expect(auditTrail.length, 1);
    });

    test('2. Concurrent Retry (Simultaneous POST Requests) executes atomically with 1 effect', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();
      final date = DateTime.now();

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'SR-CONC-001',
        supplier: 'Supp 1',
        accountId: cashAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        receiptDate: date,
        companyId: testCompanyId,
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-IDEM-01',
            itemName: 'Idempotency Test Item',
            mainQuantity: 20,
            subQuantity: 0,
            quantity: 20,
            unitCost: 50.0,
            totalCost: 1000.0,
          ),
        ],
        createdAt: date,
        updatedAt: date,
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      );

      // Execute 3 concurrent post requests simultaneously
      final results = await Future.wait([
        postingCoordinator.post(document: docRef),
        postingCoordinator.post(document: docRef),
        postingCoordinator.post(document: docRef),
      ]);

      expect(results[0], isA<PostSuccess>());
      expect(results[1], isA<PostSuccess>());
      expect(results[2], isA<PostSuccess>());

      // VERIFY CONCURRENCY IDEMPOTENCY:
      final prod = await (invDb.select(invDb.products)..where((p) => p.itemCode.equals('ITEM-IDEM-01'))).getSingle();
      expect(prod.onHandQty, 20.0);

      final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(costLayers.length, 1);

      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries.length, 1);
    });

    test('3. Crash After Commit Simulation (Fresh PostingCoordinator) detects persisted posted state', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();
      final date = DateTime.now();

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'SR-CRASH-001',
        supplier: 'Supp 1',
        accountId: cashAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        receiptDate: date,
        companyId: testCompanyId,
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-IDEM-01',
            itemName: 'Idempotency Test Item',
            mainQuantity: 15,
            subQuantity: 0,
            quantity: 15,
            unitCost: 50.0,
            totalCost: 750.0,
          ),
        ],
        createdAt: date,
        updatedAt: date,
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      );

      // Post with initial coordinator
      final res1 = await postingCoordinator.post(document: docRef);
      expect(res1, isA<PostSuccess>());

      // Instantiate a FRESH PostingCoordinatorImpl instance (simulating process restart)
      final freshCoordinator = PostingCoordinatorImpl(
        db: invDb,
        stockValidationService: stockValidationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        accountingPoster: accountingPoster,
        readCompanyId: () => testCompanyId,
        syncQueue: syncQueue,
      );

      // Attempt post on fresh coordinator instance
      final res2 = await freshCoordinator.post(document: docRef);
      expect(res2, isA<PostSuccess>());

      // Verify DB data remains non-duplicated
      final prod = await (invDb.select(invDb.products)..where((p) => p.itemCode.equals('ITEM-IDEM-01'))).getSingle();
      expect(prod.onHandQty, 15.0);

      final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(costLayers.length, 1);

      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries.length, 1);
    });

    test('4. Sequential & Concurrent Reversal Retry is safely idempotent', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();
      final date = DateTime.now();

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'SR-UNP-IDEM',
        supplier: 'Supp 1',
        accountId: cashAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        receiptDate: date,
        companyId: testCompanyId,
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-IDEM-01',
            itemName: 'Idempotency Test Item',
            mainQuantity: 10,
            subQuantity: 0,
            quantity: 10,
            unitCost: 50.0,
            totalCost: 500.0,
          ),
        ],
        createdAt: date,
        updatedAt: date,
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      );

      // Post
      await postingCoordinator.post(document: docRef);

      final postedDocRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.posted,
      );

      // UNPOST 1
      final unpostRes1 = await postingCoordinator.unpost(document: postedDocRef);
      expect(unpostRes1, isA<UnpostSuccess>());

      // UNPOST 2 (Sequential retry)
      final unpostRes2 = await postingCoordinator.unpost(document: postedDocRef);
      expect(unpostRes2, isA<UnpostSuccess>());

      // UNPOST CONCURRENT RETRY
      final unpostResults = await Future.wait([
        postingCoordinator.unpost(document: postedDocRef),
        postingCoordinator.unpost(document: postedDocRef),
      ]);
      expect(unpostResults[0], isA<UnpostSuccess>());
      expect(unpostResults[1], isA<UnpostSuccess>());

      // VERIFY UNPOST IDEMPOTENCY:
      // A. Document is draft in DB
      final dbReceipt = await stockMovementsRepo.getReceiptById(receipt.id);
      expect(dbReceipt?.status, InventoryDocumentStatus.draft);

      // B. Offsetting reversal journal entry created EXACTLY ONCE
      final journalEntries = await accDb.select(accDb.journalEntries).get();
      final reversalEntries = journalEntries.where((e) => e.voucherNumber == 'SR-UNP-IDEM-R').toList();
      expect(reversalEntries.length, 1);
    });
  });
}
