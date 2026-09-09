import 'package:flutter/material.dart';
import 'app_field_shell.dart';

/// Item definition for [AppDropdown].
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Canonical Dropdown / Select control for NexaBiz ERP backed by shadcn_flutter.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint = 'Select an option',
    this.required = false,
    this.errorText,
    this.helperText,
    this.enabled = true,
  });

  final List<AppDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String hint;
  final bool required;
  final String? errorText;
  final String? helperText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selectedItem = items.cast<AppDropdownItem<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => null,
    );

    return AppFieldShell(
      label: label,
      required: required,
      errorText: errorText,
      helperText: helperText,
      enabled: enabled,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          disabledHint: selectedItem != null ? Text(selectedItem.label) : null,
          onChanged: enabled ? onChanged : null,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(item.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
