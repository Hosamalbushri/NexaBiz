import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Specification for a typed column in [AppEditableTableShell].
class AppEditableTableColumn<T> {
  const AppEditableTableColumn({
    required this.label,
    required this.width,
    this.alignment = Alignment.centerLeft,
    this.headerAlignment = TextAlign.start,
  });

  /// Header title label.
  final String label;

  /// Fixed column width in density-independent pixels.
  final double width;

  /// Content alignment within the cell.
  final Alignment alignment;

  /// Header text alignment.
  final TextAlign headerAlignment;
}

/// Custom dashed border painter for empty-state add cards.
class AppTableDashedBorderPainter extends CustomPainter {
  const AppTableDashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = AppRadius.lg,
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
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AppTableDashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Canonical reusable editable line-item table shell for NexaBiz ERP.
///
/// Disconnects generic table layout, horizontal scrolling, column headers,
/// index counters, empty states, and focus traversal from domain-specific
/// feature logic.
class AppEditableTableShell<T> extends StatefulWidget {
  const AppEditableTableShell({
    super.key,
    required this.items,
    required this.columns,
    required this.rowCellBuilder,
    this.sectionHeader,
    this.draftRows = const [],
    this.draftRowBuilder,
    this.footerSummaryBuilder,
    this.onAddRow,
    this.onScan,
    this.addLabel = 'إضافة سطر',
    this.scanLabel = 'مسح الضوئي',
    this.emptyLabel = 'لا توجد عناصر في الجدول',
    this.showIndexColumn = true,
    this.indexColumnWidth = 44.0,
    this.actionsColumnWidth = 48.0,
    this.showActionsColumn = true,
    this.rowActionsBuilder,
    this.isReadOnly = false,
  });

  /// List of items displayed in the table.
  final List<T> items;

  /// Defined typed columns.
  final List<AppEditableTableColumn<T>> columns;

  /// Cell builder for a specific column and item.
  final Widget Function(
    BuildContext context,
    int index,
    T item,
    AppEditableTableColumn<T> column,
  )
  rowCellBuilder;

  /// Optional section header widget (rendered above table container).
  final Widget? sectionHeader;

  /// Draft row IDs currently active in draft mode.
  final List<int> draftRows;

  /// Builder for draft rows (e.g., product search autocomplete).
  final Widget Function(BuildContext context, int draftId)? draftRowBuilder;

  /// Optional summary footer widget (totals, counts).
  final Widget Function(BuildContext context)? footerSummaryBuilder;

  /// Callback when "Add Row" button is pressed.
  final VoidCallback? onAddRow;

  /// Callback when "Scan Barcode" button is pressed.
  final VoidCallback? onScan;

  /// Label for Add Row button.
  final String addLabel;

  /// Label for Scan Barcode button.
  final String scanLabel;

  /// Label for empty table state.
  final String emptyLabel;

  /// Whether to show the leading numeric index counter column `#`.
  final bool showIndexColumn;

  /// Width of index column.
  final double indexColumnWidth;

  /// Width of trailing actions column.
  final double actionsColumnWidth;

  /// Whether to allocate trailing actions column space in header/footer.
  final bool showActionsColumn;

  /// Trailing row actions builder (e.g. Delete icon button).
  final Widget Function(BuildContext context, int index, T item)?
  rowActionsBuilder;

  /// Read-only mode flag.
  final bool isReadOnly;

  @override
  State<AppEditableTableShell<T>> createState() =>
      _AppEditableTableShellState<T>();
}

class _AppEditableTableShellState<T> extends State<AppEditableTableShell<T>> {
  final _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  double get _contentWidth {
    var width = 0.0;
    if (widget.showIndexColumn) width += widget.indexColumnWidth;
    for (final col in widget.columns) {
      width += col.width;
    }
    if (widget.showActionsColumn && !widget.isReadOnly) {
      width += widget.actionsColumnWidth;
    }
    return width;
  }

  double get _totalWidth => _contentWidth + AppSpacing.sm * 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tableWidth = math.max(_totalWidth, viewportWidth - 48);
    final hasContent = widget.items.isNotEmpty || widget.draftRows.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sectionHeader != null) ...[
          widget.sectionHeader!,
          const SizedBox(height: AppSpacing.md),
        ],
        if (!hasContent && !widget.isReadOnly)
          _buildEmptyAddCard(context)
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
                        child: FocusTraversalGroup(
                          policy: ReadingOrderTraversalPolicy(),
                          child: Column(
                            children: [
                              _buildTableHeader(context),
                              for (var i = 0; i < widget.items.length; i++)
                                _buildTableRow(context, i, widget.items[i]),
                              if (widget.items.isNotEmpty &&
                                  widget.footerSummaryBuilder != null)
                                widget.footerSummaryBuilder!(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.draftRowBuilder != null)
                    for (final draftId in widget.draftRows)
                      widget.draftRowBuilder!(context, draftId),
                  if (!widget.isReadOnly && widget.onAddRow != null)
                    _buildTableActionsBar(context),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: scheme.onSurfaceVariant,
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
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.showIndexColumn)
            SizedBox(
              width: widget.indexColumnWidth,
              child: Text('#', style: style, textAlign: TextAlign.center),
            ),
          for (final col in widget.columns)
            SizedBox(
              width: col.width,
              child: Text(
                col.label,
                style: style,
                textAlign: col.headerAlignment,
              ),
            ),
          if (widget.showActionsColumn && !widget.isReadOnly)
            SizedBox(width: widget.actionsColumnWidth),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, int index, T item) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOdd = index.isOdd;

    return ColoredBox(
      color: isOdd
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
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showIndexColumn)
              SizedBox(
                width: widget.indexColumnWidth,
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
            for (final col in widget.columns)
              SizedBox(
                width: col.width,
                child: widget.rowCellBuilder(context, index, item, col),
              ),
            if (widget.showActionsColumn &&
                !widget.isReadOnly &&
                widget.rowActionsBuilder != null)
              SizedBox(
                width: widget.actionsColumnWidth,
                child: widget.rowActionsBuilder!(context, index, item),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAddCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: AppTableDashedBorderPainter(
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
                widget.emptyLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (widget.onAddRow != null)
                    Expanded(
                      child: _AddRowButton(
                        label: widget.addLabel,
                        onTap: widget.onAddRow!,
                      ),
                    ),
                  if (widget.onScan != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _ScanIconButton(
                      label: widget.scanLabel,
                      onTap: widget.onScan!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableActionsBar(BuildContext context) {
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
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          if (widget.onAddRow != null)
            Expanded(
              child: _AddRowButton(
                label: widget.addLabel,
                onTap: widget.onAddRow!,
              ),
            ),
          if (widget.onScan != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _ScanIconButton(label: widget.scanLabel, onTap: widget.onScan!),
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
              border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
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
