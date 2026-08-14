import '../../modules/reports/domain/services/sales_period_report_data_port.dart';
import '../../modules/sales/domain/entities/sale_list_item.dart';
import '../../modules/sales/domain/entities/sale_settlement_type.dart';
import '../../modules/sales/domain/entities/sale_status.dart';
import '../../modules/sales/domain/models/sale_list_filter.dart';
import '../../modules/sales/domain/repositories/sale_repository.dart';

/// App adapter: Reports sales-period data ← Sales repository.
class SalesPeriodReportDataAdapter implements SalesPeriodReportDataPort {
  const SalesPeriodReportDataAdapter(this._sales);

  final SaleRepository _sales;

  static const int _pageSize = 200;
  static const int _maxRows = 5000;

  @override
  Future<SalesPeriodReportPayload> load({
    DateTime? fromDate,
    DateTime? toDate,
    String? statusStorageValue,
    required SalesPeriodReportLabels labels,
  }) async {
    final status = statusStorageValue == null || statusStorageValue.isEmpty
        ? null
        : SaleStatusX.fromStorage(statusStorageValue);

    final filter = SaleListFilter(
      fromDate: fromDate,
      toDate: toDate,
      saleStatus: status,
    );

    final rows = <SalesPeriodReportRow>[];
    var page = 0;
    var grandTotal = 0.0;

    while (rows.length < _maxRows) {
      final result = await _sales.searchListPaged(
        filter,
        page: page,
        pageSize: _pageSize,
      );
      if (result.items.isEmpty) {
        break;
      }
      for (final item in result.items) {
        rows.add(_mapRow(item, labels));
        grandTotal += item.total;
        if (rows.length >= _maxRows) {
          break;
        }
      }
      if (!result.hasNext) {
        break;
      }
      page++;
    }

    final periodLabel = _periodLabel(
      labels: labels,
      fromDate: fromDate,
      toDate: toDate,
      status: status,
    );

    return SalesPeriodReportPayload(
      companyName: labels.companyName,
      reportTitle: labels.reportTitle,
      generatedAtLabel: labels.generatedAtLabel,
      periodLabel: periodLabel,
      totalLabel: labels.totalLabel,
      rowsLabel: labels.rowsLabel,
      columnSaleNumber: labels.columnSaleNumber,
      columnDate: labels.columnDate,
      columnCustomer: labels.columnCustomer,
      columnSettlement: labels.columnSettlement,
      columnStatus: labels.columnStatus,
      columnCurrency: labels.columnCurrency,
      columnTotal: labels.columnTotal,
      rows: rows,
      grandTotal: grandTotal,
      fromDate: fromDate,
      toDate: toDate,
      emptyMessage: labels.emptyMessage,
    );
  }

  SalesPeriodReportRow _mapRow(
    SaleListItem item,
    SalesPeriodReportLabels labels,
  ) {
    return SalesPeriodReportRow(
      saleNumber: item.saleNumber,
      saleDate: item.saleDate,
      customerName: item.customerName,
      settlementLabel: item.settlementType.isCash
          ? labels.settlementCash
          : labels.settlementCredit,
      statusLabel: labels.statusLabelOf(item.saleStatus.storageValue),
      currencyCode: item.currencyCode,
      total: item.total,
    );
  }

  String _periodLabel({
    required SalesPeriodReportLabels labels,
    required DateTime? fromDate,
    required DateTime? toDate,
    required SaleStatus? status,
  }) {
    final parts = <String>[];
    if (fromDate == null && toDate == null) {
      parts.add(labels.periodAll);
    } else {
      final from = fromDate?.toIso8601String().split('T').first ?? '…';
      final to = toDate?.toIso8601String().split('T').first ?? '…';
      parts.add('${labels.periodLabel}: $from → $to');
    }
    if (status != null) {
      parts.add(labels.statusLabelOf(status.storageValue));
    } else {
      parts.add(labels.allStatuses);
    }
    return parts.join(' · ');
  }
}
