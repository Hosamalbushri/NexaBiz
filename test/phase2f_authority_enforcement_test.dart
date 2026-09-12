import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/shared/data/adapters/inventory_subledger_query_adapter.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/inventory_accounting_reconciliation_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase invDb;
  late AccountingDatabase accDb;
  const companyA = 'company-uuid-1111-aaaa';
  const companyB = 'company-uuid-2222-bbbb';

  const whUuidA = '11111111-1111-1111-1111-111111111111';
  const whUuidB = '22222222-2222-2222-2222-222222222222';

  Future<void> seedWarehouse(String uuid, String code, String companyId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await invDb.into(invDb.warehouses).insert(
      WarehousesCompanion.insert(
        uuid: uuid,
        name: 'Warehouse $code',
        code: code,
        companyId: Value(companyId),
        isDefault: const Value(true),
        isActive: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  setUp(() async {
    invDb = InventoryDatabase.memory();
    accDb = AccountingDatabase.memory();

    await seedWarehouse(whUuidA, 'WH-A', companyA);
    await seedWarehouse(whUuidB, 'WH-B', companyB);
  });

  tearDown(() async {
    await invDb.close();
    await accDb.close();
  });

  group('Phase 2F — Accounting & Inventory Authority Enforcement', () {
    test('1. Canonical Inventory Posting Authority creates stock ledger & cost layers', () async {
      final costLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => companyA,
      );
      final postingEngine = PostingEngineImpl(
        invDb,
        costLayerService,
        null,
        () => companyA,
      );

      final docRef = InventoryDocumentRef(
        documentId: '00000000-0000-0000-0000-000000000001',
        documentNumber: 'REC-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 1, 10),
        status: InventoryDocumentStatus.draft,
      );

      final lineData = InboundLineData(
        lineUuid: '00000000-0000-0000-0000-000000000011',
        itemCode: 'ITEM-001',
        itemName: 'Test Item 1',
        quantity: 100.0,
        unitCost: 25.0,
      );

      final totalValuation = await postingEngine.applyInboundPosting(
        document: docRef,
        lines: [lineData],
        warehouseId: whUuidA,
        documentDate: DateTime.utc(2026, 1, 10),
      );

      expect(totalValuation, equals(2500.0));

      // Verify stock movement ledger was written by PostingEngineImpl
      final ledgers = await (invDb.select(invDb.stockMovementLedgers)
            ..where((t) => t.companyId.equals(companyA)))
          .get();
      expect(ledgers.length, equals(1));
      expect(ledgers.first.movementType, equals('stock_receipt'));
      expect(ledgers.first.itemCode, equals('ITEM-001'));
      expect(ledgers.first.quantity, equals(100.0));
      expect(ledgers.first.unitCost, equals(25.0));

      // Verify cost layer was created by CostLayerServiceImpl
      final layers = await (invDb.select(invDb.inventoryCostLayers)
            ..where((t) => t.companyId.equals(companyA)))
          .get();
      expect(layers.length, equals(1));
      expect(layers.first.remainingQty, equals(100.0));
      expect(layers.first.unitCost, equals(25.0));

      // Verify warehouse stock was updated
      final stocks = await (invDb.select(invDb.productWarehouseStocks)
            ..where((t) => t.companyId.equals(companyA)))
          .get();
      expect(stocks.length, equals(1));
      expect(stocks.first.onHandQty, equals(100.0));
    });

    test('2. Canonical Outbound Posting consumes cost layers atomically', () async {
      final costLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => companyA,
      );
      final postingEngine = PostingEngineImpl(
        invDb,
        costLayerService,
        null,
        () => companyA,
      );

      // 1. Inbound receipt: 50 units @ $10
      await postingEngine.applyInboundPosting(
        document: InventoryDocumentRef(
          documentId: '00000000-0000-0000-0000-000000000002',
          documentNumber: 'REC-002',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.utc(2026, 1, 10),
          status: InventoryDocumentStatus.draft,
        ),
        lines: [
          InboundLineData(
            lineUuid: '00000000-0000-0000-0000-000000000012',
            itemCode: 'ITEM-002',
            itemName: 'Test Item 2',
            quantity: 50.0,
            unitCost: 10.0,
          ),
        ],
        warehouseId: whUuidA,
        documentDate: DateTime.utc(2026, 1, 10),
      );

      // 2. Outbound issue: 20 units
      final issueValuation = await postingEngine.applyOutboundPosting(
        document: InventoryDocumentRef(
          documentId: '00000000-0000-0000-0000-000000000003',
          documentNumber: 'ISS-001',
          documentType: InventoryDocumentType.stockIssue,
          documentDate: DateTime.utc(2026, 1, 12),
          status: InventoryDocumentStatus.draft,
        ),
        lines: [
          OutboundLineData(
            lineUuid: '00000000-0000-0000-0000-000000000013',
            itemCode: 'ITEM-002',
            itemName: 'Test Item 2',
            quantity: 20.0,
          ),
        ],
        warehouseId: whUuidA,
        valuationMethod: CostValuationMethod.fifo,
      );

      expect(issueValuation, equals(200.0)); // 20 * $10

      // Verify remaining layer qty is 30
      final layers = await (invDb.select(invDb.inventoryCostLayers)
            ..where((t) => t.companyId.equals(companyA)))
          .get();
      expect(layers.first.remainingQty, equals(30.0));

      // Verify warehouse stock is now 30
      final stocks = await (invDb.select(invDb.productWarehouseStocks)
            ..where((t) => t.companyId.equals(companyA)))
          .get();
      expect(stocks.first.onHandQty, equals(30.0));
    });

    test('3. Canonical Journal Posting Authority enforces tenant scoping & balancing', () async {
      final accountRepo = AccountRepositoryImpl(accDb, readCompanyId: () => companyA);
      final fiscalYearRepo = FiscalYearRepositoryImpl(accDb, readCompanyId: () => companyA);
      final periodValidator = AccountingPeriodValidator(
        repository: fiscalYearRepo,
        legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
      );
      final journalRepo = JournalRepositoryImpl(
        accDb,
        accounts: accountRepo,
        periodValidator: periodValidator,
        readCompanyId: () => companyA,
      );

      // Seed posting accounts for Company A with valid 36-character UUIDs
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await accDb.into(accDb.accounts).insert(AccountsCompanion.insert(
        uuid: '10000000-0000-0000-0000-000000001000',
        accountCode: '1000',
        name: 'Cash',
        accountType: 'asset',
        normalBalance: 'debit',
        isGroup: const Value(false),
        isActive: const Value(true),
        createdAt: nowMs,
        updatedAt: nowMs,
        companyId: const Value(companyA),
      ));
      await accDb.into(accDb.accounts).insert(AccountsCompanion.insert(
        uuid: '20000000-0000-0000-0000-000000002000',
        accountCode: '2000',
        name: 'Sales Revenue',
        accountType: 'revenue',
        normalBalance: 'credit',
        isGroup: const Value(false),
        isActive: const Value(true),
        createdAt: nowMs,
        updatedAt: nowMs,
        companyId: const Value(companyA),
      ));

      final draft = JournalEntryDraft(
        voucherNumber: 'JV-2026-001',
        voucherType: 'journal',
        entryDate: DateTime.utc(2026, 1, 15),
        currencyCode: 'USD',
        isPosted: true,
        lines: const [
          JournalLineDraft(
            accountUuid: '10000000-0000-0000-0000-000000001000',
            debit: 500.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          JournalLineDraft(
            accountUuid: '20000000-0000-0000-0000-000000002000',
            debit: 0.0,
            credit: 500.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final postedEntry = await journalRepo.post(draft);

      expect(postedEntry.uuid, isNotEmpty);
      expect(postedEntry.isPosted, isTrue);

      // Verify row in database is tenant-scoped to Company A
      final dbRow = await (accDb.select(accDb.journalEntries)
            ..where((t) => t.uuid.equals(postedEntry.uuid)))
          .getSingle();
      expect(dbRow.companyId, equals(companyA));
    });

    test('4. Missing company context in posting engine throws MissingCompanyContextException', () async {
      final costLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => '',
      );
      final postingEngine = PostingEngineImpl(
        invDb,
        costLayerService,
        null,
        () => '',
      );

      final docRef = InventoryDocumentRef(
        documentId: '00000000-0000-0000-0000-000000000099',
        documentNumber: 'REC-NC',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 1, 10),
        status: InventoryDocumentStatus.draft,
      );

      expect(
        () => postingEngine.applyInboundPosting(
          document: docRef,
          lines: [
            InboundLineData(
              lineUuid: '00000000-0000-0000-0000-000000000199',
              itemCode: 'ITEM-NC',
              itemName: 'No Company Item',
              quantity: 10.0,
              unitCost: 5.0,
            ),
          ],
          warehouseId: whUuidA,
          documentDate: DateTime.utc(2026, 1, 10),
        ),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('5. Reconciliation Engine verifies subledger valuation & GL inventory balance', () async {
      final subledgerQuery = InventorySubledgerQueryAdapter(
        inventoryDb: invDb,
      );
      final reconEngine = InventoryAccountingReconciliationEngine(
        inventorySubledgerQuery: subledgerQuery,
        accountingDb: accDb,
        readCompanyId: () => companyA,
      );

      // Seed 1 cost layer in Inventory (100 units @ $10 = $1000 valuation)
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await invDb.into(invDb.inventoryCostLayers).insert(InventoryCostLayersCompanion.insert(
        uuid: '33333333-3333-3333-3333-333333333333',
        itemCode: 'ITEM-RECON',
        warehouseId: Value(whUuidA),
        movementUuid: '44444444-4444-4444-4444-444444444444',
        movementType: 'receipt',
        receivedDate: nowMs,
        receivedQty: const Value(100.0),
        remainingQty: const Value(100.0),
        unitCost: const Value(10.0),
        inventoryCurrencyId: 'USD',
        documentCurrencyId: 'USD',
        createdAt: nowMs,
        updatedAt: nowMs,
        companyId: const Value(companyA),
      ));

      final valuation = await reconEngine.calculateSubledgerValuation();
      expect(valuation, equals(1000.0));

      final report = await reconEngine.runReconciliation();
      expect(report.companyId, equals(companyA));
      expect(report.subledgerValuation, equals(1000.0));
    });

    test('6. Dynamic tenant context switching in posting engine', () async {
      String currentCompany = companyA;
      final costLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => currentCompany,
      );
      final postingEngine = PostingEngineImpl(
        invDb,
        costLayerService,
        null,
        () => currentCompany,
      );

      // Post inbound for Company A
      currentCompany = companyA;
      await postingEngine.applyInboundPosting(
        document: InventoryDocumentRef(
          documentId: '55555555-5555-5555-5555-555555555555',
          documentNumber: 'REC-A',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.utc(2026, 1, 10),
          status: InventoryDocumentStatus.draft,
        ),
        lines: [
          InboundLineData(
            lineUuid: '55555555-5555-5555-5555-555555555551',
            itemCode: 'ITEM-COMP-A',
            itemName: 'Company A Item',
            quantity: 50.0,
            unitCost: 10.0,
          ),
        ],
        warehouseId: whUuidA,
        documentDate: DateTime.utc(2026, 1, 10),
      );

      // Switch context to Company B and post inbound
      currentCompany = companyB;
      await postingEngine.applyInboundPosting(
        document: InventoryDocumentRef(
          documentId: '66666666-6666-6666-6666-666666666666',
          documentNumber: 'REC-B',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.utc(2026, 1, 10),
          status: InventoryDocumentStatus.draft,
        ),
        lines: [
          InboundLineData(
            lineUuid: '66666666-6666-6666-6666-666666666661',
            itemCode: 'ITEM-COMP-B',
            itemName: 'Company B Item',
            quantity: 100.0,
            unitCost: 12.0,
          ),
        ],
        warehouseId: whUuidB,
        documentDate: DateTime.utc(2026, 1, 10),
      );

      // Query cost layers for Company A
      final layersA = await (invDb.select(invDb.inventoryCostLayers)
            ..where((t) => t.companyId.equals(companyA)))
          .get();
      expect(layersA.length, equals(1));
      expect(layersA.first.receivedQty, equals(50.0));

      // Query cost layers for Company B
      final layersB = await (invDb.select(invDb.inventoryCostLayers)
            ..where((t) => t.companyId.equals(companyB)))
          .get();
      expect(layersB.length, equals(1));
      expect(layersB.first.receivedQty, equals(100.0));
    });
  });
}
