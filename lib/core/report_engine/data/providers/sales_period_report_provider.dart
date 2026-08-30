import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';
import '../../domain/models/report_cursor.dart';
import '../../domain/models/report_dataset.dart';
import '../../domain/models/report_execution_context.dart';
import '../../domain/models/report_page.dart';
import '../../domain/models/report_query_context.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/services/paged_report_data_provider.dart';
import 'report_data_provider.dart';

/// SQL-Native, Paged Data Provider querying Sales Invoices for the Unified ERP Report Engine.
/// Strictly read-only, keyset paginated, tenant-isolated, and memory efficient.
class SalesPeriodReportDataProvider
    implements ReportDataProvider, PagedReportDataProvider<ReportRowData> {
  SalesPeriodReportDataProvider({
    required this.salesDb,
    this.companyName = 'شركة نكسا بيز NexaBiz',
  });

  final SalesDatabase salesDb;
  final String companyName;

  @override
  String get reportId => 'sales_period';

  /// SQL-Native Summary Aggregation
  @override
  Future<ReportSummary> fetchSummary(ReportExecutionContext context) async {
    final fromDate = context.fromDate;
    final toDate = context.toDate;
    final customerId = context.filters['customer'] as String?;

    final fromMs = fromDate != null ? fromDate.millisecondsSinceEpoch : null;
    final toMs = toDate != null
        ? toDate.add(const Duration(days: 1)).millisecondsSinceEpoch
        : null;

    final query = salesDb.selectOnly(salesDb.sales)
      ..addColumns([
        salesDb.sales.id.count(),
        salesDb.sales.subtotal.sum(),
        salesDb.sales.taxAmount.sum(),
        salesDb.sales.total.sum(),
      ])
      ..where(salesDb.sales.deletedAt.isNull());

    _applySqlFilters(
      query: query,
      context: context,
      fromMs: fromMs,
      toMs: toMs,
      customerId: customerId,
    );

    final row = await query.getSingle();
    final count = row.read(salesDb.sales.id.count()) ?? 0;
    final subtotal = row.read(salesDb.sales.subtotal.sum()) ?? 0.0;
    final tax = row.read(salesDb.sales.taxAmount.sum()) ?? 0.0;
    final grandTotal = row.read(salesDb.sales.total.sum()) ?? 0.0;

    return ReportSummary(
      totalCount: count,
      aggregates: {
        'subtotal': subtotal,
        'taxAmount': tax,
        'grandTotal': grandTotal,
      },
      kpis: {
        'countInvoices': count,
      },
    );
  }

  /// SQL-Native Keyset Cursor Page Fetching
  @override
  Future<ReportPage<ReportRowData>> fetchPage(
    ReportExecutionContext context, {
    ReportCursor? cursor,
    int pageSize = 50,
  }) async {
    final fromDate = context.fromDate;
    final toDate = context.toDate;
    final customerId = context.filters['customer'] as String?;

    final fromMs = fromDate != null ? fromDate.millisecondsSinceEpoch : null;
    final toMs = toDate != null
        ? toDate.add(const Duration(days: 1)).millisecondsSinceEpoch
        : null;

    final query = salesDb.select(salesDb.sales)
      ..where((tbl) => tbl.deletedAt.isNull());

    _applySqlFiltersTyped(
      query: query,
      context: context,
      fromMs: fromMs,
      toMs: toMs,
      customerId: customerId,
    );

    final isAscending = context.sorting.ascending;

    // Apply Keyset Cursor predicate: (sale_date, id)
    if (cursor != null) {
      final cursorDate = cursor.primarySortValue as int;
      final cursorId = int.parse(cursor.uniqueId);

      if (isAscending) {
        query.where((tbl) =>
            tbl.saleDate.isBiggerThanValue(cursorDate) |
            (tbl.saleDate.equals(cursorDate) & tbl.id.isBiggerThanValue(cursorId)));
      } else {
        query.where((tbl) =>
            tbl.saleDate.isSmallerThanValue(cursorDate) |
            (tbl.saleDate.equals(cursorDate) & tbl.id.isSmallerThanValue(cursorId)));
      }
    }

    query.orderBy([
      (tbl) => isAscending ? OrderingTerm.asc(tbl.saleDate) : OrderingTerm.desc(tbl.saleDate),
      (tbl) => isAscending ? OrderingTerm.asc(tbl.id) : OrderingTerm.desc(tbl.id),
    ]);

    query.limit(pageSize);

    final salesList = await query.get();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final currencyFormat = NumberFormat('#,##0.00');

    final datasetRows = <ReportRowData>[];
    for (final sale in salesList) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        sale.saleDate > 0 ? sale.saleDate : sale.createdAt,
      );

      datasetRows.add(ReportRowData(
        documentType: 'sales_invoice',
        documentUuid: sale.uuid,
        values: {
          'invoiceDate': dateFormat.format(date),
          'invoiceNumber': sale.saleNumber,
          'customerName': (sale.customerName != null && sale.customerName!.isNotEmpty)
              ? sale.customerName!
              : (sale.settlementType == 'cash' ? 'نقدي' : 'آجل'),
          'paymentType': sale.settlementType == 'cash' ? 'نقدي' : 'آجل',
          'subtotal': currencyFormat.format(sale.subtotal),
          'taxAmount': currencyFormat.format(sale.taxAmount),
          'grandTotal': currencyFormat.format(sale.total),
          'id': sale.id.toString(),
          'saleDateMs': (sale.saleDate > 0 ? sale.saleDate : sale.createdAt).toString(),
        },
      ));
    }

    ReportCursor? nextCursor;
    if (salesList.length == pageSize) {
      final last = salesList.last;
      nextCursor = ReportCursor(
        primarySortValue: last.saleDate > 0 ? last.saleDate : last.createdAt,
        uniqueId: last.id.toString(),
      );
    }

    return ReportPage<ReportRowData>(
      items: datasetRows,
      nextCursor: nextCursor,
      hasNextPage: nextCursor != null,
    );
  }

  void _applySqlFilters({
    required JoinedSelectStatement query,
    required ReportExecutionContext context,
    int? fromMs,
    int? toMs,
    String? customerId,
  }) {
    query.where(salesDb.sales.companyId.equals(context.companyId));

    if (fromMs != null) {
      query.where(salesDb.sales.saleDate.isBiggerOrEqualValue(fromMs));
    }
    if (toMs != null) {
      query.where(salesDb.sales.saleDate.isSmallerOrEqualValue(toMs));
    }
    if (customerId != null && customerId.isNotEmpty) {
      query.where(salesDb.sales.customerId.equals(customerId));
    }

    switch (context.postingScope) {
      case PostingScope.postedOnly:
        query.where(salesDb.sales.saleStatus.equals('posted'));
        break;
      case PostingScope.unpostedOnly:
        query.where(salesDb.sales.saleStatus.equals('draft'));
        break;
      case PostingScope.all:
        query.where(salesDb.sales.saleStatus.equals('cancelled').not());
        break;
    }
  }

  void _applySqlFiltersTyped({
    required SimpleSelectStatement<$SalesTable, SaleRow> query,
    required ReportExecutionContext context,
    int? fromMs,
    int? toMs,
    String? customerId,
  }) {
    query.where((tbl) => tbl.companyId.equals(context.companyId));

    if (fromMs != null) {
      query.where((tbl) => tbl.saleDate.isBiggerOrEqualValue(fromMs));
    }
    if (toMs != null) {
      query.where((tbl) => tbl.saleDate.isSmallerOrEqualValue(toMs));
    }
    if (customerId != null && customerId.isNotEmpty) {
      query.where((tbl) => tbl.customerId.equals(customerId));
    }

    switch (context.postingScope) {
      case PostingScope.postedOnly:
        query.where((tbl) => tbl.saleStatus.equals('posted'));
        break;
      case PostingScope.unpostedOnly:
        query.where((tbl) => tbl.saleStatus.equals('draft'));
        break;
      case PostingScope.all:
        query.where((tbl) => tbl.saleStatus.equals('cancelled').not());
        break;
    }
  }

  /// Legacy interface query fallback
  @override
  Future<ReportDataset> query(ReportQueryContext context) async {
    final execContext = ReportExecutionContext(
      companyId: context.companyId,
      filters: context.parameterValues,
      postingScope: PostingScope.all,
    );

    final summary = await fetchSummary(execContext);
    final firstPage = await fetchPage(execContext, pageSize: 100);

    final currencyFormat = NumberFormat('#,##0.00');

    final metadata = ReportMetadata(
      reportId: reportId,
      reportTitle: 'تقرير مبيعات الفترة والعملاء',
      companyName: companyName,
      currencyCode: context.currencyCode,
      generatedAt: DateTime.now(),
      activeFiltersSummary: 'عدد الفواتير: ${summary.totalCount}',
      totalRowsCount: summary.totalCount,
    );

    final headerCards = [
      ReportHeaderCardData(
        title: 'عدد الفواتير',
        value: summary.totalCount.toString(),
        icon: Icons.receipt_long_rounded,
        accentColor: Colors.blue,
      ),
      ReportHeaderCardData(
        title: 'الإجمالي قبل الضريبة',
        value: currencyFormat.format(summary.aggregates['subtotal'] ?? 0.0),
        icon: Icons.payments_outlined,
        accentColor: Colors.amber,
      ),
      ReportHeaderCardData(
        title: 'إجمالي الضريبة',
        value: currencyFormat.format(summary.aggregates['taxAmount'] ?? 0.0),
        icon: Icons.account_balance_wallet_outlined,
        accentColor: Colors.orange,
      ),
      ReportHeaderCardData(
        title: 'صافي إجمالي المبيعات',
        value: currencyFormat.format(summary.aggregates['grandTotal'] ?? 0.0),
        icon: Icons.monetization_on_outlined,
        accentColor: Colors.green,
      ),
    ];

    return ReportDataset(
      metadata: metadata,
      headerCards: headerCards,
      rows: firstPage.items,
    );
  }
}
