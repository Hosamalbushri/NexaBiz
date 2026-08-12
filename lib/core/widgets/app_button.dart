import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum AppButtonVariant { filled, elevated, outlined, text, tonal }

/// Design-system button wrapping Material 3 button variants.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.elevated => ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    };

    final wrapped = expand
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return wrapped.animate().fadeIn(duration: 160.ms);
  }
}
