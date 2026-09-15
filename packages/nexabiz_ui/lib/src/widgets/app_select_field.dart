import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'app_field_shell.dart';

/// Item definition for [AppSelectField].
class AppSelectItem<T> {
  const AppSelectItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final Widget? icon;
}

/// Canonical dropdown selection field primitive for NexaBiz ERP built natively on [shadcn.Select].
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
  final dynamic prefixIcon;
  final AppFieldDensity density;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);

    final prefixWidget = prefixIcon is IconData
        ? Icon(
            prefixIcon as IconData,
            size: 18,
            color: enabled
                ? theme.colorScheme.primary
                : theme.colorScheme.mutedForeground,
          )
        : prefixIcon as Widget?;

    final childSelect = shadcn.Select<T>(
      value: value,
      enabled: enabled && !readOnly,
      onChanged: (val) => onChanged?.call(val),
      placeholder: Text(
        hint,
        style: theme.typography.small.copyWith(
          color: theme.colorScheme.mutedForeground,
        ),
      ),
      itemBuilder: (context, item) {
        for (final element in items) {
          if (element.value == item) {
            return Text(element.label);
          }
        }
        return Text(item.toString());
      },
      popup: shadcn.SelectPopup.builder(
        builder: (context, searchQuery) {
          return shadcn.SelectItemList(
            children: items.map((item) {
              return shadcn.SelectItemButton<T>(
                value: item.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      item.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(item.label),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ).asBuilder,
    );

    return AppFieldShell(
      label: label,
      required: required,
      errorText: errorText,
      helperText: helperText,
      density: density,
      enabled: enabled,
      readOnly: readOnly,
      prefix: prefixWidget,
      child: childSelect,
    );
  }
}
