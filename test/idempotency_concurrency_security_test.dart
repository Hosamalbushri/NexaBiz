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
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  late AccountRepositoryImpl accountRepo;
  late PostingCoordinatorImpl coordinator;
  late AccountingPeriodValidator validator;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;
  late DocumentPostingOrchestrator orchestrator;
  late AccountingEntryBuilder entryBuilder;
  late Directory tempDir;

  const tenantId = 'tenant-idempotency-05';

  Future<void> seedReceipt(StockReceipt receipt) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await invDb.into(invDb.stockReceipts).insert(
          StockReceiptsCompanion.insert(
            uuid: receipt.id,
            receiptNumber: receipt.receiptNumber,
            receiptDate: receipt.receiptDate.millisecondsSinceEpoch,
            supplier: Value(receipt.supplier),
            status: const Value('draft'),
            companyId: const Value(tenantId),
            createdAt: now,
            updatedAt: now,
          ),
        );

    for (final line in receipt.lines) {
      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: line.id,
              movementUuid: line.movementUuid,
              movementType: line.movementType,
              itemCode: line.itemCode,
              itemName: line.itemName,
              quantity: Value(line.quantity),
              unitCost: Value(line.unitCost),
              totalCost: Value(line.totalCost),
            ),
          );
    }
  }

  Future<void> seedIssue(StockIssue issue) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await invDb.into(invDb.stockIssues).insert(
          StockIssuesCompanion.insert(
            uuid: issue.id,
            issueNumber: issue.issueNumber,
            issueDate: issue.issueDate.millisecondsSinceEpoch,
            status: const Value('draft'),
            companyId: const Value(tenantId),
            createdAt: now,
            updatedAt: now,
          ),
        );

    for (final line in issue.lines) {
      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: line.id,
              movementUuid: line.movementUuid,
              movementType: line.movementType,
              itemCode: line.itemCode,
              itemName: line.itemName,
              quantity: Value(line.quantity),
              unitCost: Value(line.unitCost),
              totalCost: Value(line.totalCost),
            ),
          );
    }
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('idempotency_test_');
    Hive.init(tempDir.path);

    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();

    final validationService = StockValidationServiceImpl(invDb, () => tenantId);
    final depDetector = InventoryDependencyDetectorImpl(invDb);
    final costLayerService = CostLayerServiceImpl(db: invDb, readCompanyId: () => tenantId);
    final postingEngine = PostingEngineImpl(invDb, costLayerService, null, () => tenantId);

    coordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: validationService,
      dependencyDetector: depDetector,
      postingEngine: postingEngine,
      readCompanyId: () => tenantId,
    );

    accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => tenantId,
    );
    await accountRepo.seedDefaultChart();
    await accountRepo.ensureDefaultChartSeeded();

    validator = legacyPeriodValidator();
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

    final accountValidator = AccountValidationServiceImpl(accountRepo);
    final mappingResolver = AccountMappingResolverImpl(
      accountRepository: accountRepo,
      validationService: accountValidator,
    );

    entryBuilder = AccountingEntryBuilder(
      mappingResolver: mappingResolver,
      validationService: accountValidator,
    );

    orchestrator = DocumentPostingOrchestrator(
      postingCoordinator: coordinator,
      journalPostingService: journalPostingService,
      entryBuilder: entryBuilder,
    );

    // Create a product row
    await invDb.into(invDb.products).insert(
          ProductsCompanion.insert(
            uuid: '10000000-0000-0000-0000-000000000100',
            itemCode: 'ITEM-100',
            name: 'Idempotent Test Item',
            price: 25.0,
            packSize: 1,
            onHandQty: const Value(0.0),
            unitCost: const Value(15.0),
            companyId: const Value(tenantId),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
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

  group('ACCOUNTING INTEGRITY FIX 05 — Idempotency & Concurrency Security Test Suite', () {
    test('Test A — Same Request Twice (Sequential Idempotency)', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000a1';
      const lineUuid = '00000000-0000-0000-0000-0000000000b1';

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-SEQ-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 50.0,
            unitCost: 20.0,
            totalCost: 1000.0,
          ),
        ],
      );

      await seedReceipt(receipt);

      final res1 = await orchestrator.postReceipt(receipt: receipt);
      expect(res1, isA<OrchestrationSuccess>());

      final res2 = await orchestrator.postReceipt(receipt: receipt);
      expect(res2, isA<OrchestrationSuccess>());

      // Verify exactly ONE journal entry exists
      final headers = await journalRepo.listHeaders();
      expect(headers.length, equals(1));
      expect(headers.first.sourceId, equals(receiptUuid));

      // Verify exactly ONE cost layer exists
      final layers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(layers.length, equals(1));
      expect(layers.first.receivedQty, equals(50.0));
    });

    test('Test B — Concurrent Posting Race Condition Protection', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000a2';
      const lineUuid = '00000000-0000-0000-0000-0000000000b2';

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-CONC-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 100.0,
            unitCost: 15.0,
            totalCost: 1500.0,
          ),
        ],
      );

      await seedReceipt(receipt);

      // Execute 5 concurrent posting requests simultaneously
      final futures = List.generate(5, (_) => orchestrator.postReceipt(receipt: receipt));
      final results = await Future.wait(futures);

      for (final r in results) {
        expect(r, isA<OrchestrationSuccess>());
      }

      // Verify exactly ONE journal entry was created
      final headers = await journalRepo.listHeaders();
      expect(headers.length, equals(1));

      // Verify exactly ONE cost layer was created
      final layers = await invDb.select(invDb.inventoryCostLayers).get();
      expect(layers.length, equals(1));

      // Verify product on-hand quantity increased by 100.0 exactly ONCE
      final prod = await (invDb.select(invDb.products)
            ..where((tbl) => tbl.itemCode.equals('ITEM-100')))
          .getSingle();
      expect(prod.onHandQty, equals(100.0));
    });

    test('Test C — Network Retry Safety', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000a3';
      const lineUuid = '00000000-0000-0000-0000-0000000000b3';

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-RETRY-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 20.0,
            unitCost: 10.0,
            totalCost: 200.0,
          ),
        ],
      );

      await seedReceipt(receipt);

      // First posting succeeds on server
      final res1 = await orchestrator.postReceipt(receipt: receipt);
      expect(res1, isA<OrchestrationSuccess>());

      // Client network connection dropped before receiving response — client retries
      final res2 = await orchestrator.postReceipt(receipt: receipt);
      expect(res2, isA<OrchestrationSuccess>());

      final headers = await journalRepo.listHeaders();
      expect(headers.length, equals(1));
    });

    test('Test D — Duplicate Inventory Issue Quantity Protection', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000a4';
      const lineInUuid = '00000000-0000-0000-0000-0000000000b4';
      const issueUuid = '00000000-0000-0000-0000-0000000000c4';
      const lineOutUuid = '00000000-0000-0000-0000-0000000000d4';

      // 1. Inbound receipt of 100 units
      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-QTY-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineInUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 100.0,
            unitCost: 15.0,
            totalCost: 1500.0,
          ),
        ],
      );
      await seedReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      // Verify on-hand = 100
      var prod = await (invDb.select(invDb.products)..where((tbl) => tbl.itemCode.equals('ITEM-100'))).getSingle();
      expect(prod.onHandQty, equals(100.0));

      // 2. Outbound issue of 10 units
      final issue = StockIssue(
        id: issueUuid,
        issueNumber: 'ISS-QTY-001',
        issueDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineOutUuid,
            movementUuid: issueUuid,
            movementType: 'stock_issue',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 10.0,
            unitCost: 15.0,
            totalCost: 150.0,
          ),
        ],
      );
      await seedIssue(issue);

      // Post issue TWICE
      await orchestrator.postIssue(issue: issue);
      await orchestrator.postIssue(issue: issue);

      // Verify on-hand = 90.0 (NOT 80.0)
      prod = await (invDb.select(invDb.products)..where((tbl) => tbl.itemCode.equals('ITEM-100'))).getSingle();
      expect(prod.onHandQty, equals(90.0));
    });

    test('Test E — Duplicate COGS Accounting Protection', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000a5';
      const lineInUuid = '00000000-0000-0000-0000-0000000000b5';
      const issueUuid = '00000000-0000-0000-0000-0000000000c5';
      const lineOutUuid = '00000000-0000-0000-0000-0000000000d5';

      // Inbound 100 @ 15 = 1500
      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-COGS-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineInUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 100.0,
            unitCost: 15.0,
            totalCost: 1500.0,
          ),
        ],
      );
      await seedReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      // Issue 10 units -> COGS should be 150.0
      final issue = StockIssue(
        id: issueUuid,
        issueNumber: 'ISS-COGS-001',
        issueDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineOutUuid,
            movementUuid: issueUuid,
            movementType: 'stock_issue',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 10.0,
            unitCost: 15.0,
            totalCost: 150.0,
          ),
        ],
      );
      await seedIssue(issue);

      // Post issue twice
      await orchestrator.postIssue(issue: issue);
      await orchestrator.postIssue(issue: issue);

      // Check journal entries for stock_issue
      final issueJournals = accDb.select(accDb.journalEntries)
        ..where((tbl) => tbl.sourceType.equals('stock_issue') & tbl.sourceId.equals(issueUuid));
      final rows = await issueJournals.get();
      expect(rows.length, equals(1));

      // Verify COGS line debit total equals 150.0 (NOT 300.0)
      final lines = accDb.select(accDb.journalLines)
        ..where((tbl) => tbl.entryUuid.equals(rows.first.uuid));
      final lineRows = await lines.get();
      final totalDebit = lineRows.fold<double>(0.0, (sum, l) => sum + l.debit);
      expect(totalDebit, equals(150.0));
    });

    test('Test F — Duplicate Cost Consumption Record Protection', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000a6';
      const lineInUuid = '00000000-0000-0000-0000-0000000000b6';
      const issueUuid = '00000000-0000-0000-0000-0000000000c6';
      const lineOutUuid = '00000000-0000-0000-0000-0000000000d6';

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-CONS-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineInUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 50.0,
            unitCost: 10.0,
            totalCost: 500.0,
          ),
        ],
      );
      await seedReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      final issue = StockIssue(
        id: issueUuid,
        issueNumber: 'ISS-CONS-001',
        issueDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineOutUuid,
            movementUuid: issueUuid,
            movementType: 'stock_issue',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 5.0,
            unitCost: 10.0,
            totalCost: 50.0,
          ),
        ],
      );
      await seedIssue(issue);

      // Post twice
      await orchestrator.postIssue(issue: issue);
      await orchestrator.postIssue(issue: issue);

      final consumptions = invDb.select(invDb.inventoryCostConsumptions)
        ..where((tbl) => tbl.issueLineUuid.equals(lineOutUuid));
      final rows = await consumptions.get();

      // Verify exactly ONE consumption record exists for this issue line
      expect(rows.length, equals(1));
      expect(rows.first.consumedQty, equals(5.0));
    });

    test('Test G — Concurrent Reversal Idempotency', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000a7';
      const lineUuid = '00000000-0000-0000-0000-0000000000b7';

      // 1. Post a stock receipt
      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-REV-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 20.0,
            unitCost: 25.0,
            totalCost: 500.0,
          ),
        ],
      );
      await seedReceipt(receipt);
      await orchestrator.postReceipt(receipt: receipt);

      final postedJournal = await journalRepo.findBySource(
        sourceType: 'stock_receipt',
        sourceId: receiptUuid,
      );
      expect(postedJournal, isNotNull);

      // 2. Execute 5 concurrent reversal requests
      final futures = List.generate(
        5,
        (_) => journalPostingService.reverseByUuid(postedJournal!.uuid),
      );
      final reversals = await Future.wait(futures);

      // Verify all 5 concurrent calls returned the EXACT same reversal entry UUID
      final firstUuid = reversals.first.uuid;
      for (final r in reversals) {
        expect(r.uuid, equals(firstUuid));
      }

      // Verify exactly ONE reversal journal entry exists in DB
      final allReversals = accDb.select(accDb.journalEntries)
        ..where((tbl) => tbl.sourceType.equals(JournalPostingService.reverseSourceType) & tbl.sourceId.equals(postedJournal!.uuid));
      final revRows = await allReversals.get();
      expect(revRows.length, equals(1));
    });

    test('Test H — Multi-Tenant Idempotency Keying Scoped to Company', () async {
      const companyA = 'tenant-company-A';
      const companyB = 'tenant-company-B';

      final dbA = AccountingDatabase.memory();
      final dbB = AccountingDatabase.memory();

      final accountRepoA = AccountRepositoryImpl(dbA, readCompanyId: () => companyA);
      await accountRepoA.seedDefaultChart();
      final journalRepoA = JournalRepositoryImpl(dbA, accounts: accountRepoA, periodValidator: validator, readCompanyId: () => companyA);

      final accountRepoB = AccountRepositoryImpl(dbB, readCompanyId: () => companyB);
      await accountRepoB.seedDefaultChart();
      final journalRepoB = JournalRepositoryImpl(dbB, accounts: accountRepoB, periodValidator: validator, readCompanyId: () => companyB);

      const sourceDocId = '00000000-0000-0000-0000-0000000000h1';

      final accountsA = (await dbA.select(dbA.accounts).get()).where((a) => !a.isGroup && a.isActive).toList();
      final acc1 = accountsA[0].uuid;
      final acc2 = accountsA[1].uuid;

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 30),
        voucherNumber: 'V-SAME-100',
        voucherType: 'مبيعات',
        currencyCode: 'SAR',
        description: 'Multi-tenant test',
        sourceType: 'sale',
        sourceId: sourceDocId,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 100, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 100, currencyCode: 'SAR'),
        ],
      );

      // Post in Company A
      final entryA = await journalRepoA.post(draft);

      // Post same sourceId in Company B -> MUST succeed independently without conflict
      final entryB = await journalRepoB.post(draft);
      expect(entryB.uuid, isNot(equals(entryA.uuid)));

      // Lookup in Company A returns ONLY Company A's entry
      final lookupA = await journalRepoA.findBySource(sourceType: 'sale', sourceId: sourceDocId);
      expect(lookupA!.uuid, equals(entryA.uuid));

      await dbA.close();
      await dbB.close();
    });

    test('Test I — Database Unique Constraint Conflict Recovery', () async {
      const sourceDocId = '00000000-0000-0000-0000-0000000000i1';

      final accounts = (await accDb.select(accDb.accounts).get()).where((a) => !a.isGroup && a.isActive).toList();
      final acc1 = accounts[0].uuid;
      final acc2 = accounts[1].uuid;

      final draft1 = JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 30),
        voucherNumber: 'V-DB-001',
        voucherType: 'مشتريات',
        currencyCode: 'SAR',
        sourceType: 'purchase',
        sourceId: sourceDocId,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 500, currencyCode: 'SAR'),
        ],
      );

      // Thread A posts
      final resA = await journalRepo.post(draft1);

      // Thread B attempts to post identical sourceType & sourceId with a different voucher number
      final draft2 = JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 30),
        voucherNumber: 'V-DB-002-DUPLICATE',
        voucherType: 'مشتريات',
        currencyCode: 'SAR',
        sourceType: 'purchase',
        sourceId: sourceDocId,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 500, currencyCode: 'SAR'),
        ],
      );

      // Must recover gracefully by returning Thread A's existing entry
      final resB = await journalRepo.post(draft2);
      expect(resB.uuid, equals(resA.uuid));
    });

    test('Test J — App Restart & State Persistence Idempotency', () async {
      const receiptUuid = '00000000-0000-0000-0000-0000000000j1';
      const lineUuid = '00000000-0000-0000-0000-0000000000j2';

      final receipt = StockReceipt(
        id: receiptUuid,
        receiptNumber: 'REC-RST-001',
        receiptDate: DateTime.utc(2026, 8, 30),
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'ITEM-100',
            itemName: 'Idempotent Test Item',
            quantity: 30.0,
            unitCost: 10.0,
            totalCost: 300.0,
          ),
        ],
      );

      await seedReceipt(receipt);

      // Post initial receipt before process restart
      final res1 = await orchestrator.postReceipt(receipt: receipt);
      expect(res1, isA<OrchestrationSuccess>());

      // Simulate App Restart by instantiating new repository & orchestrator instances over the same DBs
      final newAccountRepo = AccountRepositoryImpl(accDb, readCompanyId: () => tenantId);
      final newJournalRepo = JournalRepositoryImpl(accDb, accounts: newAccountRepo, periodValidator: validator, readCompanyId: () => tenantId);
      final newJournalPostingService = JournalPostingService(journals: newJournalRepo, periodValidator: validator);
      final newCoordinator = PostingCoordinatorImpl(
        db: invDb,
        stockValidationService: StockValidationServiceImpl(invDb),
        dependencyDetector: InventoryDependencyDetectorImpl(invDb),
        postingEngine: PostingEngineImpl(invDb, CostLayerServiceImpl(db: invDb, readCompanyId: () => tenantId), null, () => tenantId),
        readCompanyId: () => tenantId,
      );

      final accountValidator = AccountValidationServiceImpl(newAccountRepo);
      final mappingResolver = AccountMappingResolverImpl(accountRepository: newAccountRepo, validationService: accountValidator);
      final newEntryBuilder = AccountingEntryBuilder(mappingResolver: mappingResolver, validationService: accountValidator);

      final newOrchestrator = DocumentPostingOrchestrator(
        postingCoordinator: newCoordinator,
        journalPostingService: newJournalPostingService,
        entryBuilder: newEntryBuilder,
      );

      // Post receipt AGAIN after restart
      final res2 = await newOrchestrator.postReceipt(receipt: receipt);
      expect(res2, isA<OrchestrationSuccess>());

      // Verify DB still contains exactly ONE journal entry
      final headers = await newJournalRepo.listHeaders();
      expect(headers.length, equals(1));
    });
  });
}
