import 'package:flutter/material.dart';

/// Reusable expandable text component for long notes, descriptions, addresses,
/// and invoice comments across NexaBiz forms and details views.
class AppExpandableText extends StatefulWidget {
  const AppExpandableText({
    super.key,
    required this.text,
    this.maxCollapsedLines = 2,
    this.style,
    this.expandText = 'عرض النص كاملًا',
    this.collapseText = 'إخفاء التفاصيل',
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final int maxCollapsedLines;
  final TextStyle? style;
  final String expandText;
  final String collapseText;
  final EdgeInsetsGeometry padding;

  @override
  State<AppExpandableText> createState() => _AppExpandableTextState();
}

class _AppExpandableTextState extends State<AppExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textStyle = widget.style ?? theme.textTheme.bodyMedium;

    return Padding(
      padding: widget.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final span = TextSpan(text: widget.text, style: textStyle);
          final tp = TextPainter(
            text: span,
            maxLines: widget.maxCollapsedLines,
            textDirection: Directionality.of(context),
          );
          tp.layout(maxWidth: constraints.maxWidth);

          final hasOverflow = tp.didExceedMaxLines;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  widget.text,
                  style: textStyle,
                  maxLines: widget.maxCollapsedLines,
                  overflow: TextOverflow.ellipsis,
                ),
                secondChild: Text(
                  widget.text,
                  style: textStyle,
                  softWrap: true,
                ),
              ),
              if (hasOverflow)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? widget.collapseText : widget.expandText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
