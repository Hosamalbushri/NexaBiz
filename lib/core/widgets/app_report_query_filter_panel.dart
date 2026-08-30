import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/modules/accounting/fiscal_years/presentation/providers/open_fiscal_period_providers.dart';

/// Posting status choices for report queries.
enum ReportPostingStatusFilter {
  /// All entries (both posted and unposted). Default choice.
  all('all'),

  /// Posted entries only (مرحل).
  posted('posted'),

  /// Unposted entries only (غير مرحل).
  unposted('unposted');

  const ReportPostingStatusFilter(this.storageValue);

  final String storageValue;

  String label(AppLocalizations l10n, {required bool isArabic}) {
    switch (this) {
      case ReportPostingStatusFilter.all:
        return isArabic ? 'الكل' : 'All';
      case ReportPostingStatusFilter.posted:
        return isArabic ? 'مرحل' : 'Posted';
      case ReportPostingStatusFilter.unposted:
        return isArabic ? 'غير مرحل' : 'Unposted';
    }
  }
}

/// Structured filter parameters emitted when user applies query.
class ReportQueryFilterData {
  const ReportQueryFilterData({
    required this.fromDate,
    required this.toDate,
    required this.postingStatus,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final ReportPostingStatusFilter postingStatus;

  @override
  String toString() =>
      'ReportQueryFilterData(from: $fromDate, to: $toDate, status: ${postingStatus.storageValue})';
}

/// Extensible, production-grade Report Query Filter Container widget.
///
/// Features:
/// - Automatically fetches open fiscal periods from Accounting Ledger.
/// - Automatically initializes default date range from the start date of the first open period
///   to the end date of the last open period (e.g. 01-01-2025 to 31-12-2026).
/// - Includes 3-way radio/segmented control for Posting Status (الكل / مرحل / غير مرحل), default is الكل.
/// - Accepts custom `extraFilters` list for additional report-specific inputs (account, product, cost center, etc.).
class AppReportQueryFilterPanel extends ConsumerStatefulWidget {
  const AppReportQueryFilterPanel({
    super.key,
    required this.onApply,
    this.title,
    this.subtitle,
    this.showDateRange = true,
    this.showPostingStatus = true,
    this.entitySearchField,
    this.initialFromDate,
    this.initialToDate,
    this.initialPostingStatus = ReportPostingStatusFilter.all,
    this.extraFilters = const [],
    this.onPrint,
    this.onViewAsTable,
    this.onReset,
    this.isLoading = false,
    this.applyButtonLabel,
  });

  /// Callback when user presses the query/apply button.
  final ValueChanged<ReportQueryFilterData> onApply;

  /// Optional panel title. Default is null (no header).
  final String? title;

  /// Optional subtitle or helper hint.
  final String? subtitle;

  /// Whether to display date range pickers (From / To). Default is `true`.
  final bool showDateRange;

  /// Whether to display posting status choices (الكل / مرحل / غير مرحل). Default is `true`.
  final bool showPostingStatus;

  /// Primary entity search widget (e.g. `AppReportEntitySearchField.account` or `AppReportEntitySearchField.product`).
  final Widget? entitySearchField;

  /// Override initial from date. If null, automatically resolves from open fiscal periods.
  final DateTime? initialFromDate;

  /// Override initial to date. If null, automatically resolves from open fiscal periods.
  final DateTime? initialToDate;

  /// Initial posting status. Default is `ReportPostingStatusFilter.all`.
  final ReportPostingStatusFilter initialPostingStatus;

  /// Extensible custom filter widgets (e.g. Warehouse Selector, Currency Selector, Detail Level).
  final List<Widget> extraFilters;

  /// Optional callback when user taps Print / PDF button.
  final VoidCallback? onPrint;

  /// Optional callback when user taps Open Table View in Separate Page button.
  final VoidCallback? onViewAsTable;

  /// Optional callback when reset button is tapped.
  final VoidCallback? onReset;

  /// Whether report generation is currently loading.
  final bool isLoading;

  /// Custom label for apply button. Default is "عرض التقرير" / "Generate Report".
  final String? applyButtonLabel;

  @override
  ConsumerState<AppReportQueryFilterPanel> createState() =>
      _AppReportQueryFilterPanelState();
}

class _AppReportQueryFilterPanelState
    extends ConsumerState<AppReportQueryFilterPanel> {
  DateTime? _fromDate;
  DateTime? _toDate;
  late ReportPostingStatusFilter _postingStatus;
  bool _initializedFromFiscalBounds = false;

  @override
  void initState() {
    super.initState();
    _postingStatus = widget.initialPostingStatus;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  void _syncFiscalBounds(OpenFiscalPeriodDateBounds? bounds) {
    if (_initializedFromFiscalBounds) return;
    if (widget.initialFromDate != null || widget.initialToDate != null) return;
    if (bounds == null) return;

    setState(() {
      _fromDate = bounds.startDate;
      _toDate = bounds.endDate;
      _initializedFromFiscalBounds = true;
    });
  }

  Future<void> _pickFromDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'اختر تاريخ بداية الاستعلام',
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'اختر تاريخ نهاية الاستعلام',
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  void _resetFilters(OpenFiscalPeriodDateBounds? bounds) {
    setState(() {
      _postingStatus = widget.initialPostingStatus;
      if (bounds != null) {
        _fromDate = bounds.startDate;
        _toDate = bounds.endDate;
      } else {
        _fromDate = widget.initialFromDate;
        _toDate = widget.initialToDate;
      }
    });
    if (widget.onReset != null) {
      widget.onReset!();
    }
  }

  void _submitQuery() {
    widget.onApply(
      ReportQueryFilterData(
        fromDate: _fromDate,
        toDate: _toDate,
        postingStatus: _postingStatus,
      ),
    );
  }

  void _handlePrimaryAction() {
    _submitQuery();
    if (widget.onViewAsTable != null) {
      widget.onViewAsTable!();
    } else if (widget.onPrint != null) {
      widget.onPrint!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isArabic = l10n.localeName == 'ar';

    String formatDateNumeric(DateTime date) {
      return '${date.day}-${date.month}-${date.year}';
    }

    // Watch open fiscal period bounds
    final fiscalBoundsAsync = ref.watch(openFiscalDateRangeProvider);
    fiscalBoundsAsync.whenData(_syncFiscalBounds);

    final bounds = fiscalBoundsAsync.valueOrNull;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg + 2),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top Decorative Gradient Accent Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    scheme.secondary,
                    scheme.tertiary,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),

                // Top Header Row (Title/Subtitle on left, Reset Button on right)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0.15),
                            scheme.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? (isArabic ? 'معايير الاستعلام' : 'Query Filters'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Top Header Reset Button (زر إعادة الضبط في أعلى الحاوية)
                    InkWell(
                      onTap: () => _resetFilters(bounds),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restart_alt_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isArabic ? 'إعادة ضبط' : 'Reset',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurfaceVariant,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 1. FIRST FIELD: Hero Target Entity Search Picker (if passed)
                if (widget.entitySearchField != null) ...[
                  widget.entitySearchField!,
                  const SizedBox(height: AppSpacing.md),
                ],

                // 2. SECOND FIELD: Custom Extra Report Filters
                if (widget.extraFilters.isNotEmpty) ...[
                  ...widget.extraFilters.map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: child,
                    ),
                  ),
                ],

                // 3. THIRD FIELD: Date Range Pickers (Dual Connected Modules)
                if (widget.showDateRange) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _ReportDateField(
                          label: isArabic ? 'من تاريخ' : 'From Date',
                          value: _fromDate == null
                              ? (isArabic ? 'اختر التاريخ' : 'Select Date')
                              : formatDateNumeric(_fromDate!),
                          isSelected: _fromDate != null,
                          onPick: () => _pickFromDate(context),
                          onClear: _fromDate == null
                              ? null
                              : () => setState(() => _fromDate = null),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ReportDateField(
                          label: isArabic ? 'إلى تاريخ' : 'To Date',
                          value: _toDate == null
                              ? (isArabic ? 'اختر التاريخ' : 'Select Date')
                              : formatDateNumeric(_toDate!),
                          isSelected: _toDate != null,
                          onPick: () => _pickToDate(context),
                          onClear: _toDate == null
                              ? null
                              : () => setState(() => _toDate = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 4. FOURTH FIELD: Posting Status Filter Choices (Pill Segmented Options)
                if (widget.showPostingStatus) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isArabic ? 'نوع الكشف (حالة الترحيل)' : 'Posting Status',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ReportPostingStatusFilter>(
                            segments: [
                              for (final status in const [
                                ReportPostingStatusFilter.posted,
                                ReportPostingStatusFilter.unposted,
                                ReportPostingStatusFilter.all,
                              ])
                                ButtonSegment<ReportPostingStatusFilter>(
                                  value: status,
                                  label: Center(
                                    child: Text(
                                      status.label(l10n, isArabic: isArabic),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            selected: {_postingStatus},
                            onSelectionChanged: (newSelection) {
                              if (newSelection.isNotEmpty) {
                                setState(() => _postingStatus = newSelection.first);
                              }
                            },
                            showSelectedIcon: false,
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return scheme.primary;
                                  }
                                  return Colors.transparent;
                                },
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return scheme.onPrimary;
                                  }
                                  return scheme.onSurfaceVariant;
                                },
                              ),
                              elevation: WidgetStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return 2;
                                  }
                                  return 0;
                                },
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                                ),
                              ),
                              side: WidgetStateProperty.all(BorderSide.none),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // 5. FIFTH ROW: Bottom Main Action Button ("طباعة التقرير")
                Row(
                  children: [
                    // Primary Action Button: "عرض التقرير / طباعة"
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AppButton(
                          label: widget.applyButtonLabel ??
                              (isArabic ? 'عرض التقرير' : 'View Report'),
                          icon: Icons.analytics_rounded,
                          isLoading: widget.isLoading,
                          onPressed: widget.isLoading ? null : _handlePrimaryAction,
                        ),
                      ),
                    ),
                    if (widget.onPrint != null && widget.onViewAsTable != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.isLoading ? null : widget.onPrint,
                          icon: widget.isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.secondary,
                                  ),
                                )
                              : Icon(
                                  Icons.print_rounded,
                                  size: 18,
                                  color: scheme.secondary,
                                ),
                          label: Text(
                            isArabic ? 'طباعة / PDF' : 'Print / PDF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: scheme.secondary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            side: BorderSide(
                              color: scheme.secondary.withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDateField extends StatelessWidget {
  const _ReportDateField({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : scheme.outline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.sm + 1,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primaryContainer.withValues(alpha: 0.1)
                    : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected
                      ? scheme.primary.withValues(alpha: 0.4)
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected && onClear != null)
                    InkWell(
                      onTap: onClear,
                      borderRadius: BorderRadius.circular(100),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
