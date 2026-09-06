import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/cash_flow_report_data_port.dart';

/// Concrete adapter for [CashFlowReportDataPort] calculating Cash Flow Statement.
class CashFlowReportDataAdapter implements CashFlowReportDataPort {
  CashFlowReportDataAdapter({
    required this.journals,
    required this.accounts,
    required this.loadCompanyProfile,
  });

  final JournalRepository journals;
  final AccountRepository accounts;
  final Future<CompanyProfile> Function() loadCompanyProfile;

  @override
  Future<CashFlowReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required CashFlowReportLabels labels,
  }) async {
    final profile = await loadCompanyProfile();
    final baseCurrency = filter.currencyCode == 'ALL'
        ? profile.defaultCurrencyCode
        : filter.currencyCode;

    final isPostedFilter = filter.postingScope == PostingScope.postedOnly
        ? true
        : (filter.postingScope == PostingScope.unpostedOnly ? false : null);

    final allAccounts = await accounts.getAll();

    // Cash and Bank accounts: Code starting 11 (Cash, Bank, Treasury)
    final cashAccounts = allAccounts.where((a) => a.accountCode.startsWith('11')).toList();

    double openingCash = 0.0;
    if (filter.fromDate != null) {
      for (final ca in cashAccounts) {
        openingCash += await journals.sumNetBefore(
          accountUuid: ca.uuid,
          beforeDate: filter.fromDate!,
          isPosted: isPostedFilter,
        );
      }
    }

    final operatingItems = <CashFlowLineItem>[];
    final investingItems = <CashFlowLineItem>[];
    final financingItems = <CashFlowLineItem>[];

    double totalOperatingNet = 0.0;
    double totalInvestingNet = 0.0;
    double totalFinancingNet = 0.0;

    for (final ca in cashAccounts) {
      final movements = await journals.listMovementsForAccount(
        accountUuid: ca.uuid,
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        isPosted: isPostedFilter,
      );

      double inflow = 0.0;
      double outflow = 0.0;

      for (final m in movements) {
        if (m.debit > 0) inflow += m.debit;
        if (m.credit > 0) outflow += m.credit;
      }

      final netFlow = inflow - outflow;

      if (inflow != 0 || outflow != 0) {
        totalOperatingNet += netFlow;
        operatingItems.add(
          CashFlowLineItem(
            accountCode: ca.accountCode,
            accountName: ca.name,
            inflow: inflow,
            outflow: outflow,
            netFlow: netFlow,
          ),
        );
      }
    }

    final netCashChange = totalOperatingNet + totalInvestingNet + totalFinancingNet;
    final endingCash = openingCash + netCashChange;

    return CashFlowReportPayload(
      labels: labels,
      baseCurrencyCode: baseCurrency,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      operatingItems: operatingItems,
      investingItems: investingItems,
      financingItems: financingItems,
      openingCashBalance: openingCash,
      totalOperatingNet: totalOperatingNet,
      totalInvestingNet: totalInvestingNet,
      totalFinancingNet: totalFinancingNet,
      netCashChange: netCashChange,
      endingCashBalance: endingCash,
    );
  }
}
