import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/app_dimensions.dart';
import '../theme/tokens/app_icons.dart';

enum AppIconButtonVariant { standard, primary, destructive, outline, ghost }

/// Canonical icon button primitive for NexaBiz ERP.
///
/// Enforces WCAG AA touch targets (min 48x48px) with token-driven sizing,
/// tooltip support, badge counter, loading state, and variant styling.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.tooltip,
    this.badgeCount,
    this.isLoading = false,
    this.iconSize = AppIcons.sm,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final String? tooltip;
  final int? badgeCount;
  final bool isLoading;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final childWidget = isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: const shadcn.CircularProgressIndicator(strokeWidth: 2.0),
          )
        : Icon(icon, size: iconSize, color: color);

    final Widget badgedChild = badgeCount != null && badgeCount! > 0
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              childWidget,
              Positioned(
                top: -4,
                right: -4,
                child: shadcn.PrimaryBadge(
                  child: Text('$badgeCount'),
                ),
              ),
            ],
          )
        : childWidget;

    final VoidCallback? handler = enabled ? onPressed : null;

    Widget button = switch (variant) {
      AppIconButtonVariant.standard => shadcn.GhostButton(
          onPressed: handler,
          density: shadcn.ButtonDensity.icon,
          shape: shadcn.ButtonShape.circle,
          child: badgedChild,
        ),
      AppIconButtonVariant.primary => shadcn.PrimaryButton(
          onPressed: handler,
          density: shadcn.ButtonDensity.icon,
          shape: shadcn.ButtonShape.circle,
          child: badgedChild,
        ),
      AppIconButtonVariant.destructive => shadcn.DestructiveButton(
          onPressed: handler,
          density: shadcn.ButtonDensity.icon,
          shape: shadcn.ButtonShape.circle,
          child: badgedChild,
        ),
      AppIconButtonVariant.outline => shadcn.OutlineButton(
          onPressed: handler,
          density: shadcn.ButtonDensity.icon,
          shape: shadcn.ButtonShape.circle,
          child: badgedChild,
        ),
      AppIconButtonVariant.ghost => shadcn.GhostButton(
          onPressed: handler,
          density: shadcn.ButtonDensity.icon,
          shape: shadcn.ButtonShape.circle,
          child: badgedChild,
        ),
    };

    button = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.minTouchTarget,
        minHeight: AppDimensions.minTouchTarget,
      ),
      child: button,
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = shadcn.Tooltip(
        tooltip: (context) => Text(tooltip!),
        child: button,
      );
    }

    return button;
  }
}
