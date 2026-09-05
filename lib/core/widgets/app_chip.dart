import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';

enum AppChipVariant { choice, filter, action }

/// Canonical chip primitive for NexaBiz ERP.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.icon,
    this.variant = AppChipVariant.choice,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final leadingIcon = icon == null ? null : Icon(icon, size: AppIcons.xs);

    switch (variant) {
      case AppChipVariant.choice:
      case AppChipVariant.filter:
        return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: onSelected,
          avatar: leadingIcon,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        );
      case AppChipVariant.action:
        return ActionChip(
          label: Text(label),
          onPressed: onPressed,
          avatar: leadingIcon,
          visualDensity: VisualDensity.compact,
          backgroundColor: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        );
    }
  }
}
