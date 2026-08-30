import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_report_entity_search_field.dart';
import 'package:stock_count/core/widgets/app_report_query_filter_panel.dart';
import '../../domain/models/report_parameter_spec.dart';
import '../../domain/services/report_relative_date_evaluator.dart';

/// Auto-generates interactive filter form UI based on [List<ReportParameterSpec>].
/// Handles dynamic relative dates, entity pickers, cascading dependencies, and posting status choices.
class AppDynamicFilterGenerator extends StatefulWidget {
  const AppDynamicFilterGenerator({
    super.key,
    required this.parameters,
    required this.values,
    required this.onChanged,
  });

  final List<ReportParameterSpec> parameters;
  final Map<String, dynamic> values;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<AppDynamicFilterGenerator> createState() => _AppDynamicFilterGeneratorState();
}

class _AppDynamicFilterGeneratorState extends State<AppDynamicFilterGenerator> {
  late Map<String, dynamic> _currentValues;
  ReportRelativeDateRange _selectedRelativeDate = ReportRelativeDateRange.custom;

  @override
  void initState() {
    super.initState();
    _currentValues = Map<String, dynamic>.from(widget.values);
  }

  @override
  void didUpdateWidget(covariant AppDynamicFilterGenerator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values != oldWidget.values) {
      _currentValues = Map<String, dynamic>.from(widget.values);
    }
  }

  void _updateValue(String key, dynamic value) {
    setState(() {
      _currentValues[key] = value;
      // Handle cascading clear for dependent parameters
      for (final param in widget.parameters) {
        if (param.dependsOn == key) {
          _currentValues[param.id] = null;
        }
      }
    });
    widget.onChanged(_currentValues);
  }

  void _applyRelativeDate(ReportRelativeDateRange option) {
    setState(() {
      _selectedRelativeDate = option;
      final range = ReportRelativeDateEvaluator.evaluate(option);
      if (range != null) {
        _currentValues['fromDate'] = range.start;
        _currentValues['toDate'] = range.end;
      }
    });
    widget.onChanged(_currentValues);
  }

  Widget _buildParameterWidget(ReportParameterSpec param, bool isAr) {
    final theme = Theme.of(context);

    switch (param.type) {
      case ReportParameterType.postingStatus:
        final currentStatus =
            _currentValues[param.id] as ReportPostingStatusFilter? ??
                ReportPostingStatusFilter.all;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              param.label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            SegmentedButton<ReportPostingStatusFilter>(
              segments: [
                ButtonSegment(
                  value: ReportPostingStatusFilter.all,
                  label: Text(isAr ? 'الكل' : 'All'),
                ),
                ButtonSegment(
                  value: ReportPostingStatusFilter.posted,
                  label: Text(isAr ? 'مرحّل' : 'Posted'),
                ),
                ButtonSegment(
                  value: ReportPostingStatusFilter.unposted,
                  label: Text(isAr ? 'غير مرحّل' : 'Unposted'),
                ),
              ],
              selected: {currentStatus},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  _updateValue(param.id, selected.first);
                }
              },
            ),
          ],
        );

      case ReportParameterType.relativeDate:
      case ReportParameterType.dateRange:
        final fromDate = _currentValues['fromDate'] as DateTime?;
        final toDate = _currentValues['toDate'] as DateTime?;
        final dateFormat = DateFormat('yyyy/MM/dd');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  param.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<ReportRelativeDateRange>(
                  value: _selectedRelativeDate,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  items: ReportRelativeDateRange.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label(isArabic: isAr)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _applyRelativeDate(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fromDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedRelativeDate = ReportRelativeDateRange.custom);
                        _updateValue('fromDate', picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(
                      fromDate != null
                          ? dateFormat.format(fromDate)
                          : (isAr ? 'من تاريخ' : 'From Date'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: toDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedRelativeDate = ReportRelativeDateRange.custom);
                        _updateValue('toDate', picked);
                      }
                    },
                    icon: const Icon(Icons.event_outlined, size: 16),
                    label: Text(
                      toDate != null
                          ? dateFormat.format(toDate)
                          : (isAr ? 'إلى تاريخ' : 'To Date'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case ReportParameterType.select:
        final selectedVal = _currentValues[param.id] as String?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              param.label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: selectedVal,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                hintText: param.placeholder ?? (isAr ? 'الكل' : 'All'),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(isAr ? 'الكل' : 'All'),
                ),
                ...param.options.map(
                  (opt) => DropdownMenuItem<String>(
                    value: opt.value,
                    child: Text(opt.label),
                  ),
                ),
              ],
              onChanged: (val) => _updateValue(param.id, val),
            ),
          ],
        );

      case ReportParameterType.account:
        return AppReportEntitySearchField.account(
          context,
          selectedTitle: _currentValues['accountName'] as String?,
          selectedUuid: _currentValues[param.id] as String?,
          customLabel: param.label,
          isRequired: param.isRequired,
          onAccountSelected: (acc) {
            _updateValue(param.id, acc?.uuid);
            _updateValue('accountName', acc != null ? '${acc.accountCode} — ${acc.name}' : null);
          },
          onClear: () {
            _updateValue(param.id, null);
            _updateValue('accountName', null);
          },
        );

      case ReportParameterType.product:
        return AppReportEntitySearchField.product(
          context,
          selectedProductName: _currentValues['productName'] as String?,
          selectedProductCode: _currentValues[param.id] as String?,
          customLabel: param.label,
          isRequired: param.isRequired,
          onProductSelected: (prod) {
            _updateValue(param.id, prod?.itemCode);
            _updateValue('productName', prod?.name);
          },
          onClear: () {
            _updateValue(param.id, null);
            _updateValue('productName', null);
          },
        );

      case ReportParameterType.customer:
      case ReportParameterType.supplier:
        final selectedTitle = _currentValues['${param.id}_name'] as String?;
        return AppReportEntitySearchField(
          label: param.label,
          hintText: param.placeholder ?? (isAr ? 'اضغط للتحديد...' : 'Tap to select...'),
          icon: param.type == ReportParameterType.customer
              ? Icons.people_outline_rounded
              : Icons.local_shipping_outlined,
          selectedTitle: selectedTitle,
          isRequired: param.isRequired,
          onClear: selectedTitle == null
              ? null
              : () {
                  _updateValue(param.id, null);
                  _updateValue('${param.id}_name', null);
                },
          onTap: () {
            // Trigger selection dialog hook
          },
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              param.label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: _currentValues[param.id]?.toString(),
              decoration: InputDecoration(
                hintText: param.placeholder,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onChanged: (val) => _updateValue(param.id, val),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final columnsCount = isMobile ? 1 : (constraints.maxWidth < 900 ? 2 : 3);

        final items = widget.parameters.map((p) {
          return SizedBox(
            width: isMobile
                ? double.infinity
                : (constraints.maxWidth - (columnsCount - 1) * 16) / columnsCount,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildParameterWidget(p, isAr),
            ),
          );
        }).toList();

        return Wrap(
          spacing: 16,
          runSpacing: 8,
          children: items,
        );
      },
    );
  }
}
