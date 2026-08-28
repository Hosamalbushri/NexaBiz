import 'package:flutter/material.dart';

/// Modes for displaying data text in NexaBiz ERP.
enum AppDataTextMode {
  /// Standard responsive wrap without truncating important text.
  wrap,

  /// Display preview lines with an inline expand/collapse button.
  expandable,

  /// Show tooltip on mouse hover (Desktop) or tap (Mobile).
  tooltip,

  /// Compact single line with tooltip fallback if space is constrained.
  compactWithTooltip,
}

/// A responsive, smart text widget that prevents unintended data truncation
/// while maintaining layout harmony and RTL/number integrity.
class AppDataText extends StatefulWidget {
  const AppDataText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.mode = AppDataTextMode.wrap,
    this.isNumericOrCurrency = false,
    this.tooltipMessage,
    this.selectable = false,
    this.expandLabel = 'عرض المزيد',
    this.collapseLabel = 'إخفاء',
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final AppDataTextMode mode;
  final bool isNumericOrCurrency;
  final String? tooltipMessage;
  final bool selectable;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<AppDataText> createState() => _AppDataTextState();
}

class _AppDataTextState extends State<AppDataText> {
  bool _isExpanded = false;

  /// Ensures numbers and currency symbols stay grouped cleanly without awkward splitting.
  String _formatText(String rawText) {
    if (!widget.isNumericOrCurrency) return rawText;
    // Replace standard spaces between number and currency symbols with non-breaking spaces
    return rawText
        .replaceAll(' YER', '\u00A0YER')
        .replaceAll(' ر.ي', '\u00A0ر.ي')
        .replaceAll(' USD', '\u00A0USD')
        .replaceAll(' SAR', '\u00A0SAR');
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatText(widget.text);
    final theme = Theme.of(context);
    final textStyle = widget.style ?? theme.textTheme.bodyMedium;

    switch (widget.mode) {
      case AppDataTextMode.wrap:
        if (widget.selectable) {
          return SelectableText(
            formatted,
            style: textStyle,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
          );
        }
        return Text(
          formatted,
          style: textStyle,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          softWrap: true,
        );

      case AppDataTextMode.expandable:
        final limit = widget.maxLines ?? 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatted,
              style: textStyle,
              textAlign: widget.textAlign,
              maxLines: _isExpanded ? null : limit,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (formatted.length > 60 || (widget.text.contains('\n')))
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    _isExpanded ? widget.collapseLabel : widget.expandLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );

      case AppDataTextMode.tooltip:
        return Tooltip(
          message: widget.tooltipMessage ?? widget.text,
          waitDuration: const Duration(milliseconds: 300),
          showDuration: const Duration(seconds: 4),
          child: Text(
            formatted,
            style: textStyle,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            softWrap: true,
          ),
        );

      case AppDataTextMode.compactWithTooltip:
        return Tooltip(
          message: widget.tooltipMessage ?? widget.text,
          waitDuration: const Duration(milliseconds: 300),
          child: Text(
            formatted,
            style: textStyle,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines ?? 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
    }
  }
}
