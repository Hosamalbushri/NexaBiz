import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical Checkbox control for NexaBiz ERP backed by shadcn_flutter.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasShadcnTheme =
        context.findAncestorWidgetOfExactType<shadcn.ComponentTheme>() != null ||
            context.findAncestorWidgetOfExactType<shadcn.Theme>() != null;

    if (hasShadcnTheme) {
      return shadcn.Checkbox(
        state: value
            ? shadcn.CheckboxState.checked
            : shadcn.CheckboxState.unchecked,
        onChanged: enabled && onChanged != null
            ? (state) => onChanged!(state == shadcn.CheckboxState.checked)
            : null,
        trailing: label != null ? Text(label!) : null,
      );
    }

    final cb = Checkbox(
      value: value,
      onChanged: enabled && onChanged != null ? (v) => onChanged!(v ?? false) : null,
    );

    if (label == null) return cb;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        cb,
        const SizedBox(width: 8),
        Text(label!),
      ],
    );
  }
}
