import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical numeric input field primitive for NexaBiz ERP.
///
/// Wraps `shadcn_flutter` [shadcn.TextField] with numeric formatters, spinner controls,
/// min/max bounds, and math expression support while adhering to NexaBiz form field layout rules.
class AppNumberField extends StatelessWidget {
  const AppNumberField({
    super.key,
    this.controller,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.placeholder,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.allowDecimals = true,
    this.step = 1.0,
    this.min,
    this.max,
    this.enableSpinner = true,
    this.enableMathExpression = false,
    this.errorText,
    this.helperText,
    this.prefix,
    this.suffix,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final num? value;
  final ValueChanged<num?>? onChanged;
  final String? label;
  final String? hint;
  final Widget? placeholder;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final bool allowDecimals;
  final double step;
  final double? min;
  final double? max;
  final bool enableSpinner;
  final bool enableMathExpression;
  final String? errorText;
  final String? helperText;
  final Widget? prefix;
  final Widget? suffix;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;
    final isInteractive = enabled && !readOnly;

    final formatters = <TextInputFormatter>[
      if (enableMathExpression)
        shadcn.TextInputFormatters.mathExpression()
      else if (!allowDecimals)
        shadcn.TextInputFormatters.integerOnly(
          min: min?.toInt(),
          max: max?.toInt(),
        )
      else
        shadcn.TextInputFormatters.digitsOnly(
          min: min,
          max: max,
        ),
    ];

    final features = <shadcn.InputFeature>[
      if (enableSpinner && isInteractive)
        shadcn.InputSpinnerFeature(
          step: step,
          min: min,
          max: max,
          enableGesture: true,
        ),
    ];

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
        Row(
          children: [
            if (prefix != null) ...[
              prefix!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: shadcn.TextField(
                controller: controller,
                initialValue: value?.toString(),
                focusNode: focusNode,
                autofocus: autofocus,
                enabled: isInteractive,
                readOnly: readOnly,
                placeholder: placeholder ?? (hint != null ? Text(hint!) : null),
                keyboardType: TextInputType.numberWithOptions(decimal: allowDecimals),
                inputFormatters: formatters,
                features: features,
                onChanged: (text) {
                  if (onChanged == null) return;
                  if (text.isEmpty) {
                    onChanged!(null);
                  } else {
                    final parsed = num.tryParse(text);
                    onChanged!(parsed);
                  }
                },
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 8),
              suffix!,
            ],
          ],
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
