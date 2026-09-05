import 'package:flutter/material.dart';

import 'app_field_shell.dart';

/// Strongly-typed option item for [AppDropdown].
class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Canonical generic dropdown field primitive for NexaBiz ERP.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.hint = 'Select an option',
    this.errorText,
    this.helperText,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
  });

  final List<AppDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String hint;
  final String? errorText;
  final String? helperText;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppFieldShell(
      label: label,
      required: required,
      errorText: errorText,
      helperText: helperText,
      enabled: enabled,
      readOnly: readOnly,
      prefix: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: scheme.primary),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          onChanged: enabled && !readOnly ? onChanged : null,
          items: options.map((opt) {
            return DropdownMenuItem<T>(
              value: opt.value,
              child: Row(
                children: [
                  if (opt.icon != null) ...[
                    Icon(opt.icon, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      opt.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
