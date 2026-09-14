import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/trial_balance_report_data_port.dart';

/// App adapter: trial balance ← Accounting journal aggregates.
class TrialBalanceReportDataAdapter implements TrialBalanceReportDataPort {
  const TrialBalanceReportDataAdapter({
    required this.journals,
    required this.loadFunctionalCurrencyCode,
  });

  final JournalRepository journals;
  final Future<String> Function() loadFunctionalCurrencyCode;

  static const double _balanceTolerance = 0.02;

  @override
  Future<TrialBalanceReportPayload> load({
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
    required bool postedOnly,
    required TrialBalanceReportLabels labels,
  }) async {
    final baseCurrencyCode = await loadFunctionalCurrencyCode();
    final rows = await journals.listTrialBalance(
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
      isPosted: postedOnly ? true : null,
    );

    var totalsDebit = 0.0;
    var totalsCredit = 0.0;
    final reportRows = <TrialBalanceReportRow>[];
    for (final row in rows) {
      totalsDebit += row.debit;
      totalsCredit += row.credit;
      reportRows.add(
        TrialBalanceReportRow(
          accountCode: row.accountCode,
          accountName: row.accountName,
          debit: row.debit,
          credit: row.credit,
        ),
      );
    }

    final isBalanced = (totalsDebit - totalsCredit).abs() < _balanceTolerance;

    return TrialBalanceReportPayload(
      companyName: labels.companyName,
      reportTitle: labels.reportTitle,
      generatedAtLabel: labels.generatedAtLabel,
      periodLabel: _periodLabel(
        labels: labels,
        fromDate: fromDate,
        toDate: toDate,
      ),
      columnCode: labels.columnCode,
      columnName: labels.columnName,
      columnDebit: labels.columnDebit,
      columnCredit: labels.columnCredit,
      totalsLabel: labels.totalsLabel,
      balancedLabel: labels.balancedLabel,
      unbalancedLabel: labels.unbalancedLabel,
      rows: reportRows,
      totalsDebit: totalsDebit,
      totalsCredit: totalsCredit,
      isBalanced: isBalanced,
      baseCurrencyCode: baseCurrencyCode,
      fromDate: fromDate,
      toDate: toDate,
      emptyMessage: labels.emptyMessage,
    );
  }

  @override
  Future<TrialBalanceReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required TrialBalanceReportLabels labels,
  }) {
    return load(
      companyId: filter.companyId,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      postedOnly: filter.postingScope == PostingScope.postedOnly,
      labels: labels,
    );
  }

  String _periodLabel({
    required TrialBalanceReportLabels labels,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    if (fromDate == null && toDate == null) {
      return labels.periodAll;
    }
    final from = fromDate?.toIso8601String().split('T').first ?? '…';
    final to = toDate?.toIso8601String().split('T').first ?? '…';
    return '${labels.periodLabel}: $from → $to';
  }
}
