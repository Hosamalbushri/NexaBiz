import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical multiline text field component for NexaBiz ERP.
///
/// Wraps `shadcn_flutter` [shadcn.TextArea] with NexaBiz form field layout contracts:
/// `label`, `required` asterisk, resizable height handle (`expandableHeight`),
/// and error/helper footers.
class AppMultilineField extends StatelessWidget {
  const AppMultilineField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.label,
    this.hint,
    this.placeholder,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.expandableHeight = true,
    this.initialHeight = 120.0,
    this.minHeight = 80.0,
    this.maxHeight = 400.0,
    this.maxLength,
    this.errorText,
    this.helperText,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? label;
  final String? hint;
  final Widget? placeholder;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final bool expandableHeight;
  final double initialHeight;
  final double minHeight;
  final double maxHeight;
  final int? maxLength;
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
        shadcn.TextArea(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          expandableHeight: expandableHeight,
          initialHeight: initialHeight,
          minHeight: minHeight,
          maxHeight: maxHeight,
          maxLength: maxLength,
          placeholder: placeholder ?? (hint != null ? Text(hint!) : null),
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
