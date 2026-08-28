import 'package:flutter/material.dart';
import '../../app/theme/app_breakpoints.dart';

/// Reusable smart table cell component for DataTables and Dynamic Report Tables.
/// Prevents ugly text clipping while balancing space efficiency and readability.
class AppDataCell extends StatelessWidget {
  const AppDataCell(
    this.value, {
    super.key,
    this.style,
    this.alignment = Alignment.centerLeft,
    this.isNumeric = false,
    this.currencySymbol,
    this.onTap,
    this.columnTitle,
    this.showTooltip = true,
  });

  final String value;
  final TextStyle? style;
  final Alignment alignment;
  final bool isNumeric;
  final String? currencySymbol;
  final VoidCallback? onTap;
  final String? columnTitle;
  final bool showTooltip;

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    columnTitle ?? 'التفاصيل الكاملة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              SelectableText(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = style ??
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isNumeric ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        );

    final displayValue = currencySymbol != null ? '$value $currencySymbol' : value;
    final isMobile = AppBreakpoints.isMobile(MediaQuery.of(context).size.width);

    Widget content = Container(
      alignment: alignment,
      child: Text(
        displayValue,
        style: textStyle,
        textAlign: alignment == Alignment.centerRight
            ? TextAlign.right
            : alignment == Alignment.center
                ? TextAlign.center
                : TextAlign.left,
        softWrap: true,
      ),
    );

    if (value.length > 35) {
      if (isMobile) {
        return InkWell(
          onTap: () => _showDetailBottomSheet(context),
          borderRadius: BorderRadius.circular(4),
          child: content,
        );
      } else if (showTooltip) {
        content = Tooltip(
          message: displayValue,
          waitDuration: const Duration(milliseconds: 300),
          child: content,
        );
      }
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: content,
      );
    }

    return content;
  }
}
