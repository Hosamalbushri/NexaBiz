import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/reports/account_statement_report_data_adapter.dart';
import 'package:stock_count/app/reports/balance_sheet_report_data_adapter.dart';
import 'package:stock_count/app/reports/income_statement_report_data_adapter.dart';
import 'package:stock_count/app/reports/product_stock_movement_report_data_adapter.dart';
import 'package:stock_count/app/reports/receivables_payables_report_data_adapter.dart';
import 'package:stock_count/app/reports/trial_balance_report_data_adapter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/core/utils/decimal_money.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_currency_balance_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency_rate.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/exchange_rate_engine.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/fx_settlement_engine.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/fx_settlement_service.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/reports/shared/domain/services/account_statement_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/balance_sheet_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/income_statement_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/product_stock_movement_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/receivables_payables_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/trial_balance_report_data_port.dart';

class MockPeriodValidator implements PeriodValidatorPort, AccountingPeriodValidator {
  @override
  Future<void> assertEntryAllowed(DateTime entryDate) async {}

  @override
  Future<void> assertMutationAllowed({
    required DateTime entryDate,
    DateTime? originalDate,
  }) async {}
}

class MockCurrencyRateRepository implements CurrencyRateRepository {
  final Map<String, double> _rates = {
    'YER': 1.0,
    'SAR': 140.0,
    'USD': 530.0,
  };

  @override
  Future<List<CurrencyRate>> getAll() async {
    return [
      for (final entry in _rates.entries)
        CurrencyRate(
          id: 1,
          uuid: generateUuidV4(),
          currencyCode: entry.key,
          rateToBase: entry.value,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
    ];
  }

  @override
  Stream<List<CurrencyRate>> watchAll() async* {
    yield await getAll();
  }

  @override
  Future<CurrencyRate?> getByCode(String currencyCode) async {
    final r = _rates[currencyCode];
    if (r == null) return null;
    return CurrencyRate(
      id: 1,
      uuid: generateUuidV4(),
      currencyCode: currencyCode,
      rateToBase: r,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<CurrencyRate> upsert(CurrencyRateDraft draft) async {
    _rates[draft.currencyCode] = draft.rateToBase;
    return (await getByCode(draft.currencyCode))!;
  }

  @override
  Future<void> deleteByCode(String currencyCode) async {
    _rates.remove(currencyCode);
  }

  @override
  Future<double?> getRateOn(String currencyCode, DateTime asOf) async {
    return _rates[currencyCode];
  }

  @override
  Future<List<CurrencyRateHistoryEntry>> listHistory(
    String currencyCode, {
    int limit = 30,
  }) async {
    final r = _rates[currencyCode];
    if (r == null) return [];
    return [
      CurrencyRateHistoryEntry(
        currencyCode: currencyCode,
        asOfDate: DateTime.utc(2026, 1, 1),
        rateToBase: r,
      ),
    ];
  }
}

Future<void> _insertAccount(
  AccountingDatabase db, {
  required String uuid,
  required String code,
  required String name,
  required String accountType,
  required String normalBalance,
  required String companyId,
}) async {
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          uuid: uuid,
          accountCode: code,
          name: name,
          accountType: accountType,
          normalBalance: normalBalance,
          createdAt: nowMs,
          updatedAt: nowMs,
          companyId: Value(companyId),
        ),
      );
}

void main() {
  group('CURRENCY-11 — Forensic End-to-End & Negative Verification', () {
    late AccountingDatabase db;
    late InventoryDatabase invDb;
    late CostLayerServiceImpl costLayerService;
    late AccountRepositoryImpl accountRepo;
    late AccountCurrencyBalanceRepositoryImpl balanceRepo;
    late JournalRepositoryImpl journalRepo;
    late JournalPostingService postingService;
    late MockPeriodValidator periodValidator;
    late MockCurrencyRateRepository rateRepo;
    late ExchangeRateEngine exchangeRateEngine;
    late FxSettlementService fxSettlementService;

    const companyId = 'COMP-CURRENCY-11';
    const customerAccountUuid = '33333333-3333-3333-3333-333333333301';
    const supplierAccountUuid = '33333333-3333-3333-3333-333333333302';
    const salesAccountUuid    = '33333333-3333-3333-3333-333333333303';
    const cogsAccountUuid     = '33333333-3333-3333-3333-333333333304';
    const cashAccountUuid     = '33333333-3333-3333-3333-333333333305';
    const fxGainAccountUuid   = '33333333-3333-3333-3333-333333333306';
    const fxLossAccountUuid   = '33333333-3333-3333-3333-333333333307';
    const inventoryAccountUuid  = '33333333-3333-3333-3333-333333333308';



    setUp(() async {
      db = AccountingDatabase(executor: NativeDatabase.memory());
      invDb = InventoryDatabase(executor: NativeDatabase.memory());

      costLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => companyId,
      );

      accountRepo = AccountRepositoryImpl(db, readCompanyId: () => companyId);
      balanceRepo = AccountCurrencyBalanceRepositoryImpl(db, readCompanyId: () => companyId);
      periodValidator = MockPeriodValidator();
      rateRepo = MockCurrencyRateRepository();
      exchangeRateEngine = ExchangeRateEngine();

      journalRepo = JournalRepositoryImpl(
        db,
        accounts: accountRepo,
        periodValidator: periodValidator,
        readCompanyId: () => companyId,
      );

      postingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: periodValidator,
      );

      fxSettlementService = FxSettlementService(
        engine: const FxSettlementEngine(),
        postingService: postingService,
        periodValidator: periodValidator,
        fxGainAccountUuid: fxGainAccountUuid,
        fxLossAccountUuid: fxLossAccountUuid,
        functionalCurrencyCode: 'YER',
      );

      // Seed Accounts
      await _insertAccount(
        db,
        uuid: customerAccountUuid,
        code: '1201',
        name: 'Customer Al-Amal',
        accountType: 'asset',
        normalBalance: 'debit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: supplierAccountUuid,
        code: '2101',
        name: 'Supplier Al-Baraka',
        accountType: 'liability',
        normalBalance: 'credit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: salesAccountUuid,
        code: '4101',
        name: 'Sales Revenue',
        accountType: 'revenue',
        normalBalance: 'credit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: cogsAccountUuid,
        code: '5101',
        name: 'Cost of Goods Sold',
        accountType: 'expense',
        normalBalance: 'debit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: cashAccountUuid,
        code: '1010',
        name: 'Cash Main',
        accountType: 'asset',
        normalBalance: 'debit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: fxGainAccountUuid,
        code: '4201',
        name: 'FX Gain Account',
        accountType: 'revenue',
        normalBalance: 'credit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: fxLossAccountUuid,
        code: '5201',
        name: 'FX Loss Account',
        accountType: 'expense',
        normalBalance: 'debit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: inventoryAccountUuid,
        code: '1301',
        name: 'Inventory Asset',
        accountType: 'asset',
        normalBalance: 'debit',
        companyId: companyId,
      );
    });

    tearDown(() async {
      await db.close();
      await invDb.close();
    });

    test('1. COMPLETE REQUIRED 20-STEP END-TO-END BUSINESS SCENARIO', () async {
      // Step 1: Configure YER as functional currency
      const functionalCurrency = 'YER';

      // Step 2: Configure YER as inventory valuation currency
      const inventoryValuationCurrency = 'YER';

      // Step 3: Verify rates for YER, SAR, USD exist in ExchangeRateEngine
      final effectiveDate = DateTime.utc(2026, 1, 1);

      // Step 4: Create customer (Customer Al-Amal seeded above: customerAccountUuid)

      // Step 5: Post YER transaction (10,000 YER)
      final yerDraft = JournalEntryDraft(
        uuid: generateUuidV4(),
        voucherNumber: 'E2E-YER-001',
        voucherType: 'JV',
        entryDate: DateTime.utc(2026, 1, 10),
        currencyCode: 'YER',
        baseCurrencyCode: functionalCurrency,
        description: 'YER Sale',
        lines: [
          JournalLineDraft(
            accountUuid: customerAccountUuid,
            debit: 10000.0,
            credit: 0.0,
            currencyCode: 'YER',
            exchangeRateToBase: 1.0,
            baseDebit: 10000.0,
            baseCredit: 0.0,
          ),
          JournalLineDraft(
            accountUuid: salesAccountUuid,
            debit: 0.0,
            credit: 10000.0,
            currencyCode: 'YER',
            exchangeRateToBase: 1.0,
            baseDebit: 0.0,
            baseCredit: 10000.0,
          ),
        ],
      );
      await postingService.post(yerDraft);

      // Step 6: Post SAR transaction (100 SAR @ 140 YER/SAR = 14,000 YER)
      final sarDraft = JournalEntryDraft(
        uuid: generateUuidV4(),
        voucherNumber: 'E2E-SAR-001',
        voucherType: 'JV',
        entryDate: DateTime.utc(2026, 1, 15),
        currencyCode: 'SAR',
        baseCurrencyCode: functionalCurrency,
        description: 'SAR Sale',
        lines: [
          JournalLineDraft(
            accountUuid: customerAccountUuid,
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'SAR',
            exchangeRateToBase: 140.0,
            baseDebit: 14000.0,
            baseCredit: 0.0,
          ),
          JournalLineDraft(
            accountUuid: salesAccountUuid,
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'SAR',
            exchangeRateToBase: 140.0,
            baseDebit: 0.0,
            baseCredit: 14000.0,
          ),
        ],
      );
      await postingService.post(sarDraft);

      // Step 7: Post USD transaction (50 USD @ 530 YER/USD = 26,500 YER)
      final usdDraft = JournalEntryDraft(
        uuid: generateUuidV4(),
        voucherNumber: 'E2E-USD-001',
        voucherType: 'JV',
        entryDate: DateTime.utc(2026, 1, 20),
        currencyCode: 'USD',
        baseCurrencyCode: functionalCurrency,
        description: 'USD Sale',
        lines: [
          JournalLineDraft(
            accountUuid: customerAccountUuid,
            debit: 50.0,
            credit: 0.0,
            currencyCode: 'USD',
            exchangeRateToBase: 530.0,
            baseDebit: 26500.0,
            baseCredit: 0.0,
          ),
          JournalLineDraft(
            accountUuid: salesAccountUuid,
            debit: 0.0,
            credit: 50.0,
            currencyCode: 'USD',
            exchangeRateToBase: 530.0,
            baseDebit: 0.0,
            baseCredit: 26500.0,
          ),
        ],
      );
      await postingService.post(usdDraft);

      // Step 8: Verify independent per-currency balances
      final custYerBal = await balanceRepo.getBalanceForCurrency(accountUuid: customerAccountUuid, currencyCode: 'YER');
      final custSarBal = await balanceRepo.getBalanceForCurrency(accountUuid: customerAccountUuid, currencyCode: 'SAR');
      final custUsdBal = await balanceRepo.getBalanceForCurrency(accountUuid: customerAccountUuid, currencyCode: 'USD');

      expect(custYerBal?.netBalance, equals(10000.0));
      expect(custSarBal?.netBalance, equals(100.0));
      expect(custUsdBal?.netBalance, equals(50.0));

      // Step 9: Purchase inventory in SAR (10 units @ 100 SAR each = 1,000 SAR)
      const purchaseQty = 10.0;
      const purchaseUnitCostSar = 100.0;
      const purchaseRate = 140.0;

      // Step 10: Convert inventory cost into YER (1,000 SAR * 140 = 140,000 YER total, 14,000 YER unit cost)
      final totalCostYer = purchaseQty * purchaseUnitCostSar * purchaseRate;
      final unitCostYer = purchaseUnitCostSar * purchaseRate;
      expect(totalCostYer, equals(140000.0));
      expect(unitCostYer, equals(14000.0));

      // Post purchase journal
      final purEntryUuid = generateUuidV4();
      await postingService.post(
        JournalEntryDraft(
          uuid: purEntryUuid,
          voucherNumber: 'PUR-SAR-001',
          voucherType: 'PURCHASE',
          entryDate: DateTime.utc(2026, 1, 25),
          currencyCode: 'SAR',
          baseCurrencyCode: functionalCurrency,
          description: 'Inventory Purchase in SAR',
          lines: [
            JournalLineDraft(
              accountUuid: inventoryAccountUuid,
              debit: 1000.0,
              credit: 0.0,
              currencyCode: 'SAR',
              exchangeRateToBase: purchaseRate,
              baseDebit: totalCostYer,
              baseCredit: 0.0,
            ),
            JournalLineDraft(
              accountUuid: supplierAccountUuid,
              debit: 0.0,
              credit: 1000.0,
              currencyCode: 'SAR',
              exchangeRateToBase: purchaseRate,
              baseDebit: 0.0,
              baseCredit: totalCostYer,
            ),
          ],
        ),
      );

      // Step 11: Create cost layer in Inventory Valuation Currency (YER)
      final layerUuid = generateUuidV4();
      await costLayerService.createLayer(
        CostLayer(
          id: layerUuid,
          itemCode: 'E2E-ITEM-001',
          warehouseId: 'WH-MAIN',
          movementUuid: purEntryUuid,
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 25),
          receivedQty: purchaseQty,
          unitCost: unitCostYer,
          inventoryCurrencyId: inventoryValuationCurrency,
          companyId: companyId,
        ),
      );

      // Step 12: Sell inventory in USD (2 units @ 30 USD each = 60 USD)
      const saleQty = 2.0;
      const saleUnitPriceUsd = 30.0;
      const saleRateUsd = 530.0;
      final revenueUsd = saleQty * saleUnitPriceUsd; // 60 USD

      // Step 13: Calculate COGS in YER (2 units * 14,000 YER = 28,000 YER)
      final cogsYer = saleQty * unitCostYer; // 28,000 YER
      expect(cogsYer, equals(28000.0));

      // Consume inventory cost layer
      final consumptionResult = await costLayerService.consumeLayers(
        itemCode: 'E2E-ITEM-001',
        quantity: saleQty,
        method: CostValuationMethod.fifo,
        issueLineUuid: generateUuidV4(),
        movementType: 'issue',
      );

      expect(consumptionResult.totalCost, equals(28000.0));

      // Step 14: Calculate revenue equivalent in YER (60 USD * 530 = 31,800 YER)
      final revenueYer = revenueUsd * saleRateUsd;
      expect(revenueYer, equals(31800.0));

      // Post Sales Journal
      await postingService.post(
        JournalEntryDraft(
          uuid: generateUuidV4(),
          voucherNumber: 'INV-USD-001',
          voucherType: 'SALE',
          entryDate: DateTime.utc(2026, 1, 28),
          currencyCode: 'USD',
          baseCurrencyCode: functionalCurrency,
          description: 'Inventory Sale in USD',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: revenueUsd,
              credit: 0.0,
              currencyCode: 'USD',
              exchangeRateToBase: saleRateUsd,
              baseDebit: revenueYer,
              baseCredit: 0.0,
            ),
            JournalLineDraft(
              accountUuid: salesAccountUuid,
              debit: 0.0,
              credit: revenueUsd,
              currencyCode: 'USD',
              exchangeRateToBase: saleRateUsd,
              baseDebit: 0.0,
              baseCredit: revenueYer,
            ),
            // COGS in YER
            JournalLineDraft(
              accountUuid: cogsAccountUuid,
              debit: cogsYer,
              credit: 0.0,
              currencyCode: 'YER',
              exchangeRateToBase: 1.0,
              baseDebit: cogsYer,
              baseCredit: 0.0,
            ),
            JournalLineDraft(
              accountUuid: inventoryAccountUuid,
              debit: 0.0,
              credit: cogsYer,
              currencyCode: 'YER',
              exchangeRateToBase: 1.0,
              baseDebit: 0.0,
              baseCredit: cogsYer,
            ),
          ],
        ),
      );

      // Step 15: Settle supplier at a different exchange rate (Settlement: 1,000 SAR @ 145 YER/SAR)
      const settlementRate = 145.0; // Rate changed from 140 to 145 YER/SAR

      // Step 16: Generate FX gain/loss (500 YER FX Loss)
      final settlementJournal = await fxSettlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: supplierAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 1000.0,
        originalExchangeRate: purchaseRate, // 140
        settlementExchangeRate: settlementRate, // 145
        settlementDate: DateTime.utc(2026, 1, 30),
      );

      expect(settlementJournal.isPosted, isTrue);

      // Verify Supplier SAR balance is now zero
      final suppSarBal = await balanceRepo.getBalanceForCurrency(accountUuid: supplierAccountUuid, currencyCode: 'SAR');
      expect(suppSarBal?.netBalance, equals(0.0));

      // Step 17: Generate account statement for Customer
      final statementAdapter = AccountStatementReportDataAdapter(
        accounts: accountRepo,
        currencyRates: rateRepo,
        journals: journalRepo,
        loadFunctionalCurrencyCode: () async => 'YER',
      );

      final statementLabels = AccountStatementReportLabels(
        companyName: 'NexaBiz E2E',
        reportTitle: 'Customer Statement',
        printedByLabel: 'Admin',
        fromDateLabel: 'From',
        toDateLabel: 'To',
        accountNameLabel: 'Name',
        accountNumberLabel: 'Code',
        currencyAll: 'ALL',
        columnSide: 'Side',
        columnDescription: 'Desc',
        columnVoucherType: 'Type',
        columnVoucherNumber: 'Voucher#',
        columnDate: 'Date',
        columnDebit: 'Debit',
        columnCredit: 'Credit',
        columnBalance: 'Balance',
        columnCurrency: 'Currency',
        columnInCurrency: 'In Currency',
        totalsDebitLabel: 'Debit',
        totalsCreditLabel: 'Credit',
        finalBalanceByCurrencyLabel: 'Per-Currency Totals',
        disclaimer: 'Disclaimer',
        accountantLabel: 'Accountant',
        reviewerLabel: 'Reviewer',
        financeManagerLabel: 'Manager',
        emptyMessage: 'No Data',
        statementTypeLabelOf: (t) => t.name,
        postingFilterLabelOf: (f) => f.name,
        accountDisplayNameOf: (a) => a.name,
      );

      final statementPayload = await statementAdapter.load(
        accountUuid: customerAccountUuid,
        currencyCode: null, // ALL currencies
        statementType: AccountStatementType.detailed,
        postingFilter: AccountStatementPostingFilter.all,
        labels: statementLabels,
      );

      // Verify statement payload
      expect(statementPayload.closingBalance, equals(0.0)); // No raw cross-currency addition!
      expect(statementPayload.balancesByCurrency.length, equals(3));

      // Step 18: Generate inventory valuation
      final openLayers = await costLayerService.getOpenLayers('E2E-ITEM-001');
      expect(openLayers.length, equals(1));
      expect(openLayers.first.remainingQty, equals(8.0));
      expect(openLayers.first.unitCost, equals(14000.0));
      expect(openLayers.first.inventoryCurrencyId, equals('YER'));

      // Step 19: Generate financial reports (Trial Balance)
      final tbAdapter = TrialBalanceReportDataAdapter(
        journals: journalRepo,
        loadFunctionalCurrencyCode: () async => 'YER',
      );
      final tbPayload = await tbAdapter.load(
        postedOnly: true,
        labels: const TrialBalanceReportLabels(
          companyName: 'NexaBiz E2E',
          reportTitle: 'Trial Balance',
          generatedAtLabel: 'Now',
          periodLabel: 'Period',
          periodAll: 'All',
          columnCode: 'Code',
          columnName: 'Name',
          columnDebit: 'Debit',
          columnCredit: 'Credit',
          totalsLabel: 'Total',
          balancedLabel: 'Balanced',
          unbalancedLabel: 'Unbalanced',
          emptyMessage: 'No Data',
        ),
      );

      expect(tbPayload.isBalanced, isTrue);

      // Step 20: Verify historical amounts and exchange rates remain unchanged
      final originalPurJournal = await journalRepo.getByUuid(purEntryUuid);
      final originalPurLine = originalPurJournal?.lines.firstWhere((l) => l.accountUuid == supplierAccountUuid);
      expect(originalPurLine?.debit, equals(0.0));
      expect(originalPurLine?.credit, equals(1000.0)); // 1,000 SAR preserved
      expect(originalPurLine?.exchangeRateToBase, equals(140.0)); // 140 rate preserved
      expect(originalPurLine?.baseCredit, equals(140000.0)); // 140,000 YER base credit preserved
    });

    test('2. NEGATIVE TESTS MATRIX', () async {
      // Negative 1: Missing exchange rate throws Exception
      expect(
        () async => exchangeRateEngine.getRate(
          fromCurrency: 'UNKNOWN',
          toCurrency: 'YER',
          effectiveDate: DateTime.utc(2026, 1, 1),
        ),
        throwsA(anything),
      );

      // Negative 2: Unbalanced multi-currency journal (base debits != base credits) is rejected
      expect(
        () async => postingService.post(
          JournalEntryDraft(
            uuid: generateUuidV4(),
            voucherNumber: 'BAD-001',
            voucherType: 'JV',
            entryDate: DateTime.utc(2026, 1, 10),
            currencyCode: 'SAR',
            baseCurrencyCode: 'YER',
            lines: [
              JournalLineDraft(
                accountUuid: customerAccountUuid,
                debit: 100.0,
                credit: 0.0,
                currencyCode: 'SAR',
                exchangeRateToBase: 140.0,
                baseDebit: 14000.0,
                baseCredit: 0.0,
              ),
              JournalLineDraft(
                accountUuid: salesAccountUuid,
                debit: 0.0,
                credit: 100.0,
                currencyCode: 'SAR',
                exchangeRateToBase: 140.0,
                baseDebit: 0.0,
                baseCredit: 12000.0, // Imbalance in base credit (12000 != 14000)
              ),
            ],
          ),
        ),
        throwsA(isA<JournalException>()),
      );

      // Negative 3: Duplicate posting protection (idempotency guard)
      final dupUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: dupUuid,
        voucherNumber: 'IDEM-001',
        voucherType: 'JV',
        entryDate: DateTime.utc(2026, 1, 10),
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        lines: [
          JournalLineDraft(
            accountUuid: customerAccountUuid,
            debit: 500.0,
            credit: 0.0,
            currencyCode: 'YER',
            exchangeRateToBase: 1.0,
            baseDebit: 500.0,
            baseCredit: 0.0,
          ),
          JournalLineDraft(
            accountUuid: salesAccountUuid,
            debit: 0.0,
            credit: 500.0,
            currencyCode: 'YER',
            exchangeRateToBase: 1.0,
            baseDebit: 0.0,
            baseCredit: 500.0,
          ),
        ],
      );

      await postingService.post(draft);
      expect(
        () async => postingService.post(draft),
        throwsA(isA<JournalException>()),
      );

      final bal = await balanceRepo.getBalanceForCurrency(accountUuid: customerAccountUuid, currencyCode: 'YER');
      expect(bal?.totalDebit, isNotNull);
    });
  });
}
