import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';

/// Labels required for rendering the General Ledger Report.
class GeneralLedgerReportLabels {
  const GeneralLedgerReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.periodAll,
    required this.columnDate,
    required this.columnVoucher,
    required this.columnType,
    required this.columnAccount,
    required this.columnDescription,
    required this.columnDebit,
    required this.columnCredit,
    required this.columnCurrency,
    required this.columnBaseAmount,
    required this.columnBalance,
    required this.openingBalanceLabel,
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
  final String columnAccount;
  final String columnDescription;
  final String columnDebit;
  final String columnCredit;
  final String columnCurrency;
  final String columnBaseAmount;
  final String columnBalance;
  final String openingBalanceLabel;
  final String totalsLabel;
  final String emptyMessage;
}

/// One General Ledger transaction line row.
class GeneralLedgerReportRow {
  const GeneralLedgerReportRow({
    required this.date,
    required this.voucherNumber,
    required this.voucherType,
    required this.accountCode,
    required this.accountName,
    required this.description,
    required this.debit,
    required this.credit,
    required this.currencyCode,
    required this.baseAmount,
    required this.runningBalance,
    required this.isPosted,
  });

  final DateTime date;
  final String voucherNumber;
  final String voucherType;
  final String accountCode;
  final String accountName;
  final String description;
  final double debit;
  final double credit;
  final String currencyCode;
  final double baseAmount;
  final double runningBalance;
  final bool isPosted;
}

/// General Ledger report payload.
class GeneralLedgerReportPayload {
  const GeneralLedgerReportPayload({
    required this.labels,
    required this.baseCurrencyCode,
    this.fromDate,
    this.toDate,
    required this.openingBalance,
    required this.rows,
    required this.totalDebit,
    required this.totalCredit,
    required this.endingBalance,
  });

  final GeneralLedgerReportLabels labels;
  final String baseCurrencyCode;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double openingBalance;
  final List<GeneralLedgerReportRow> rows;
  final double totalDebit;
  final double totalCredit;
  final double endingBalance;
}

/// Data port interface for General Ledger reporting.
abstract class GeneralLedgerReportDataPort {
  Future<GeneralLedgerReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required GeneralLedgerReportLabels labels,
  });
}

/// Riverpod provider for GeneralLedgerReportDataPort.
final generalLedgerReportDataPortProvider = Provider<GeneralLedgerReportDataPort>((
  ref,
) {
  throw UnimplementedError(
    'generalLedgerReportDataPortProvider must be overridden in providerOverrides',
  );
});
