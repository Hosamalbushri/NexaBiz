import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';

/// Syncfusion DataGrid for one page of inventory report rows.
class ReportItemsDataGrid extends StatefulWidget {
  const ReportItemsDataGrid({
    super.key,
    required this.items,
    required this.statusLabel,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  final List<InventoryItem> items;
  final String Function(ItemStatus status) statusLabel;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  State<ReportItemsDataGrid> createState() => _ReportItemsDataGridState();
}

class _ReportItemsDataGridState extends State<ReportItemsDataGrid> {
  late InventoryReportDataSource _source;

  @override
  void initState() {
    super.initState();
    _rebuildSource();
  }

  @override
  void didUpdateWidget(covariant ReportItemsDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.statusLabel != widget.statusLabel) {
      _rebuildSource();
    }
  }

  void _rebuildSource() {
    _source = InventoryReportDataSource(
      items: widget.items,
      statusLabel: widget.statusLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final totalPages = widget.totalCount == 0
        ? 0
        : (widget.totalCount / widget.pageSize).ceil();

    return AppCard(
      padding: EdgeInsets.zero,
      animate: false,
      child: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              child: SfDataGrid(
              source: _source,
              allowSorting: false,
              rowHeight: 52,
              headerRowHeight: 48,
              gridLinesVisibility: GridLinesVisibility.horizontal,
              headerGridLinesVisibility: GridLinesVisibility.none,
              columnWidthMode: ColumnWidthMode.fill,
              columns: [
                GridColumn(
                  columnName: 'code',
                  minimumWidth: 90,
                  label: _header(context, localization.codeLabel),
                ),
                GridColumn(
                  columnName: 'name',
                  minimumWidth: 140,
                  label: _header(context, localization.itemName),
                ),
                GridColumn(
                  columnName: 'main',
                  minimumWidth: 100,
                  label: _header(context, localization.mainQuantity),
                ),
                GridColumn(
                  columnName: 'sub',
                  minimumWidth: 100,
                  label: _header(context, localization.subQuantity),
                ),
                GridColumn(
                  columnName: 'status',
                  minimumWidth: 110,
                  label: _header(context, localization.status),
                ),
              ],
            ),
            ),
          ),
          const Divider(height: 1),
          _ReportPager(
            page: widget.page,
            totalPages: totalPages,
            totalCount: widget.totalCount,
            pageSize: widget.pageSize,
            onPageChanged: widget.onPageChanged,
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ReportPager extends StatelessWidget {
  const _ReportPager({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final canPrev = page > 0;
    final canNext = totalPages > 0 && page < totalPages - 1;
    final from = totalCount == 0 ? 0 : page * pageSize + 1;
    final to =
        totalCount == 0 ? 0 : ((page + 1) * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              localization.paginationRange(from, to, totalCount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            tooltip: localization.previousPage,
            onPressed: canPrev ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            localization.paginationPage(
              totalPages == 0 ? 0 : page + 1,
              totalPages,
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          IconButton(
            tooltip: localization.nextPage,
            onPressed: canNext ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class InventoryReportDataSource extends DataGridSource {
  InventoryReportDataSource({
    required List<InventoryItem> items,
    required String Function(ItemStatus status) statusLabel,
  }) {
    _rows = [
      for (final item in items)
        DataGridRow(
          cells: [
            DataGridCell<String>(columnName: 'code', value: item.itemCode),
            DataGridCell<String>(columnName: 'name', value: item.itemName),
            DataGridCell<String>(
              columnName: 'main',
              value: _formatQuantity(item.mainQuantity),
            ),
            DataGridCell<String>(
              columnName: 'sub',
              value: _formatQuantity(item.subQuantity),
            ),
            DataGridCell<_StatusCell>(
              columnName: 'status',
              value: _StatusCell(
                label: statusLabel(item.status),
                status: item.status,
              ),
            ),
          ],
        ),
    ];
  }

  List<DataGridRow> _rows = [];

  static String _formatQuantity(double? value) {
    if (value == null) {
      return '-';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = _rows.indexOf(row);
    final isOdd = index.isOdd;

    return DataGridRowAdapter(
      color: isOdd ? AppColors.neutralContainer : null,
      cells: row.getCells().map(_buildCell).toList(growable: false),
    );
  }

  Widget _buildCell(DataGridCell<dynamic> cell) {
    final value = cell.value;

    if (value is _StatusCell) {
      final colors = _statusColors(value.status);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: colors.$1,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            value.label,
            style: TextStyle(
              color: colors.$2,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final text = '$value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, overflow: TextOverflow.ellipsis),
    );
  }

  (Color, Color) _statusColors(ItemStatus status) {
    switch (status) {
      case ItemStatus.matched:
        return (AppColors.successContainer, AppColors.success);
      case ItemStatus.shortage:
        return (AppColors.warningContainer, AppColors.warning);
      case ItemStatus.overage:
        return (AppColors.infoContainer, AppColors.info);
      case ItemStatus.notCounted:
        return (AppColors.neutralContainer, AppColors.neutral);
    }
  }
}

class _StatusCell {
  const _StatusCell({
    required this.label,
    required this.status,
  });

  final String label;
  final ItemStatus status;
}
