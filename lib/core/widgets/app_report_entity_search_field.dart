import 'package:flutter/material.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_account_search_picker.dart';
import 'package:stock_count/core/widgets/app_product_search_picker.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';

/// Unified Entity Search Target Picker for report filter panels.
///
/// Ensures a consistent, beautiful design across all report types while adapting its entity target:
/// - Accounting Reports: Chart of Accounts Search (الدليل المحاسبي).
/// - Inventory Reports: Product Catalog Search (دليل المنتجات).
/// - Customer / Vendor / Custom Search.
class AppReportEntitySearchField extends StatelessWidget {
  const AppReportEntitySearchField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.onTap,
    this.selectedTitle,
    this.selectedSubtitle,
    this.onClear,
    this.isRequired = false,
  });

  /// Factory constructor for Chart of Accounts search in accounting reports.
  factory AppReportEntitySearchField.account(
    BuildContext context, {
    Key? key,
    Account? selectedAccount,
    String? selectedTitle,
    String? selectedSubtitle,
    String? selectedUuid,
    required ValueChanged<Account?> onAccountSelected,
    VoidCallback? onClear,
    String? customLabel,
    bool isRequired = true,
  }) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';

    final title = selectedTitle ??
        (selectedAccount == null
            ? null
            : '${selectedAccount.accountCode} — ${selectedAccount.name}');
    final subtitle =
        selectedSubtitle ?? selectedAccount?.accountType.storageValue;

    return AppReportEntitySearchField(
      key: key,
      label: customLabel ?? (isArabic ? 'الحساب المحاسبي' : 'Account'),
      hintText: isArabic
          ? 'اضغط هنا للبحث والتحديد في الدليل المحاسبي...'
          : 'Tap to search Chart of Accounts...',
      icon: Icons.account_tree_outlined,
      selectedTitle: title,
      selectedSubtitle: subtitle,
      isRequired: isRequired,
      onClear: (selectedAccount == null && selectedTitle == null)
          ? null
          : (onClear ?? () => onAccountSelected(null)),
      onTap: () async {
        final account = await showAppAccountPicker(
          context,
          selectedUuid: selectedAccount?.uuid ?? selectedUuid,
        );
        if (account != null) {
          onAccountSelected(account);
        }
      },
    );
  }

  /// Factory constructor for Product catalog search in inventory reports.
  factory AppReportEntitySearchField.product(
    BuildContext context, {
    Key? key,
    Product? selectedProduct,
    String? selectedProductCode,
    String? selectedProductName,
    required ValueChanged<Product?> onProductSelected,
    VoidCallback? onClear,
    String? customLabel,
    bool isRequired = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';

    final title = selectedProduct != null
        ? '${selectedProduct.itemCode} — ${selectedProduct.name}'
        : (selectedProductCode != null && selectedProductCode.isNotEmpty
            ? (selectedProductName != null && selectedProductName.isNotEmpty
                ? '$selectedProductCode — $selectedProductName'
                : selectedProductCode)
            : null);

    final subtitle = selectedProduct?.barcode == null ||
            selectedProduct!.barcode!.isEmpty
        ? null
        : 'الباركود: ${selectedProduct.barcode}';

    return AppReportEntitySearchField(
      key: key,
      label: customLabel ?? (isArabic ? 'الصنف / المنتج المستهدف' : 'Target Product'),
      hintText: isArabic
          ? 'اضغط هنا للبحث والتحديد في دليل المنتجات...'
          : 'Tap to search product catalog...',
      icon: Icons.inventory_2_outlined,
      selectedTitle: title,
      selectedSubtitle: subtitle,
      isRequired: isRequired,
      onClear: (selectedProduct == null && (selectedProductCode == null || selectedProductCode.isEmpty))
          ? null
          : (onClear ?? () => onProductSelected(null)),
      onTap: () async {
        final product = await showAppProductPicker(
          context,
          selectedProductCode: selectedProduct?.itemCode ?? selectedProductCode,
        );
        if (product != null) {
          onProductSelected(product);
        }
      },
    );
  }

  /// Field label text (e.g. "الحساب المحاسبي").
  final String label;

  /// Placeholder hint when nothing is selected.
  final String hintText;

  /// Main trailing/leading entity icon.
  final IconData icon;

  /// Display title when an entity is selected.
  final String? selectedTitle;

  /// Display subtitle when an entity is selected.
  final String? selectedSubtitle;

  /// Callback when user taps to pick an entity.
  final VoidCallback onTap;

  /// Callback when user taps to clear selection.
  final VoidCallback? onClear;

  /// Whether selection is required.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasSelection = selectedTitle != null && selectedTitle!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label Header with optional required marker & badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasSelection ? scheme.primary : scheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: scheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (hasSelection)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'تم التحديد',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Hero Search Card Container
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: hasSelection
                    ? scheme.primaryContainer.withValues(alpha: 0.12)
                    : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md + 2),
                border: Border.all(
                  color: hasSelection
                      ? scheme.primary.withValues(alpha: 0.5)
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                  width: hasSelection ? 1.5 : 1.0,
                ),
                boxShadow: hasSelection
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Icon Avatar Box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: hasSelection
                          ? LinearGradient(
                              colors: [
                                scheme.primary,
                                scheme.primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: hasSelection
                          ? null
                          : scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: hasSelection
                          ? [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: hasSelection ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),

                  // Selected Text or Placeholder
                  Expanded(
                    child: hasSelection
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedTitle!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                  fontSize: 13,
                                  height: 1.25,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (selectedSubtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  selectedSubtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          )
                        : Text(
                            hintText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),

                  // Clear Action Button
                  if (hasSelection && onClear != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    InkWell(
                      onTap: onClear,
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],

                  // Prominent Search Icon Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                      ],
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
