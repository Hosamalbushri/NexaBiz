import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical phone input field primitive for NexaBiz ERP.
///
/// Wraps `shadcn_flutter` [shadcn.PhoneInput] in a standardized NexaBiz form field layout (`label`, `required`, `errorText`, `helperText`).
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    this.initialCountry,
    this.initialValue,
    this.value,
    this.onChanged,
    this.controller,
    this.countries,
    this.onlyNumber = true,
    this.label,
    this.searchPlaceholder = 'ابحث عن الدولة...',
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.helperText,
  });

  final shadcn.Country? initialCountry;
  final shadcn.PhoneNumber? initialValue;
  final shadcn.PhoneNumber? value;
  final ValueChanged<shadcn.PhoneNumber?>? onChanged;
  final TextEditingController? controller;
  final List<shadcn.Country>? countries;
  final bool onlyNumber;
  final String? label;
  final String searchPlaceholder;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? helperText;

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
        shadcn.PhoneInput(
          initialCountry: initialCountry,
          initialValue: value ?? initialValue,
          onChanged: isInteractive ? onChanged : null,
          controller: controller,
          countries: countries,
          onlyNumber: onlyNumber,
          searchPlaceholder: Text(searchPlaceholder),
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
