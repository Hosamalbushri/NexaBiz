import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'app_field_shell.dart';

/// Canonical date range selection field primitive for NexaBiz ERP.
///
/// Backed natively by `shadcn_flutter` [shadcn.DateRangePicker], providing
/// dialog/popover date range selection, date range bounds filtering (`firstDate`/`lastDate`),
/// full type safety via [shadcn.DateTimeRange], and ERP form field layout rules (`label`, `errorText`, `helperText`).
class AppDateRangeField extends StatelessWidget {
  const AppDateRangeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint = 'اختر الفترة الزمنية...',
    this.placeholder,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.firstDate,
    this.lastDate,
    this.errorText,
    this.helperText,
    this.density = AppFieldDensity.standard,
    this.mode = shadcn.PromptMode.dialog,
    this.dialogTitle,
    this.stateBuilder,
  });

  /// Currently selected [shadcn.DateTimeRange] value (`null` if empty).
  final shadcn.DateTimeRange? value;

  /// Callback fired when date range is selected or cleared.
  final ValueChanged<shadcn.DateTimeRange?>? onChanged;

  /// Label string displayed above the field.
  final String? label;

  /// Default hint text when no range is selected.
  final String hint;

  /// Custom placeholder widget when no range is selected.
  final Widget? placeholder;

  /// Whether the field is mandatory (displays red `*`).
  final bool required;

  /// Whether the field accepts interaction.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Minimum allowable date for range selection.
  final DateTime? firstDate;

  /// Maximum allowable date for range selection.
  final DateTime? lastDate;

  /// Validation error message string.
  final String? errorText;

  /// Helper text displayed below field.
  final String? helperText;

  /// Standardized ERP field density (compact, standard, large).
  final AppFieldDensity density;

  /// Presentation mode for the picker (`PromptMode.dialog` or `PromptMode.popover`).
  final shadcn.PromptMode mode;

  /// Custom title for the modal dialog mode.
  final Widget? dialogTitle;

  /// Custom date state builder callback for fine-grained cell states.
  final shadcn.DateStateBuilder? stateBuilder;

  shadcn.DateStateBuilder? get _effectiveStateBuilder {
    if (stateBuilder != null) return stateBuilder;
    if (firstDate == null && lastDate == null) return null;

    return (date) {
      if (firstDate != null && date.isBefore(firstDate!)) {
        return shadcn.DateState.disabled;
      }
      if (lastDate != null && date.isAfter(lastDate!)) {
        return shadcn.DateState.disabled;
      }
      return shadcn.DateState.enabled;
    };
  }

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
        shadcn.DateRangePicker(
          value: value,
          onChanged: isInteractive ? onChanged : null,
          placeholder: placeholder ?? Text(hint),
          mode: mode,
          dialogTitle: dialogTitle ?? (label != null ? Text(label!) : null),
          stateBuilder: _effectiveStateBuilder,
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
