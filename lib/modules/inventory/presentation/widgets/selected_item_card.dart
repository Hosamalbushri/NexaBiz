import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/item_status.dart';
import 'status_badge.dart';

/// Selected inventory item card — visual language matches barcode product view.
class SelectedItemCard extends StatelessWidget {
  const SelectedItemCard({
    super.key,
    required this.item,
  });

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final barcodeValue = item.barcode?.trim() ?? '';
    final hasBarcode = barcodeValue.isNotEmpty;
    final hasPack = item.hasPackSize;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.itemName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.center,
              child: StatusBadge(status: item.status),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.tag_outlined,
              label: localization.codeLabel,
              value: item.itemCode,
            ),
            _DetailRow(
              icon: Icons.qr_code_2_outlined,
              label: localization.barcode,
              value: hasBarcode
                  ? barcodeValue
                  : localization.productsBarcodeNoCode,
              monospace: hasBarcode,
              muted: !hasBarcode,
            ),
            _DetailRow(
              icon: Icons.inventory_2_outlined,
              label: localization.packSize,
              value: hasPack
                  ? '${item.packSize}'
                  : localization.packSizeRequiredHint,
              muted: !hasPack,
              isLast: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              localization.systemQuantity,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              icon: Icons.inventory_outlined,
              label: localization.mainQuantity,
              value: _format(item.systemMainQuantity),
            ),
            _DetailRow(
              icon: Icons.layers_outlined,
              label: localization.subQuantity,
              value: _format(item.systemSubQuantity),
              isLast: !item.isCounted,
            ),
            if (item.isCounted) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                localization.countDetails,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                icon: Icons.inventory_outlined,
                label: localization.mainQuantity,
                value: _format(item.mainQuantity ?? 0),
              ),
              _DetailRow(
                icon: Icons.layers_outlined,
                label: localization.subQuantity,
                value: _format(item.subQuantity ?? 0),
                isLast: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _varianceTitle(localization, item.status),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                icon: Icons.inventory_outlined,
                label: localization.mainQuantity,
                value: _formatSigned(item.differenceMainQuantity),
                valueColor: _varianceColor(item.status),
              ),
              _DetailRow(
                icon: Icons.layers_outlined,
                label: localization.subQuantity,
                value: _formatSigned(item.differenceSubQuantity),
                valueColor: _varianceColor(item.status),
                isLast: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _varianceTitle(AppLocalizations localization, ItemStatus status) {
    switch (status) {
      case ItemStatus.shortage:
        return localization.shortageQuantity;
      case ItemStatus.overage:
        return localization.overageQuantity;
      case ItemStatus.matched:
      case ItemStatus.notCounted:
        return localization.difference;
    }
  }

  Color _varianceColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.shortage:
        return AppColors.warning;
      case ItemStatus.overage:
        return AppColors.info;
      case ItemStatus.matched:
      case ItemStatus.notCounted:
        return AppColors.success;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.muted = false,
    this.isLast = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final bool muted;
  final bool isLast;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
                color: valueColor ??
                    (muted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface),
              ),
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
