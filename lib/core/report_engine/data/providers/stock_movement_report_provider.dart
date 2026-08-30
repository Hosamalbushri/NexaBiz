import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';
import '../../domain/models/report_cursor.dart';
import '../../domain/models/report_dataset.dart';
import '../../domain/models/report_execution_context.dart';
import '../../domain/models/report_page.dart';
import '../../domain/models/report_query_context.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/services/paged_report_data_provider.dart';
import 'report_data_provider.dart';

/// SQL-Native, Paged Data Provider executing Stock Movement Queries for ERP Engine.
/// Strictly read-only, keyset paginated, tenant-isolated, and memory efficient.
class StockMovementReportDataProvider
    implements ReportDataProvider, PagedReportDataProvider<ReportRowData> {
  StockMovementReportDataProvider({
    required this.inventoryDb,
    this.salesDb,
    this.companyName = 'شركة نكسا بيز NexaBiz',
  });

  final InventoryDatabase inventoryDb;
  final SalesDatabase? salesDb;
  final String companyName;

  @override
  String get reportId => 'stock_movement';

  /// SQL-Native Summary Aggregation
  @override
  Future<ReportSummary> fetchSummary(ReportExecutionContext context) async {
    final productCode = context.filters['productCode'] as String?;
    final statementType = context.filters['statementType'] as String? ?? 'detailed';
    final fromDate = context.fromDate;
    final toDate = context.toDate;

    final fromMs = fromDate != null ? fromDate.millisecondsSinceEpoch : null;
    final toMs = toDate != null
        ? toDate.add(const Duration(days: 1)).millisecondsSinceEpoch
        : null;

    if (statementType == 'summary') {
      final subQuery = inventoryDb.selectOnly(inventoryDb.stockMovementLines)
        ..addColumns([inventoryDb.stockMovementLines.itemCode]);
      _applySqlFilters(
        query: subQuery,
        context: context,
        productCode: productCode,
        fromMs: fromMs,
        toMs: toMs,
      );
      final itemRows = await subQuery.get();
      final uniqueCount = itemRows.map((r) => r.read(inventoryDb.stockMovementLines.itemCode)).toSet().length;

      final aggQuery = inventoryDb.selectOnly(inventoryDb.stockMovementLines)
        ..addColumns([
          inventoryDb.stockMovementLines.quantity.sum(),
          inventoryDb.stockMovementLines.totalCost.sum(),
        ]);
      _applySqlFilters(
        query: aggQuery,
        context: context,
        productCode: productCode,
        fromMs: fromMs,
        toMs: toMs,
      );

      final aggRow = await aggQuery.getSingle();
      final totalQty = aggRow.read(inventoryDb.stockMovementLines.quantity.sum()) ?? 0.0;
      final totalCost = aggRow.read(inventoryDb.stockMovementLines.totalCost.sum()) ?? 0.0;

      return ReportSummary(
        totalCount: uniqueCount,
        aggregates: {
          'totalQty': totalQty,
          'totalValue': totalCost,
        },
        kpis: {
          'totalCount': uniqueCount,
        },
      );
    }

    final query = inventoryDb.selectOnly(inventoryDb.stockMovementLines)
      ..addColumns([
        inventoryDb.stockMovementLines.id.count(),
        inventoryDb.stockMovementLines.quantity.sum(),
        inventoryDb.stockMovementLines.totalCost.sum(),
      ]);

    _applySqlFilters(
      query: query,
      context: context,
      productCode: productCode,
      fromMs: fromMs,
      toMs: toMs,
    );

    final row = await query.getSingle();
    final count = row.read(inventoryDb.stockMovementLines.id.count()) ?? 0;
    final totalQty = row.read(inventoryDb.stockMovementLines.quantity.sum()) ?? 0.0;
    final totalCost = row.read(inventoryDb.stockMovementLines.totalCost.sum()) ?? 0.0;

    return ReportSummary(
      totalCount: count,
      aggregates: {
        'totalQty': totalQty,
        'totalValue': totalCost,
      },
      kpis: {
        'totalCount': count,
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
    final productCode = context.filters['productCode'] as String?;
    final statementType = context.filters['statementType'] as String? ?? 'detailed';
    final fromDate = context.fromDate;
    final toDate = context.toDate;

    final fromMs = fromDate != null ? fromDate.millisecondsSinceEpoch : null;
    final toMs = toDate != null
        ? toDate.add(const Duration(days: 1)).millisecondsSinceEpoch
        : null;

    final dateFormat = DateFormat('yyyy/MM/dd');
    final currencyFormat = NumberFormat('#,##0.00');
    final qtyFormat = NumberFormat('#,##0');

    if (statementType == 'summary') {
      final query = inventoryDb.select(inventoryDb.stockMovementLines);
      _applySqlFiltersTyped(
        query: query,
        context: context,
        productCode: productCode,
        fromMs: fromMs,
        toMs: toMs,
      );

      final allLines = await query.get();

      final summaryMap = <String, Map<String, dynamic>>{};
      for (final l in allLines) {
        final key = l.itemCode.isNotEmpty ? l.itemCode : l.itemName;
        final entry = summaryMap.putIfAbsent(key, () => {
          'itemCode': l.itemCode,
          'itemName': l.itemName.isNotEmpty ? l.itemName : l.itemCode,
          'inMain': 0.0,
          'inSub': 0.0,
          'outMain': 0.0,
          'outSub': 0.0,
          'totalCost': 0.0,
        });

        final isIn = l.movementType == 'receipt';
        final mainQty = l.mainQuantity > 0 ? l.mainQuantity : l.quantity;
        final subQty = l.subQuantity;

        if (isIn) {
          entry['inMain'] = (entry['inMain'] as double) + mainQty;
          entry['inSub'] = (entry['inSub'] as double) + subQty;
        } else {
          entry['outMain'] = (entry['outMain'] as double) + mainQty;
          entry['outSub'] = (entry['outSub'] as double) + subQty;
        }
        entry['totalCost'] = (entry['totalCost'] as double) + (l.totalCost > 0 ? l.totalCost : l.quantity * (l.postedCost ?? l.unitCost));
      }

      final summaryList = summaryMap.values.toList();

      int offset = 0;
      if (cursor != null) {
        offset = int.tryParse(cursor.uniqueId) ?? 0;
      }

      final chunk = summaryList.skip(offset).take(pageSize).toList();
      final hasNext = summaryList.length > offset + chunk.length;

      final datasetRows = <ReportRowData>[];
      for (int i = 0; i < chunk.length; i++) {
        final row = chunk[i];
        final inMain = row['inMain'] as double;
        final inSub = row['inSub'] as double;
        final outMain = row['outMain'] as double;
        final outSub = row['outSub'] as double;
        final netMain = inMain - outMain;
        final totalVal = row['totalCost'] as double;
        final unitCost = netMain != 0 ? totalVal / netMain.abs() : 0.0;

        datasetRows.add(ReportRowData(
          documentType: 'summary_product',
          documentUuid: row['itemCode'] as String,
          values: {
            'transactionDate': '-',
            'documentTypeLabel': 'كشف إجمالي',
            'documentNumber': '-',
            'productName': row['itemName'] as String,
            'inMainQuantity': qtyFormat.format(inMain),
            'inSubQuantity': inSub > 0 ? qtyFormat.format(inSub) : '-',
            'outMainQuantity': qtyFormat.format(outMain),
            'outSubQuantity': outSub > 0 ? qtyFormat.format(outSub) : '-',
            'balanceQuantity': qtyFormat.format(netMain),
            'unitCost': currencyFormat.format(unitCost),
            'totalValue': currencyFormat.format(totalVal),
            'id': (offset + i).toString(),
          },
        ));
      }

      ReportCursor? nextCursor;
      if (hasNext) {
        nextCursor = ReportCursor(
          primarySortValue: offset + chunk.length,
          uniqueId: (offset + chunk.length).toString(),
        );
      }

      return ReportPage<ReportRowData>(
        items: datasetRows,
        nextCursor: nextCursor,
        hasNextPage: hasNext,
      );
    }

    // Detailed Statement
    final query = inventoryDb.select(inventoryDb.stockMovementLines);
    _applySqlFiltersTyped(
      query: query,
      context: context,
      productCode: productCode,
      fromMs: fromMs,
      toMs: toMs,
    );

    final isAscending = context.sorting.ascending;

    if (cursor != null) {
      final cursorId = int.parse(cursor.uniqueId);
      if (isAscending) {
        query.where((tbl) => tbl.id.isBiggerThanValue(cursorId));
      } else {
        query.where((tbl) => tbl.id.isSmallerThanValue(cursorId));
      }
    }

    query.orderBy([
      (tbl) => isAscending ? drift.OrderingTerm.asc(tbl.id) : drift.OrderingTerm.desc(tbl.id),
    ]);

    query.limit(pageSize);

    final lines = await query.get();

    final receiptUuids = lines
        .where((l) => l.movementType == 'receipt')
        .map((l) => l.movementUuid)
        .toSet();
    final issueUuids = lines
        .where((l) => l.movementType == 'issue')
        .map((l) => l.movementUuid)
        .toSet();

    final receiptsMap = <String, StockReceiptRow>{};
    if (receiptUuids.isNotEmpty) {
      final recRows = await (inventoryDb.select(inventoryDb.stockReceipts)
            ..where((tbl) => tbl.uuid.isIn(receiptUuids)))
          .get();
      for (final r in recRows) {
        receiptsMap[r.uuid] = r;
      }
    }

    final issuesMap = <String, StockIssueRow>{};
    if (issueUuids.isNotEmpty) {
      final issRows = await (inventoryDb.select(inventoryDb.stockIssues)
            ..where((tbl) => tbl.uuid.isIn(issueUuids)))
          .get();
      for (final i in issRows) {
        issuesMap[i.uuid] = i;
      }
    }

    final datasetRows = <ReportRowData>[];

    for (final line in lines) {
      final isIn = line.movementType == 'receipt';
      final rec = receiptsMap[line.movementUuid];
      final iss = issuesMap[line.movementUuid];

      final docNum = rec?.receiptNumber ?? iss?.issueNumber ?? line.movementUuid;
      final docDateMs = rec?.receiptDate ?? iss?.issueDate ?? line.postedAt ?? 0;
      final docDate = DateTime.fromMillisecondsSinceEpoch(
        docDateMs > 0 ? docDateMs : DateTime.now().millisecondsSinceEpoch,
      );

      final cost = line.postedCost ?? line.unitCost;
      final totalLineCost = line.totalCost > 0 ? line.totalCost : line.quantity * cost;
      final mainQty = line.mainQuantity > 0 ? line.mainQuantity : line.quantity;
      final subQty = line.subQuantity;

      datasetRows.add(ReportRowData(
        documentType: isIn ? 'stock_receipt' : 'stock_issue',
        documentUuid: line.movementUuid,
        values: {
          'transactionDate': dateFormat.format(docDate),
          'documentTypeLabel': isIn ? 'أمر توريد' : 'أمر صرف',
          'documentNumber': docNum,
          'productName': line.itemName.isNotEmpty ? line.itemName : line.itemCode,
          'inMainQuantity': isIn ? qtyFormat.format(mainQty) : '-',
          'inSubQuantity': isIn && subQty > 0 ? qtyFormat.format(subQty) : '-',
          'outMainQuantity': !isIn ? qtyFormat.format(mainQty) : '-',
          'outSubQuantity': !isIn && subQty > 0 ? qtyFormat.format(subQty) : '-',
          'balanceQuantity': qtyFormat.format(mainQty),
          'unitCost': currencyFormat.format(cost),
          'totalValue': currencyFormat.format(totalLineCost),
          'id': line.id.toString(),
        },
      ));
    }

    ReportCursor? nextCursor;
    if (lines.length == pageSize) {
      nextCursor = ReportCursor(
        primarySortValue: lines.last.id,
        uniqueId: lines.last.id.toString(),
      );
    }

    return ReportPage<ReportRowData>(
      items: datasetRows,
      nextCursor: nextCursor,
      hasNextPage: nextCursor != null,
    );
  }

  void _applySqlFilters({
    required drift.JoinedSelectStatement query,
    required ReportExecutionContext context,
    String? productCode,
    int? fromMs,
    int? toMs,
  }) {
    if (productCode != null && productCode.isNotEmpty) {
      query.where(
        inventoryDb.stockMovementLines.itemCode.equals(productCode) |
            inventoryDb.stockMovementLines.movementUuid.equals(productCode),
      );
    }
    if (fromMs != null) {
      query.where(inventoryDb.stockMovementLines.postedAt.isBiggerOrEqualValue(fromMs));
    }
    if (toMs != null) {
      query.where(inventoryDb.stockMovementLines.postedAt.isSmallerOrEqualValue(toMs));
    }

    switch (context.postingScope) {
      case PostingScope.postedOnly:
        query.where(inventoryDb.stockMovementLines.postedAt.isNotNull());
        break;
      case PostingScope.unpostedOnly:
        query.where(inventoryDb.stockMovementLines.postedAt.isNull());
        break;
      case PostingScope.all:
        break;
    }
  }

  void _applySqlFiltersTyped({
    required drift.SimpleSelectStatement<$StockMovementLinesTable, StockMovementLineRow> query,
    required ReportExecutionContext context,
    String? productCode,
    int? fromMs,
    int? toMs,
  }) {
    if (productCode != null && productCode.isNotEmpty) {
      query.where(
        (tbl) =>
            tbl.itemCode.equals(productCode) |
            tbl.movementUuid.equals(productCode),
      );
    }
    if (fromMs != null) {
      query.where((tbl) => tbl.postedAt.isBiggerOrEqualValue(fromMs));
    }
    if (toMs != null) {
      query.where((tbl) => tbl.postedAt.isSmallerOrEqualValue(toMs));
    }

    switch (context.postingScope) {
      case PostingScope.postedOnly:
        query.where((tbl) => tbl.postedAt.isNotNull());
        break;
      case PostingScope.unpostedOnly:
        query.where((tbl) => tbl.postedAt.isNull());
        break;
      case PostingScope.all:
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
      reportTitle: 'تقرير حركة الأصناف والمخزون',
      companyName: companyName,
      currencyCode: context.currencyCode,
      generatedAt: DateTime.now(),
      activeFiltersSummary: 'عدد الحركات: ${summary.totalCount}',
      totalRowsCount: summary.totalCount,
    );

    final headerCards = [
      ReportHeaderCardData(
        title: 'عدد الحركات المنفذة',
        value: summary.totalCount.toString(),
        icon: Icons.inventory_2_outlined,
        accentColor: Colors.blue,
      ),
      ReportHeaderCardData(
        title: 'إجمالي الكميات',
        value: (summary.aggregates['totalQty'] ?? 0.0).toStringAsFixed(0),
        icon: Icons.add_circle_outline_rounded,
        accentColor: Colors.green,
      ),
      ReportHeaderCardData(
        title: 'إجمالي القيمة التقديرية',
        value: currencyFormat.format(summary.aggregates['totalValue'] ?? 0.0),
        icon: Icons.payments_outlined,
        accentColor: Colors.purple,
      ),
    ];

    return ReportDataset(
      metadata: metadata,
      headerCards: headerCards,
      rows: firstPage.items,
    );
  }
}
