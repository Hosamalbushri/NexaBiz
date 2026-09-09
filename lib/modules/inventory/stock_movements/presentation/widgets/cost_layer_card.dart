import 'package:flutter/material.dart';
import 'package:stock_count/app/settings/company/app_currency.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';

class CostLayerCard extends StatelessWidget {
  const CostLayerCard({super.key, required this.layer, this.compact = false});

  final CostLayer layer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final valCurrency = AppCurrencies.byCode(
      layer.inventoryCurrencyId.isNotEmpty ? layer.inventoryCurrencyId : 'YER',
    );

    final hasDifferentSourceCurrency =
        layer.documentCurrencyId.isNotEmpty &&
        layer.documentCurrencyId.toUpperCase() !=
            layer.inventoryCurrencyId.toUpperCase();

    final docCurrency = hasDifferentSourceCurrency
        ? AppCurrencies.byCode(layer.documentCurrencyId)
        : null;

    final dateStr =
        '${layer.receivedDate.year}-${layer.receivedDate.month.toString().padLeft(2, '0')}-${layer.receivedDate.day.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: layer.closed
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: layer.closed
              ? scheme.outlineVariant.withValues(alpha: 0.3)
              : scheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Movement Type & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.layers_rounded,
                    size: 18,
                    color: layer.closed ? scheme.outline : scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'طبقة تكلفة: ${layer.itemCode}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: layer.closed ? scheme.outline : scheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: layer.closed
                      ? Colors.grey.shade200
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  layer.closed ? 'مغلقة (Fully Consumed)' : 'نشطة (Active)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: layer.closed
                        ? Colors.grey.shade700
                        : Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'تاريخ الورود: $dateStr | المستند: ${layer.movementUuid.substring(0, layer.movementUuid.length > 8 ? 8 : layer.movementUuid.length)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: AppSpacing.md),

          // Core Cost Breakdown: Quantity, Unit Cost, Total Cost, Valuation Currency
          Row(
            children: [
              Expanded(
                child: _CostMetricTile(
                  label: 'الكمية المستلمة',
                  value: layer.receivedQty.toStringAsFixed(2),
                  subtitle: 'المتبقي: ${layer.remainingQty.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _CostMetricTile(
                  label: 'تكلفة الوحدة (Valuation)',
                  value:
                      '${layer.unitCostInventoryCurrency.toStringAsFixed(2)} ${valCurrency.symbol}',
                  subtitle: 'عملة التقييم: ${valCurrency.code}',
                  highlight: true,
                ),
              ),
              Expanded(
                child: _CostMetricTile(
                  label: 'إجمالي التكلفة',
                  value:
                      '${layer.totalCostInventoryCurrency.toStringAsFixed(2)} ${valCurrency.symbol}',
                  subtitle: 'إجمالي التقييم',
                ),
              ),
            ],
          ),

          // Source Currency / Foreign Purchase Section (If source currency exists & differs)
          if (hasDifferentSourceCurrency && docCurrency != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_exchange_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'المبلغ المصدر (Source Amount): ${layer.totalCostDocumentCurrency.toStringAsFixed(2)} ${docCurrency.symbol} (${docCurrency.code}) '
                      '| تكلفة الوحدة المصدر: ${layer.unitCostDocumentCurrency.toStringAsFixed(2)} ${docCurrency.symbol} '
                      '| سعر الصرف: ${layer.exchangeRate.toStringAsFixed(4)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CostMetricTile extends StatelessWidget {
  const _CostMetricTile({
    required this.label,
    required this.value,
    this.subtitle,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
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
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? scheme.primary : scheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}
