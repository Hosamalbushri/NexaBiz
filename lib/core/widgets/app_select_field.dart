import 'package:flutter/material.dart';
import 'app_field_shell.dart';

/// Item definition for [AppSelectField].
class AppSelectItem<T> {
  const AppSelectItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Canonical dropdown selection field primitive for NexaBiz ERP.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint = 'اختر...',
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.density = AppFieldDensity.standard,
  });

  final T? value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String hint;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final AppFieldDensity density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppFieldShell(
      label: label,
      required: required,
      errorText: errorText,
      helperText: helperText,
      density: density,
      enabled: enabled,
      readOnly: readOnly,
      prefix: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              size: 20,
              color: scheme.primary,
            ),
      suffix: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 22,
        color: scheme.onSurfaceVariant,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          isExpanded: true,
          isDense: true,
          icon: const SizedBox.shrink(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          onChanged: enabled && !readOnly ? onChanged : null,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
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
