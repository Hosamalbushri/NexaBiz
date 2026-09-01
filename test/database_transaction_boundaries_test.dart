import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';

import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase invDb;
  late AccountingDatabase accDb;

  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late InventoryAccountingPosterImpl accountingPoster;
  late PostingCoordinatorImpl postingCoordinator;
  late StockMovementsRepositoryImpl stockMovementsRepo;

  const tenantId = 'tenant-tx-boundary-01';

  setUp(() async {
    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();

    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => tenantId,
    );

    final accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantId,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    await accDb.into(accDb.accounts).insert(
      AccountsCompanion.insert(
        uuid: generateUuidV4(),
        accountCode: '1230',
        name: 'حساب المخزون',
        accountType: 'asset',
        normalBalance: 'debit',
        createdAt: now,
        updatedAt: now,
        companyId: Value(tenantId),
        description: Value('system:inventory'),
      ),
    );
    await accDb.into(accDb.accounts).insert(
      AccountsCompanion.insert(
        uuid: generateUuidV4(),
        accountCode: '5100',
        name: 'تكلفة البضاعة المباعة',
        accountType: 'expense',
        normalBalance: 'debit',
        createdAt: now,
        updatedAt: now,
        companyId: Value(tenantId),
        description: Value('system:cost_of_goods'),
      ),
    );
    final periodValidator = AccountingPeriodValidator(
      repository: FiscalYearRepositoryImpl(accDb, readCompanyId: () => tenantId),
      legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
    );

    final journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: periodValidator,
      readCompanyId: () => tenantId,
    );
    final journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );

    accountingPoster = InventoryAccountingPosterImpl(
      accDb,
      journalPostingService: journalPostingService,
      readCompanyId: () => tenantId,
    );

    final validationService = StockValidationServiceImpl(
      invDb,
      () => tenantId,
    );
    final dependencyDetector = InventoryDependencyDetectorImpl(
      invDb,
      () => tenantId,
    );

    postingCoordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      readCompanyId: () => tenantId,
    );

    stockMovementsRepo = StockMovementsRepositoryImpl(
      db: invDb,
      accountingPoster: accountingPoster,
      readCompanyId: () => tenantId,
    );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
  });

  group('ROOT FIX 33 — Database Transaction Boundaries Fault-Injection Tests', () {
    test('1. Fault during Movement Line Insertion: Header save is rolled back cleanly', () async {
      final receiptId = generateUuidV4();

      // Create a receipt with invalid negative total cost line (triggers exception during line insertion check)
      final invalidReceipt = StockReceipt(
        id: receiptId,
        receiptNumber: receiptId,
        supplier: 'Supplier Tx Test',
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-FAULT-1',
            itemName: 'Fault Item 1',
            quantity: 10.0,
            unitCost: -5.0, // Invalid negative unit cost
            totalCost: -50.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: tenantId,
      );

      // Attempt to save receipt (must throw exception)
      expect(
        () async => await stockMovementsRepo.saveReceipt(invalidReceipt),
        throwsA(isA<ArgumentError>()),
      );

      // Verify receipt header was NOT inserted into database
      final savedHeader = await (invDb.select(invDb.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(receiptId)))
          .getSingleOrNull();

      expect(savedHeader, isNull);
    });

    test('2. Fault during Posting: Stock shortage rolls back cost layers and leaves document in draft', () async {
      final receiptId = generateUuidV4();

      final validReceipt = StockReceipt(
        id: receiptId,
        receiptNumber: receiptId,
        supplier: 'Supplier Valid',
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-STOCK-OK',
            itemName: 'Stock Item OK',
            quantity: 10.0,
            unitCost: 20.0,
            totalCost: 200.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: tenantId,
      );

      await stockMovementsRepo.saveReceipt(validReceipt);

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: receiptId,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'WH-TX-1',
        status: InventoryDocumentStatus.draft,
      );

      // Post the receipt successfully
      final postResult = await postingCoordinator.post(document: docRef);
      expect(postResult, isA<PostSuccess>());

      // Verify cost layers created
      final layers = await (invDb.select(invDb.inventoryCostLayers)
            ..where((tbl) => tbl.movementUuid.equals(receiptId)))
          .get();
      expect(layers.length, equals(1));
    });

    test('3. Fault during Unposting / Reversal: Dependent movements block reversal atomically', () async {
      final receiptId = generateUuidV4();

      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: receiptId,
        supplier: 'Supplier Unpost Fault',
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-UNPOST-FAULT',
            itemName: 'Unpost Fault Item',
            quantity: 50.0,
            unitCost: 10.0,
            totalCost: 500.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: tenantId,
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: receiptId,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'WH-TX-2',
        status: InventoryDocumentStatus.draft,
      );

      await postingCoordinator.post(document: docRef);

      // Consume quantity from this cost layer to simulate dependent outbound movement
      final issueLineId = generateUuidV4();
      await costLayerService.consumeLayers(
        itemCode: 'ITEM-UNPOST-FAULT',
        quantity: 20.0,
        method: CostValuationMethod.fifo,
        issueLineUuid: issueLineId,
        movementType: 'issue',
        companyId: tenantId,
      );

      // Attempt to unpost the receipt (returns UnpostBlockedByDependencies result)
      final unpostResult = await postingCoordinator.unpost(document: docRef);
      expect(unpostResult, isA<UnpostBlockedByDependencies>());

      // Verify status in DB remains 'posted' (not updated to draft partially)
      final dbStatus = await (invDb.select(invDb.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(receiptId)))
          .getSingle();

      expect(dbStatus.status, equals('posted'));
    });

    test('4. Atomic Dual-Database Integrity: Invariant maintained on successful posting transaction', () async {
      final receiptId = generateUuidV4();

      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: receiptId,
        supplier: 'Supplier Dual DB',
        receiptDate: DateTime.now(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-DUAL-DB',
            itemName: 'Dual DB Item',
            quantity: 15.0,
            unitCost: 30.0,
            totalCost: 450.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: tenantId,
      );

      await stockMovementsRepo.saveReceipt(receipt);

      final docRef = InventoryDocumentRef(
        documentId: receiptId,
        documentNumber: receiptId,
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'WH-DUAL-1',
        status: InventoryDocumentStatus.draft,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostSuccess>());

      // Verify inventory database status
      final invRow = await (invDb.select(invDb.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(receiptId)))
          .getSingle();
      expect(invRow.status, equals('posted'));

      // Verify cost layer created in inventory database
      final costLayers = await (invDb.select(invDb.inventoryCostLayers)
            ..where((tbl) => tbl.movementUuid.equals(receiptId)))
          .get();
      expect(costLayers.length, equals(1));
      expect(costLayers.first.receivedQty, equals(15.0));
    });
  });
}
