import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';

enum ReceivablesPayablesType { receivables, payables }

/// Labels required for localized rendering of Receivables / Payables Statement.
class ReceivablesPayablesReportLabels {
  const ReceivablesPayablesReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.periodAll,
    required this.columnEntityCode,
    required this.columnEntityName,
    required this.columnOpeningBalance,
    required this.columnInvoices,
    required this.columnPayments,
    required this.columnAdjustments,
    required this.columnEndingBalance,
    required this.totalsLabel,
    required this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String periodAll;
  final String columnEntityCode;
  final String columnEntityName;
  final String columnOpeningBalance;
  final String columnInvoices;
  final String columnPayments;
  final String columnAdjustments;
  final String columnEndingBalance;
  final String totalsLabel;
  final String emptyMessage;
}

/// Statement summary row per customer/supplier or receivable/payable account.
class ReceivablesPayablesSummaryRow {
  const ReceivablesPayablesSummaryRow({
    required this.entityCode,
    required this.entityName,
    required this.openingBalance,
    required this.invoicesAmount,
    required this.paymentsAmount,
    required this.adjustmentsAmount,
    required this.endingBalance,
  });

  final String entityCode;
  final String entityName;
  final double openingBalance;
  final double invoicesAmount;
  final double paymentsAmount;
  final double adjustmentsAmount;
  final double endingBalance;
}

/// Data payload for Receivables & Payables statement.
class ReceivablesPayablesReportPayload {
  const ReceivablesPayablesReportPayload({
    required this.type,
    required this.labels,
    required this.baseCurrencyCode,
    this.fromDate,
    this.toDate,
    required this.rows,
    required this.totalOpening,
    required this.totalInvoices,
    required this.totalPayments,
    required this.totalAdjustments,
    required this.totalEnding,
  });

  final ReceivablesPayablesType type;
  final ReceivablesPayablesReportLabels labels;
  final String baseCurrencyCode;
  final DateTime? fromDate;
  final DateTime? toDate;

  final List<ReceivablesPayablesSummaryRow> rows;
  final double totalOpening;
  final double totalInvoices;
  final double totalPayments;
  final double totalAdjustments;
  final double totalEnding;
}

/// Data port interface for Receivables & Payables reporting.
abstract class ReceivablesPayablesReportDataPort {
  Future<ReceivablesPayablesReportPayload> loadFromFilter({
    required ReportQueryFilter filter,
    required ReceivablesPayablesType type,
    required ReceivablesPayablesReportLabels labels,
  });
}

/// Provider for ReceivablesPayablesReportDataPort.
final receivablesPayablesReportDataPortProvider =
    Provider<ReceivablesPayablesReportDataPort>((ref) {
      throw UnimplementedError(
        'receivablesPayablesReportDataPortProvider must be overridden in providerOverrides',
      );
    });
