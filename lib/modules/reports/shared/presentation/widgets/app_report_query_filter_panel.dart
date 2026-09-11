import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_count/core/theme/tokens/app_radii.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
/// Reusable, canonical filter panel widget for ERP report pages.
///
/// Unifies date range picking, custom filter fields, and PDF preview generation actions.
class AppReportQueryFilterPanel extends StatelessWidget {
  const AppReportQueryFilterPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.fromDate,
    required this.toDate,
    required this.onPickFromDate,
    required this.onPickToDate,
    this.onClearDates,
    this.additionalFilters = const [],
    required this.onGenerate,
    this.isGenerating = false,
    this.generateButtonLabel,
  });

  final String title;
  final String? subtitle;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback? onClearDates;
  final List<Widget> additionalFilters;
  final VoidCallback? onGenerate;
  final bool isGenerating;
  final String? generateButtonLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMd(locale);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadii.radiusSm,
                ),
                child: Icon(
                  Icons.filter_alt_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (onClearDates != null && (fromDate != null || toDate != null))
                IconButton(
                  icon: const Icon(Icons.clear_all_outlined, size: 20),
                  tooltip: 'إعادة ضبط التصفية',
                  onPressed: onClearDates,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Date Range Cards
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'من تاريخ',
                  valueText: fromDate == null ? '—' : dateFmt.format(fromDate!),
                  onTap: onPickFromDate,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateTile(
                  label: 'إلى تاريخ',
                  valueText: toDate == null ? '—' : dateFmt.format(toDate!),
                  onTap: onPickToDate,
                ),
              ),
            ],
          ),

          if (additionalFilters.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...additionalFilters,
          ],

          const SizedBox(height: AppSpacing.lg),

          // Action Button
          AppButton(
            label: isGenerating
                ? 'جاري إعداد التقرير...'
                : (generateButtonLabel ?? 'معاينة واستخراج PDF'),
            icon: Icons.picture_as_pdf_outlined,
            expand: true,
            isLoading: isGenerating,
            onPressed: isGenerating ? null : onGenerate,
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.valueText,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.radiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: AppRadii.radiusSm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    valueText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
