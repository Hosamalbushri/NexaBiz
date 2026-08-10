import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import 'status_badge.dart';

/// Reference card for the selected inventory item.
///
/// Shows the full imported name, item code, system main/sub quantities,
/// and count details (status + shortage/overage main/sub) after saving.
class SelectedItemCard extends StatelessWidget {
  const SelectedItemCard({
    super.key,
    required this.item,
  });

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.itemName,
            softWrap: true,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${localization.codeLabel}: ${item.itemCode}',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _QuantityRow(
            label: localization.mainQuantity,
            value: _format(item.systemMainQuantity),
          ),
          const SizedBox(height: AppSpacing.xs),
          _QuantityRow(
            label: localization.subQuantity,
            value: _format(item.systemSubQuantity),
          ),
          if (item.isCounted) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _CountDetailsSection(item: item),
          ],
        ],
      ),
    );
  }
}

class _CountDetailsSection extends StatelessWidget {
  const _CountDetailsSection({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final String varianceTitle;
    final Color valueColor;
    switch (item.status) {
      case ItemStatus.shortage:
        varianceTitle = localization.shortageQuantity;
        valueColor = AppColors.warning;
      case ItemStatus.overage:
        varianceTitle = localization.overageQuantity;
        valueColor = AppColors.info;
      case ItemStatus.matched:
      case ItemStatus.notCounted:
        varianceTitle = localization.difference;
        valueColor = AppColors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localization.countDetails,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  localization.status,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(status: item.status),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          varianceTitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _QuantityRow(
          label: localization.mainQuantity,
          value: _formatSigned(item.differenceMainQuantity),
          valueColor: valueColor,
        ),
        const SizedBox(height: AppSpacing.xs),
        _QuantityRow(
          label: localization.subQuantity,
          value: _formatSigned(item.differenceSubQuantity),
          valueColor: valueColor,
        ),
      ],
    );
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

String _format(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

String _formatSigned(double value) {
  final absValue = value.abs();
  final formatted = absValue == absValue.roundToDouble()
      ? absValue.toInt().toString()
      : absValue.toStringAsFixed(2);

  if (value > 0) {
    return '+$formatted';
  }
  if (value < 0) {
    return '-$formatted';
  }
  return formatted;
}
