import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_product_catalog_port.dart';
import '../providers/sale_providers.dart';
import '../utils/sale_autocomplete.dart';
import '../../domain/services/sale_autocomplete_defaults.dart';
import 'sale_status_badge.dart';

/// Fixed multi-column widths for the products spreadsheet.
class _Cols {
  static const index = 44.0;
  static const product = 220.0;
  static const main = 96.0;
  static const sub = 96.0;
  static const price = 128.0;
  static const total = 120.0;
  static const actions = 48.0;

  /// Matches horizontal padding on header / filled rows.
  static const hPad = AppSpacing.sm;

  static double get contentWidth =>
      index + product + main + sub + price + total + actions;

  /// Outer scroll width: columns + side padding (avoids Row overflow).
  static double get width => contentWidth + hPad * 2;

  static double get readonlyContentWidth =>
      index + product + main + sub + price + total;

  static double get readonlyWidth => readonlyContentWidth + hPad * 2;
}

/// Read-only products spreadsheet matching [SaleProductsTable] layout.
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
        _ProductsSectionHeader(title: l10n.salesProducts),
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
                          _TableHeader(
                            theme: theme,
                            l10n: l10n,
                            showActions: false,
                          ),
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

/// Spreadsheet-style multi-column products editor.
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
  final _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

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
    final scheme = theme.colorScheme;
    final hasContent = widget.items.isNotEmpty || _draftRowIds.isNotEmpty;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tableWidth = math.max(_Cols.width, viewportWidth - 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductsSectionHeader(title: l10n.salesProducts),
        const SizedBox(height: AppSpacing.md),
        if (!hasContent)
          _EmptyAddCard(
            onAdd: _addDraftRow,
            onScan: widget.onScan,
            addLabel: l10n.salesAddProduct,
            scanLabel: l10n.salesScanProduct,
            emptyLabel: l10n.salesProductsEmpty,
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
              child: Column(
                children: [
                  Scrollbar(
                    controller: _horizontalScroll,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    notificationPredicate: (n) =>
                        n.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _horizontalScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            _TableHeader(theme: theme, l10n: l10n),
                            for (var i = 0; i < widget.items.length; i++)
                              _FilledProductRow(
                                index: i,
                                item: widget.items[i],
                                striped: i.isOdd,
                                minUnitPrice: widget.minUnitPriceOf(
                                  widget.items[i],
                                ),
                                onQuantitiesChanged: (main, sub) {
                                  widget.onQuantitiesChanged(i, main, sub);
                                },
                                onUnitPriceChanged: (price) {
                                  return widget.onUnitPriceChanged(i, price);
                                },
                                onUnitPriceBelowMin: widget.onUnitPriceBelowMin,
                                onRemove: () => widget.onRemove(i),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (final draftId in _draftRowIds)
                    _DraftProductRow(
                      key: ValueKey('draft-$draftId'),
                      onProductSelected: (product) {
                        _onDraftProductSelected(draftId, product);
                      },
                      onCancel: () => _removeDraftRow(draftId),
                    ),
                  _TableActionsBar(
                    onAdd: _addDraftRow,
                    onScan: widget.onScan,
                    addLabel: l10n.salesAddRow,
                    scanLabel: l10n.salesScanProduct,
                  ),
                ],
              ),
            ),
          ),
      ],
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
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.12),
            ),
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

class _TableActionsBar extends StatelessWidget {
  const _TableActionsBar({
    required this.onAdd,
    required this.addLabel,
    required this.scanLabel,
    this.onScan,
  });

  final VoidCallback onAdd;
  final VoidCallback? onScan;
  final String addLabel;
  final String scanLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AddRowButton(label: addLabel, onTap: onAdd),
          ),
          if (onScan != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _ScanIconButton(label: scanLabel, onTap: onScan!),
          ],
        ],
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.primaryContainer, 0.28)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanIconButton extends StatelessWidget {
  const _ScanIconButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: scheme.primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAddCard extends StatelessWidget {
  const _EmptyAddCard({
    required this.onAdd,
    required this.addLabel,
    required this.scanLabel,
    required this.emptyLabel,
    this.onScan,
  });

  final VoidCallback onAdd;
  final VoidCallback? onScan;
  final String addLabel;
  final String scanLabel;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
          radius: AppRadius.lg,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.16),
                      scheme.primary.withValues(alpha: 0.06),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.playlist_add_rounded,
                  color: scheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _AddRowButton(label: addLabel, onTap: onAdd),
                  ),
                  if (onScan != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _ScanIconButton(label: scanLabel, onTap: onScan!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.theme,
    required this.l10n,
    this.showActions = true,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Cols.index,
            child: Text('#', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _Cols.product,
            child: Text(l10n.salesProductName, style: style),
          ),
          SizedBox(
            width: _Cols.main,
            child: Text(
              l10n.mainQuantity,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.sub,
            child: Text(
              l10n.subQuantity,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.price,
            child: Text(
              l10n.salesUnitPrice,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.total,
            child: Text(
              l10n.salesTotal,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          if (showActions) const SizedBox(width: _Cols.actions),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return ColoredBox(
      color: striped
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
          : scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _Cols.index,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.product,
              child: Text(
                item.productName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            SizedBox(
              width: _Cols.main,
              child: Text(
                formatSaleMoney(context, item.mainQuantity),
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
            SizedBox(
              width: _Cols.sub,
              child: Text(
                formatSaleMoney(context, item.subQuantity),
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
            SizedBox(
              width: _Cols.price,
              child: SaleMoneyText(
                item.unitPrice,
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
            SizedBox(
              width: _Cols.total,
              child: SaleMoneyText(
                item.total,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledProductRow extends StatefulWidget {
  const _FilledProductRow({
    required this.index,
    required this.item,
    required this.striped,
    required this.minUnitPrice,
    required this.onQuantitiesChanged,
    required this.onUnitPriceChanged,
    required this.onUnitPriceBelowMin,
    required this.onRemove,
  });

  final int index;
  final SaleItemDraft item;
  final bool striped;
  final double minUnitPrice;
  final void Function(double main, double sub) onQuantitiesChanged;
  final bool Function(double unitPrice) onUnitPriceChanged;
  final VoidCallback onUnitPriceBelowMin;
  final VoidCallback onRemove;

  @override
  State<_FilledProductRow> createState() => _FilledProductRowState();
}

class _FilledProductRowState extends State<_FilledProductRow> {
  /// Live unit price while editing (drives line + invoice totals).
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
  void didUpdateWidget(covariant _FilledProductRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.unitPrice != widget.item.unitPrice &&
        _liveUnitPrice == null) {
      // Parent committed a new price; keep row in sync.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final line = const SaleCalculationService().calculateLine(
      widget.item.copyWith(unitPrice: _effectiveUnitPrice),
    );

    return ColoredBox(
      color: widget.striped
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
          : scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _Cols.index,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.product,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  widget.item.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.main,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppAmountField(
                  value: widget.item.mainQuantity,
                  decimalPlaces: 3,
                  trimTrailingZeros: true,
                  variant: AppAmountFieldVariant.compact,
                  skipTraversal: true,
                  keepFocusOnSubmit: true,
                  onChanged: (main) => onQuantitiesChangedSafe(
                    main,
                    widget.item.subQuantity,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.sub,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppAmountField(
                  value: widget.item.subQuantity,
                  decimalPlaces: 3,
                  trimTrailingZeros: true,
                  variant: AppAmountFieldVariant.compact,
                  skipTraversal: true,
                  keepFocusOnSubmit: true,
                  onChanged: (sub) => onQuantitiesChangedSafe(
                    widget.item.mainQuantity,
                    sub,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.price,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppAmountField(
                  value: _effectiveUnitPrice,
                  variant: AppAmountFieldVariant.compact,
                  skipTraversal: true,
                  errorText: _priceBelowMin
                      ? l10n.salesPriceBelowCatalogHint
                      : null,
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
              ),
            ),
            SizedBox(
              width: _Cols.total,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SaleMoneyText(
                  line.total,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _priceBelowMin ? scheme.error : null,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.actions,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: scheme.error.withValues(alpha: 0.85),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onQuantitiesChangedSafe(double main, double sub) {
    widget.onQuantitiesChanged(main, sub);
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
  final _session = AutocompleteSearchSession();
  var _loading = false;
  var _showResults = false;
  var _searchFailed = false;
  List<SaleProductRef> _results = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 140), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showResults = false);
          }
        });
      } else if (normalizeDigitsToWestern(_controller.text).trim().length >=
          SaleAutocompleteDefaults.productMinLength) {
        setState(() => _showResults = true);
      }
    });
  }

  @override
  void dispose() {
    _session.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final query = normalizeDigitsToWestern(value).trim();
    if (query.length < SaleAutocompleteDefaults.productMinLength) {
      _session.invalidate();
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = false;
        _searchFailed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _showResults = true;
      _searchFailed = false;
    });
    _session.schedule(run: (token) => _search(query, token));
  }

  Future<void> _search(String query, int token) async {
    try {
      final results = await ref
          .read(saleProductCatalogPortProvider)
          .search(query, limit: SaleAutocompleteDefaults.resultLimit);
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = results;
        _loading = false;
        _showResults = true;
        _searchFailed = false;
      });
    } catch (_) {
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = true;
        _searchFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = normalizeDigitsToWestern(_controller.text).trim();

    return ColoredBox(
      color: scheme.primaryContainer.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              inputFormatters: const [WesternDigitsInputFormatter()],
              textInputAction: TextInputAction.done,
              onChanged: _onChanged,
              onEditingComplete: () => _focusNode.unfocus(),
              onSubmitted: (_) => _focusNode.unfocus(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: scheme.surface,
                hintText: l10n.salesSearchProductHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: scheme.primary,
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .cancelButtonLabel,
                        onPressed: widget.onCancel,
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
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
                  borderSide: BorderSide(
                    color: scheme.primary,
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (_showResults &&
              query.length >= SaleAutocompleteDefaults.productMinLength)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Material(
                color: scheme.surface,
                elevation: 2,
                shadowColor: scheme.shadow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : _searchFailed
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            l10n.salesAutocompleteSearchFailed,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                        )
                      : _results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            l10n.salesProductNotFound,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final product = _results[index];
                            return InkWell(
                              onTap: () {
                                _focusNode.unfocus();
                                FocusManager.instance.primaryFocus?.unfocus();
                                widget.onProductSelected(product);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm + 2,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
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
                                        color: scheme.primaryContainer
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: SaleMoneyText(
                                        product.unitPrice,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: scheme.primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
