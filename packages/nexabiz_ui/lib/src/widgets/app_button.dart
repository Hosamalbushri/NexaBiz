import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

enum AppButtonVariant { filled, elevated, outlined, text, tonal }

/// Design-system button wrapping shadcn_flutter button primitives.
///
/// Preserves NexaBiz API: [label], [onPressed], [variant], [icon],
/// [trailingIcon], [isLoading], [expand].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool trailingIcon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final hasShadcnTheme =
        context.findAncestorWidgetOfExactType<shadcn.ComponentTheme>() != null ||
            context.findAncestorWidgetOfExactType<shadcn.Theme>() != null;

    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: hasShadcnTheme
                ? const shadcn.CircularProgressIndicator(strokeWidth: 2)
                : const CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: trailingIcon
                ? [
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ]
                : [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ],
          );

    final VoidCallback? handler = enabled ? onPressed : null;

    final Widget button = hasShadcnTheme
        ? switch (variant) {
            AppButtonVariant.filled => shadcn.PrimaryButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.elevated => shadcn.SecondaryButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.outlined => shadcn.OutlineButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.text => shadcn.GhostButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.tonal => shadcn.SecondaryButton(
              onPressed: handler,
              child: child,
            ),
          }
        : switch (variant) {
            AppButtonVariant.filled => FilledButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.elevated => ElevatedButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.outlined => OutlinedButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.text => TextButton(
              onPressed: handler,
              child: child,
            ),
            AppButtonVariant.tonal => FilledButton.tonal(
              onPressed: handler,
              child: child,
            ),
          };

    final wrapped = expand
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return wrapped.animate().fadeIn(duration: 160.ms);
  }
}
