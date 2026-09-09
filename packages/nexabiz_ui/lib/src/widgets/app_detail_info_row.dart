import 'package:flutter/material.dart';

/// Canonical key-value detail row widget for details pages.
class AppDetailInfoRow extends StatelessWidget {
  const AppDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.valueAlign = TextAlign.end,
    this.emphasizedValue = false,
  });

  final String label;
  final String value;
  final EdgeInsetsGeometry padding;
  final TextAlign valueAlign;
  final bool emphasizedValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: valueAlign,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasizedValue ? FontWeight.w900 : FontWeight.w800,
                color: emphasizedValue ? scheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
