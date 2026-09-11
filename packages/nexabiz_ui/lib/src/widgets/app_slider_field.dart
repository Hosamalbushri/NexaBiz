import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical slider form field component for NexaBiz ERP.
///
/// Wraps `shadcn_flutter` [shadcn.Slider] with a NexaBiz form field header (`label`, `required`, formatted value badge),
/// range labels (`min`, `max`), and error/helper footers.
class AppSliderField extends StatelessWidget {
  const AppSliderField({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.label,
    this.valueFormatter,
    this.required = false,
    this.enabled = true,
    this.showMinMaxLabels = true,
    this.errorText,
    this.helperText,
  });

  final shadcn.SliderValue value;
  final ValueChanged<shadcn.SliderValue>? onChanged;
  final ValueChanged<shadcn.SliderValue>? onChangeStart;
  final ValueChanged<shadcn.SliderValue>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String Function(shadcn.SliderValue value)? valueFormatter;
  final bool required;
  final bool enabled;
  final bool showMinMaxLabels;
  final String? errorText;
  final String? helperText;

  String _defaultFormat(shadcn.SliderValue val) {
    if (val.isRanged) {
      return '${val.start.toStringAsFixed(0)} - ${val.end.toStringAsFixed(0)}';
    }
    return val.value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;
    final isInteractive = enabled && onChanged != null;
    final formattedValue = valueFormatter != null ? valueFormatter!(value) : _defaultFormat(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(theme.radiusSm),
                ),
                child: Text(
                  formattedValue,
                  style: theme.typography.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondaryForeground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        shadcn.Slider(
          value: value,
          onChanged: isInteractive ? onChanged : null,
          onChangeStart: onChangeStart,
          onChangeEnd: onChangeEnd,
          min: min,
          max: max,
          divisions: divisions,
          enabled: isInteractive,
        ),
        if (showMinMaxLabels) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toStringAsFixed(0),
                style: theme.typography.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontSize: 11,
                ),
              ),
              Text(
                max.toStringAsFixed(0),
                style: theme.typography.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
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
