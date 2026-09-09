import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_product_catalog_port.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/services/sale_autocomplete_defaults.dart';
import '../../domain/services/sale_calculation_service.dart';
import '../providers/sale_providers.dart';
import 'sale_status_badge.dart';

export 'sale_products_readonly_table.dart';

/// Fixed column width constants for sales products table.
class _SaleCols {
  static const product = 220.0;
  static const main = 96.0;
  static const sub = 96.0;
  static const price = 128.0;
  static const total = 120.0;
}

/// Spreadsheet-style multi-column products editor for Sales Invoices.
class SaleProductsTable extends ConsumerStatefulWidget {
  const SaleProductsTable({
    super.key,
    required this.items,
    required this.onProductSelected,
    required this.onQuantitiesChanged,
    required this.onUnitPriceChanged,
    required this.minUnitPriceOf,
    required this.onUnitPriceBelowMin,
    required this.onRemove,
    this.onScan,
  });

  final List<SaleItemDraft> items;
  final ValueChanged<SaleProductRef> onProductSelected;
  final void Function(int index, double main, double sub) onQuantitiesChanged;

  /// Apply unit price; return `false` if below catalog default.
  final bool Function(int index, double unitPrice) onUnitPriceChanged;
  final double Function(SaleItemDraft item) minUnitPriceOf;
  final VoidCallback onUnitPriceBelowMin;
  final ValueChanged<int> onRemove;
  final VoidCallback? onScan;

  @override
  ConsumerState<SaleProductsTable> createState() => _SaleProductsTableState();
}

class _SaleProductsTableState extends ConsumerState<SaleProductsTable> {
  final List<int> _draftRowIds = [];
  var _nextDraftId = 0;

  void _addDraftRow() {
    setState(() => _draftRowIds.add(_nextDraftId++));
  }

  void _removeDraftRow(int id) {
    setState(() => _draftRowIds.remove(id));
  }

  void _onDraftProductSelected(int draftId, SaleProductRef product) {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onProductSelected(product);
    _removeDraftRow(draftId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final columns = [
      AppEditableTableColumn<SaleItemDraft>(
        label: l10n.salesProductName,
        width: _SaleCols.product,
        headerAlignment: TextAlign.start,
      ),
      AppEditableTableColumn<SaleItemDraft>(
        label: l10n.mainQuantity,
        width: _SaleCols.main,
        headerAlignment: TextAlign.center,
      ),
      AppEditableTableColumn<SaleItemDraft>(
        label: l10n.subQuantity,
        width: _SaleCols.sub,
        headerAlignment: TextAlign.center,
      ),
      AppEditableTableColumn<SaleItemDraft>(
        label: l10n.salesUnitPrice,
        width: _SaleCols.price,
        headerAlignment: TextAlign.center,
      ),
      AppEditableTableColumn<SaleItemDraft>(
        label: l10n.salesTotal,
        width: _SaleCols.total,
        headerAlignment: TextAlign.end,
      ),
    ];

    return AppEditableTableShell<SaleItemDraft>(
      items: widget.items,
      columns: columns,
      sectionHeader: _ProductsSectionHeader(title: l10n.salesProducts),
      draftRows: _draftRowIds,
      draftRowBuilder: (context, draftId) {
        return _DraftProductRow(
          key: ValueKey('draft-$draftId'),
          onProductSelected: (product) {
            _onDraftProductSelected(draftId, product);
          },
          onCancel: () => _removeDraftRow(draftId),
        );
      },
      footerSummaryBuilder: (context) {
        return _TableFooter(items: widget.items, theme: theme);
      },
      onAddRow: _addDraftRow,
      onScan: widget.onScan,
      addLabel: widget.items.isEmpty ? l10n.salesAddProduct : l10n.salesAddRow,
      scanLabel: l10n.salesScanProduct,
      emptyLabel: l10n.salesProductsEmpty,
      rowActionsBuilder: (context, index, item) {
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: () => widget.onRemove(index),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: scheme.error.withValues(alpha: 0.85),
            ),
            visualDensity: VisualDensity.compact,
          ),
        );
      },
      rowCellBuilder: (context, index, item, column) {
        return _SaleProductCell(
          index: index,
          item: item,
          column: column,
          minUnitPrice: widget.minUnitPriceOf(item),
          onQuantitiesChanged: (main, sub) {
            widget.onQuantitiesChanged(index, main, sub);
          },
          onUnitPriceChanged: (price) {
            return widget.onUnitPriceChanged(index, price);
          },
          onUnitPriceBelowMin: widget.onUnitPriceBelowMin,
        );
      },
    );
  }
}

class _ProductsSectionHeader extends StatelessWidget {
  const _ProductsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.18),
                scheme.primary.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: scheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaleProductCell extends StatefulWidget {
  const _SaleProductCell({
    required this.index,
    required this.item,
    required this.column,
    required this.minUnitPrice,
    required this.onQuantitiesChanged,
    required this.onUnitPriceChanged,
    required this.onUnitPriceBelowMin,
  });

  final int index;
  final SaleItemDraft item;
  final AppEditableTableColumn<SaleItemDraft> column;
  final double minUnitPrice;
  final void Function(double main, double sub) onQuantitiesChanged;
  final bool Function(double unitPrice) onUnitPriceChanged;
  final VoidCallback onUnitPriceBelowMin;

  @override
  State<_SaleProductCell> createState() => _SaleProductCellState();
}

class _SaleProductCellState extends State<_SaleProductCell> {
  double? _liveUnitPrice;
  var _priceBelowMin = false;

  double get _effectiveUnitPrice => _liveUnitPrice ?? widget.item.unitPrice;

  void _onPriceEdited(double parsed) {
    final belowMin = parsed < widget.minUnitPrice;
    setState(() {
      _liveUnitPrice = parsed;
      _priceBelowMin = belowMin;
    });

    if (!belowMin) {
      final accepted = widget.onUnitPriceChanged(parsed);
      if (!accepted) {
        setState(() => _priceBelowMin = true);
      }
    }
  }

  void _onPriceCommitFinished({required bool rejected}) {
    if (rejected) {
      setState(() {
        _liveUnitPrice = widget.item.unitPrice;
        _priceBelowMin = false;
      });
      widget.onUnitPriceBelowMin();
      return;
    }
    setState(() {
      _liveUnitPrice = null;
      _priceBelowMin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final col = widget.column;

    if (col.width == _SaleCols.product) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          widget.item.productName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      );
    }

    if (col.width == _SaleCols.main) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppAmountField(
          value: widget.item.mainQuantity,
          decimalPlaces: 3,
          trimTrailingZeros: true,
          variant: AppAmountFieldVariant.compact,
          skipTraversal: true,
          keepFocusOnSubmit: true,
          onChanged: (main) =>
              widget.onQuantitiesChanged(main, widget.item.subQuantity),
        ),
      );
    }

    if (col.width == _SaleCols.sub) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppAmountField(
          value: widget.item.subQuantity,
          decimalPlaces: 3,
          trimTrailingZeros: true,
          variant: AppAmountFieldVariant.compact,
          skipTraversal: true,
          keepFocusOnSubmit: true,
          onChanged: (sub) =>
              widget.onQuantitiesChanged(widget.item.mainQuantity, sub),
        ),
      );
    }

    if (col.width == _SaleCols.price) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppAmountField(
          value: _effectiveUnitPrice,
          variant: AppAmountFieldVariant.compact,
          skipTraversal: true,
          errorText: _priceBelowMin ? l10n.salesPriceBelowCatalogHint : null,
          onChanged: _onPriceEdited,
          onSubmitted: (price) {
            if (price < widget.minUnitPrice) {
              _onPriceCommitFinished(rejected: true);
              return;
            }
            final accepted = widget.onUnitPriceChanged(price);
            _onPriceCommitFinished(rejected: !accepted);
          },
        ),
      );
    }

    if (col.width == _SaleCols.total) {
      final line = const SaleCalculationService().calculateLine(
        widget.item.copyWith(unitPrice: _effectiveUnitPrice),
      );
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SaleMoneyText(
          line.total,
          textAlign: TextAlign.end,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: _priceBelowMin ? scheme.error : null,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({required this.items, required this.theme});

  final List<SaleItemDraft> items;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final totalMain = items.fold(0.0, (sum, i) => sum + i.mainQuantity);
    final totalSub = items.fold(0.0, (sum, i) => sum + i.subQuantity);
    final grandTotal = items.fold(
      0.0,
      (sum, i) => sum + const SaleCalculationService().calculateLine(i).total,
    );

    String fmtQty(double v) =>
        v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: scheme.onSurfaceVariant,
    );
    final totalStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w900,
      color: scheme.primary,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 44.0), // Index col
          SizedBox(
            width: _SaleCols.product,
            child: Text('المجموع الإجمالي (${items.length})', style: style),
          ),
          SizedBox(
            width: _SaleCols.main,
            child: Text(
              fmtQty(totalMain),
              style: style?.copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _SaleCols.sub,
            child: Text(
              fmtQty(totalSub),
              style: style?.copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _SaleCols.price,
            child: Text('—', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _SaleCols.total,
            child: Text(
              grandTotal.toStringAsFixed(2),
              style: totalStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 48.0), // Actions col
        ],
      ),
    );
  }
}

class _DraftProductRow extends ConsumerStatefulWidget {
  const _DraftProductRow({
    super.key,
    required this.onProductSelected,
    required this.onCancel,
  });

  final ValueChanged<SaleProductRef> onProductSelected;
  final VoidCallback onCancel;

  @override
  ConsumerState<_DraftProductRow> createState() => _DraftProductRowState();
}

class _DraftProductRowState extends ConsumerState<_DraftProductRow> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<SaleProductRef>> _search(String query) async {
    return ref
        .read(saleProductCatalogPortProvider)
        .search(query, limit: SaleAutocompleteDefaults.resultLimit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final customDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: scheme.surface,
      hintText: l10n.salesSearchProductHint,
      prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
      suffixIcon: IconButton(
        tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
        onPressed: widget.onCancel,
        icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 14,
      ),
    );

    return ColoredBox(
      color: scheme.primaryContainer.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppAsyncAutocompleteField<SaleProductRef>(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          minQueryLength: SaleAutocompleteDefaults.productMinLength,
          debounceDuration: const Duration(
            milliseconds: SaleAutocompleteDefaults.debounceMs,
          ),
          decoration: customDecoration,
          fetchOptions: _search,
          itemLabelBuilder: (p) => p.name,
          onSelected: (product) {
            if (product != null) {
              widget.onProductSelected(product);
            }
          },
          noResultsText: l10n.salesProductNotFound,
          errorText: l10n.salesAutocompleteSearchFailed,
          itemBuilder: (context, product) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: SaleMoneyText(
                      product.unitPrice,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
