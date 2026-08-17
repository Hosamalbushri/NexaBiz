/// One journal-book line prepared outside the PDF layer.
class JournalBookReportRow {
  const JournalBookReportRow({
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    required this.description,
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  final DateTime entryDate;
  final String voucherNumber;
  final String voucherType;
  final String description;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
}

class JournalBookReportPayload {
  const JournalBookReportPayload({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.columnDate,
    required this.columnVoucher,
    required this.columnType,
    required this.columnDescription,
    required this.columnAccount,
    required this.columnDebit,
    required this.columnCredit,
    required this.totalsLabel,
    required this.rows,
    required this.totalsDebit,
    required this.totalsCredit,
    this.baseCurrencyCode,
    this.fromDate,
    this.toDate,
    this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String columnDate;
  final String columnVoucher;
  final String columnType;
  final String columnDescription;
  final String columnAccount;
  final String columnDebit;
  final String columnCredit;
  final String totalsLabel;
  final List<JournalBookReportRow> rows;
  final double totalsDebit;
  final double totalsCredit;
  final String? baseCurrencyCode;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? emptyMessage;
}

/// Localized labels passed into the data port (UI resolves ARB first).
class JournalBookReportLabels {
  const JournalBookReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.periodAll,
    required this.columnDate,
    required this.columnVoucher,
    required this.columnType,
    required this.columnDescription,
    required this.columnAccount,
    required this.columnDebit,
    required this.columnCredit,
    required this.totalsLabel,
    required this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String periodAll;
  final String columnDate;
  final String columnVoucher;
  final String columnType;
  final String columnDescription;
  final String columnAccount;
  final String columnDebit;
  final String columnCredit;
  final String totalsLabel;
  final String emptyMessage;
}

/// App wires this to Accounting journal repository (modules ↛ modules).
abstract class JournalBookReportDataPort {
  Future<JournalBookReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    required bool postedOnly,
    required JournalBookReportLabels labels,
  });
}

class NoOpJournalBookReportDataPort implements JournalBookReportDataPort {
  const NoOpJournalBookReportDataPort();

  @override
  Future<JournalBookReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    required bool postedOnly,
    required JournalBookReportLabels labels,
  }) async {
    return JournalBookReportPayload(
      companyName: labels.companyName,
      reportTitle: labels.reportTitle,
      generatedAtLabel: labels.generatedAtLabel,
      periodLabel: labels.periodAll,
      columnDate: labels.columnDate,
      columnVoucher: labels.columnVoucher,
      columnType: labels.columnType,
      columnDescription: labels.columnDescription,
      columnAccount: labels.columnAccount,
      columnDebit: labels.columnDebit,
      columnCredit: labels.columnCredit,
      totalsLabel: labels.totalsLabel,
      rows: const [],
      totalsDebit: 0,
      totalsCredit: 0,
      fromDate: fromDate,
      toDate: toDate,
      emptyMessage: labels.emptyMessage,
    );
  }
}
