import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical Switch control for NexaBiz ERP backed natively by `shadcn_flutter`.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return shadcn.Switch(
      value: value,
      onChanged: enabled && onChanged != null ? onChanged : null,
      trailing: label != null ? Text(label!) : null,
    );
  }
}
