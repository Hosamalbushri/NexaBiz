import 'package:flutter/material.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import '../../domain/entities/sale_item.dart';
import 'sale_status_badge.dart';

class _ReadonlyCols {
  static const product = 220.0;
  static const main = 96.0;
  static const sub = 96.0;
  static const price = 128.0;
  static const total = 120.0;
}

/// Read-only products spreadsheet table for Sales Invoice details page.
class SaleProductsReadonlyTable extends StatelessWidget {
  const SaleProductsReadonlyTable({super.key, required this.items});

  final List<SaleItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final columns = [
      AppEditableTableColumn<SaleItem>(
        label: l10n.salesProductName,
        width: _ReadonlyCols.product,
        headerAlignment: TextAlign.start,
      ),
      AppEditableTableColumn<SaleItem>(
        label: l10n.mainQuantity,
        width: _ReadonlyCols.main,
        headerAlignment: TextAlign.end,
      ),
      AppEditableTableColumn<SaleItem>(
        label: l10n.subQuantity,
        width: _ReadonlyCols.sub,
        headerAlignment: TextAlign.end,
      ),
      AppEditableTableColumn<SaleItem>(
        label: l10n.salesUnitPrice,
        width: _ReadonlyCols.price,
        headerAlignment: TextAlign.end,
      ),
      AppEditableTableColumn<SaleItem>(
        label: l10n.salesTotal,
        width: _ReadonlyCols.total,
        headerAlignment: TextAlign.end,
      ),
    ];

    return AppEditableTableShell<SaleItem>(
      items: items,
      columns: columns,
      isReadOnly: true,
      showActionsColumn: false,
      sectionHeader: _ReadonlySectionHeader(title: l10n.salesProducts),
      emptyLabel: l10n.salesProductsEmpty,
      rowCellBuilder: (context, index, item, column) {
        if (column.width == _ReadonlyCols.product) {
          return Text(
            item.productName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          );
        }
        if (column.width == _ReadonlyCols.main) {
          return Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatSaleMoney(context, item.mainQuantity),
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        if (column.width == _ReadonlyCols.sub) {
          return Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatSaleMoney(context, item.subQuantity),
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        if (column.width == _ReadonlyCols.price) {
          return Align(
            alignment: Alignment.centerRight,
            child: SaleMoneyText(
              item.unitPrice,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }
        if (column.width == _ReadonlyCols.total) {
          return Align(
            alignment: Alignment.centerRight,
            child: SaleMoneyText(
              item.total,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
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
