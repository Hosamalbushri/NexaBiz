import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/app/reports/income_statement_report_data_adapter.dart';
import 'package:stock_count/app/reports/receivables_payables_report_data_adapter.dart';
import 'package:stock_count/app/reports/cash_flow_report_data_adapter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/income_statement_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/receivables_payables_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/cash_flow_report_data_port.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';

class AdversarialMockAccountRepo implements AccountRepository {
  static Account _acc(
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
    _acc(1, 'acc-cash', '1101', 'Cash Register', AccountType.asset),
    _acc(2, 'acc-ar', '1201', 'Customer AR', AccountType.asset),
    _acc(3, 'acc-sales', '4101', 'Sales Revenue', AccountType.revenue),
    _acc(4, 'acc-cogs', '5101', 'COGS', AccountType.expense),
    _acc(5, 'acc-inv', '1301', 'Inventory Asset', AccountType.asset),
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

class AdversarialMockJournalRepo implements JournalRepository {
  final String activeCompanyId;
  AdversarialMockJournalRepo({required this.activeCompanyId});

  @override
  Future<List<TrialBalanceRow>> listTrialBalance({
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async {
    if (companyId != null && companyId != activeCompanyId) {
      return []; // Strict tenant isolation: wrong company yields 0 rows
    }
    // Financial Scenario:
    // Sale = 1000 SAR (DR AR 1000, CR Sales 1000, DR COGS 600, CR Inventory 600)
    // Receipt 1 = 400 SAR (DR Cash 400, CR AR 400)
    // Receipt 2 = 600 SAR (DR Cash 600, CR AR 600)
    // TB Balances:
    // Cash: DR 1000
    // AR: DR 1000 - 1000 = 0
    // Sales Revenue: CR 1000
    // COGS: DR 600
    // Inventory: CR 600
    return const [
      TrialBalanceRow(
        accountId: 'acc-cash',
        accountCode: '1101',
        accountName: 'Cash Register',
        debit: 1000,
        credit: 0,
      ),
      TrialBalanceRow(
        accountId: 'acc-ar',
        accountCode: '1201',
        accountName: 'Customer AR',
        debit: 1000,
        credit: 1000,
      ),
      TrialBalanceRow(
        accountId: 'acc-sales',
        accountCode: '4101',
        accountName: 'Sales Revenue',
        debit: 0,
        credit: 1000,
      ),
      TrialBalanceRow(
        accountId: 'acc-cogs',
        accountCode: '5101',
        accountName: 'COGS',
        debit: 600,
        credit: 0,
      ),
      TrialBalanceRow(
        accountId: 'acc-inv',
        accountCode: '1301',
        accountName: 'Inventory Asset',
        debit: 0,
        credit: 600,
      ),
    ];
  }

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
          entryDate: DateTime(2026, 1, 10),
          voucherNumber: 'INV-1000',
          voucherType: 'SALE',
          description: 'Sale 1000 SAR',
          debit: 1000,
          credit: 0,
          currencyCode: 'SAR',
          isPosted: true,
          accountId: 'acc-ar',
          entryId: 'je-sale',
          lineUuid: 'line-1',
          lineId: 1,
          sortOrder: 1,
        ),
        AccountLedgerMovement(
          entryDate: DateTime(2026, 1, 12),
          voucherNumber: 'REC-400',
          voucherType: 'RECEIPT',
          description: 'Receipt 1',
          debit: 0,
          credit: 400,
          currencyCode: 'SAR',
          isPosted: true,
          accountId: 'acc-ar',
          entryId: 'je-rec1',
          lineUuid: 'line-2',
          lineId: 2,
          sortOrder: 2,
        ),
        AccountLedgerMovement(
          entryDate: DateTime(2026, 1, 15),
          voucherNumber: 'REC-600',
          voucherType: 'RECEIPT',
          description: 'Receipt 2',
          debit: 0,
          credit: 600,
          currencyCode: 'SAR',
          isPosted: true,
          accountId: 'acc-ar',
          entryId: 'je-rec2',
          lineUuid: 'line-3',
          lineId: 3,
          sortOrder: 3,
        ),
      ];
    } else if (accountId == 'acc-cash') {
      return [
        AccountLedgerMovement(
          entryDate: DateTime(2026, 1, 12),
          voucherNumber: 'REC-400',
          voucherType: 'RECEIPT',
          description: 'Receipt 1',
          debit: 400,
          credit: 0,
          currencyCode: 'SAR',
          isPosted: true,
          accountId: 'acc-cash',
          entryId: 'je-rec1',
          lineUuid: 'line-4',
          lineId: 4,
          sortOrder: 1,
        ),
        AccountLedgerMovement(
          entryDate: DateTime(2026, 1, 15),
          voucherNumber: 'REC-600',
          voucherType: 'RECEIPT',
          description: 'Receipt 2',
          debit: 600,
          credit: 0,
          currencyCode: 'SAR',
          isPosted: true,
          accountId: 'acc-cash',
          entryId: 'je-rec2',
          lineUuid: 'line-5',
          lineId: 5,
          sortOrder: 2,
        ),
      ];
    }
    return [];
  }

  @override
  Future<double> sumNetBefore({
    required String accountId,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  }) async => 0.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RE-11 Adversarial Financial & Inventory Verification Tests', () {
    late AdversarialMockAccountRepo mockAccounts;
    late AdversarialMockJournalRepo mockJournals;

    setUp(() {
      mockAccounts = AdversarialMockAccountRepo();
      mockJournals = AdversarialMockJournalRepo(activeCompanyId: 'comp-sar');
    });

    test(
      '1. Financial Scenario: Sale 1000, Receipts 400 + 600 => Outstanding 0 & Cash +1000',
      () async {
        final arAdapter = ReceivablesPayablesReportDataAdapter(
          journals: mockJournals,
          accounts: mockAccounts,
          loadCompanyProfile: () async =>
              const CompanyProfile(defaultCurrencyCode: 'SAR'),
        );

        final filter = ReportQueryFilter(companyId: 'comp-sar');
        const arLabels = ReceivablesPayablesReportLabels(
          companyName: 'Test SAR',
          reportTitle: 'Receivables Statement',
          generatedAtLabel: 'Generated',
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

        final arPayload = await arAdapter.loadFromFilter(
          filter: filter,
          type: ReceivablesPayablesType.receivables,
          labels: arLabels,
        );

        expect(arPayload.rows.length, 1);
        expect(arPayload.rows.first.invoicesAmount, 1000.0);
        expect(arPayload.rows.first.paymentsAmount, 1000.0);
        expect(arPayload.rows.first.endingBalance, 0.0); // Outstanding = 0 SAR

        // Verify Cash Flow matches receipts (+1000 SAR)
        final cfAdapter = CashFlowReportDataAdapter(
          journals: mockJournals,
          accounts: mockAccounts,
          loadCompanyProfile: () async =>
              const CompanyProfile(defaultCurrencyCode: 'SAR'),
        );
        const cfLabels = CashFlowReportLabels(
          companyName: 'Test SAR',
          reportTitle: 'Cash Flow',
          generatedAtLabel: 'Generated',
          periodLabel: 'Period',
          periodAll: 'All',
          operatingActivitiesHeader: 'Operations',
          investingActivitiesHeader: 'Investing',
          financingActivitiesHeader: 'Financing',
          openingCashLabel: 'Opening',
          netCashMovementLabel: 'Net Change',
          endingCashLabel: 'Ending',
          accountCodeLabel: 'Code',
          accountNameLabel: 'Name',
          inflowLabel: 'Inflow',
          outflowLabel: 'Outflow',
          netFlowLabel: 'Net',
          totalsLabel: 'Total',
          emptyMessage: 'Empty',
        );

        final cfPayload = await cfAdapter.loadFromFilter(
          filter: filter,
          labels: cfLabels,
        );
        expect(cfPayload.endingCashBalance, 1000.0);
      },
    );

    test(
      '2. Inventory Scenario: COGS in P&L matches authoritative cost (600 SAR)',
      () async {
        final pnlAdapter = IncomeStatementReportDataAdapter(
          journals: mockJournals,
          accounts: mockAccounts,
          loadCompanyProfile: () async =>
              const CompanyProfile(defaultCurrencyCode: 'SAR'),
        );

        final filter = ReportQueryFilter(companyId: 'comp-sar');
        const pnlLabels = IncomeStatementReportLabels(
          companyName: 'Test SAR',
          reportTitle: 'Income Statement',
          generatedAtLabel: 'Generated',
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

        final pnlPayload = await pnlAdapter.loadFromFilter(
          filter: filter,
          labels: pnlLabels,
        );
        expect(pnlPayload.totalRevenue, 1000.0);
        expect(pnlPayload.totalCogs, 600.0);
        expect(pnlPayload.grossProfit, 400.0); // 1000 - 600 = 400 SAR
      },
    );

    test(
      '3. Multi-Company Isolation: Querying wrong company returns zero data',
      () async {
        final pnlAdapter = IncomeStatementReportDataAdapter(
          journals: mockJournals,
          accounts: mockAccounts,
          loadCompanyProfile: () async =>
              const CompanyProfile(defaultCurrencyCode: 'SAR'),
        );

        final wrongFilter = ReportQueryFilter(companyId: 'comp-unauthorized');
        const pnlLabels = IncomeStatementReportLabels(
          companyName: 'Test SAR',
          reportTitle: 'Income Statement',
          generatedAtLabel: 'Generated',
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

        final payload = await pnlAdapter.loadFromFilter(
          filter: wrongFilter,
          labels: pnlLabels,
        );
        expect(payload.totalRevenue, 0.0);
        expect(payload.totalCogs, 0.0);
        expect(payload.netProfit, 0.0);
      },
    );
  });
}
