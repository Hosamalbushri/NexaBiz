import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import '../../domain/entities/currency.dart';
import '../providers/currency_providers.dart';

/// Canonical currency dropdown & picker selector component for NexaBiz ERP.
///
/// Fully supports dynamic currencies from domain/configuration layer, search,
/// active/inactive state indication, loading/error states, and custom form validation.
class AppCurrencySelector extends ConsumerWidget {
  const AppCurrencySelector({
    super.key,
    required this.onChanged,
    this.selectedCurrencyCode,
    this.currencies,
    this.includeInactive = false,
    this.label = 'العملة',
    this.hint,
    this.errorText,
    this.enabled = true,
    this.isRequired = false,
    this.validator,
  });

  /// Fired when currency selection changes.
  final ValueChanged<Currency?> onChanged;

  /// Currently selected ISO 4217 code (e.g. 'SAR', 'USD', 'YER').
  final String? selectedCurrencyCode;

  /// Optional static list of currencies. If null, watches Riverpod currency providers.
  final List<Currency>? currencies;

  /// Whether to include inactive currencies in the selector.
  final bool includeInactive;

  /// Form field label.
  final String label;

  /// Optional hint text.
  final String? hint;

  /// Explicit error text.
  final String? errorText;

  /// Enables or disables interaction.
  final bool enabled;

  /// Requires non-null currency selection.
  final bool isRequired;

  /// Custom form field validator.
  final FormFieldValidator<String?>? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currencies != null) {
      return _buildField(context, currencies!);
    }

    final asyncCurrencies = ref.watch(
      includeInactive ? allCurrenciesProvider : activeCurrenciesProvider,
    );

    return asyncCurrencies.when(
      loading: () => _buildLoadingState(context),
      error: (e, st) => _buildErrorState(context, ref, e.toString()),
      data: (items) => _buildField(context, items),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'جاري تحميل العملات...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'تعذر تحميل العملات. انقر لإعادة المحاولة.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: () {
              ref.invalidate(
                includeInactive ? allCurrenciesProvider : activeCurrenciesProvider,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, List<Currency> list) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final normalizedCode = selectedCurrencyCode?.trim().toUpperCase();

    // Find current matching currency object
    Currency? selectedObj;
    if (normalizedCode != null && normalizedCode.isNotEmpty) {
      for (final c in list) {
        if (c.code.toUpperCase() == normalizedCode) {
          selectedObj = c;
          break;
        }
      }
    }

    return FormField<String>(
      initialValue: normalizedCode,
      validator: (val) {
        if (isRequired && (val == null || val.trim().isEmpty)) {
          return isArabic ? 'يرجى اختيار العملة' : 'Please select a currency';
        }
        if (validator != null) {
          return validator!(val);
        }
        return null;
      },
      builder: (fieldState) {
        final theme = Theme.of(context);
        final effectiveError = errorText ?? fieldState.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: enabled
                  ? () async {
                      final picked = await _showCurrencyPickerSheet(
                        context: context,
                        currencies: list,
                        selected: selectedObj,
                        label: label,
                        isArabic: isArabic,
                      );
                      if (picked != null) {
                        fieldState.didChange(picked.code);
                        onChanged(picked);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint ?? (isArabic ? 'اختر العملة' : 'Select currency'),
                  errorText: effectiveError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                child: selectedObj != null
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: selectedObj.isActive
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              selectedObj.symbol.isNotEmpty
                                  ? selectedObj.symbol
                                  : selectedObj.code,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: selectedObj.isActive
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            selectedObj.code,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              '— ${selectedObj.localizedName(isArabic)}',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (!selectedObj.isActive)
                            const AppStatusBadge(
                              label: 'غير نشط',
                              tone: AppStatusTone.neutral,
                              animate: false,
                            ),
                        ],
                      )
                    : Text(
                        hint ?? (isArabic ? 'اختر العملة...' : 'Select currency...'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<Currency?> _showCurrencyPickerSheet({
    required BuildContext context,
    required List<Currency> currencies,
    required Currency? selected,
    required String label,
    required bool isArabic,
  }) async {
    return showModalBottomSheet<Currency>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _CurrencyPickerBottomSheet(
        currencies: currencies,
        selected: selected,
        label: label,
        isArabic: isArabic,
      ),
    );
  }
}

/// Alias for [AppCurrencySelector] matching product specification.
typedef AppCurrencyPickerField = AppCurrencySelector;

class _CurrencyPickerBottomSheet extends StatefulWidget {
  const _CurrencyPickerBottomSheet({
    required this.currencies,
    required this.selected,
    required this.label,
    required this.isArabic,
  });

  final List<Currency> currencies;
  final Currency? selected;
  final String label;
  final bool isArabic;

  @override
  State<_CurrencyPickerBottomSheet> createState() =>
      _CurrencyPickerBottomSheetState();
}

class _CurrencyPickerBottomSheetState
    extends State<_CurrencyPickerBottomSheet> {
  late TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.currencies.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final matchCode = c.code.toLowerCase().contains(q);
      final matchAr = c.nameAr.toLowerCase().contains(q);
      final matchEn = c.nameEn.toLowerCase().contains(q);
      final matchSymbol = c.symbol.toLowerCase().contains(q);
      return matchCode || matchAr || matchEn || matchSymbol;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.monetization_on_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.isArabic
                    ? 'بحث برمز العملة أو الاسم...'
                    : 'Search code or name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onChanged: (val) => setState(() => _query = val.trim()),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 320,
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.isArabic
                                ? 'لا توجد عملات تطابق البحث'
                                : 'No matching currencies found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = widget.selected?.uuid == item.uuid ||
                          widget.selected?.code == item.code;

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        selected: isSelected,
                        selectedTileColor:
                            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.isActive
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            item.symbol.isNotEmpty ? item.symbol : item.code,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: item.isActive
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.code,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '— ${item.localizedName(widget.isArabic)}',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          widget.isArabic
                              ? 'الخانات العشرية: ${item.decimalDigits}'
                              : 'Decimals: ${item.decimalDigits}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!item.isActive)
                              AppStatusBadge(
                                label: widget.isArabic ? 'غير نشط' : 'Inactive',
                                tone: AppStatusTone.neutral,
                                animate: false,
                              ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
