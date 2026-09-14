import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/balance_sheet_report_data_port.dart';

/// Adapter for Balance Sheet (الميزانية العمومية).
class BalanceSheetReportDataAdapter implements BalanceSheetReportDataPort {
  BalanceSheetReportDataAdapter({
    required this.journals,
    required this.accounts,
    required this.loadFunctionalCurrencyCode,
  });

  final JournalRepository journals;
  final AccountRepository accounts;
  final Future<String> Function() loadFunctionalCurrencyCode;

  @override
  Future<BalanceSheetReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required BalanceSheetReportLabels labels,
  }) async {
    final functionalCode = await loadFunctionalCurrencyCode();
    final baseCurrency = filter.currencyCode == 'ALL'
        ? functionalCode
        : filter.currencyCode;

    final isPostedFilter = filter.postingScope == PostingScope.postedOnly
        ? true
        : (filter.postingScope == PostingScope.unpostedOnly ? false : null);

    final tbRows = await journals.listTrialBalance(
      companyId: filter.companyId,
      toDate: filter.toDate ?? filter.asOfDate,
      isPosted: isPostedFilter,
    );

    final allAccounts = await accounts.getAll();
    final accountMap = {for (final a in allAccounts) a.id: a};

    final assetItems = <BalanceSheetLineItem>[];
    final liabilityItems = <BalanceSheetLineItem>[];
    final equityItems = <BalanceSheetLineItem>[];

    double totalAssets = 0.0;
    double totalLiabilities = 0.0;
    double totalEquity = 0.0;

    double totalRevenue = 0.0;
    double totalExpense = 0.0;

    for (final row in tbRows) {
      final acc = accountMap[row.accountUuid];
      if (acc == null) continue;

      final netDebit = row.debit - row.credit;
      final netCredit = row.credit - row.debit;

      // Assets (Class 1 / AccountType.asset) -> Net debit
      if (acc.accountType == AccountType.asset ||
          acc.accountCode.startsWith('1')) {
        if (netDebit != 0) {
          totalAssets += netDebit;
          assetItems.add(
            BalanceSheetLineItem(
              accountCode: row.accountCode,
              accountName: row.accountName,
              amount: netDebit,
            ),
          );
        }
      }
      // Liabilities (Class 2 / AccountType.liability) -> Net credit
      else if (acc.accountType == AccountType.liability ||
          acc.accountCode.startsWith('2')) {
        if (netCredit != 0) {
          totalLiabilities += netCredit;
          liabilityItems.add(
            BalanceSheetLineItem(
              accountCode: row.accountCode,
              accountName: row.accountName,
              amount: netCredit,
            ),
          );
        }
      }
      // Equity (Class 3 / AccountType.equity) -> Net credit
      else if (acc.accountType == AccountType.equity ||
          acc.accountCode.startsWith('3')) {
        if (netCredit != 0) {
          totalEquity += netCredit;
          equityItems.add(
            BalanceSheetLineItem(
              accountCode: row.accountCode,
              accountName: row.accountName,
              amount: netCredit,
            ),
          );
        }
      }
      // P&L Accounts (Revenue/Expense) aggregate into retained earnings
      else if (acc.accountType == AccountType.revenue ||
          acc.accountCode.startsWith('4')) {
        totalRevenue += netCredit;
      } else if (acc.accountType == AccountType.expense ||
          acc.accountCode.startsWith('5') ||
          acc.accountCode.startsWith('6')) {
        totalExpense += netDebit;
      }
    }

    final retainedEarnings = totalRevenue - totalExpense;
    final totalEquityWithRetained = totalEquity + retainedEarnings;
    final totalLiabilitiesAndEquity =
        totalLiabilities + totalEquityWithRetained;

    // Check Assets == Liabilities + Equity (within floating point precision tolerance)
    final isBalanced = (totalAssets - totalLiabilitiesAndEquity).abs() < 0.01;

    return BalanceSheetReportPayload(
      labels: labels,
      baseCurrencyCode: baseCurrency,
      asOfDate: filter.toDate ?? filter.asOfDate,
      assetItems: assetItems,
      liabilityItems: liabilityItems,
      equityItems: equityItems,
      retainedEarnings: retainedEarnings,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalEquity: totalEquityWithRetained,
      totalLiabilitiesAndEquity: totalLiabilitiesAndEquity,
      isBalanced: isBalanced,
    );
  }
}
