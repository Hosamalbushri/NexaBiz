import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical Checkbox control for NexaBiz ERP backed natively by `shadcn_flutter`.
///
/// Supports binary (`bool?`) and tristate (`shadcn.CheckboxState`) representations,
/// leading and trailing labels, and standard design system scaling.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    this.value = false,
    this.state,
    this.onChanged,
    this.onStateChanged,
    this.label,
    this.leading,
    this.trailing,
    this.tristate = false,
    this.enabled = true,
    this.size,
    this.gap,
  });

  /// Boolean state value (`true` = checked, `false` = unchecked, `null` = indeterminate).
  final bool? value;

  /// Explicit [shadcn.CheckboxState] (`checked`, `unchecked`, `indeterminate`).
  final shadcn.CheckboxState? state;

  /// Callback fired when state changes, providing `bool?` (`null` for indeterminate).
  final ValueChanged<bool?>? onChanged;

  /// Callback fired when state changes, providing explicit [shadcn.CheckboxState].
  final ValueChanged<shadcn.CheckboxState>? onStateChanged;

  /// Optional label text displayed after the checkbox.
  final String? label;

  /// Optional leading widget before the checkbox.
  final Widget? leading;

  /// Optional trailing widget after the checkbox.
  final Widget? trailing;

  /// Whether the checkbox supports three states (checked, unchecked, indeterminate).
  final bool tristate;

  /// Whether the control is interactive.
  final bool enabled;

  /// Override checkbox square size.
  final double? size;

  /// Override spacing around checkbox.
  final double? gap;

  shadcn.CheckboxState get _effectiveState {
    if (state != null) return state!;
    if (value == null) return shadcn.CheckboxState.indeterminate;
    return value! ? shadcn.CheckboxState.checked : shadcn.CheckboxState.unchecked;
  }

  void _handleChanged(shadcn.CheckboxState newState) {
    if (!enabled) return;
    onStateChanged?.call(newState);
    if (onChanged != null) {
      switch (newState) {
        case shadcn.CheckboxState.checked:
          onChanged!(true);
          break;
        case shadcn.CheckboxState.unchecked:
          onChanged!(false);
          break;
        case shadcn.CheckboxState.indeterminate:
          onChanged!(null);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTrailing = trailing ?? (label != null ? Text(label!) : null);

    return shadcn.Checkbox(
      state: _effectiveState,
      onChanged: enabled && (onChanged != null || onStateChanged != null)
          ? _handleChanged
          : null,
      tristate: tristate,
      enabled: enabled,
      leading: leading,
      trailing: effectiveTrailing,
      size: size,
      gap: gap,
    );
  }
}
