import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/inventory_accounting_reconciliation_engine.dart';
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
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late StockMovementsRepositoryImpl stockRepo;
  late StockTransferRepositoryImpl transferRepo;
  late PostingCoordinatorImpl coordinator;
  late AccountingPeriodValidator validator;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;
  late DocumentPostingOrchestrator orchestrator;
  late InventoryAccountingReconciliationEngine reconEngine;
  late InventoryAccountingPosterImpl accountingPoster;
  late AccountingEntryBuilder entryBuilder;
  late Directory tempDir;

  const tenantId = 'company-recon-test-27';
  const warehouseA = 'WH-RECON-A';
  const warehouseB = 'WH-RECON-B';
  const itemCode = 'ITEM-RECON-01';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recon_fix27_test_');
    Hive.init(tempDir.path);

    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();

    stockRepo = StockMovementsRepositoryImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    transferRepo = StockTransferRepositoryImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    final validationService = StockValidationServiceImpl(invDb, () => tenantId);
    final depDetector = InventoryDependencyDetectorImpl(invDb, () => tenantId);
    final costLayerService = CostLayerServiceImpl(db: invDb, readCompanyId: () => tenantId);
    final postingEngine = PostingEngineImpl(invDb, costLayerService, null, () => tenantId);

    accountingPoster = InventoryAccountingPosterImpl(
      accDb,
      readCompanyId: () => tenantId,
    );

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: validationService,
      dependencyDetector: depDetector,
      postingEngine: postingEngine,
      accountingPoster: accountingPoster,
      readCompanyId: () => tenantId,
    );

    validator = legacyPeriodValidator();

    final accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantId,
    );

    journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: validator,
      readCompanyId: () => tenantId,
    );

    journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: validator,
    );

    final accValService = AccountValidationServiceImpl(accountRepo);
    final mappingResolver = AccountMappingResolverImpl(
      accountRepository: accountRepo,
      validationService: accValService,
    );

    entryBuilder = AccountingEntryBuilder(
      mappingResolver: mappingResolver,
      validationService: accValService,
    );

    orchestrator = DocumentPostingOrchestrator(
      postingCoordinator: coordinator,
      journalPostingService: journalPostingService,
      entryBuilder: entryBuilder,
    );

    reconEngine = InventoryAccountingReconciliationEngine(
      inventoryDb: invDb,
      accountingDb: accDb,
      readCompanyId: () => tenantId,
    );

    // Seed default chart of accounts for tenantId
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await accDb.into(accDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '11111111-1111-1111-1111-111111111111',
            accountCode: '1230',
            name: 'Inventory Asset',
            accountType: 'asset',
            normalBalance: 'debit',
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
            companyId: const Value(tenantId),
            description: const Value('system:inventory'),
          ),
        );

    await accDb.into(accDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '22222222-2222-2222-2222-222222222222',
            accountCode: '5100',
            name: 'COGS Account',
            accountType: 'expense',
            normalBalance: 'debit',
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
            companyId: const Value(tenantId),
            description: const Value('system:cost_of_goods'),
          ),
        );

    await accDb.into(accDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '33333333-3333-3333-3333-333333333333',
            accountCode: '2100',
            name: 'Payable Account',
            accountType: 'liability',
            normalBalance: 'credit',
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
            companyId: const Value(tenantId),
          ),
        );

    // Seed Product in Inventory
    await invDb.into(invDb.products).insert(
          ProductsCompanion.insert(
            uuid: generateUuidV4(),
            itemCode: itemCode,
            name: 'Reconciliation Test Item',
            companyId: const Value(tenantId),
            onHandQty: const Value(0.0),
            unitCost: const Value(0.0),
            price: 0.0,
            packSize: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ROOT FIX 27 — Inventory to General Ledger Reconciliation Full Suite', () {
    test('1. Receipt Sequence maintains Subledger == GL Valuation equality', () async {
      final receipt = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-27-01',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'rec-01',
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 100.0,
            unitCost: 15.0,
            totalCost: 1500.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );

      await stockRepo.saveReceipt(receipt);
      final result = await orchestrator.postReceipt(receipt: receipt);
      expect(result, isA<OrchestrationSuccess>());

      // Verify Reconciliation Subledger == GL Inventory Balance ($1,500.0)
      final report = await reconEngine.verifyReconciliationOrThrow(companyId: tenantId);
      expect(report.hasDiscrepancies, isFalse);
      expect(report.subledgerValuation, equals(1500.0));
      expect(report.glInventoryBalance, equals(1500.0));
      expect(report.valuationDiscrepancy, equals(0.0));
    });

    test('2. Issue Sequence maintains Subledger == GL Valuation equality', () async {
      // Step A: Post Receipt of 100 units @ $10.0 ($1,000 Total)
      final receipt = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-27-02',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'rec-02',
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 100.0,
            unitCost: 10.0,
            totalCost: 1000.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );
      await stockRepo.saveReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      // Step B: Post Issue of 40 units ($400 Cost of Goods Sold)
      final issue = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-27-01',
        destination: '22222222-2222-2222-2222-222222222222',
        accountId: '22222222-2222-2222-2222-222222222222',
        issueDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'iss-01',
            movementType: 'issue',
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 40.0,
            unitCost: 10.0,
            totalCost: 400.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );
      await stockRepo.saveIssue(issue);
      await orchestrator.postIssue(issue: issue);

      // Subledger remaining: 60 units @ $10 = $600
      // GL balance remaining: Debit $1,000 (Receipt) - Credit $400 (Issue) = $600
      final report = await reconEngine.verifyReconciliationOrThrow(companyId: tenantId);
      expect(report.hasDiscrepancies, isFalse);
      expect(report.subledgerValuation, equals(600.0));
      expect(report.glInventoryBalance, equals(600.0));
    });

    test('3. Stock Transfer maintains GL Inventory total valuation invariant', () async {
      // Step A: Stock Receipt of 50 units @ $20 = $1,000 in WH-A
      final recId = generateUuidV4();
      final receipt = StockReceipt(
        id: recId,
        receiptNumber: 'REC-27-TR',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        companyId: tenantId,
        warehouse: warehouseA,
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: recId,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 50.0,
            unitCost: 20.0,
            totalCost: 1000.0,
          ),
        ],
      );
      await stockRepo.saveReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      // Step B: Transfer 20 units from WH-A to WH-B
      final transferId = generateUuidV4();
      final transfer = StockTransfer(
        id: transferId,
        transferNumber: 'TR-27-01',
        fromWarehouseId: warehouseA,
        toWarehouseId: warehouseB,
        transferDate: DateTime.now().toUtc(),
        lines: [
          StockTransferLine(
            id: generateUuidV4(),
            transferUuid: transferId,
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 20.0,
            unitCost: 20.0,
            totalCost: 400.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );
      await transferRepo.saveTransfer(transfer);

      final refTr = InventoryDocumentRef(
        documentId: transferId,
        documentNumber: transfer.transferNumber,
        documentType: InventoryDocumentType.stockTransfer,
        documentDate: transfer.transferDate,
        warehouseId: warehouseA,
      );
      await coordinator.post(document: refTr);

      // Verify Total Subledger Valuation is still $1,000 across WH-A (30 @ $20) and WH-B (20 @ $20)
      final report = await reconEngine.verifyReconciliationOrThrow(companyId: tenantId);
      expect(report.hasDiscrepancies, isFalse);
      expect(report.subledgerValuation, equals(1000.0));
      expect(report.glInventoryBalance, equals(1000.0));
    });

    test('4. Reversal Sequence restores complete GL & Subledger balance without residual error', () async {
      // Step A: Post Receipt of 50 units @ $30 = $1,500
      final recId = generateUuidV4();
      final receipt = StockReceipt(
        id: recId,
        receiptNumber: 'REC-27-REV',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        companyId: tenantId,
        warehouse: warehouseA,
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: recId,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 50.0,
            unitCost: 30.0,
            totalCost: 1500.0,
          ),
        ],
      );
      await stockRepo.saveReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      // Step B: Post Issue of 20 units @ $30 = $600
      final issueId = generateUuidV4();
      final issueLineId = generateUuidV4();
      final issue = StockIssue(
        id: issueId,
        issueNumber: 'ISS-27-REV',
        destination: '22222222-2222-2222-2222-222222222222',
        accountId: '22222222-2222-2222-2222-222222222222',
        issueDate: DateTime.now().toUtc(),
        companyId: tenantId,
        warehouse: warehouseA,
        status: InventoryDocumentStatus.draft,
        lines: [
          StockMovementLine(
            id: issueLineId,
            movementUuid: issueId,
            movementType: 'issue',
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 20.0,
            unitCost: 30.0,
            totalCost: 600.0,
          ),
        ],
      );
      await stockRepo.saveIssue(issue);
      await orchestrator.postIssue(issue: issue);

      // Step C: Unpost Issue (Reversal) via Orchestrator
      final fetchedIssue = await stockRepo.getIssueById(issueId);
      final unpostResult = await orchestrator.unpostIssue(issue: fetchedIssue!);
      expect(unpostResult, isA<OrchestrationSuccess>());

      // Subledger restored: 50 units @ $30 = $1,500
      // GL balance restored: Receipt $1,500 - Issue $600 + Reversal $600 = $1,500
      final report = await reconEngine.verifyReconciliationOrThrow(companyId: tenantId);
      expect(report.hasDiscrepancies, isFalse);
      expect(report.subledgerValuation, equals(1500.0));
      expect(report.glInventoryBalance, equals(1500.0));
    });

    test('5. Exposed Inconsistency Failure: Unbalanced tampered GL state throws ReconciliationException', () async {
      // Step A: Post Receipt of 10 units @ $50 = $500
      final receipt = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-27-TAMP',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'rec-tamp',
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'Reconciliation Test Item',
            quantity: 10.0,
            unitCost: 50.0,
            totalCost: 500.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );
      await stockRepo.saveReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      // Tamper with GL line by altering debit amount to cause $100 inconsistency
      final jes = await accDb.select(accDb.journalEntries).get();
      final targetJe = jes.first;

      await (accDb.update(accDb.journalLines)..where((tbl) => tbl.entryUuid.equals(targetJe.uuid)))
          .write(const JournalLinesCompanion(debit: Value(400.0), baseDebit: Value(400.0)));

      // Invoking verifyReconciliationOrThrow MUST throw ReconciliationException without hiding differences
      expect(
        () async => await reconEngine.verifyReconciliationOrThrow(companyId: tenantId),
        throwsA(isA<ReconciliationException>()),
      );
    });

    test('6. Multi-tenant scoping: Reconciliation remains strictly isolated per tenant', () async {
      final reportTenant = await reconEngine.runReconciliation(companyId: tenantId);
      final reportForeign = await reconEngine.runReconciliation(companyId: 'company-foreign-99');

      expect(reportTenant.companyId, equals(tenantId));
      expect(reportForeign.companyId, equals('company-foreign-99'));
      expect(reportForeign.subledgerValuation, equals(0.0));
      expect(reportForeign.glInventoryBalance, equals(0.0));
      expect(reportForeign.hasDiscrepancies, isFalse);
    });
  });
}
