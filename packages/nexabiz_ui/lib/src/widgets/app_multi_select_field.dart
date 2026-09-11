import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'app_field_shell.dart';

/// Canonical multi-select field primitive for NexaBiz ERP.
///
/// Wraps `shadcn_flutter` [shadcn.ControlledMultiSelect] in a type-safe generic (`T`)
/// field wrapper that adheres to NexaBiz ERP form field layout rules (`label`,
/// `required`, `errorText`, `helperText`, `density`).
class AppMultiSelectField<T> extends StatelessWidget {
  const AppMultiSelectField({
    super.key,
    required this.items,
    required this.itemLabelBuilder,
    this.value,
    this.onChanged,
    this.label,
    this.hint = 'اختر العناصر...',
    this.placeholder,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.helperText,
    this.density = AppFieldDensity.standard,
    this.itemBuilder,
  });

  /// The collection of selectable items of type [T].
  final List<T> items;

  /// Function mapping each item [T] to its display string label.
  final String Function(T item) itemLabelBuilder;

  /// Currently selected collection of items [T].
  final Iterable<T>? value;

  /// Callback fired when item selection is updated.
  final ValueChanged<Iterable<T>?>? onChanged;

  /// Field label text displayed above the component.
  final String? label;

  /// Default hint text when no items are selected.
  final String hint;

  /// Custom placeholder widget.
  final Widget? placeholder;

  /// Whether the field is mandatory (displays red `*`).
  final bool required;

  /// Whether the field accepts user interaction.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Validation error message string.
  final String? errorText;

  /// Helper message string displayed below the field.
  final String? helperText;

  /// Standardized ERP field density.
  final AppFieldDensity density;

  /// Optional custom builder for items inside the popup menu.
  final Widget Function(BuildContext context, T item, bool isSelected)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;
    final isInteractive = enabled && !readOnly;

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
                  color: isInteractive
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
        shadcn.ControlledMultiSelect<T>(
          initialValue: value,
          onChanged: isInteractive ? onChanged : null,
          enabled: isInteractive,
          placeholder: placeholder ?? Text(hint),
          popup: (context) {
            return shadcn.SelectGroup(
              children: items.map((item) {
                final displayLabel = itemLabelBuilder(item);
                if (itemBuilder != null) {
                  return shadcn.SelectItemButton<T>(
                    value: item,
                    child: Builder(
                      builder: (ctx) {
                        final popupHandle = shadcn.Data.maybeOf<shadcn.SelectPopupHandle>(ctx);
                        final selected = popupHandle?.isSelected(item) ?? false;
                        return itemBuilder!(ctx, item, selected);
                      },
                    ),
                  );
                }
                return shadcn.SelectItemButton<T>(
                  value: item,
                  child: Text(displayLabel),
                );
              }).toList(),
            );
          },
          itemBuilder: (context, itemValue) {
            return Text(itemLabelBuilder(itemValue));
          },
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
