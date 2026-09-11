import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/app_dimensions.dart';
import '../theme/tokens/app_icons.dart';

enum AppIconButtonVariant { standard, primary, destructive, outline, ghost }

/// Canonical icon button primitive for NexaBiz ERP.
///
/// Modernized with interactive hover micro-animations, touch target enforcement,
/// tooltip support, badge counter, and variant styling.
class AppIconButton extends StatefulWidget {
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
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    final childWidget = widget.isLoading
        ? SizedBox(
            width: widget.iconSize,
            height: widget.iconSize,
            child: const shadcn.CircularProgressIndicator(strokeWidth: 2.0),
          )
        : Icon(widget.icon, size: widget.iconSize, color: widget.color);

    final Widget badgedChild = widget.badgeCount != null && widget.badgeCount! > 0
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              childWidget,
              Positioned(
                top: -4,
                right: -4,
                child: shadcn.PrimaryBadge(
                  child: Text('${widget.badgeCount}'),
                ),
              ),
            ],
          )
        : childWidget;

    final VoidCallback? handler = enabled ? widget.onPressed : null;

    Widget button = switch (widget.variant) {
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

    button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered && enabled ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.minTouchTarget,
            minHeight: AppDimensions.minTouchTarget,
          ),
          child: button,
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = shadcn.Tooltip(
        tooltip: (context) => Text(widget.tooltip!),
        child: button,
      );
    }

    return button;
  }
}
