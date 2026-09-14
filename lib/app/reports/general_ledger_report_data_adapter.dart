import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/reports/shared/domain/services/general_ledger_report_data_port.dart';

/// Concrete adapter for [GeneralLedgerReportDataPort] reading directly from [JournalRepository].
class GeneralLedgerReportDataAdapter implements GeneralLedgerReportDataPort {
  GeneralLedgerReportDataAdapter({
    required this.journals,
    required this.loadFunctionalCurrencyCode,
  });

  final JournalRepository journals;
  final Future<String> Function() loadFunctionalCurrencyCode;

  @override
  Future<GeneralLedgerReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required GeneralLedgerReportLabels labels,
  }) async {
    final functionalCode = await loadFunctionalCurrencyCode();
    final baseCurrency = filter.currencyCode == 'ALL'
        ? functionalCode
        : filter.currencyCode;

    final isPostedFilter = filter.postingScope == PostingScope.postedOnly
        ? true
        : (filter.postingScope == PostingScope.unpostedOnly ? false : null);

    double openingBalance = 0.0;
    if (filter.accountUuid != null &&
        filter.accountUuid!.isNotEmpty &&
        filter.fromDate != null) {
      openingBalance = await journals.sumNetBefore(
        accountUuid: filter.accountUuid!,
        beforeDate: filter.fromDate!,
        currencyCode: filter.currencyCode == 'ALL' ? null : filter.currencyCode,
        isPosted: isPostedFilter,
      );
    }

    List<GeneralLedgerReportRow> rows = [];
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    double runningBalance = openingBalance;

    if (filter.accountUuid != null && filter.accountUuid!.isNotEmpty) {
      final movements = await journals.listMovementsForAccount(
        accountUuid: filter.accountUuid!,
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        currencyCode: filter.currencyCode == 'ALL' ? null : filter.currencyCode,
        isPosted: isPostedFilter,
      );

      for (final m in movements) {
        totalDebit += m.debit;
        totalCredit += m.credit;
        runningBalance += (m.debit - m.credit);

        rows.add(
          GeneralLedgerReportRow(
            date: m.entryDate,
            voucherNumber: m.voucherNumber,
            voucherType: m.voucherType,
            accountCode: filter.accountUuid ?? '',
            accountName: labels.reportTitle,
            description: m.description,
            debit: m.debit,
            credit: m.credit,
            currencyCode: m.currencyCode,
            baseAmount: m.debit > 0 ? m.debit : m.credit,
            runningBalance: runningBalance,
            isPosted: m.isPosted,
          ),
        );
      }
    } else {
      // General ledger overview across all posted journal lines
      final jbLines = await journals.listJournalBookLines(
        fromDate: filter.fromDate,
        toDate: filter.toDate,
        isPosted: isPostedFilter,
      );

      for (final line in jbLines) {
        totalDebit += line.debit;
        totalCredit += line.credit;
        runningBalance += (line.debit - line.credit);

        rows.add(
          GeneralLedgerReportRow(
            date: line.entryDate,
            voucherNumber: line.voucherNumber,
            voucherType: line.voucherType,
            accountCode: line.accountCode,
            accountName: line.accountName,
            description: line.description,
            debit: line.debit,
            credit: line.credit,
            currencyCode: baseCurrency,
            baseAmount: line.debit > 0 ? line.debit : line.credit,
            runningBalance: runningBalance,
            isPosted: true,
          ),
        );
      }
    }

    return GeneralLedgerReportPayload(
      labels: labels,
      baseCurrencyCode: baseCurrency,
      fromDate: filter.fromDate,
      toDate: filter.toDate,
      openingBalance: openingBalance,
      rows: rows,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      endingBalance: runningBalance,
    );
  }
}
