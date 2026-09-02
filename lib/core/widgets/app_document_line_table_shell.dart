import 'package:flutter/material.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

/// Dashed border painter for empty-state add-row cards across document line tables.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = AppRadius.md,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        canvas.drawPath(
          metric.extractPath(distance, distance + len),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Canonical multi-column spreadsheet document line table shell.
///
/// Owns generic presentation structure (horizontal scrolling, scrollbars,
/// row index column, dashed empty-state add card, and table outline container),
/// while delegating cell/line editing and domain calculations to feature builders.
class AppDocumentLineTableShell<T> extends StatelessWidget {
  const AppDocumentLineTableShell({
    super.key,
    required this.items,
    required this.rowBuilder,
    this.headerBuilder,
    this.rowActionsBuilder,
    this.emptyAddCardBuilder,
    this.footerSummaryBuilder,
    this.padding,
    this.minContentWidth = 780.0,
    this.showIndexColumn = true,
    this.indexColumnWidth = 44.0,
    this.emptyText,
    this.emptyAddLabel = 'إضافة سطر جديد',
    this.onAddRow,
    this.scrollController,
  });

  /// List of line items.
  final List<T> items;

  /// Builder for rendering each item row.
  final Widget Function(BuildContext context, int index, T item) rowBuilder;

  /// Optional header builder.
  final Widget Function(BuildContext context)? headerBuilder;

  /// Optional builder for row-level trailing action widgets (e.g. Delete icon button).
  final Widget Function(BuildContext context, int index, T item)? rowActionsBuilder;

  /// Optional builder for custom empty-state add card.
  final Widget Function(BuildContext context)? emptyAddCardBuilder;

  /// Optional footer summary widget builder (totals, notes).
  final Widget Function(BuildContext context)? footerSummaryBuilder;

  /// Outer padding constraint.
  final EdgeInsetsGeometry? padding;

  /// Minimum scrollable content width.
  final double minContentWidth;

  /// Whether to render a leading numeric index counter column.
  final bool showIndexColumn;

  /// Width of the index column.
  final double indexColumnWidth;

  /// Custom empty state prompt label.
  final String? emptyText;

  /// Add row button label text.
  final String emptyAddLabel;

  /// Callback when user taps to append a new line draft.
  final VoidCallback? onAddRow;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tableBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Slot
        if (headerBuilder != null) headerBuilder!(context),

        // Row Items
        if (items.isEmpty)
          _buildEmptyAddState(context)
        else ...[
          for (var i = 0; i < items.length; i++) ...[
            _buildRowWrapper(context, i, items[i]),
          ],
        ],

        // Footer Summary Slot
        if (footerSummaryBuilder != null)
          footerSummaryBuilder!(context),
      ],
    );

    final childScrollView = SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: minContentWidth,
        child: tableBody,
      ),
    );

    final scrollableShell = scrollController != null
        ? Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            radius: const Radius.circular(8),
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: childScrollView,
          )
        : Scrollbar(
            child: childScrollView,
          );

    return DecoratedBox(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            scrollableShell,
            if (items.isNotEmpty && footerSummaryBuilder != null)
              footerSummaryBuilder!(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRowWrapper(BuildContext context, int index, T item) {
    if (!showIndexColumn && rowActionsBuilder == null) {
      return rowBuilder(context, index, item);
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOdd = index % 2 != 0;
    final baseBg = isOdd
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
        : scheme.surface;

    return _TableRowWrapper(
      baseColor: baseBg,
      hoverColor: scheme.primary.withValues(alpha: 0.04),
      borderBottomColor: scheme.outlineVariant.withValues(alpha: 0.28),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIndexColumn) ...[
              SizedBox(
                width: indexColumnWidth,
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
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Expanded(child: rowBuilder(context, index, item)),
            if (rowActionsBuilder != null)
              rowActionsBuilder!(context, index, item),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAddState(BuildContext context) {
    if (emptyAddCardBuilder != null) {
      return emptyAddCardBuilder!(context);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
          borderRadius: AppRadius.lg,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                emptyText ?? 'جدول الأسطر فارغ',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (onAddRow != null)
                Row(
                  children: [
                    Expanded(
                      child: _buildAddRowGradientButton(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddRowGradientButton(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAddRow,
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
                  emptyAddLabel,
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

class _TableRowWrapper extends StatefulWidget {
  const _TableRowWrapper({
    required this.baseColor,
    required this.hoverColor,
    required this.borderBottomColor,
    required this.child,
  });

  final Color baseColor;
  final Color hoverColor;
  final Color borderBottomColor;
  final Widget child;

  @override
  State<_TableRowWrapper> createState() => _TableRowWrapperState();
}

class _TableRowWrapperState extends State<_TableRowWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _isHovered
        ? Color.alphaBlend(widget.hoverColor, widget.baseColor)
        : widget.baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: effectiveColor,
          border: Border(
            bottom: BorderSide(color: widget.borderBottomColor),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

