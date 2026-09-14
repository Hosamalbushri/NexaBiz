import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/app/reports/general_ledger_report_data_adapter.dart';
import 'package:stock_count/app/reports/income_statement_report_data_adapter.dart';
import 'package:stock_count/app/reports/balance_sheet_report_data_adapter.dart';
import 'package:stock_count/app/reports/receivables_payables_report_data_adapter.dart';
import 'package:stock_count/app/reports/cash_flow_report_data_adapter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/general_ledger_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/income_statement_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/balance_sheet_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/receivables_payables_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/cash_flow_report_data_port.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';

class MockAccountRepository implements AccountRepository {
  static Account _makeAcc(
    int id,
    String uuid,
    String code,
    String name,
    AccountType type,
  ) {
    return Account(
      id: id,
      uuid: uuid,
      accountCode: code,
      name: name,
      accountType: type,
      normalBalance: type.normalBalance,
      level: 1,
      isGroup: false,
      isActive: true,
      isSystemAccount: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  final List<Account> _accounts = [
    _makeAcc(1, 'acc-cash', '1101', 'Cash', AccountType.asset),
    _makeAcc(2, 'acc-ar', '1201', 'Customers AR', AccountType.asset),
    _makeAcc(3, 'acc-ap', '2101', 'Suppliers AP', AccountType.liability),
    _makeAcc(4, 'acc-equity', '3101', 'Capital', AccountType.equity),
    _makeAcc(5, 'acc-sales', '4101', 'Sales Revenue', AccountType.revenue),
    _makeAcc(6, 'acc-cogs', '5101', 'COGS', AccountType.expense),
    _makeAcc(7, 'acc-exp', '5201', 'Rent Expense', AccountType.expense),
  ];

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      _accounts;

  Future<Account?> getByCode(String code) async =>
      _accounts.firstWhere((a) => a.accountCode == code);

  @override
  Future<Account?> getByUuid(String uuid) async =>
      _accounts.firstWhere((a) => a.uuid == uuid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockJournalRepository implements JournalRepository {
  final List<TrialBalanceRow> _tbRows = const [
    TrialBalanceRow(
      accountId: 'acc-cash',
      accountCode: '1101',
      accountName: 'Cash',
      debit: 5000,
      credit: 0,
    ),
    TrialBalanceRow(
      accountId: 'acc-ar',
      accountCode: '1201',
      accountName: 'Customers AR',
      debit: 3000,
      credit: 0,
    ),
    TrialBalanceRow(
      accountId: 'acc-ap',
      accountCode: '2101',
      accountName: 'Suppliers AP',
      debit: 0,
      credit: 2000,
    ),
    TrialBalanceRow(
      accountId: 'acc-equity',
      accountCode: '3101',
      accountName: 'Capital',
      debit: 0,
      credit: 4000,
    ),
    TrialBalanceRow(
      accountId: 'acc-sales',
      accountCode: '4101',
      accountName: 'Sales Revenue',
      debit: 0,
      credit: 5000,
    ),
    TrialBalanceRow(
      accountId: 'acc-cogs',
      accountCode: '5101',
      accountName: 'COGS',
      debit: 2000,
      credit: 0,
    ),
    TrialBalanceRow(
      accountId: 'acc-exp',
      accountCode: '5201',
      accountName: 'Rent Expense',
      debit: 1000,
      credit: 0,
    ),
  ];

  @override
  Future<List<TrialBalanceRow>> listTrialBalance({
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async => _tbRows;

  @override
  Future<List<JournalBookLineRow>> listJournalBookLines({
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
    String? accountId,
  }) async {
    return [
      JournalBookLineRow(
        entryDate: DateTime(2026, 1, 15),
        voucherNumber: 'JE-001',
        voucherType: 'JV',
        description: 'Initial Capital',
        accountCode: '1101',
        accountName: 'Cash',
        debit: 5000,
        credit: 0,
      ),
    ];
  }

  @override
  Future<double> sumNetBefore({
    required String accountId,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  }) async => 0.0;

  @override
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountId,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
    dynamic after,
    int? limit,
  }) async {
    if (accountId == 'acc-ar') {
      return [
        AccountLedgerMovement(
          entryDate: DateTime(2026, 1, 20),
          voucherNumber: 'INV-101',
          voucherType: 'SALE',
          description: 'Sale on Credit',
          debit: 3000,
          credit: 0,
          currencyCode: 'USD',
          isPosted: true,
          accountId: 'acc-ar',
          entryId: 'je-2',
          lineUuid: 'line-2',
          lineId: 2,
          sortOrder: 1,
        ),
      ];
    } else if (accountId == 'acc-cash') {
      return [
        AccountLedgerMovement(
          entryDate: DateTime(2026, 1, 15),
          voucherNumber: 'JE-001',
          voucherType: 'JV',
          description: 'Initial Capital',
          debit: 5000,
          credit: 0,
          currencyCode: 'USD',
          isPosted: true,
          accountId: 'acc-cash',
          entryId: 'je-1',
          lineUuid: 'line-1',
          lineId: 1,
          sortOrder: 1,
        ),
      ];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RE-02 Financial Reports Suite Tests', () {
    late MockAccountRepository mockAccounts;
    late MockJournalRepository mockJournals;

    setUp(() {
      mockAccounts = MockAccountRepository();
      mockJournals = MockJournalRepository();
    });

    test('1. General Ledger report loads correctly from filter', () async {
      final adapter = GeneralLedgerReportDataAdapter(
        journals: mockJournals,
        loadCompanyProfile: () async =>
            const CompanyProfile(defaultCurrencyCode: 'USD'),
      );

      final filter = ReportQueryFilter(
        companyId: 'test-co',
        postingScope: PostingScope.postedOnly,
      );
      const labels = GeneralLedgerReportLabels(
        companyName: 'Test Co',
        reportTitle: 'General Ledger',
        generatedAtLabel: 'Generated At',
        periodLabel: 'Period',
        periodAll: 'All',
        columnDate: 'Date',
        columnVoucher: 'Voucher',
        columnType: 'Type',
        columnAccount: 'Account',
        columnDescription: 'Description',
        columnDebit: 'Debit',
        columnCredit: 'Credit',
        columnCurrency: 'Currency',
        columnBaseAmount: 'Base Amount',
        columnBalance: 'Balance',
        openingBalanceLabel: 'Opening Balance',
        totalsLabel: 'Total',
        emptyMessage: 'Empty',
      );

      final payload = await adapter.loadFromFilter(
        filter: filter,
        labels: labels,
      );
      expect(payload.rows.length, 1);
      expect(payload.totalDebit, 5000.0);
      expect(payload.totalCredit, 0.0);
    });

    test(
      '2. Income Statement / P&L calculates Revenue, COGS, Expenses, and Net Profit accurately',
      () async {
        final adapter = IncomeStatementReportDataAdapter(
          journals: mockJournals,
          accounts: mockAccounts,
          loadCompanyProfile: () async =>
              const CompanyProfile(defaultCurrencyCode: 'USD'),
        );

        final filter = ReportQueryFilter(companyId: 'test-co');
        const labels = IncomeStatementReportLabels(
          companyName: 'Test Co',
          reportTitle: 'Income Statement',
          generatedAtLabel: 'Generated At',
          periodLabel: 'Period',
          periodAll: 'All',
          revenueHeader: 'Revenue',
          cogsHeader: 'COGS',
          grossProfitLabel: 'Gross Profit',
          operatingExpensesHeader: 'Expenses',
          operatingProfitLabel: 'Operating Profit',
          netProfitLabel: 'Net Profit',
          netLossLabel: 'Net Loss',
          accountCodeLabel: 'Code',
          accountNameLabel: 'Name',
          amountLabel: 'Amount',
          totalsLabel: 'Total',
          emptyMessage: 'Empty',
        );

        final payload = await adapter.loadFromFilter(
          filter: filter,
          labels: labels,
        );
        expect(payload.totalRevenue, 5000.0);
        expect(payload.totalCogs, 2000.0);
        expect(payload.grossProfit, 3000.0); // 5000 - 2000
        expect(payload.totalExpenses, 1000.0);
        expect(payload.netProfit, 2000.0); // 3000 - 1000
      },
    );

    test(
      '3. Balance Sheet validates Assets = Liabilities + Equity (including Retained Earnings)',
      () async {
        final adapter = BalanceSheetReportDataAdapter(
          journals: mockJournals,
          accounts: mockAccounts,
          loadCompanyProfile: () async =>
              const CompanyProfile(defaultCurrencyCode: 'USD'),
        );

        final filter = ReportQueryFilter(companyId: 'test-co');
        const labels = BalanceSheetReportLabels(
          companyName: 'Test Co',
          reportTitle: 'Balance Sheet',
          generatedAtLabel: 'Generated At',
          asOfDateLabel: 'As of',
          assetsHeader: 'Assets',
          liabilitiesHeader: 'Liabilities',
          equityHeader: 'Equity',
          retainedEarningsLabel: 'Retained Earnings',
          totalAssetsLabel: 'Total Assets',
          totalLiabilitiesLabel: 'Total Liabilities',
          totalEquityLabel: 'Total Equity',
          totalLiabilitiesAndEquityLabel: 'Total Liabilities & Equity',
          balancedLabel: 'Balanced',
          unbalancedLabel: 'Unbalanced',
          emptyMessage: 'Empty',
        );

        final payload = await adapter.loadFromFilter(
          filter: filter,
          labels: labels,
        );
        expect(payload.totalAssets, 8000.0); // Cash 5000 + AR 3000
        expect(payload.totalLiabilities, 2000.0); // AP 2000
        expect(
          payload.retainedEarnings,
          2000.0,
        ); // Revenue 5000 - (COGS 2000 + Exp 1000)
        expect(
          payload.totalEquity,
          6000.0,
        ); // Capital 4000 + Retained Earnings 2000
        expect(payload.totalLiabilitiesAndEquity, 8000.0); // 2000 + 6000
        expect(payload.isBalanced, isTrue); // 8000 == 8000
      },
    );

    test(
      '4. Receivables statement derives AR invoice and payment movements',
      () async {
        final adapter = ReceivablesPayablesReportDataAdapter(
          journals: mockJournals,
          accounts: mockAccounts,
          loadCompanyProfile: () async =>
              const CompanyProfile(defaultCurrencyCode: 'USD'),
        );

        final filter = ReportQueryFilter(companyId: 'test-co');
        const labels = ReceivablesPayablesReportLabels(
          companyName: 'Test Co',
          reportTitle: 'Receivables',
          generatedAtLabel: 'Generated At',
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
          emptyMessage: 'Empty',
        );

        final payload = await adapter.loadFromFilter(
          filter: filter,
          type: ReceivablesPayablesType.receivables,
          labels: labels,
        );

        expect(payload.rows.length, 1);
        expect(payload.rows.first.entityCode, '1201');
        expect(payload.rows.first.invoicesAmount, 3000.0);
        expect(payload.totalEnding, 3000.0);
      },
    );

    test('5. Cash Flow statement derives net cash changes', () async {
      final adapter = CashFlowReportDataAdapter(
        journals: mockJournals,
        accounts: mockAccounts,
        loadCompanyProfile: () async =>
            const CompanyProfile(defaultCurrencyCode: 'USD'),
      );

      final filter = ReportQueryFilter(companyId: 'test-co');
      const labels = CashFlowReportLabels(
        companyName: 'Test Co',
        reportTitle: 'Cash Flow',
        generatedAtLabel: 'Generated At',
        periodLabel: 'Period',
        periodAll: 'All',
        operatingActivitiesHeader: 'Operations',
        investingActivitiesHeader: 'Investing',
        financingActivitiesHeader: 'Financing',
        openingCashLabel: 'Opening Cash',
        netCashMovementLabel: 'Net Cash Change',
        endingCashLabel: 'Ending Cash',
        accountCodeLabel: 'Code',
        accountNameLabel: 'Name',
        inflowLabel: 'Inflow',
        outflowLabel: 'Outflow',
        netFlowLabel: 'Net Flow',
        totalsLabel: 'Total',
        emptyMessage: 'Empty',
      );

      final payload = await adapter.loadFromFilter(
        filter: filter,
        labels: labels,
      );
      expect(payload.operatingItems.length, 1);
      expect(payload.operatingItems.first.inflow, 5000.0);
      expect(payload.netCashChange, 5000.0);
      expect(payload.endingCashBalance, 5000.0);
    });
  });
}
