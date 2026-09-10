import 'package:flutter/material.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import '../../domain/entities/app_currency.dart';

/// Interactive field trigger + Searchable Modal Picker for predefined currencies.
class AppSearchableCurrencyPickerField extends StatelessWidget {
  const AppSearchableCurrencyPickerField({
    super.key,
    required this.onPresetSelected,
    this.selectedPreset,
    this.excludedCodes,
    this.enabled = true,
  });

  final ValueChanged<AppCurrency> onPresetSelected;
  final AppCurrency? selectedPreset;
  final Set<String>? excludedCodes;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AppFieldShell(
      label: isArabic ? 'بحث وتعبئة عملة مسبقة' : 'Search & Auto-fill Preset',
      helperText: isArabic
          ? 'انقر للبحث في قائمة العملات العالمية والإقليمية'
          : 'Tap to search world and regional currencies',
      enabled: enabled,
      onTap: enabled
          ? () => showAppSearchableCurrencyPicker(
                context,
                onSelected: onPresetSelected,
                selectedPreset: selectedPreset,
                excludedCodes: excludedCodes,
              )
          : null,
      prefix: Icon(
        Icons.search_rounded,
        size: 20,
        color: theme.colorScheme.primary,
      ),
      suffix: const Icon(Icons.arrow_drop_down_rounded, size: 24),
      child: selectedPreset == null
          ? Text(
              isArabic
                  ? 'ابحث باسم العملة أو الرمز (USD, SAR...)'
                  : 'Search currency name or code (USD, SAR...)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    selectedPreset!.code,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  selectedPreset!.symbol,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '— ${selectedPreset!.localizedName(isArabic)}',
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Displays a searchable modal bottom sheet to select from predefined currencies.
Future<void> showAppSearchableCurrencyPicker(
  BuildContext context, {
  required ValueChanged<AppCurrency> onSelected,
  AppCurrency? selectedPreset,
  Set<String>? excludedCodes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SearchableCurrencyPickerSheet(
      onSelected: onSelected,
      selectedPreset: selectedPreset,
      excludedCodes: excludedCodes,
    ),
  );
}

class _SearchableCurrencyPickerSheet extends StatefulWidget {
  const _SearchableCurrencyPickerSheet({
    required this.onSelected,
    this.selectedPreset,
    this.excludedCodes,
  });

  final ValueChanged<AppCurrency> onSelected;
  final AppCurrency? selectedPreset;
  final Set<String>? excludedCodes;

  @override
  State<_SearchableCurrencyPickerSheet> createState() =>
      _SearchableCurrencyPickerSheetState();
}

class _SearchableCurrencyPickerSheetState
    extends State<_SearchableCurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final filteredList = AppCurrencies.all.where((c) {
      if (widget.excludedCodes != null &&
          widget.excludedCodes!.contains(c.code.toUpperCase())) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final matchCode = c.code.toLowerCase().contains(q);
      final matchAr = c.nameAr.toLowerCase().contains(q);
      final matchEn = c.nameEn.toLowerCase().contains(q);
      final matchSymbol = c.symbol.toLowerCase().contains(q);
      return matchCode || matchAr || matchEn || matchSymbol;
    }).toList();

    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: screenHeight * 0.75,
        child: Column(
          children: [
            // Header Drag Handle
            const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Sheet Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_exchange_rounded,
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
                        isArabic ? 'اختر عملة مسبقة' : 'Select Predefined Currency',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isArabic
                            ? 'انقر لتعبئة بيانات العملة تلقائياً في النموذج'
                            : 'Tap to auto-fill currency data into the form',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSearchToolbar(
              searchController: _searchController,
              searchHint: isArabic
                  ? 'ابحث باسم العملة (دولار, يورو...) أو رمز ISO...'
                  : 'Search currency name or ISO code...',
              onSearchChanged: (val) => setState(() => _query = val.trim()),
              onSearchClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),

          // Search Results List
          Expanded(
            child: filteredList.isEmpty
                ? AppEmptyState(
                    title: isArabic ? 'لم يتم العثور على عملة' : 'No Currency Found',
                    subtitle: isArabic
                        ? 'جرب البحث برمز آخر مثل USD, SAR, EUR'
                        : 'Try searching with another code like USD, SAR, EUR',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: filteredList.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final item = filteredList[index];
                      final isSelected = widget.selectedPreset?.code == item.code;

                      return ListTile(
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.of(context).pop();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            item.symbol.isNotEmpty ? item.symbol : item.code,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Text(
                                item.code,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                item.localizedName(isArabic),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          isArabic
                              ? '${item.nameEn} • الخانات: ${item.decimalDigits}'
                              : '${item.nameAr} • Decimals: ${item.decimalDigits}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    );
  }
}
