import 'package:flutter/material.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_dynamic_report_table.dart' as table;
import 'package:stock_count/core/widgets/app_responsive_scaffold.dart';
import '../../application/universal_report_execution_controller.dart';
import '../../domain/adapters/report_dataset_compatibility_adapter.dart';
import '../../domain/models/report_dataset.dart';
import '../../domain/models/report_definition_spec.dart';
import '../../domain/models/report_page.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/services/report_drill_down_handler.dart';
import '../../export/pdf_report_exporter.dart';

/// Full-screen Table View page supporting incremental infinite scrolling & real-time KPI updates.
class UniversalReportTableViewPage extends StatefulWidget {
  const UniversalReportTableViewPage({
    super.key,
    required this.definition,
    this.controller,
    this.dataset,
    this.companyName = 'NexaBiz ERP',
  });

  final ReportDefinitionSpec definition;
  final UniversalReportExecutionController? controller;
  final ReportDataset? dataset;
  final String companyName;

  @override
  State<UniversalReportTableViewPage> createState() => _UniversalReportTableViewPageState();
}

class _UniversalReportTableViewPageState extends State<UniversalReportTableViewPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.controller;
    if (controller == null) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.fetchNextPage();
    }
  }

  bool _checkIsPosted(ReportRowData row) {
    final isPostedVal = row['isPosted'] ?? row['posted'] ?? row['is_posted'];
    if (isPostedVal is bool) return isPostedVal;
    if (isPostedVal is int) return isPostedVal == 1;
    if (isPostedVal is String) {
      final s = isPostedVal.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'posted' || s == 'مرحل') return true;
      if (s == 'false' || s == '0' || s == 'unposted' || s == 'draft' || s == 'غير مرحل') return false;
    }
    final status = row['postingStatus']?.toString().toLowerCase();
    if (status != null) {
      if (status.contains('unposted') || status.contains('draft') || status.contains('غير مرحل')) {
        return false;
      }
    }
    return true;
  }

  List<table.ReportColumnSpec<ReportRowData>> _buildTableColumns(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return widget.definition.columns.where((c) => c.isVisible).map((col) {
      final isDateColumn = col.id.toLowerCase().contains('date') || col.label.contains('تاريخ');

      return table.ReportColumnSpec<ReportRowData>(
        id: col.id,
        label: col.label,
        flex: col.flex,
        width: col.width,
        alignment: col.alignment,
        isNumeric: col.isNumeric,
        cellBuilder: isDateColumn
            ? (context, row) {
                final isPosted = _checkIsPosted(row);
                final val = row[col.id]?.toString() ?? '';
                return Text(
                  val,
                  textAlign: col.alignment == Alignment.center
                      ? TextAlign.center
                      : (col.isNumeric ? TextAlign.right : TextAlign.left),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: !isPosted ? FontWeight.bold : FontWeight.normal,
                    color: !isPosted ? scheme.error : null,
                  ),
                );
              }
            : null,
        getValue: (row) {
          final val = row[col.id];
          if (val == null) return '';
          return val.toString();
        },
      );
    }).toList();
  }

  List<table.ReportHeaderInfoSpec> _buildHeaderCards(UniversalReportState state) {
    if (widget.dataset != null) {
      return widget.dataset!.headerCards
          .map(
            (card) => table.ReportHeaderInfoSpec(
              title: card.title,
              value: card.value,
              subValue: card.subValue,
              icon: card.icon,
              accentColor: card.accentColor,
            ),
          )
          .toList();
    }

    final summary = state.summary;
    if (summary == null) return const [];

    final cards = <table.ReportHeaderInfoSpec>[];
    cards.add(table.ReportHeaderInfoSpec(
      title: 'إجمالي السجلات',
      value: summary.totalCount.toString(),
      icon: Icons.numbers_rounded,
      accentColor: Colors.blue,
    ));

    summary.aggregates.forEach((key, val) {
      cards.add(table.ReportHeaderInfoSpec(
        title: key,
        value: val.toStringAsFixed(2),
        icon: Icons.analytics_outlined,
        accentColor: Colors.teal,
      ));
    });

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (widget.controller != null) {
      return ValueListenableBuilder<UniversalReportState>(
        valueListenable: widget.controller!,
        builder: (context, state, _) {
          final scheme = Theme.of(context).colorScheme;

          if (state.isLoadingFirstPage && state.items.isEmpty) {
            return AppResponsiveScaffold(
              appBar: AppBar(
                title: Text(widget.definition.name),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isAr ? 'جاري تحميل وتجهيز التقرير...' : 'Loading report data...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isAr ? 'يرجى الانتظار لحين استعلام قاعدة البيانات' : 'Please wait while records are fetched',
                      style: TextStyle(color: scheme.outline, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!state.isLoadingFirstPage && state.items.isEmpty && state.pageError == null) {
            return AppResponsiveScaffold(
              appBar: AppBar(
                title: Text(widget.definition.name),
                actions: [
                  IconButton(
                    tooltip: isAr ? 'تحديث' : 'Refresh',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => widget.controller!.refresh(),
                  ),
                ],
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_rows_outlined,
                        size: 64,
                        color: scheme.outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isAr ? 'لا توجد بيانات مطابقة لمعايير التصفية المحددة' : 'No records match selected query criteria',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => widget.controller!.refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(isAr ? 'إعادة الاستعلام' : 'Re-query'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return AppResponsiveScaffold(
            appBar: AppBar(
              title: Text(widget.definition.name),
              actions: [
                IconButton(
                  tooltip: isAr ? 'تحديث' : 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => widget.controller!.refresh(),
                ),
                IconButton(
                  tooltip: isAr ? 'طباعة / PDF' : 'Print / PDF',
                  icon: const Icon(Icons.print_rounded, color: Colors.blue),
                  onPressed: () {
                    final dataset = ReportDatasetCompatibilityAdapter.fromPagedResult(
                      reportId: widget.definition.id,
                      reportTitle: widget.definition.name,
                      companyName: widget.companyName,
                      currencyCode: state.context.currencyScope,
                      summary: state.summary ?? const ReportSummary(totalCount: 0),
                      firstPage: ReportPage(
                        items: state.items,
                        nextCursor: state.nextCursor,
                        hasNextPage: state.hasNextPage,
                      ),
                      headerCards: const [],
                    );
                    PdfReportExporter.openPrintPreview(
                      context: context,
                      definition: widget.definition,
                      dataset: dataset,
                      companyName: widget.companyName,
                    );
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  Expanded(
                    child: table.AppDynamicReportTable<ReportRowData>(
                      title: widget.definition.name,
                      subtitle: 'إجمالي السجلات: ${state.summary?.totalCount ?? 0}',
                      minTableWidth: widget.definition.minTableWidth,
                      columns: _buildTableColumns(context),
                      items: state.items,
                      headerInfoCards: _buildHeaderCards(state),
                      onRowTap: (row) {
                        if (row.documentType != null && row.documentUuid != null) {
                          ReportDrillDownHandler.navigateToDocument(
                            context,
                            documentType: row.documentType!,
                            documentUuid: row.documentUuid!,
                          );
                        }
                      },
                    ),
                  ),
                  if (state.isLoadingNextPage) ...[
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],
                  if (state.pageError != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'خطأ أثناء تحميل الصفحة التالية: ${state.pageError}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          TextButton.icon(
                            onPressed: () => widget.controller!.fetchNextPage(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    // Fallback for direct dataset rendering
    final dataset = widget.dataset!;
    return AppResponsiveScaffold(
      appBar: AppBar(
        title: Text(widget.definition.name),
        actions: [
          IconButton(
            tooltip: isAr ? 'طباعة / PDF' : 'Print / PDF',
            icon: const Icon(Icons.print_rounded, color: Colors.blue),
            onPressed: () {
              PdfReportExporter.openPrintPreview(
                context: context,
                definition: widget.definition,
                dataset: dataset,
                companyName: widget.companyName,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: table.AppDynamicReportTable<ReportRowData>(
          title: widget.definition.name,
          subtitle: dataset.metadata.activeFiltersSummary,
          minTableWidth: widget.definition.minTableWidth,
          columns: _buildTableColumns(context),
          items: dataset.rows,
          headerInfoCards: dataset.headerCards
              .map(
                (card) => table.ReportHeaderInfoSpec(
                  title: card.title,
                  value: card.value,
                  subValue: card.subValue,
                  icon: card.icon,
                  accentColor: card.accentColor,
                ),
              )
              .toList(),
          onRowTap: (row) {
            if (row.documentType != null && row.documentUuid != null) {
              ReportDrillDownHandler.navigateToDocument(
                context,
                documentType: row.documentType!,
                documentUuid: row.documentUuid!,
              );
            }
          },
        ),
      ),
    );
  }
}
