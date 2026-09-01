import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/document_posting_orchestrator.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/inventory_accounting_reconciliation_engine.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';

import 'helpers/journal_posting_test_helper.dart';

class FailingJournalPostingService extends JournalPostingService {
  FailingJournalPostingService({required super.journals, required super.periodValidator});

  @override
  Future<JournalEntry> post(JournalEntryDraft draft, {String? userId}) async {
    throw StateError('CRITICAL_ACCOUNTING_FAILURE: Database connection lost or period closed');
  }

  @override
  Future<void> voidBySource({required String sourceType, required String sourceId}) async {}
}

void main() {
  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late StockMovementsRepositoryImpl stockRepo;
  late PostingCoordinatorImpl coordinator;
  late AccountingPeriodValidator validator;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;
  late DocumentPostingOrchestrator orchestrator;
  late InventoryAccountingReconciliationEngine reconEngine;
  late AccountingEntryBuilder entryBuilder;
  late Directory tempDir;

  const tenantId = 'company-test-04';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recon_test_');
    Hive.init(tempDir.path);

    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();

    stockRepo = StockMovementsRepositoryImpl(
      db: invDb,
      readCompanyId: () => tenantId,
    );

    final validationService = StockValidationServiceImpl(invDb);
    final depDetector = InventoryDependencyDetectorImpl(invDb);
    final costLayerService = CostLayerServiceImpl(db: invDb);
    final postingEngine = PostingEngineImpl(invDb, costLayerService, null, () => tenantId);

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: validationService,
      dependencyDetector: depDetector,
      postingEngine: postingEngine,
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
            name: 'Inventory Account',
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

    // Seed a product in inventory
    await invDb.into(invDb.products).insert(
          ProductsCompanion.insert(
            uuid: '44444444-4444-4444-4444-444444444444',
            itemCode: 'ITEM01',
            name: 'Widget A',
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

  group('ACCOUNTING INTEGRITY FIX 04 — Failure Injection & Compensation Safety', () {
    test('Test 1: Accounting failure triggers inventory compensation rollback to draft', () async {
      final failingOrchestrator = DocumentPostingOrchestrator(
        postingCoordinator: coordinator,
        journalPostingService: FailingJournalPostingService(
          journals: journalRepo,
          periodValidator: validator,
        ),
        entryBuilder: entryBuilder,
      );

      final receipt = StockReceipt(
        id: '55555555-5555-5555-5555-555555555555',
        receiptNumber: 'REC-FAIL-01',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: '55555555-5555-5555-5555-55555555555a',
            movementUuid: '55555555-5555-5555-5555-555555555555',
            movementType: 'receipt',
            itemCode: 'ITEM01',
            itemName: 'Widget A',
            quantity: 10.0,
            unitCost: 50.0,
            totalCost: 500.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );

      await stockRepo.saveReceipt(receipt);

      final result = await failingOrchestrator.postReceipt(receipt: receipt);

      expect(result, isA<OrchestrationFailure>());
      final failure = result as OrchestrationFailure;
      expect(failure.reason, contains('CRITICAL_ACCOUNTING_FAILURE'));

      // Verify Inventory status was safely compensated back to 'draft'
      final dbReceipt = await stockRepo.getReceiptById('55555555-5555-5555-5555-555555555555');
      expect(dbReceipt?.status, equals(InventoryDocumentStatus.draft));

      // Verify Product onHandQty remains 0 (not falsely increased)
      final prod = await (invDb.select(invDb.products)..where((tbl) => tbl.itemCode.equals('ITEM01'))).getSingle();
      expect(prod.onHandQty, equals(0.0));
    });

    test('Test 2: Outbound shortage blocks accounting journal creation', () async {
      final issue = StockIssue(
        id: '66666666-6666-6666-6666-666666666666',
        issueNumber: 'ISS-SHORT-01',
        destination: '22222222-2222-2222-2222-222222222222',
        accountId: '22222222-2222-2222-2222-222222222222',
        issueDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: '66666666-6666-6666-6666-66666666666a',
            movementUuid: '66666666-6666-6666-6666-666666666666',
            movementType: 'issue',
            itemCode: 'ITEM01',
            itemName: 'Widget A',
            quantity: 50.0, // Requested 50 when on-hand is 0
            unitCost: 50.0,
            totalCost: 2500.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );

      await stockRepo.saveIssue(issue);

      final result = await orchestrator.postIssue(issue: issue);

      expect(result, isA<OrchestrationFailure>());

      // Assert zero journal entries in Accounting DB
      final jes = await accDb.select(accDb.journalEntries).get();
      expect(jes.isEmpty, isTrue);
    });

    test('Test 3: Idempotent double-posting produces single economic and accounting effect', () async {
      final receipt = StockReceipt(
        id: '77777777-7777-7777-7777-777777777777',
        receiptNumber: 'REC-IDEM-01',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: '77777777-7777-7777-7777-77777777777a',
            movementUuid: '77777777-7777-7777-7777-777777777777',
            movementType: 'receipt',
            itemCode: 'ITEM01',
            itemName: 'Widget A',
            quantity: 20.0,
            unitCost: 100.0,
            totalCost: 2000.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );

      await stockRepo.saveReceipt(receipt);

      final res1 = await orchestrator.postReceipt(receipt: receipt);
      expect(res1, isA<OrchestrationSuccess>());

      // Attempt second post on already posted receipt
      final res2 = await orchestrator.postReceipt(receipt: receipt);
      expect(res2, isA<OrchestrationSuccess>());

      // Verify product onHandQty is 20.0 (not 40.0)
      final prod = await (invDb.select(invDb.products)..where((tbl) => tbl.itemCode.equals('ITEM01'))).getSingle();
      expect(prod.onHandQty, equals(20.0));

      // Verify exactly ONE active journal entry exists for this source document
      final jes = await (accDb.select(accDb.journalEntries)
            ..where((tbl) => tbl.sourceId.equals('77777777-7777-7777-7777-777777777777') & tbl.deletedAt.isNull()))
          .get();
      expect(jes.length, equals(1));
    });

    test('Test 4: Reconciliation Engine detects missing journal entry for posted inventory doc', () async {
      // Manually force a posted receipt without journal entry
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await invDb.into(invDb.stockReceipts).insert(
            StockReceiptsCompanion.insert(
              uuid: '88888888-8888-8888-8888-888888888888',
              receiptNumber: 'REC-UNREC-01',
              receiptDate: now,
              createdAt: now,
              updatedAt: now,
              status: const Value('posted'),
              companyId: const Value(tenantId),
            ),
          );

      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: '88888888-8888-8888-8888-88888888888a',
              movementUuid: '88888888-8888-8888-8888-888888888888',
              movementType: 'receipt',
              itemCode: 'ITEM01',
              itemName: 'Widget A',
              quantity: const Value(5.0),
              unitCost: const Value(10.0),
              totalCost: const Value(50.0),
            ),
          );

      final report = await reconEngine.runReconciliation(companyId: tenantId);

      expect(report.hasDiscrepancies, isTrue);
      expect(report.discrepancies.first.issueType, equals(ReconciliationIssueType.missingJournalEntry));
      expect(report.discrepancies.first.documentNumber, equals('REC-UNREC-01'));
    });

    test('Test 5: Reconciliation Engine detects value mismatch between subledger and GL', () async {
      final receipt = StockReceipt(
        id: '99999999-9999-9999-9999-999999999999',
        receiptNumber: 'REC-VAL-01',
        supplier: '33333333-3333-3333-3333-333333333333',
        accountId: '33333333-3333-3333-3333-333333333333',
        receiptDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            id: '99999999-9999-9999-9999-99999999999a',
            movementUuid: '99999999-9999-9999-9999-999999999999',
            movementType: 'receipt',
            itemCode: 'ITEM01',
            itemName: 'Widget A',
            quantity: 10.0,
            unitCost: 100.0,
            totalCost: 1000.0,
          ),
        ],
        status: InventoryDocumentStatus.draft,
        companyId: tenantId,
      );

      await stockRepo.saveReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      // Tamper with journal lines debit amount to cause a $200 discrepancy
      final je = await (accDb.select(accDb.journalEntries)
            ..where((tbl) => tbl.sourceId.equals('99999999-9999-9999-9999-999999999999')))
          .getSingle();

      await (accDb.update(accDb.journalLines)..where((tbl) => tbl.entryUuid.equals(je.uuid)))
          .write(const JournalLinesCompanion(debit: Value(800.0), baseDebit: Value(800.0)));

      final report = await reconEngine.runReconciliation(companyId: tenantId);

      expect(report.hasDiscrepancies, isTrue);
      expect(report.discrepancies.any((d) => d.issueType == ReconciliationIssueType.valueMismatch), isTrue);
    });

    test('Test 6: Reconciliation Engine respects multi-tenant scoping', () async {
      final report = await reconEngine.runReconciliation(companyId: 'other-company-tenant');

      expect(report.scannedDocumentCount, equals(0));
      expect(report.hasDiscrepancies, isFalse);
    });
  });
}
