import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import '../../domain/entities/sale_item.dart';
import 'sale_status_badge.dart';

class _Cols {
  static const index = 44.0;
  static const product = 220.0;
  static const main = 96.0;
  static const sub = 96.0;
  static const price = 128.0;
  static const total = 120.0;

  static const hPad = AppSpacing.sm;

  static double get readonlyContentWidth =>
      index + product + main + sub + price + total;

  static double get readonlyWidth => readonlyContentWidth + hPad * 2;
}

/// Read-only products spreadsheet table for details page.
class SaleProductsReadonlyTable extends StatelessWidget {
  const SaleProductsReadonlyTable({super.key, required this.items});

  final List<SaleItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tableWidth = math.max(_Cols.readonlyWidth, viewportWidth - 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadonlySectionHeader(title: l10n.salesProducts),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                l10n.salesProductsEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(tableWidth, constraints.maxWidth),
                      child: Column(
                        children: [
                          _ReadonlyTableHeader(theme: theme, l10n: l10n),
                          for (var i = 0; i < items.length; i++)
                            _ReadonlyProductRow(
                              index: i,
                              item: items[i],
                              striped: i.isOdd,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ReadonlySectionHeader extends StatelessWidget {
  const _ReadonlySectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReadonlyTableHeader extends StatelessWidget {
  const _ReadonlyTableHeader({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  Widget _col(String text, double width, {TextAlign align = TextAlign.start}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: align,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Cols.hPad,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          _col('#', _Cols.index),
          _col(l10n.salesProductName, _Cols.product),
          _col(l10n.mainQuantity, _Cols.main, align: TextAlign.end),
          _col(l10n.subQuantity, _Cols.sub, align: TextAlign.end),
          _col(l10n.salesUnitPrice, _Cols.price, align: TextAlign.end),
          _col(l10n.salesTotal, _Cols.total, align: TextAlign.end),
        ],
      ),
    );
  }
}

class _ReadonlyProductRow extends StatelessWidget {
  const _ReadonlyProductRow({
    required this.index,
    required this.item,
    required this.striped,
  });

  final int index;
  final SaleItem item;
  final bool striped;

  Widget _cell(
    Widget child,
    double width, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: width,
      child: Align(alignment: alignment, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rowTotal = item.total;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Cols.hPad,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: striped
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.2)
            : scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          _cell(
            Text(
              '${index + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            _Cols.index,
          ),
          _cell(
            Text(
              item.productName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            _Cols.product,
          ),
          _cell(
            Text(
              formatSaleMoney(context, item.mainQuantity),
              style: theme.textTheme.bodyMedium,
            ),
            _Cols.main,
            alignment: Alignment.centerRight,
          ),
          _cell(
            Text(
              formatSaleMoney(context, item.subQuantity),
              style: theme.textTheme.bodyMedium,
            ),
            _Cols.sub,
            alignment: Alignment.centerRight,
          ),
          _cell(
            SaleMoneyText(
              item.unitPrice,
              style: theme.textTheme.bodyMedium,
            ),
            _Cols.price,
            alignment: Alignment.centerRight,
          ),
          _cell(
            SaleMoneyText(
              rowTotal,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            _Cols.total,
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }
}
