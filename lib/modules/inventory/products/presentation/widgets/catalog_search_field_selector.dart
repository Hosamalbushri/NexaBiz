import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import '../../domain/models/catalog_search_field.dart';

/// Segmented control for catalog search field scope (all / name / code / barcode).
class CatalogSearchFieldSelector extends StatelessWidget {
  const CatalogSearchFieldSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CatalogSearchField value;
  final ValueChanged<CatalogSearchField> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final options = <(CatalogSearchField, IconData, String)>[
      (CatalogSearchField.all, Icons.apps_rounded, l10n.catalogSearchFieldAll),
      (
        CatalogSearchField.name,
        Icons.badge_outlined,
        l10n.catalogSearchFieldName,
      ),
      (
        CatalogSearchField.code,
        Icons.tag_outlined,
        l10n.catalogSearchFieldCode,
      ),
      (
        CatalogSearchField.barcode,
        Icons.view_week_outlined,
        l10n.catalogSearchFieldBarcode,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final option in options)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: _SearchFieldSegment(
                    selected: value == option.$1,
                    icon: option.$2,
                    label: option.$3,
                    onTap: () => onChanged(option.$1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchFieldSegment extends StatelessWidget {
  const _SearchFieldSegment({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: foreground),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension CatalogSearchFieldL10n on CatalogSearchField {
  String hint(AppLocalizations l10n) {
    return switch (this) {
      CatalogSearchField.all => l10n.productsSearchHint,
      CatalogSearchField.name => l10n.catalogSearchHintName,
      CatalogSearchField.code => l10n.catalogSearchHintCode,
      CatalogSearchField.barcode => l10n.catalogSearchHintBarcode,
    };
  }

  String label(AppLocalizations l10n) {
    return switch (this) {
      CatalogSearchField.all => l10n.catalogSearchFieldAll,
      CatalogSearchField.name => l10n.catalogSearchFieldName,
      CatalogSearchField.code => l10n.catalogSearchFieldCode,
      CatalogSearchField.barcode => l10n.catalogSearchFieldBarcode,
    };
  }
}
