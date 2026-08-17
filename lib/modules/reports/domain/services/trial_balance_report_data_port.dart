/// One trial-balance line prepared outside the PDF layer.
class TrialBalanceReportRow {
  const TrialBalanceReportRow({
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
}

class TrialBalanceReportPayload {
  const TrialBalanceReportPayload({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.columnCode,
    required this.columnName,
    required this.columnDebit,
    required this.columnCredit,
    required this.totalsLabel,
    required this.balancedLabel,
    required this.unbalancedLabel,
    required this.rows,
    required this.totalsDebit,
    required this.totalsCredit,
    required this.isBalanced,
    this.baseCurrencyCode,
    this.fromDate,
    this.toDate,
    this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String columnCode;
  final String columnName;
  final String columnDebit;
  final String columnCredit;
  final String totalsLabel;
  final String balancedLabel;
  final String unbalancedLabel;
  final List<TrialBalanceReportRow> rows;
  final double totalsDebit;
  final double totalsCredit;
  final bool isBalanced;
  final String? baseCurrencyCode;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? emptyMessage;
}

/// Localized labels passed into the data port (UI resolves ARB first).
class TrialBalanceReportLabels {
  const TrialBalanceReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.periodAll,
    required this.columnCode,
    required this.columnName,
    required this.columnDebit,
    required this.columnCredit,
    required this.totalsLabel,
    required this.balancedLabel,
    required this.unbalancedLabel,
    required this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String periodAll;
  final String columnCode;
  final String columnName;
  final String columnDebit;
  final String columnCredit;
  final String totalsLabel;
  final String balancedLabel;
  final String unbalancedLabel;
  final String emptyMessage;
}

/// App wires this to Accounting journal repository (modules ↛ modules).
abstract class TrialBalanceReportDataPort {
  Future<TrialBalanceReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    required bool postedOnly,
    required TrialBalanceReportLabels labels,
  });
}

class NoOpTrialBalanceReportDataPort implements TrialBalanceReportDataPort {
  const NoOpTrialBalanceReportDataPort();

  @override
  Future<TrialBalanceReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    required bool postedOnly,
    required TrialBalanceReportLabels labels,
  }) async {
    return TrialBalanceReportPayload(
      companyName: labels.companyName,
      reportTitle: labels.reportTitle,
      generatedAtLabel: labels.generatedAtLabel,
      periodLabel: labels.periodAll,
      columnCode: labels.columnCode,
      columnName: labels.columnName,
      columnDebit: labels.columnDebit,
      columnCredit: labels.columnCredit,
      totalsLabel: labels.totalsLabel,
      balancedLabel: labels.balancedLabel,
      unbalancedLabel: labels.unbalancedLabel,
      rows: const [],
      totalsDebit: 0,
      totalsCredit: 0,
      isBalanced: true,
      fromDate: fromDate,
      toDate: toDate,
      emptyMessage: labels.emptyMessage,
    );
  }
}
