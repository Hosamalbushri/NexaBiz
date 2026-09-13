import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/income_statement_report_data_port.dart';

/// Adapter for Income Statement / Profit & Loss.
class IncomeStatementReportDataAdapter
    implements IncomeStatementReportDataPort {
  IncomeStatementReportDataAdapter({
    required this.journals,
    required this.accounts,
    required this.loadFunctionalCurrencyCode,
  });

  final JournalRepository journals;
  final AccountRepository accounts;
  final Future<String> Function() loadFunctionalCurrencyCode;

  @override
  Future<IncomeStatementReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required IncomeStatementReportLabels labels,
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
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      isPosted: isPostedFilter,
    );

    final allAccounts = await accounts.getAll();
    final accountMap = {for (final a in allAccounts) a.id: a};

    final revenueItems = <IncomeStatementLineItem>[];
    final cogsItems = <IncomeStatementLineItem>[];
    final expenseItems = <IncomeStatementLineItem>[];

    double totalRevenue = 0.0;
    double totalCogs = 0.0;
    double totalExpenses = 0.0;

    for (final row in tbRows) {
      final acc = accountMap[row.accountUuid];
      if (acc == null) continue;

      // Revenue (Class 4 / AccountType.revenue) -> Net credit (credit - debit)
      if (acc.accountType == AccountType.revenue ||
          acc.accountCode.startsWith('4')) {
        final netAmount = row.credit - row.debit;
        if (netAmount != 0) {
          totalRevenue += netAmount;
          revenueItems.add(
            IncomeStatementLineItem(
              accountCode: row.accountCode,
              accountName: row.accountName,
              amount: netAmount,
            ),
          );
        }
      }
      // Cost of Goods Sold (Accounts with code starting 51 or type expense named cogs/تكلفة)
      else if (acc.accountCode.startsWith('51') ||
          acc.name.contains('تكلفة') ||
          acc.name.toLowerCase().contains('cogs')) {
        final netAmount = row.debit - row.credit;
        if (netAmount != 0) {
          totalCogs += netAmount;
          cogsItems.add(
            IncomeStatementLineItem(
              accountCode: row.accountCode,
              accountName: row.accountName,
              amount: netAmount,
            ),
          );
        }
      }
      // Operating Expenses (Class 5/6 / AccountType.expense) -> Net debit (debit - credit)
      else if (acc.accountType == AccountType.expense ||
          acc.accountCode.startsWith('5') ||
          acc.accountCode.startsWith('6')) {
        final netAmount = row.debit - row.credit;
        if (netAmount != 0) {
          totalExpenses += netAmount;
          expenseItems.add(
            IncomeStatementLineItem(
              accountCode: row.accountCode,
              accountName: row.accountName,
              amount: netAmount,
            ),
          );
        }
      }
    }

    final grossProfit = totalRevenue - totalCogs;
    final netProfit = grossProfit - totalExpenses;

    return IncomeStatementReportPayload(
      labels: labels,
      baseCurrencyCode: baseCurrency,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      revenueItems: revenueItems,
      cogsItems: cogsItems,
      expenseItems: expenseItems,
      totalRevenue: totalRevenue,
      totalCogs: totalCogs,
      grossProfit: grossProfit,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
  }
}
