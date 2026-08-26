import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/journal_book_report_data_port.dart';
import '../settings/company/company_profile.dart';

/// App adapter: journal book ← Accounting journal lines.
class JournalBookReportDataAdapter implements JournalBookReportDataPort {
  const JournalBookReportDataAdapter({
    required this.journals,
    required this.loadCompanyProfile,
  });

  final JournalRepository journals;
  final Future<CompanyProfile> Function() loadCompanyProfile;

  @override
  Future<JournalBookReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    required bool postedOnly,
    required JournalBookReportLabels labels,
  }) async {
    final profile = await loadCompanyProfile();
    final rows = await journals.listJournalBookLines(
      fromDate: fromDate,
      toDate: toDate,
      isPosted: postedOnly ? true : null,
    );

    var totalsDebit = 0.0;
    var totalsCredit = 0.0;
    final reportRows = <JournalBookReportRow>[];
    for (final row in rows) {
      totalsDebit += row.debit;
      totalsCredit += row.credit;
      reportRows.add(
        JournalBookReportRow(
          entryDate: row.entryDate,
          voucherNumber: row.voucherNumber,
          voucherType: row.voucherType,
          description: row.description,
          accountCode: row.accountCode,
          accountName: row.accountName,
          debit: row.debit,
          credit: row.credit,
        ),
      );
    }

    return JournalBookReportPayload(
      companyName: labels.companyName,
      reportTitle: labels.reportTitle,
      generatedAtLabel: labels.generatedAtLabel,
      periodLabel: _periodLabel(
        labels: labels,
        fromDate: fromDate,
        toDate: toDate,
      ),
      columnDate: labels.columnDate,
      columnVoucher: labels.columnVoucher,
      columnType: labels.columnType,
      columnDescription: labels.columnDescription,
      columnAccount: labels.columnAccount,
      columnDebit: labels.columnDebit,
      columnCredit: labels.columnCredit,
      totalsLabel: labels.totalsLabel,
      rows: reportRows,
      totalsDebit: totalsDebit,
      totalsCredit: totalsCredit,
      baseCurrencyCode: profile.defaultCurrencyCode,
      fromDate: fromDate,
      toDate: toDate,
      emptyMessage: labels.emptyMessage,
    );
  }

  String _periodLabel({
    required JournalBookReportLabels labels,
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
