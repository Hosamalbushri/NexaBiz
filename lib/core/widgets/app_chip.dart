import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

enum AppChipVariant { choice, filter, action }

/// Canonical chip primitive for NexaBiz ERP backed natively by `shadcn_flutter`.
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
  final Widget? icon;
  final AppChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(label);

    switch (variant) {
      case AppChipVariant.choice:
      case AppChipVariant.filter:
        return shadcn.Chip(
          leading: icon,
          style: selected
              ? const shadcn.ButtonStyle.primary()
              : const shadcn.ButtonStyle.outline(),
          onPressed: onSelected != null ? () => onSelected!(!selected) : null,
          child: labelWidget,
        );
      case AppChipVariant.action:
        return shadcn.Chip(
          leading: icon,
          style: const shadcn.ButtonStyle.secondary(),
          onPressed: onPressed,
          child: labelWidget,
        );
    }
  }
}
