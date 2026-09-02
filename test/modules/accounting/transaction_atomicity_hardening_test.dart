import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

import '../../helpers/journal_posting_test_helper.dart';

class _FailingAccountingPoster implements InventoryAccountingPoster {
  bool shouldFail = false;

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
  }) async {
    if (shouldFail) {
      throw const JournalException('missing_account', 'Simulated accounting failure: debit account missing');
    }
  }

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 7 — Audit and Harden Accounting Transaction Atomicity', () {
    late AccountingDatabase accountingDb;
    late InventoryDatabase inventoryDb;
    late AccountRepositoryImpl accountRepo;
    late JournalRepositoryImpl journalRepo;
    late JournalPostingService journalPostingService;
    late StockMovementsRepositoryImpl stockMovementsRepo;
    late PostingCoordinatorImpl postingCoordinator;
    late _FailingAccountingPoster failingAccountingPoster;

    const testCompanyId = 'company-test-1';

    setUp(() async {
      accountingDb = AccountingDatabase(executor: NativeDatabase.memory());
      inventoryDb = InventoryDatabase(executor: NativeDatabase.memory());

      accountRepo = AccountRepositoryImpl(
        accountingDb,
        readCompanyId: () => testCompanyId,
      );

      final periodValidator = legacyPeriodValidator();

      journalRepo = JournalRepositoryImpl(
        accountingDb,
        accounts: accountRepo,
        periodValidator: periodValidator,
        readCompanyId: () => testCompanyId,
      );

      journalPostingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: periodValidator,
        permissionGuard: const AllowAllPermissionGuard(),
      );

      stockMovementsRepo = StockMovementsRepositoryImpl(
        db: inventoryDb,
        readCompanyId: () => testCompanyId,
      );

      failingAccountingPoster = _FailingAccountingPoster();

      final costLayerService = CostLayerServiceImpl(db: inventoryDb, readCompanyId: () => testCompanyId);
      final postingEngine = PostingEngineImpl(inventoryDb, costLayerService, null, () => testCompanyId);
      final stockValidationService = StockValidationServiceImpl(inventoryDb, () => testCompanyId);
      final dependencyDetector = InventoryDependencyDetectorImpl(inventoryDb, () => testCompanyId);

      postingCoordinator = PostingCoordinatorImpl(
        db: inventoryDb,
        stockValidationService: stockValidationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        accountingPoster: failingAccountingPoster,
        permissionGuard: const AllowAllPermissionGuard(),
        readCompanyId: () => testCompanyId,
      );
    });

    tearDown(() async {
      await accountingDb.close();
      await inventoryDb.close();
    });

    Future<double> getStockBalance(String itemCode, String warehouseId) async {
      final rows = await (inventoryDb.select(inventoryDb.productWarehouseStocks)
            ..where((t) => t.itemCode.equals(itemCode) & t.warehouseId.equals(warehouseId)))
          .get();
      if (rows.isEmpty) return 0.0;
      return rows.first.onHandQty;
    }

    test('1. Success path atomicity: Composite stock receipt posting commits cleanly', () async {
      final receiptUuid = generateUuidV4();

      await stockMovementsRepo.saveReceipt(
        StockReceipt(
          id: receiptUuid,
          receiptNumber: 'REC-001',
          receiptDate: DateTime.now(),
          warehouse: 'wh-main',
          lines: [
            StockMovementLine(
              movementUuid: receiptUuid,
              movementType: 'receipt',
              itemCode: 'ITEM-A',
              itemName: 'Item A',
              quantity: 10,
              unitCost: 50.0,
              totalCost: 500.0,
            ),
          ],
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-main',
        status: InventoryDocumentStatus.draft,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      final dbReceipt = await stockMovementsRepo.getReceiptById(receiptUuid);
      expect(dbReceipt?.status, InventoryDocumentStatus.posted);

      final stockBalance = await getStockBalance('ITEM-A', 'wh-main');
      expect(stockBalance, 10.0);
    });

    test('2. Failure injection on accounting failure: DB transaction rolls back stock movements completely', () async {
      final receiptUuid = generateUuidV4();

      await stockMovementsRepo.saveReceipt(
        StockReceipt(
          id: receiptUuid,
          receiptNumber: 'REC-002',
          receiptDate: DateTime.now(),
          warehouse: 'wh-main',
          lines: [
            StockMovementLine(
              movementUuid: receiptUuid,
              movementType: 'receipt',
              itemCode: 'ITEM-B',
              itemName: 'Item B',
              quantity: 5,
              unitCost: 100.0,
              totalCost: 500.0,
            ),
          ],
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-002',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-main',
        status: InventoryDocumentStatus.draft,
      );

      // Inject accounting failure!
      failingAccountingPoster.shouldFail = true;

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostInvalidStatus>());

      // Verify complete rollback in DB
      final dbReceipt = await stockMovementsRepo.getReceiptById(receiptUuid);
      expect(dbReceipt?.status, InventoryDocumentStatus.draft);

      final stockBalance = await getStockBalance('ITEM-B', 'wh-main');
      expect(stockBalance, 0.0, reason: 'Stock balance must remain 0 after rolled-back posting');
    });

    test('3. Idempotency guard: Re-posting an already posted document returns PostSuccess without duplicates', () async {
      final receiptUuid = generateUuidV4();

      await stockMovementsRepo.saveReceipt(
        StockReceipt(
          id: receiptUuid,
          receiptNumber: 'REC-003',
          receiptDate: DateTime.now(),
          warehouse: 'wh-main',
          lines: [
            StockMovementLine(
              movementUuid: receiptUuid,
              movementType: 'receipt',
              itemCode: 'ITEM-C',
              itemName: 'Item C',
              quantity: 20,
              unitCost: 25.0,
              totalCost: 500.0,
            ),
          ],
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-003',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-main',
        status: InventoryDocumentStatus.draft,
      );

      // First post
      final result1 = await postingCoordinator.post(document: docRef);
      expect(result1, isA<PostSuccess>());

      // Second post (Retry)
      final result2 = await postingCoordinator.post(document: docRef);
      expect(result2, isA<PostSuccess>());

      // Verify stock balance was NOT duplicated (should remain 20, not 40)
      final stockBalance = await getStockBalance('ITEM-C', 'wh-main');
      expect(stockBalance, 20.0, reason: 'Stock balance must not duplicate on idempotent re-post');
    });

    test('4. Reversal auditability: Voiding posted journal entry creates offsetting entry without deleting history', () async {
      final cashAcc = await accountRepo.insert(
        const AccountDraft(
          accountCode: '1211',
          name: 'Cash',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      final salesAcc = await accountRepo.insert(
        const AccountDraft(
          accountCode: '4100',
          name: 'Sales',
          accountType: AccountType.revenue,
          isGroup: false,
        ),
      );

      final journalUuid = generateUuidV4();

      final draft = JournalEntryDraft(
        uuid: journalUuid,
        entryDate: DateTime.now(),
        voucherNumber: 'V-1001',
        voucherType: 'قبض',
        currencyCode: 'SAR',
        isPosted: true,
        sourceType: 'manual',
        sourceId: 'manual-001',
        lines: [
          JournalLineDraft(
            accountUuid: cashAcc.uuid,
            debit: 1000.0,
            credit: 0.0,
            currencyCode: 'SAR',
          ),
          JournalLineDraft(
            accountUuid: salesAcc.uuid,
            debit: 0.0,
            credit: 1000.0,
            currencyCode: 'SAR',
          ),
        ],
      );

      final posted = await journalPostingService.post(draft);
      expect(posted.isPosted, isTrue);

      // Perform void / reversal
      await journalPostingService.voidByUuid(posted.uuid);

      // Verify original journal entry is still present and marked posted (not deleted!)
      final original = await journalRepo.getByUuid(posted.uuid);
      expect(original, isNotNull);
      expect(original!.isPosted, isTrue);
      expect(original.deletedAt, isNull);

      // Verify reversing journal entry exists with swapped debit/credit
      final reversal = await journalRepo.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: posted.uuid,
      );
      expect(reversal, isNotNull);
      expect(reversal!.isPosted, isTrue);
      expect(reversal.voucherNumber, 'V-1001-R');

      final revCashLine = reversal.lines.firstWhere((l) => l.accountUuid == cashAcc.uuid);
      expect(revCashLine.credit, 1000.0); // Debit was swapped to Credit
      expect(revCashLine.debit, 0.0);
    });

    test('5. Retry recovery: Retrying post after fixing failure succeeds cleanly', () async {
      final receiptUuid = generateUuidV4();

      await stockMovementsRepo.saveReceipt(
        StockReceipt(
          id: receiptUuid,
          receiptNumber: 'REC-005',
          receiptDate: DateTime.now(),
          warehouse: 'wh-main',
          lines: [
            StockMovementLine(
              movementUuid: receiptUuid,
              movementType: 'receipt',
              itemCode: 'ITEM-D',
              itemName: 'Item D',
              quantity: 15,
              unitCost: 10.0,
              totalCost: 150.0,
            ),
          ],
        ),
      );

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-005',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-main',
        status: InventoryDocumentStatus.draft,
      );

      // Step A: Failure
      failingAccountingPoster.shouldFail = true;
      final failedResult = await postingCoordinator.post(document: docRef);
      expect(failedResult, isA<PostInvalidStatus>());

      // Step B: Fix condition
      failingAccountingPoster.shouldFail = false;

      // Step C: Retry
      final successResult = await postingCoordinator.post(document: docRef);
      expect(successResult, isA<PostSuccess>());

      final dbReceipt = await stockMovementsRepo.getReceiptById(receiptUuid);
      expect(dbReceipt?.status, InventoryDocumentStatus.posted);

      final stockBalance = await getStockBalance('ITEM-D', 'wh-main');
      expect(stockBalance, 15.0);
    });
  });
}
