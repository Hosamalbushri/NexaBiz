/// Opaque sales-period report rows prepared outside the PDF layer.
class SalesPeriodReportRow {
  const SalesPeriodReportRow({
    required this.saleNumber,
    required this.saleDate,
    required this.settlementLabel,
    required this.statusLabel,
    required this.currencyCode,
    required this.total,
    this.customerName,
  });

  final String saleNumber;
  final DateTime saleDate;
  final String? customerName;
  final String settlementLabel;
  final String statusLabel;
  final String currencyCode;
  final double total;
}

class SalesPeriodReportPayload {
  const SalesPeriodReportPayload({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.totalLabel,
    required this.rowsLabel,
    required this.columnSaleNumber,
    required this.columnDate,
    required this.columnCustomer,
    required this.columnSettlement,
    required this.columnStatus,
    required this.columnCurrency,
    required this.columnTotal,
    required this.rows,
    required this.grandTotal,
    this.fromDate,
    this.toDate,
    this.emptyMessage,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String totalLabel;
  final String rowsLabel;
  final String columnSaleNumber;
  final String columnDate;
  final String columnCustomer;
  final String columnSettlement;
  final String columnStatus;
  final String columnCurrency;
  final String columnTotal;
  final List<SalesPeriodReportRow> rows;
  final double grandTotal;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? emptyMessage;
}

/// App wires this to Sales repository (modules ↛ modules).
abstract class SalesPeriodReportDataPort {
  Future<SalesPeriodReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    String? statusStorageValue,
    required SalesPeriodReportLabels labels,
  });
}

/// Localized labels passed into the data port (UI resolves ARB first).
class SalesPeriodReportLabels {
  const SalesPeriodReportLabels({
    required this.companyName,
    required this.reportTitle,
    required this.generatedAtLabel,
    required this.periodLabel,
    required this.totalLabel,
    required this.rowsLabel,
    required this.columnSaleNumber,
    required this.columnDate,
    required this.columnCustomer,
    required this.columnSettlement,
    required this.columnStatus,
    required this.columnCurrency,
    required this.columnTotal,
    required this.emptyMessage,
    required this.settlementCash,
    required this.settlementCredit,
    required this.statusLabelOf,
    required this.allStatuses,
    required this.periodAll,
  });

  final String companyName;
  final String reportTitle;
  final String generatedAtLabel;
  final String periodLabel;
  final String totalLabel;
  final String rowsLabel;
  final String columnSaleNumber;
  final String columnDate;
  final String columnCustomer;
  final String columnSettlement;
  final String columnStatus;
  final String columnCurrency;
  final String columnTotal;
  final String emptyMessage;
  final String settlementCash;
  final String settlementCredit;
  final String Function(String statusStorageValue) statusLabelOf;
  final String allStatuses;
  final String periodAll;
}

class NoOpSalesPeriodReportDataPort implements SalesPeriodReportDataPort {
  const NoOpSalesPeriodReportDataPort();

  @override
  Future<SalesPeriodReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    String? statusStorageValue,
    required SalesPeriodReportLabels labels,
  }) async {
    return SalesPeriodReportPayload(
      companyName: labels.companyName,
      reportTitle: labels.reportTitle,
      generatedAtLabel: labels.generatedAtLabel,
      periodLabel: labels.periodAll,
      totalLabel: labels.totalLabel,
      rowsLabel: labels.rowsLabel,
      columnSaleNumber: labels.columnSaleNumber,
      columnDate: labels.columnDate,
      columnCustomer: labels.columnCustomer,
      columnSettlement: labels.columnSettlement,
      columnStatus: labels.columnStatus,
      columnCurrency: labels.columnCurrency,
      columnTotal: labels.columnTotal,
      rows: const [],
      grandTotal: 0,
      fromDate: fromDate,
      toDate: toDate,
      emptyMessage: labels.emptyMessage,
    );
  }
}
