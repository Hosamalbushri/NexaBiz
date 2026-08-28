import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';

/// Specification for a grouped header spanning multiple table columns.
class ReportGroupHeaderSpec {
  const ReportGroupHeaderSpec({
    required this.title,
    required this.startColumnIndex,
    required this.columnSpan,
    this.backgroundColor,
    this.textColor,
  });

  final String title;
  final int startColumnIndex;
  final int columnSpan;
  final Color? backgroundColor;
  final Color? textColor;
}

/// Column definition for [AppDynamicReportTable].
class ReportColumnSpec<T> {
  const ReportColumnSpec({
    required this.id,
    required this.label,
    this.flex = 1,
    this.width,
    this.alignment = Alignment.center,
    this.isNumeric = false,
    this.getValue,
    this.cellBuilder,
    this.headerBackgroundColor,
    this.headerTextColor,
    this.footerValue,
    this.footerCellBuilder,
  });

  final String id;
  final String label;
  final int flex;
  final double? width;
  final Alignment alignment;
  final bool isNumeric;
  final String Function(T item)? getValue;
  final Widget Function(BuildContext context, T item)? cellBuilder;
  final Color? headerBackgroundColor;
  final Color? headerTextColor;
  final String? footerValue;
  final Widget Function(BuildContext context)? footerCellBuilder;
}

/// Header Info Card specification for displaying report metadata above the grid.
class ReportHeaderInfoSpec {
  const ReportHeaderInfoSpec({
    required this.title,
    required this.value,
    this.subValue,
    this.icon,
    this.accentColor,
  });

  final String title;
  final String value;
  final String? subValue;
  final IconData? icon;
  final Color? accentColor;
}

/// Footer summary metric item specification.
class ReportFooterSummarySpec {
  const ReportFooterSummarySpec({
    required this.label,
    required this.value,
    this.columnId,
    this.color,
    this.icon,
  });

  final String label;
  final String value;
  final String? columnId;
  final Color? color;
  final IconData? icon;
}

/// Master Core Dynamic Report Preview Table Component.
///
/// Provides a rich, responsive dynamic preview container for operational reports
/// with support for top metadata cards, grouped multi-level column headers,
/// client-side filtering, zebra-striped data rows, and summary footer rows.
class AppDynamicReportTable<T> extends StatefulWidget {
  const AppDynamicReportTable({
    super.key,
    required this.columns,
    required this.items,
    this.groupHeaders = const [],
    this.headerInfoCards = const [],
    this.footerSummaries = const [],
    this.title,
    this.subtitle,
    this.centerTitle = true,
    this.onExportPdf,
    this.onPrint,
    this.onRefresh,
    this.minTableWidth = 900.0,
    this.emptyTitle = 'لا توجد بيانات',
    this.emptySubtitle = 'لا توجد نتائج مطابقة لخيارات التصفية المختارة',
    this.searchFilterPredicate,
    this.rowBackgroundColorBuilder,
    this.onRowTap,
  });

  final List<ReportColumnSpec<T>> columns;
  final List<T> items;
  final List<ReportGroupHeaderSpec> groupHeaders;
  final List<ReportHeaderInfoSpec> headerInfoCards;
  final List<ReportFooterSummarySpec> footerSummaries;
  final String? title;
  final String? subtitle;
  final bool centerTitle;
  final VoidCallback? onExportPdf;
  final VoidCallback? onPrint;
  final VoidCallback? onRefresh;
  final double minTableWidth;
  final String emptyTitle;
  final String emptySubtitle;

  /// Custom search predicate function.
  final bool Function(T item, String query)? searchFilterPredicate;

  /// Custom row background color builder (e.g. highlight unposted/draft rows).
  final Color? Function(T item)? rowBackgroundColorBuilder;

  /// Callback when a data row is tapped.
  final void Function(T item)? onRowTap;

  @override
  State<AppDynamicReportTable<T>> createState() =>
      _AppDynamicReportTableState<T>();
}

class _AppDynamicReportTableState<T> extends State<AppDynamicReportTable<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Filter items
    final filteredItems = widget.items.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      if (widget.searchFilterPredicate != null) {
        return widget.searchFilterPredicate!(item, _searchQuery.trim());
      }
      // Default search: iterate over column getValue
      final queryLower = _searchQuery.trim().toLowerCase();
      for (final col in widget.columns) {
        if (col.getValue != null) {
          final val = col.getValue!(item);
          if (val.toLowerCase().contains(queryLower)) {
            return true;
          }
        }
      }
      return false;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Report Title & Actions Bar
        if (widget.title != null || widget.onExportPdf != null || widget.onPrint != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: widget.centerTitle
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          textAlign: widget.centerTitle ? TextAlign.center : TextAlign.left,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: scheme.onSurface,
                          ),
                        ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          textAlign: widget.centerTitle ? TextAlign.center : TextAlign.left,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'تحديث البيانات',
                  ),
                if (widget.onExportPdf != null)
                  FilledButton.icon(
                    onPressed: widget.onExportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('تصدير PDF'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (widget.onPrint != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.filledTonal(
                    onPressed: widget.onPrint,
                    icon: const Icon(Icons.print_outlined, size: 20),
                    tooltip: 'طباعة التقرير',
                  ),
                ],
              ],
            ),
          ),

        if (widget.title != null || widget.onExportPdf != null)
          const SizedBox(height: AppSpacing.md),

        // 2. Header Info Metadata Cards Grid
        if (widget.headerInfoCards.isNotEmpty) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.headerInfoCards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 84,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemBuilder: (context, index) {
                  final card = widget.headerInfoCards[index];
                  final accent = card.accentColor ?? scheme.primary;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (card.icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Icon(card.icon, size: 18, color: accent),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: accent,
                                ),
                              ),
                              if (card.subValue != null)
                                Text(
                                  card.subValue!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 3. Search Bar within Table
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'تصفية نتائج الجدول الحالية...',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      prefixIcon: const Icon(Icons.filter_alt_outlined, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 15,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _searchQuery.trim().isNotEmpty
                          ? 'النتائج: ${filteredItems.length} من ${widget.items.length}'
                          : 'إجمالي السجلات: ${widget.items.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 4. Main Dynamic Table Box
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, widget.minTableWidth);
              return Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        // Grouped Row Headers (Level 1)
                        if (widget.groupHeaders.isNotEmpty)
                          _buildGroupedHeaderRow(theme, scheme),

                        // Column Headers (Level 2)
                        _buildColumnHeaderRow(theme, scheme),

                        const Divider(height: 1),

                        // Table Body / Rows
                        if (filteredItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: AppEmptyState(
                              title: widget.emptyTitle,
                              subtitle: widget.emptySubtitle,
                              icon: Icons.table_chart_outlined,
                            ),
                          )
                        else
                          Column(
                            children: [
                              for (int i = 0; i < filteredItems.length; i++)
                                _buildDataRow(
                                  context,
                                  theme,
                                  scheme,
                                  filteredItems[i],
                                  i,
                                ),
                            ],
                          ),

                        // Footer Summary Cards Bar
                        if (widget.footerSummaries.isNotEmpty) ...[
                          const Divider(height: 1),
                          _buildFooterSummaryRow(theme, scheme),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Renders top grouped multi-column headers.
  Widget _buildGroupedHeaderRow(ThemeData theme, ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < widget.columns.length; i++) ...[
              if (_getGroupHeaderForColumn(i) != null)
                _buildGroupHeaderCell(
                  theme,
                  scheme,
                  _getGroupHeaderForColumn(i)!,
                )
              else if (!_isColumnInsideAnyGroup(i))
                Expanded(
                  flex: widget.columns[i].flex,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }


  bool _isColumnInsideAnyGroup(int index) {
    for (final group in widget.groupHeaders) {
      if (index >= group.startColumnIndex &&
          index < group.startColumnIndex + group.columnSpan) {
        return true;
      }
    }
    return false;
  }

  ReportGroupHeaderSpec? _getGroupHeaderForColumn(int index) {
    for (final group in widget.groupHeaders) {
      if (group.startColumnIndex == index) return group;
    }
    return null;
  }

  Widget _buildGroupHeaderCell(
    ThemeData theme,
    ColorScheme scheme,
    ReportGroupHeaderSpec group,
  ) {
    // Calculate total flex sum for the spanned columns
    int flexSum = 0;
    for (int c = group.startColumnIndex;
        c < group.startColumnIndex + group.columnSpan && c < widget.columns.length;
        c++) {
      flexSum += widget.columns[c].flex;
    }

    final bg = group.backgroundColor ?? scheme.primaryContainer.withValues(alpha: 0.5);
    final fg = group.textColor ?? scheme.onPrimaryContainer;

    return Expanded(
      flex: flexSum,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          group.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );
  }

  /// Renders standard column headers with vertical column gridlines.
  Widget _buildColumnHeaderRow(ThemeData theme, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          for (int i = 0; i < widget.columns.length; i++)
            Expanded(
              flex: widget.columns[i].flex,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: widget.columns[i].alignment,
                decoration: BoxDecoration(
                  border: i < widget.columns.length - 1
                      ? Border(
                          right: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.35),
                          ),
                        )
                      : null,
                ),
                child: Text(
                  widget.columns[i].label,
                  textAlign: widget.columns[i].alignment == Alignment.centerRight
                      ? TextAlign.right
                      : widget.columns[i].alignment == Alignment.center
                          ? TextAlign.center
                          : TextAlign.left,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.1,
                    color: widget.columns[i].headerTextColor ?? scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Renders individual data rows with hover state, zebra striping, and column gridlines.
  Widget _buildDataRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    T item,
    int index,
  ) {
    final customBg = widget.rowBackgroundColorBuilder?.call(item);
    final isEven = index % 2 == 0;
    final rowBg = customBg ?? (isEven ? scheme.surface : scheme.surfaceContainerLowest);

    return InkWell(
      onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
      child: _ReportDataRowHoverWidget(
        baseColor: rowBg,
        hoverColor: scheme.primary.withValues(alpha: 0.06),
        borderBottomColor: scheme.outlineVariant.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              for (int i = 0; i < widget.columns.length; i++)
                Expanded(
                  flex: widget.columns[i].flex,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: widget.columns[i].alignment,
                    decoration: BoxDecoration(
                      border: i < widget.columns.length - 1
                          ? Border(
                              right: BorderSide(
                                color: scheme.outlineVariant.withValues(alpha: 0.2),
                              ),
                            )
                          : null,
                    ),
                    child: widget.columns[i].cellBuilder != null
                        ? widget.columns[i].cellBuilder!(context, item)
                        : Text(
                            widget.columns[i].getValue != null
                                ? widget.columns[i].getValue!(item)
                                : '',
                            textAlign: widget.columns[i].alignment == Alignment.centerRight
                                ? TextAlign.right
                                : widget.columns[i].alignment == Alignment.center
                                    ? TextAlign.center
                                    : TextAlign.left,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: widget.columns[i].isNumeric
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                              color: scheme.onSurface,
                              fontFeatures: widget.columns[i].isNumeric
                                  ? const [FontFeature.tabularFigures()]
                                  : null,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders a column-aligned table footer summary row mirroring the column header bar.
  Widget _buildFooterSummaryRow(ThemeData theme, ColorScheme scheme) {
    // Find index of 'description' or first summary column to merge empty preceding cells
    final mergeUntilIndex = widget.columns.indexWhere((c) => c.id == 'description');

    final children = <Widget>[];

    if (mergeUntilIndex > 0) {
      int mergedFlex = 0;
      for (int i = 0; i <= mergeUntilIndex; i++) {
        mergedFlex += widget.columns[i].flex;
      }

      children.add(
        Expanded(
          flex: mergedFlex,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Text(
              'الإجمالي العام',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      );

      for (int i = mergeUntilIndex + 1; i < widget.columns.length; i++) {
        children.add(
          Expanded(
            flex: widget.columns[i].flex,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: widget.columns[i].alignment,
              decoration: BoxDecoration(
                border: i < widget.columns.length - 1
                    ? Border(
                        right: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      )
                    : null,
              ),
              child: _buildFooterCellContent(context, theme, scheme, i),
            ),
          ),
        );
      }
    } else {
      for (int i = 0; i < widget.columns.length; i++) {
        children.add(
          Expanded(
            flex: widget.columns[i].flex,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: widget.columns[i].alignment,
              decoration: BoxDecoration(
                border: i < widget.columns.length - 1
                    ? Border(
                        right: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      )
                    : null,
              ),
              child: _buildFooterCellContent(context, theme, scheme, i),
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: scheme.primary.withValues(alpha: 0.6),
            width: 2.0,
          ),
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: children,
      ),
    );
  }

  Widget _buildFooterCellContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    int columnIndex,
  ) {
    final col = widget.columns[columnIndex];

    if (col.footerCellBuilder != null) {
      return col.footerCellBuilder!(context);
    }

    if (col.footerValue != null) {
      return Text(
        col.footerValue!,
        textAlign: col.alignment == Alignment.centerRight
            ? TextAlign.right
            : col.alignment == Alignment.center
                ? TextAlign.center
                : TextAlign.left,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 13.5,
          color: scheme.primary,
        ),
      );
    }

    // Try finding matched footer summary by columnId or label match
    final summaryIndex = widget.footerSummaries.indexWhere(
      (f) => f.columnId == col.id || f.label == col.label || f.label.contains(col.label),
    );

    if (summaryIndex != -1) {
      final summary = widget.footerSummaries[summaryIndex];
      final itemColor = summary.color ?? (col.isNumeric ? scheme.primary : scheme.onSurface);
      return Text(
        summary.value,
        textAlign: col.alignment == Alignment.centerRight
            ? TextAlign.right
            : col.alignment == Alignment.center
                ? TextAlign.center
                : TextAlign.left,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 13.5,
          color: itemColor,
          fontFeatures: col.isNumeric ? const [FontFeature.tabularFigures()] : null,
        ),
      );
    }

    // If description column, show Grand Total label
    if (col.id == 'description') {
      return Text(
        'الإجمالي العام',
        textAlign: col.alignment == Alignment.centerRight
            ? TextAlign.right
            : col.alignment == Alignment.center
                ? TextAlign.center
                : TextAlign.left,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 13.5,
          color: scheme.onSurface,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Helper widget to handle hover animations for data rows.
class _ReportDataRowHoverWidget extends StatefulWidget {
  const _ReportDataRowHoverWidget({
    required this.child,
    required this.baseColor,
    required this.hoverColor,
    required this.borderBottomColor,
  });

  final Widget child;
  final Color baseColor;
  final Color hoverColor;
  final Color borderBottomColor;

  @override
  State<_ReportDataRowHoverWidget> createState() => _ReportDataRowHoverWidgetState();
}

class _ReportDataRowHoverWidgetState extends State<_ReportDataRowHoverWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? widget.hoverColor : widget.baseColor,
          border: Border(
            bottom: BorderSide(
              color: widget.borderBottomColor,
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
