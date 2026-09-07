import 'package:flutter/material.dart';

import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

/// Reusable sticky summary card for document form footers (totals & save actions).
class AppDocumentStickySummary extends StatelessWidget {
  const AppDocumentStickySummary({
    super.key,
    required this.itemsCountTitle,
    required this.totalAmount,
    required this.currencyCode,
    required this.totalLabel,
    required this.saveLabel,
    this.canSave = true,
    this.onSave,
    this.saveIcon = Icons.save_rounded,
    this.onSaveAndConfirm,
    this.saveAndConfirmLabel,
    this.saveAndConfirmIcon = Icons.check_circle_outline,
  });

  final String itemsCountTitle;
  final double totalAmount;
  final String currencyCode;
  final String totalLabel;
  final String saveLabel;
  final bool canSave;
  final VoidCallback? onSave;
  final IconData saveIcon;
  final VoidCallback? onSaveAndConfirm;
  final String? saveAndConfirmLabel;
  final IconData saveAndConfirmIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  itemsCountTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalLabel: ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${totalAmount.toStringAsFixed(2)} $currencyCode',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: canSave ? onSave : null,
                icon: Icon(saveIcon, size: 20),
                label: Text(
                  saveLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            if (onSaveAndConfirm != null && saveAndConfirmLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: canSave ? onSaveAndConfirm : null,
                  icon: Icon(saveAndConfirmIcon, size: 20),
                  label: Text(
                    saveAndConfirmLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
