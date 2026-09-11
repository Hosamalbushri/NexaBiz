import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Represents an option item within [AppChoiceCardGroup].
class AppChoiceOption<T> {
  const AppChoiceOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Widget? icon;
  final bool enabled;
}

/// Canonical choice card group primitive for NexaBiz ERP.
///
/// Renders choice options as card items (`shadcn.RadioCard<T>`) inside a reactive radio group
/// (`shadcn.ControlledRadioGroup<T>`), wrapped with standard NexaBiz form shell header/footer.
class AppChoiceCardGroup<T> extends StatelessWidget {
  const AppChoiceCardGroup({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.direction = Axis.vertical,
    this.filled = true,
    this.required = false,
    this.enabled = true,
    this.errorText,
    this.helperText,
  });

  final List<AppChoiceOption<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final Axis direction;
  final bool filled;
  final bool required;
  final bool enabled;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    Widget buildCard(AppChoiceOption<T> option) {
      return shadcn.RadioCard<T>(
        value: option.value,
        filled: filled,
        enabled: enabled && option.enabled,
        child: Row(
          children: [
            if (option.icon != null) ...[
              option.icon!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.title,
                    style: theme.typography.small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled && option.enabled
                          ? theme.colorScheme.foreground
                          : theme.colorScheme.mutedForeground,
                    ),
                  ),
                  if (option.subtitle != null && option.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle!,
                      style: theme.typography.xSmall.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final children = items.map((option) {
      return Padding(
        padding: direction == Axis.vertical
            ? const EdgeInsets.only(bottom: 8.0)
            : const EdgeInsets.only(right: 8.0),
        child: buildCard(option),
      );
    }).toList();

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
        shadcn.ControlledRadioGroup<T>(
          initialValue: value,
          onChanged: enabled ? onChanged : null,
          enabled: enabled,
          child: direction == Axis.vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children.map((c) => Expanded(child: c)).toList(),
                ),
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
