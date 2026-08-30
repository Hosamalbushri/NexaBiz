import 'package:flutter/material.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_responsive_scaffold.dart';
import 'package:stock_count/core/widgets/app_report_query_filter_panel.dart';
import '../../application/universal_report_execution_controller.dart';
import '../../data/providers/report_data_provider.dart';
import '../../domain/models/report_dataset.dart';
import '../../domain/models/report_definition_spec.dart';
import '../../domain/models/report_execution_context.dart';
import '../../domain/models/report_query_context.dart';
import '../../domain/services/paged_report_data_provider.dart';
import '../../export/pdf_report_exporter.dart';
import '../widgets/app_dynamic_filter_generator.dart';
import '../widgets/app_report_preset_bar.dart';
import 'universal_report_table_view_page.dart';

/// Universal Master Report Viewer Screen for NexaBiz ERP.
/// Renders report filter options and triggers paged execution table view or PDF print preview.
class UniversalReportViewerPage extends StatefulWidget {
  const UniversalReportViewerPage({
    super.key,
    required this.definition,
    required this.dataProvider,
    this.companyId = 'DEFAULT_COMPANY',
    this.userId = 'DEFAULT_USER',
    this.currencyCode = 'SAR',
  });

  final ReportDefinitionSpec definition;
  final ReportDataProvider dataProvider;
  final String companyId;
  final String userId;
  final String currencyCode;

  @override
  State<UniversalReportViewerPage> createState() => _UniversalReportViewerPageState();
}

class _UniversalReportViewerPageState extends State<UniversalReportViewerPage> {
  late Map<String, dynamic> _filterValues;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initDefaultFilters();
  }

  void _initDefaultFilters() {
    _filterValues = {};
    for (final param in widget.definition.parameters) {
      if (param.defaultValue != null) {
        _filterValues[param.id] = param.defaultValue;
      }
    }
  }

  ReportExecutionContext _buildExecutionContext() {
    final postingStatusStr = _filterValues['postingStatus'] as String?;
    return ReportExecutionContext(
      companyId: widget.companyId,
      userId: widget.userId,
      filters: Map<String, dynamic>.from(_filterValues),
      postingScope: PostingScopeX.fromString(postingStatusStr),
      currencyScope: widget.currencyCode,
    );
  }

  Future<ReportDataset?> _executeQuery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryCtx = ReportQueryContext(
        companyId: widget.companyId,
        userId: widget.userId,
        currencyCode: widget.currencyCode,
        parameterValues: _filterValues,
        fromDate: _filterValues['fromDate'] as DateTime?,
        toDate: _filterValues['toDate'] as DateTime?,
      );

      final result = await widget.dataProvider.query(queryCtx);

      setState(() {
        _isLoading = false;
      });
      return result;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      return null;
    }
  }

  Future<void> _handlePrintPreview() async {
    final dataset = await _executeQuery();
    if (dataset != null && mounted) {
      await PdfReportExporter.openPrintPreview(
        context: context,
        definition: widget.definition,
        dataset: dataset,
        companyName: 'NexaBiz ERP',
      );
    }
  }

  Future<void> _handleTableView() async {
    final provider = widget.dataProvider;
    if (provider is PagedReportDataProvider) {
      final pagedProvider = provider as PagedReportDataProvider<ReportRowData>;
      final execContext = _buildExecutionContext();
      final controller = UniversalReportExecutionController(
        provider: pagedProvider,
        initialContext: execContext,
      );

      controller.executeNewContext(execContext);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UniversalReportTableViewPage(
              definition: widget.definition,
              controller: controller,
              companyName: 'NexaBiz ERP',
            ),
          ),
        );
      }
      return;
    }

    final dataset = await _executeQuery();
    if (dataset != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UniversalReportTableViewPage(
            definition: widget.definition,
            dataset: dataset,
            companyName: 'NexaBiz ERP',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AppResponsiveScaffold(
      appBar: AppBar(
        title: Text(widget.definition.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        children: [
          // Standard ERP Filter Panel
          AppReportQueryFilterPanel(
            title: isAr ? 'خيارات وتصفية التقرير' : 'Report Criteria & Options',
            showDateRange: widget.definition.parameters.any((p) => p.id == 'dateRange' || p.id == 'fromDate' || p.id == 'toDate'),
            showPostingStatus: widget.definition.parameters.any((p) => p.id == 'postingStatus'),
            isLoading: _isLoading,
            onPrint: _handlePrintPreview,
            onViewAsTable: _handleTableView,
            onApply: (queryData) {
              setState(() {
                if (queryData.fromDate != null) _filterValues['fromDate'] = queryData.fromDate;
                if (queryData.toDate != null) _filterValues['toDate'] = queryData.toDate;
                _filterValues['postingStatus'] = queryData.postingStatus.name;
              });
              _handleTableView();
            },
            extraFilters: [
              AppReportPresetBar(
                reportId: widget.definition.id,
                currentFilterValues: _filterValues,
                onSelectPreset: (preset) {
                  setState(() {
                    _filterValues = Map<String, dynamic>.from(preset.filterValues);
                  });
                },
                onClearPreset: () {
                  setState(() => _initDefaultFilters());
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              AppDynamicFilterGenerator(
                parameters: widget.definition.parameters
                    .where((p) => p.id != 'fromDate' && p.id != 'toDate' && p.id != 'postingStatus')
                    .toList(),
                values: _filterValues,
                onChanged: (vals) {
                  setState(() => _filterValues = vals);
                },
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
