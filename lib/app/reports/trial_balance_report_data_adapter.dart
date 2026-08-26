import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/trial_balance_report_data_port.dart';
import '../settings/company/company_profile.dart';

/// App adapter: trial balance ← Accounting journal aggregates.
class TrialBalanceReportDataAdapter implements TrialBalanceReportDataPort {
  const TrialBalanceReportDataAdapter({
    required this.journals,
    required this.loadCompanyProfile,
  });

  final JournalRepository journals;
  final Future<CompanyProfile> Function() loadCompanyProfile;

  static const double _balanceTolerance = 0.02;

  @override
  Future<TrialBalanceReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    required bool postedOnly,
    required TrialBalanceReportLabels labels,
  }) async {
    final profile = await loadCompanyProfile();
    final rows = await journals.listTrialBalance(
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
      baseCurrencyCode: profile.defaultCurrencyCode,
      fromDate: fromDate,
      toDate: toDate,
      emptyMessage: labels.emptyMessage,
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
