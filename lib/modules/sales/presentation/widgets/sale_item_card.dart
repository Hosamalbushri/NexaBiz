import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/digit_normalization.dart';
import '../../domain/entities/discount_type.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_summary.dart';
import '../../domain/services/sale_calculation_service.dart';
import 'sale_status_badge.dart';

/// Compact POS-style line card: product, main/sub qty, line total.
class SaleItemCard extends StatelessWidget {
  const SaleItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onQuantitiesChanged,
    required this.onRemove,
    this.onEditDiscount,
    this.onTap,
  });

  final SaleItemDraft item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final void Function(double mainQuantity, double subQuantity)
  onQuantitiesChanged;
  final VoidCallback onRemove;
  final VoidCallback? onEditDiscount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const calc = SaleCalculationService();
    final line = calc.calculateLine(item);

    return Dismissible(
      key: ValueKey('line-${item.lineUuid ?? item.productId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        onRemove();
        return false;
      },
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: l10n.salesItemMore,
                      onSelected: (value) {
                        switch (value) {
                          case 'discount':
                            onEditDiscount?.call();
                          case 'remove':
                            onRemove();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEditDiscount != null)
                          PopupMenuItem(
                            value: 'discount',
                            child: Text(l10n.salesDiscount),
                          ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(l10n.salesRemoveItem),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '${formatSaleMoney(context, item.unitPrice)} × ${_formatQty(item.quantity)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.discountValue > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        item.discountType == DiscountType.percentage
                            ? '(-${_formatQty(item.discountValue)}%)'
                            : '(-${formatSaleMoney(context, item.discountValue)})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    SaleMoneyText(
                      line.total,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _QtyField(
                        key: ValueKey(
                          'main-${item.productId}-${item.mainQuantity}',
                        ),
                        label: l10n.mainQuantity,
                        initialValue: _formatQty(item.mainQuantity),
                        onChanged: (main) {
                          onQuantitiesChanged(main, item.subQuantity);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _QtyField(
                        key: ValueKey(
                          'sub-${item.productId}-${item.subQuantity}',
                        ),
                        label: l10n.subQuantity,
                        initialValue: _formatQty(item.subQuantity),
                        onChanged: (sub) {
                          onQuantitiesChanged(item.mainQuantity, sub);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _QtyButton(
                      icon: Icons.remove,
                      onPressed: onDecrement,
                      semanticLabel: l10n.salesDecreaseQty,
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onPressed: onIncrement,
                      semanticLabel: l10n.salesIncreaseQty,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

class _QtyField extends StatelessWidget {
  const _QtyField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final String initialValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextFormField(
          initialValue: initialValue,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [WesternDigitsInputFormatter()],
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          onChanged: (raw) {
            final parsed = double.tryParse(
              normalizeDigitsToWestern(raw).replaceAll(',', '.'),
            );
            if (parsed != null && parsed >= 0) {
              onChanged(parsed);
            }
          },
          onFieldSubmitted: (raw) {
            final parsed = double.tryParse(
              normalizeDigitsToWestern(raw).replaceAll(',', '.'),
            );
            if (parsed != null && parsed >= 0) {
              onChanged(parsed);
            }
          },
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: semanticLabel,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Invoice totals and save actions (scrolls with the form content).
class SaleStickySummary extends StatelessWidget {
  const SaleStickySummary({
    super.key,
    required this.summary,
    required this.onSave,
    this.onSaveAndConfirm,
    this.canSave = true,
    this.currencyCode,
  });

  final SaleSummary summary;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAndConfirm;
  final bool canSave;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final discountTotal = summary.itemDiscountTotal + summary.saleDiscount;

    Widget amountRow(
      String label,
      double value, {
      bool negative = false,
    }) {
      final labelStyle = theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      );
      final valueStyle = theme.textTheme.bodyMedium?.copyWith(
        color: negative ? scheme.error : scheme.onSurface,
        fontWeight: FontWeight.w700,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: labelStyle),
            ),
            SaleMoneyText(value, style: valueStyle),
          ],
        ),
      );
    }

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.salesTotal,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (currencyCode != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      currencyCode!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            amountRow(l10n.salesSubtotal, summary.subtotal),
            if (discountTotal > 0)
              amountRow(l10n.salesDiscount, -discountTotal, negative: true),
            if (summary.tax > 0) amountRow(l10n.salesTax, summary.tax),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.salesTotal,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  SaleMoneyText(
                    summary.total,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            if (summary.paidAmount > 0 || summary.remainingAmount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (summary.paidAmount > 0)
                    Expanded(
                      child: _SummaryMetaChip(
                        label: l10n.salesPaid,
                        value: formatSaleMoney(context, summary.paidAmount),
                        color: scheme.tertiary,
                      ),
                    ),
                  if (summary.paidAmount > 0 && summary.remainingAmount > 0)
                    const SizedBox(width: AppSpacing.sm),
                  if (summary.remainingAmount > 0)
                    Expanded(
                      child: _SummaryMetaChip(
                        label: l10n.salesRemaining,
                        value:
                            formatSaleMoney(context, summary.remainingAmount),
                        color: scheme.tertiary,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: canSave ? onSave : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.save_outlined, size: 20),
              label: Text(l10n.salesSave),
            ),
            if (onSaveAndConfirm != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: canSave ? onSaveAndConfirm : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(l10n.salesSaveAndConfirm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryMetaChip extends StatelessWidget {
  const _SummaryMetaChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only totals panel for details screens.
class SaleSummaryPanel extends StatelessWidget {
  const SaleSummaryPanel({
    super.key,
    required this.summary,
    this.currencyCode,
  });

  final SaleSummary summary;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final discountTotal = summary.itemDiscountTotal + summary.saleDiscount;

    Widget amountRow(String label, double value, {bool negative = false}) {
      final labelStyle = theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      );
      final valueStyle = theme.textTheme.bodyMedium?.copyWith(
        color: negative ? scheme.error : scheme.onSurface,
        fontWeight: FontWeight.w700,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            SaleMoneyText(value, style: valueStyle),
          ],
        ),
      );
    }

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.salesTotal,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (currencyCode != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      currencyCode!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            amountRow(l10n.salesSubtotal, summary.subtotal),
            if (discountTotal > 0)
              amountRow(l10n.salesDiscount, -discountTotal, negative: true),
            if (summary.tax > 0) amountRow(l10n.salesTax, summary.tax),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.salesTotal,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  SaleMoneyText(
                    summary.total,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            if (summary.paidAmount > 0 || summary.remainingAmount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (summary.paidAmount > 0)
                    Expanded(
                      child: _SummaryMetaChip(
                        label: l10n.salesPaid,
                        value: formatSaleMoney(context, summary.paidAmount),
                        color: scheme.tertiary,
                      ),
                    ),
                  if (summary.paidAmount > 0 && summary.remainingAmount > 0)
                    const SizedBox(width: AppSpacing.sm),
                  if (summary.remainingAmount > 0)
                    Expanded(
                      child: _SummaryMetaChip(
                        label: l10n.salesRemaining,
                        value:
                            formatSaleMoney(context, summary.remainingAmount),
                        color: scheme.tertiary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
