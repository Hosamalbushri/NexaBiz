import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';

import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_base_amount_resolver.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency_rate.dart';

import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

import 'package:stock_count/app/sales/accounting_sale_ledger_adapter.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;
  late CurrencyRateRepositoryImpl rateRepo;
  late Directory tempDir;

  late InventoryDatabase invDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;

  late String companyId;
  late String cashAccountUuid;
  late String salesAccountUuid;
  late String arAccountUuid;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fx_test_');
    Hive.init(tempDir.path);

    companyId = 'company_fx_test';

    db = AccountingDatabase(executor: NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(
      db,
      readCompanyId: () => companyId,
    );
    rateRepo = CurrencyRateRepositoryImpl(
      db,
      readCompanyId: () => companyId,
    );
    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      rates: rateRepo,
      readCompanyId: () => companyId,
    );
    postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: legacyPeriodValidator(),
    );

    invDb = InventoryDatabase(executor: NativeDatabase.memory());
    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => companyId,
    );
    postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => companyId,
    );

    cashAccountUuid = generateUuidV4();
    salesAccountUuid = generateUuidV4();
    arAccountUuid = generateUuidV4();

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Seed Accounts
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: cashAccountUuid,
            companyId: Value(companyId),
            accountCode: '1010',
            name: 'Cash Account',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: arAccountUuid,
            companyId: Value(companyId),
            accountCode: '1110',
            name: 'AR Customer Account',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: salesAccountUuid,
            companyId: Value(companyId),
            accountCode: '4100',
            name: 'Sales Revenue',
            accountType: 'revenue',
            normalBalance: 'credit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );
  });

  tearDown(() async {
    await db.close();
    await invDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ROOT FIX 13 — Historical FX Integrity Suite', () {
    test('1. Posted Journal Entry retains historical exchange rate when current rate changes', () async {
      const historicalRate = 3.75;
      final entryDate = DateTime.now().subtract(const Duration(days: 90));

      // 1. Seed rate of 3.75 on that historical date
      await rateRepo.upsert(
        CurrencyRateDraft(
          currencyCode: 'USD',
          rateToBase: historicalRate,
          asOfDate: entryDate,
        ),
      );

      // 2. Post Journal Entry in USD
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-FX-01',
        voucherType: 'journal',
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        description: 'Historical FX entry',
        isPosted: true,
        entryDate: entryDate,
        lines: [
          JournalLineDraft(
            accountUuid: cashAccountUuid,
            debit: 100,
            credit: 0,
            currencyCode: 'USD',
            exchangeRateToBase: historicalRate,
            baseDebit: 375,
            baseCredit: 0,
          ),
          JournalLineDraft(
            accountUuid: salesAccountUuid,
            debit: 0,
            credit: 100,
            currencyCode: 'USD',
            exchangeRateToBase: historicalRate,
            baseDebit: 0,
            baseCredit: 375,
          ),
        ],
      );

      final posted = await postingService.post(draft);
      expect(posted.isPosted, isTrue);

      // 3. Update current FX rate to 5.00 today
      await rateRepo.upsert(
        CurrencyRateDraft(
          currencyCode: 'USD',
          rateToBase: 5.00,
          asOfDate: DateTime.now(),
        ),
      );

      // 4. Fetch the historical entry from DB and verify rate & base amounts remain intact
      final fetched = await journalRepo.getByUuid(posted.uuid);
      expect(fetched, isNotNull);
      final line1 = fetched!.lines.firstWhere((l) => l.accountUuid == cashAccountUuid);
      expect(line1.exchangeRateToBase, equals(historicalRate));
      expect(line1.baseDebit, equals(375.0));
      expect(line1.debit, equals(100.0));

      final line2 = fetched.lines.firstWhere((l) => l.accountUuid == salesAccountUuid);
      expect(line2.exchangeRateToBase, equals(historicalRate));
      expect(line2.baseCredit, equals(375.0));
      expect(line2.credit, equals(100.0));
    });

    test('2. Sales Ledger Adapter passes explicit historical exchange rate to journal entry', () async {
      const historicalRate = 3.75;
      final saleDate = DateTime.now().subtract(const Duration(days: 30));

      final saleAdapter = AccountingSaleLedgerAdapter(
        posting: postingService,
        accounts: accountRepo,
      );

      final sale = Sale(
        id: 1,
        uuid: generateUuidV4(),
        saleNumber: 'INV-FX-101',
        saleDate: saleDate,
        settlementType: SaleSettlementType.credit,
        customerAccountId: arAccountUuid,
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        exchangeRate: historicalRate,
        items: const [],
        payments: const [],
        subtotal: 200,
        itemDiscountTotal: 0,
        discountType: DiscountType.fixed,
        discountValue: 0,
        discountAmount: 0,
        taxRate: 0,
        taxAmount: 0,
        total: 200,
        paidAmount: 0,
        remainingAmount: 200,
        paymentStatus: PaymentStatus.unpaid,
        paymentMethod: PaymentMethod.cash,
        saleStatus: SaleStatus.posted,
        dataSource: SaleDataSource.local,
        createdAt: saleDate,
        updatedAt: saleDate,
      );

      await saleAdapter.syncSale(sale);

      // Change rate to 5.50 today
      await rateRepo.upsert(
        CurrencyRateDraft(
          currencyCode: 'USD',
          rateToBase: 5.50,
          asOfDate: DateTime.now(),
        ),
      );

      final entry = await journalRepo.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );

      expect(entry, isNotNull);
      expect(entry!.isPosted, isTrue);

      final arLine = entry.lines.firstWhere((l) => l.accountUuid == arAccountUuid);
      expect(arLine.exchangeRateToBase, equals(historicalRate));
      expect(arLine.baseDebit, equals(750.0)); // 200 * 3.75

      final revenueLine = entry.lines.firstWhere((l) => l.accountUuid == salesAccountUuid);
      expect(revenueLine.exchangeRateToBase, equals(historicalRate));
      expect(revenueLine.baseCredit, equals(750.0)); // 200 * 3.75
    });

    test('3. Reversal entry preserves original exchange rate when current rate changes', () async {
      const originalRate = 3.75;
      final entryDate = DateTime.now().subtract(const Duration(days: 45));

      final draft = JournalEntryDraft(
        voucherNumber: 'JE-REV-FX',
        voucherType: 'journal',
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        description: 'Original entry for reversal test',
        isPosted: true,
        entryDate: entryDate,
        lines: [
          JournalLineDraft(
            accountUuid: cashAccountUuid,
            debit: 500,
            credit: 0,
            currencyCode: 'USD',
            exchangeRateToBase: originalRate,
            baseDebit: 1875,
            baseCredit: 0,
          ),
          JournalLineDraft(
            accountUuid: salesAccountUuid,
            debit: 0,
            credit: 500,
            currencyCode: 'USD',
            exchangeRateToBase: originalRate,
            baseDebit: 0,
            baseCredit: 1875,
          ),
        ],
      );

      final original = await postingService.post(draft);

      // Drastically change FX rate today
      await rateRepo.upsert(
        CurrencyRateDraft(
          currencyCode: 'USD',
          rateToBase: 6.20,
          asOfDate: DateTime.now(),
        ),
      );

      // Perform reversal
      final reversal = await postingService.reverseByUuid(original.uuid);

      // Check that reversal uses original exchange rate (3.75) and original base amounts (1875)
      final revCashLine = reversal.lines.firstWhere((l) => l.accountUuid == cashAccountUuid);
      expect(revCashLine.exchangeRateToBase, equals(originalRate));
      expect(revCashLine.credit, equals(500.0));
      expect(revCashLine.baseCredit, equals(1875.0));

      final revSalesLine = reversal.lines.firstWhere((l) => l.accountUuid == salesAccountUuid);
      expect(revSalesLine.exchangeRateToBase, equals(originalRate));
      expect(revSalesLine.debit, equals(500.0));
      expect(revSalesLine.baseDebit, equals(1875.0));
    });

    test('4. Inventory cost layer locks foreign receipt exchange rate into base unit cost', () async {
      const receiptRate = 4.00;
      const foreignUnitCost = 50.0; // 50 USD
      const qty = 10.0;
      const itemCode = 'ITEM-FX-LAYER';
      const warehouseId = 'WH-MAIN';
      final receiptDate = DateTime.now().subtract(const Duration(days: 30));

      final receiptDoc = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'REC-FX-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receiptDate,
        warehouseId: warehouseId,
        currencyCode: 'USD',
        exchangeRate: receiptRate,
      );

      // Post inbound stock receipt
      await postingEngine.applyInboundPosting(
        document: receiptDoc,
        lines: [
          InboundLineData(
            lineUuid: generateUuidV4(),
            itemCode: itemCode,
            itemName: 'FX Item',
            quantity: qty,
            unitCost: foreignUnitCost,
          ),
        ],
        warehouseId: warehouseId,
        documentDate: receiptDate,
      );

      // Verify layer unitCost is locked in base currency: 50 USD * 4.00 = 200 SAR
      var openLayers = await costLayerService.getOpenLayers(itemCode, warehouseId: warehouseId);
      expect(openLayers.length, equals(1));
      expect(openLayers.single.unitCost, equals(200.0));

      // Change today's exchange rate for USD to 6.00
      await rateRepo.upsert(
        CurrencyRateDraft(
          currencyCode: 'USD',
          rateToBase: 6.00,
          asOfDate: DateTime.now(),
        ),
      );

      // Post outbound issue today consuming 4 units
      final issueDoc = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'ISS-FX-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: warehouseId,
      );

      final issueResult = await postingEngine.applyOutboundPosting(
        document: issueDoc,
        lines: [
          OutboundLineData(
            lineUuid: generateUuidV4(),
            itemCode: itemCode,
            itemName: 'FX Item',
            quantity: 4.0,
          ),
        ],
        warehouseId: warehouseId,
        valuationMethod: CostValuationMethod.fifo,
      );

      // 4 units @ 200 SAR = 800 SAR total COGS in base currency
      expect(issueResult, equals(800.0));
    });

    test('5. JournalBaseAmountResolver resolves historical rate from date history correctly', () async {
      final janDate = DateTime.utc(2026, 1, 15);
      final junDate = DateTime.utc(2026, 6, 15);
      final julDate = DateTime.utc(2026, 7, 15);

      // Seed historical rate history
      await rateRepo.upsert(
        CurrencyRateDraft(
          currencyCode: 'EUR',
          rateToBase: 3.50,
          asOfDate: janDate,
        ),
      );

      await rateRepo.upsert(
        CurrencyRateDraft(
          currencyCode: 'EUR',
          rateToBase: 3.80,
          asOfDate: junDate,
        ),
      );

      final resolver = JournalBaseAmountResolver(rateRepo);

      // Resolve for March 2026 -> should pick 3.50 (latest rate on or before March)
      final marchLines = await resolver.resolve(
        entryDate: DateTime.utc(2026, 3, 1),
        baseCurrencyCode: 'SAR',
        lines: [
          JournalLineDraft(
            accountUuid: cashAccountUuid,
            debit: 100,
            credit: 0,
            currencyCode: 'EUR',
          ),
        ],
      );
      expect(marchLines.single.exchangeRateToBase, equals(3.50));
      expect(marchLines.single.baseDebit, equals(350.0));

      // Resolve for July 2026 -> should pick 3.80 (latest rate on or before July)
      final julyLines = await resolver.resolve(
        entryDate: julDate,
        baseCurrencyCode: 'SAR',
        lines: [
          JournalLineDraft(
            accountUuid: cashAccountUuid,
            debit: 100,
            credit: 0,
            currencyCode: 'EUR',
          ),
        ],
      );
      expect(julyLines.single.exchangeRateToBase, equals(3.80));
      expect(julyLines.single.baseDebit, equals(380.0));

      // Explicit rate override (3.95) must always take precedence over historical rate lookups
      final overrideLines = await resolver.resolve(
        entryDate: julDate,
        baseCurrencyCode: 'SAR',
        lines: [
          JournalLineDraft(
            accountUuid: cashAccountUuid,
            debit: 100,
            credit: 0,
            currencyCode: 'EUR',
            exchangeRateToBase: 3.95,
          ),
        ],
      );
      expect(overrideLines.single.exchangeRateToBase, equals(3.95));
      expect(overrideLines.single.baseDebit, equals(395.0));
    });
  });
}
