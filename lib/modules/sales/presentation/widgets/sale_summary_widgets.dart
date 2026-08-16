import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/sale_summary.dart';
import 'sale_status_badge.dart';

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
            if (summary.paidAmount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _SummaryMetaChip(
                label: l10n.salesPaid,
                value: formatSaleMoney(context, summary.paidAmount),
                color: scheme.tertiary,
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
          ],
        ),
      ),
    );
  }
}
