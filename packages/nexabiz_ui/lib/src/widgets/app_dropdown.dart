import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Item definition for [AppDropdown].
class AppDropdownItem<T> {
  const AppDropdownItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final Widget? icon;
}

/// Canonical Dropdown / Select control for NexaBiz ERP backed natively by `shadcn_flutter.Select`.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint = 'اختر الخيار...',
    this.placeholder,
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
  final Widget? placeholder;
  final bool required;
  final String? errorText;
  final String? helperText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label!,
                style: theme.typography.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? theme.colorScheme.foreground
                      : theme.colorScheme.mutedForeground,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: theme.colorScheme.destructive,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        shadcn.Select<T>(
          value: value,
          enabled: enabled,
          onChanged: (val) => onChanged?.call(val),
          placeholder: placeholder ?? Text(hint),
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
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.destructive,
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else if (helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
