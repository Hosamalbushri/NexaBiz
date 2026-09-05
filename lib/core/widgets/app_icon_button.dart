import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';

/// Canonical icon button primitive for NexaBiz ERP.
///
/// Enforces WCAG AA touch targets (min 48x48px) with token-driven sizing,
/// tooltip support, optional badge counter, and loading state.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount,
    this.isLoading = false,
    this.iconSize = AppIcons.sm,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final int? badgeCount;
  final bool isLoading;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;

    final child = isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: const CircularProgressIndicator(strokeWidth: 2.0),
          )
        : Icon(icon, size: iconSize, color: color ?? scheme.onSurfaceVariant);

    final buttonWidget = IconButton(
      onPressed: enabled ? onPressed : null,
      icon: badgeCount != null && badgeCount! > 0
          ? Badge(
              label: Text('$badgeCount'),
              backgroundColor: scheme.error,
              textColor: scheme.onError,
              child: child,
            )
          : child,
      constraints: const BoxConstraints(
        minWidth: AppDimensions.minTouchTarget,
        minHeight: AppDimensions.minTouchTarget,
      ),
      tooltip: tooltip,
    );

    return buttonWidget;
  }
}
