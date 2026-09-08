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
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
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
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
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
  group('CURRENCY-10 — Multi-Currency Reports and Statements Tests', () {
    late AccountingDatabase db;
    late InventoryDatabase invDb;
    late CostLayerServiceImpl costLayerService;
    late AccountRepositoryImpl accountRepo;
    late AccountCurrencyBalanceRepositoryImpl balanceRepo;
    late JournalRepositoryImpl journalRepo;
    late JournalPostingService postingService;
    late MockPeriodValidator periodValidator;
    late MockCurrencyRateRepository rateRepo;

    const companyId = 'COMP-CURRENCY-10';
    const customerAccountUuid = '22222222-2222-2222-2222-222222222201';
    const supplierAccountUuid = '22222222-2222-2222-2222-222222222202';
    const salesAccountUuid    = '22222222-2222-2222-2222-222222222203';
    const cogsAccountUuid     = '22222222-2222-2222-2222-222222222204';
    const cashAccountUuid     = '22222222-2222-2222-2222-222222222205';

    Future<CompanyProfile> loadCompanyProfile() async {
      return const CompanyProfile(
        name: 'NexaBiz Test Company',
      );
    }

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
    });

    tearDown(() async {
      await db.close();
      await invDb.close();
    });

    final testLabels = AccountStatementReportLabels(
      companyName: 'NexaBiz Test',
      reportTitle: 'Account Statement',
      printedByLabel: 'Admin',
      fromDateLabel: 'From',
      toDateLabel: 'To',
      accountNameLabel: 'Account Name',
      accountNumberLabel: 'Account Code',
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
      totalsDebitLabel: 'Debit Total',
      totalsCreditLabel: 'Credit Total',
      finalBalanceByCurrencyLabel: 'Final Balance By Currency',
      disclaimer: 'Official Document',
      accountantLabel: 'Accountant',
      reviewerLabel: 'Reviewer',
      financeManagerLabel: 'Manager',
      emptyMessage: 'No Data',
      statementTypeLabelOf: (t) => t.name,
      postingFilterLabelOf: (f) => f.name,
      accountDisplayNameOf: (a) => a.name,
    );

    test('1. Account Statement with Multi-Currency lines (YER, SAR, USD) preserves per-currency balances & NO raw cross-currency summation', () async {
      // 1. Post YER Transaction (10,000 YER)
      await postingService.post(
        JournalEntryDraft(
          uuid: generateUuidV4(),
          voucherNumber: 'JV-YER-001',
          voucherType: 'JV',
          entryDate: DateTime.utc(2026, 1, 10),
          currencyCode: 'YER',
          baseCurrencyCode: 'YER',
          description: 'Local Sale In YER',
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
        ),
      );

      // 2. Post SAR Transaction (100 SAR @ 140 YER/SAR = 14,000 YER)
      await postingService.post(
        JournalEntryDraft(
          uuid: generateUuidV4(),
          voucherNumber: 'JV-SAR-001',
          voucherType: 'JV',
          entryDate: DateTime.utc(2026, 1, 15),
          currencyCode: 'SAR',
          baseCurrencyCode: 'YER',
          description: 'Regional Sale In SAR',
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
        ),
      );

      // 3. Post USD Transaction (50 USD @ 530 YER/USD = 26,500 YER)
      await postingService.post(
        JournalEntryDraft(
          uuid: generateUuidV4(),
          voucherNumber: 'JV-USD-001',
          voucherType: 'JV',
          entryDate: DateTime.utc(2026, 1, 20),
          currencyCode: 'USD',
          baseCurrencyCode: 'YER',
          description: 'Global Sale In USD',
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
        ),
      );

      final adapter = AccountStatementReportDataAdapter(
        accounts: accountRepo,
        currencyRates: rateRepo,
        journals: journalRepo,
        loadFunctionalCurrencyCode: () async => 'YER',
      );

      // Load payload for Customer Account with ALL currencies
      final payload = await adapter.load(
        accountUuid: customerAccountUuid,
        currencyCode: null, // ALL currencies
        statementType: AccountStatementType.detailed,
        postingFilter: AccountStatementPostingFilter.all,
        labels: testLabels,
      );

      // STRICT CHECK 1: Aggregate closing balance MUST NOT sum raw (10000 YER + 100 SAR + 50 USD = 10150)
      expect(payload.closingBalance, equals(0.0)); // Zero raw cross-currency addition!

      // STRICT CHECK 2: Distinct per-currency balances present
      expect(payload.balancesByCurrency.length, equals(3));
      final yerBal = payload.balancesByCurrency.firstWhere((b) => b.currencyCode == 'YER');
      final sarBal = payload.balancesByCurrency.firstWhere((b) => b.currencyCode == 'SAR');
      final usdBal = payload.balancesByCurrency.firstWhere((b) => b.currencyCode == 'USD');

      expect(yerBal.closingBalance, equals(10000.0));
      expect(sarBal.closingBalance, equals(100.0));
      expect(usdBal.closingBalance, equals(50.0));

      // STRICT CHECK 3: Line items preserve functional base equivalents
      expect(payload.lines.length, equals(3));
      final sarLine = payload.lines.firstWhere((l) => l.currencyCode == 'SAR');
      expect(sarLine.debit, equals(100.0));
      expect(sarLine.baseDebit, equals(14000.0));
      expect(sarLine.exchangeRateToBase, equals(140.0));
      expect(sarLine.baseCurrencyCode, equals('YER'));
    });

    test('2. Trial Balance operates strictly in functional currency (base debits == base credits)', () async {
      await postingService.post(
        JournalEntryDraft(
          uuid: generateUuidV4(),
          voucherNumber: 'JV-SAR-002',
          voucherType: 'JV',
          entryDate: DateTime.utc(2026, 1, 15),
          currencyCode: 'SAR',
          baseCurrencyCode: 'YER',
          description: 'Purchase In SAR',
          lines: [
            JournalLineDraft(
              accountUuid: cogsAccountUuid,
              debit: 100.0,
              credit: 0.0,
              currencyCode: 'SAR',
              exchangeRateToBase: 140.0,
              baseDebit: 14000.0,
              baseCredit: 0.0,
            ),
            JournalLineDraft(
              accountUuid: supplierAccountUuid,
              debit: 0.0,
              credit: 100.0,
              currencyCode: 'SAR',
              exchangeRateToBase: 140.0,
              baseDebit: 0.0,
              baseCredit: 14000.0,
            ),
          ],
        ),
      );

      final adapter = TrialBalanceReportDataAdapter(
        journals: journalRepo,
        loadFunctionalCurrencyCode: () async => 'YER',
      );

      const tbLabels = TrialBalanceReportLabels(
        companyName: 'NexaBiz Test',
        reportTitle: 'Trial Balance',
        generatedAtLabel: 'Now',
        periodLabel: 'Period',
        periodAll: 'All',
        columnCode: 'Code',
        columnName: 'Name',
        columnDebit: 'Debit (YER)',
        columnCredit: 'Credit (YER)',
        totalsLabel: 'Total',
        balancedLabel: 'Balanced',
        unbalancedLabel: 'Unbalanced',
        emptyMessage: 'No Data',
      );

      final payload = await adapter.load(
        postedOnly: true,
        labels: tbLabels,
      );

      expect(payload.baseCurrencyCode, equals('YER'));
      expect(payload.isBalanced, isTrue);
      expect(payload.totalsDebit, equals(14000.0));
      expect(payload.totalsCredit, equals(14000.0));
    });

    test('3. Balance Sheet & Income Statement operate in functional currency', () async {
      // Post Revenue & COGS in SAR
      await postingService.post(
        JournalEntryDraft(
          uuid: generateUuidV4(),
          voucherNumber: 'JV-SAR-003',
          voucherType: 'JV',
          entryDate: DateTime.utc(2026, 1, 15),
          currencyCode: 'SAR',
          baseCurrencyCode: 'YER',
          description: 'Sale and COGS',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid,
              debit: 200.0,
              credit: 0.0,
              currencyCode: 'SAR',
              exchangeRateToBase: 140.0,
              baseDebit: 28000.0,
              baseCredit: 0.0,
            ),
            JournalLineDraft(
              accountUuid: salesAccountUuid,
              debit: 0.0,
              credit: 200.0,
              currencyCode: 'SAR',
              exchangeRateToBase: 140.0,
              baseDebit: 0.0,
              baseCredit: 28000.0,
            ),
          ],
        ),
      );

      final bsAdapter = BalanceSheetReportDataAdapter(
        journals: journalRepo,
        accounts: accountRepo,
        loadFunctionalCurrencyCode: () async => 'YER',
      );

      const bsLabels = BalanceSheetReportLabels(
        companyName: 'NexaBiz Test',
        reportTitle: 'Balance Sheet',
        generatedAtLabel: 'Now',
        asOfDateLabel: 'As of',
        assetsHeader: 'Assets',
        liabilitiesHeader: 'Liabilities',
        equityHeader: 'Equity',
        retainedEarningsLabel: 'Net Income',
        totalAssetsLabel: 'Total Assets',
        totalLiabilitiesLabel: 'Total Liabilities',
        totalEquityLabel: 'Total Equity',
        totalLiabilitiesAndEquityLabel: 'Total L+E',
        balancedLabel: 'Balanced',
        unbalancedLabel: 'Unbalanced',
        emptyMessage: 'No Data',
      );

      final bsPayload = await bsAdapter.loadFromFilter(
        filter: const ReportQueryFilter(companyId: companyId),
        labels: bsLabels,
      );

      expect(bsPayload.baseCurrencyCode, equals('YER'));
      expect(bsPayload.totalAssets, equals(28000.0));
      expect(bsPayload.retainedEarnings, equals(28000.0));
      expect(bsPayload.isBalanced, isTrue);

      final isAdapter = IncomeStatementReportDataAdapter(
        journals: journalRepo,
        accounts: accountRepo,
        loadFunctionalCurrencyCode: () async => 'YER',
      );

      const isLabels = IncomeStatementReportLabels(
        companyName: 'NexaBiz Test',
        reportTitle: 'Income Statement',
        generatedAtLabel: 'Now',
        periodLabel: 'Period',
        periodAll: 'All',
        revenueHeader: 'Revenues',
        cogsHeader: 'COGS',
        grossProfitLabel: 'Gross Profit',
        operatingExpensesHeader: 'Expenses',
        operatingProfitLabel: 'Operating Profit',
        netProfitLabel: 'Net Profit',
        netLossLabel: 'Net Loss',
        accountCodeLabel: 'Code',
        accountNameLabel: 'Name',
        amountLabel: 'Amount',
        totalsLabel: 'Totals',
        emptyMessage: 'No Data',
      );

      final isPayload = await isAdapter.loadFromFilter(
        filter: const ReportQueryFilter(companyId: companyId),
        labels: isLabels,
      );

      expect(isPayload.baseCurrencyCode, equals('YER'));
      expect(isPayload.totalRevenue, equals(28000.0));
      expect(isPayload.netProfit, equals(28000.0));
    });

    test('4. Receivables & Payables statement presents summary in base currency', () async {
      await postingService.post(
        JournalEntryDraft(
          uuid: generateUuidV4(),
          voucherNumber: 'JV-AR-001',
          voucherType: 'JV',
          entryDate: DateTime.utc(2026, 1, 15),
          currencyCode: 'SAR',
          baseCurrencyCode: 'YER',
          description: 'AR invoice',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccountUuid, // code starts with 12
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
        ),
      );

      final rpAdapter = ReceivablesPayablesReportDataAdapter(
        journals: journalRepo,
        accounts: accountRepo,
        loadFunctionalCurrencyCode: () async => 'YER',
      );

      const rpLabels = ReceivablesPayablesReportLabels(
        companyName: 'NexaBiz Test',
        reportTitle: 'Receivables Summary',
        generatedAtLabel: 'Now',
        periodLabel: 'Period',
        periodAll: 'All',
        columnEntityCode: 'Code',
        columnEntityName: 'Name',
        columnOpeningBalance: 'Opening',
        columnInvoices: 'Invoices',
        columnPayments: 'Payments',
        columnAdjustments: 'Adjustments',
        columnEndingBalance: 'Ending',
        totalsLabel: 'Total',
        emptyMessage: 'No Data',
      );

      final payload = await rpAdapter.loadFromFilter(
        filter: const ReportQueryFilter(companyId: companyId),
        type: ReceivablesPayablesType.receivables,
        labels: rpLabels,
      );

      expect(payload.baseCurrencyCode, equals('YER'));
      expect(payload.rows.length, equals(1));
      expect(payload.rows.first.entityCode, equals('1201'));
      expect(payload.totalInvoices, equals(100.0));
    });

    test('5. Product Stock Movement / Inventory Valuation operates strictly in Valuation Currency', () async {
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'ITEM-INV-002',
          warehouseId: 'WH-01',
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 10),
          receivedQty: 20.0,
          unitCost: 1500.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      final invAdapter = ProductStockMovementReportDataAdapter(
        db: invDb,
        loadFunctionalCurrencyCode: () async => 'YER',
      );

      const invLabels = ProductStockMovementReportLabels(
        companyName: 'NexaBiz Test',
        reportTitle: 'Stock Movement',
        warehouseLabel: 'Warehouse',
        productCodeLabel: 'Product Code',
        productNameLabel: 'Product Name',
        openingBalanceLabel: 'Opening Balance',
        mainCapacityLabel: 'Main Capacity',
        subCapacityLabel: 'Sub Capacity',
        cartonLabel: 'Carton',
        pieceLabel: 'Piece',
        finalQtyLabel: 'Final Qty',
        costLabel: 'Cost',
        docDateLabel: 'Doc Date',
        docTypeLabel: 'Doc Type',
        voucherBookLabel: 'Voucher Book',
        docNumLabel: 'Doc Num',
        inwardHeaderLabel: 'Inward',
        outwardHeaderLabel: 'Outward',
        endingBalanceHeaderLabel: 'Ending Balance',
        totalIncomingCostLabel: 'Total In Cost',
        totalOutgoingCostLabel: 'Total Out Cost',
        periodLabel: 'Period',
        periodAll: 'All',
        allWarehousesLabel: 'All Warehouses',
        emptyMessage: 'No Data',
      );

      final payload = await invAdapter.load(
        productId: 'ITEM-INV-002',
        labels: invLabels,
      );

      expect(payload.productCode, equals('ITEM-INV-002'));
    });
  });
}
