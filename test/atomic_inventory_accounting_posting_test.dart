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

  const testCompanyId = 'comp_atomic_test';
  late String cashAccountUuid;
  late String invAccountUuid;
  late String cogsAccountUuid;

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

    syncQueue = SyncQueue(box: MockSyncBox<SyncOperation>([]), companyId: testCompanyId, deviceId: 'DEV-ATOMIC-1');
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

    // Seed mandatory chart of accounts for accounting poster
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

    final cashAcc = await accountRepo.insert(
      const AccountDraft(
        accountCode: '1010',
        name: 'Cash Account',
        accountType: AccountType.asset,
        isGroup: false,
      ),
    );
    cashAccountUuid = cashAcc.uuid;

    final cogsAcc = await accountRepo.insert(
      const AccountDraft(
        accountCode: '5100',
        name: 'COGS Account',
        accountType: AccountType.expense,
        description: 'system:cost_of_goods',
        isGroup: false,
      ),
    );
    cogsAccountUuid = cogsAcc.uuid;
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
  });

  group('ROOT FIX 16 — Atomic Inventory and Accounting Posting Test Suite', () {
    test('1. Forced Journal Failure triggers 100% atomic rollback of inventory and database state', () async {
      final receiptUuid = generateUuidV4();
      final invalidAccountUuid = generateUuidV4();
      final lineUuid = generateUuidV4();

      // Create a stock receipt specifying an INVALID non-existent account ID
      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'SR-ERR-001',
        supplier: 'Supp 1',
        accountId: invalidAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        receiptDate: DateTime.now(),
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-ERR',
            itemName: 'Error Item',
            mainQuantity: 10,
            subQuantity: 0,
            quantity: 10,
            unitCost: 50.0,
            totalCost: 500.0,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      );

      // Attempt posting — expecting failure due to invalid specified account
      await expectLater(
        postingCoordinator.post(document: docRef),
        throwsA(isA<StateError>()),
      );

      // VERIFY ATOMIC ROLLBACK:
      // A. Document status in database MUST remain 'draft'
      final dbReceipt = await stockMovementsRepo.getReceiptById(receipt.id);
      expect(dbReceipt?.status, InventoryDocumentStatus.draft);
      expect(dbReceipt?.postedAt, isNull);

      // B. Cost layers in DB MUST be empty
      final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(costLayers.isEmpty, isTrue);

      // C. Stock movement line postedAt MUST remain null
      final movementLines = await invDb.select(invDb.stockMovementLines).get();
      expect(movementLines.every((l) => l.postedAt == null), isTrue);

      // D. Journal entries MUST be zero
      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries.isEmpty, isTrue);
    });

    test('2. Successful Atomic Post commits inventory, cost layers, journal, and audit together', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'SR-OK-001',
        supplier: 'Supp 1',
        accountId: cashAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        receiptDate: DateTime.now(),
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-A',
            itemName: 'Item A',
            mainQuantity: 5,
            subQuantity: 0,
            quantity: 5,
            unitCost: 100.0,
            totalCost: 500.0,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      // VERIFY ATOMIC COMMIT:
      // A. Document status in DB is 'posted'
      final dbReceipt = await stockMovementsRepo.getReceiptById(receipt.id);
      expect(dbReceipt?.status, InventoryDocumentStatus.posted);
      expect(dbReceipt?.postedAt, isNotNull);

      // B. Cost layer was created
      final costLayers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(costLayers.length, 1);
      expect(costLayers.first.itemCode, 'ITEM-A');
      expect(costLayers.first.remainingQty, 5.0);

      // C. Journal entry was created and posted
      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries.length, 1);
      expect(journalEntries.first.isPosted, isTrue);
      expect(journalEntries.first.voucherNumber, 'SR-OK-001');

      final journalLines = await accDb.select(accDb.journalLines).get();
      expect(journalLines.length, 2);
      expect(journalLines.fold<double>(0, (s, l) => s + l.debit), 500.0);
      expect(journalLines.fold<double>(0, (s, l) => s + l.credit), 500.0);

      // D. Audit record was logged
      final auditTrail = await invDb.select(invDb.inventoryAuditTrail).get();
      expect(auditTrail.isNotEmpty, isTrue);
      expect(auditTrail.first.documentId, receipt.id);
    });

    test('3. Outbound stock issue shortage rejects posting with zero accounting or inventory effects', () async {
      final issueUuid = generateUuidV4();
      final lineUuid = generateUuidV4();

      final issue = StockIssue(
        id: issueUuid,
        issueNumber: 'SI-SHORT-001',
        destination: 'Dest 1',
        accountId: cashAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        warehouse: 'WH-01',
        issueDate: DateTime.now(),
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: issueUuid,
            movementType: 'issue',
            itemCode: 'ITEM-SHORT',
            itemName: 'Short Item',
            mainQuantity: 20,
            subQuantity: 0,
            quantity: 20,
            unitCost: 15.0,
            totalCost: 300.0,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await stockMovementsRepo.saveIssue(issue);

      final docRef = InventoryDocumentRef(
        documentId: issue.id,
        documentNumber: issue.issueNumber,
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        warehouseId: 'WH-01',
        status: InventoryDocumentStatus.draft,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostStockShortage>());

      // VERIFY NO SIDE EFFECTS:
      final dbIssue = await stockMovementsRepo.getIssueById(issue.id);
      expect(dbIssue?.status, InventoryDocumentStatus.draft);

      final journalEntries = await accDb.select(accDb.journalEntries).get();
      expect(journalEntries.isEmpty, isTrue);
    });

    test('4. Atomic unpost reverses both inventory cost consumption and accounting entries', () async {
      final receiptUuid = generateUuidV4();
      final lineUuid = generateUuidV4();

      // 1. Post valid receipt
      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'SR-UNP-001',
        supplier: 'Supp 1',
        accountId: cashAccountUuid,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
        receiptDate: DateTime.now(),
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-UNP',
            itemName: 'Unpost Item',
            mainQuantity: 5,
            subQuantity: 0,
            quantity: 5,
            unitCost: 50.0,
            totalCost: 250.0,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      );

      await postingCoordinator.post(document: docRef);

      // Verify posted
      final postedDoc = await stockMovementsRepo.getReceiptById(receipt.id);
      expect(postedDoc?.status, InventoryDocumentStatus.posted);

      final postedDocRef = InventoryDocumentRef(
        documentId: receipt.id,
        documentNumber: receipt.receiptNumber,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.posted,
      );

      // 2. Unpost
      final unpostResult = await postingCoordinator.unpost(document: postedDocRef);
      expect(unpostResult, isA<UnpostSuccess>());

      // VERIFY UNPOST ATOMICITY:
      // A. Document status in DB returned to 'draft'
      final unpostedDoc = await stockMovementsRepo.getReceiptById(receipt.id);
      expect(unpostedDoc?.status, InventoryDocumentStatus.draft);
      expect(unpostedDoc?.postedAt, isNull);

      // B. Cost layer was closed/invalidated
      final activeCostLayers = await (invDb.select(invDb.inventoryCostLayers)..where((t) => t.remainingQty.isBiggerThanValue(0.0) & t.deletedAt.isNull())).get();
      expect(activeCostLayers.isEmpty, isTrue);

      // C. Offsetting reversal journal entry created
      final journalEntries = await accDb.select(accDb.journalEntries).get();
      final reversalEntry = journalEntries.firstWhere((e) => e.voucherNumber == 'SR-UNP-001-R');
      expect(reversalEntry.isPosted, isTrue);
    });
  });
}
