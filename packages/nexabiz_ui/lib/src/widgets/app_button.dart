import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/app_dimensions.dart';

enum AppButtonVariant { filled, elevated, outlined, text, tonal, destructive }

/// Modernized design-system button wrapping shadcn_flutter button primitives.
///
/// Features subtle hover scale feedback, localized text handling, crisp icon alignment,
/// and responsive density.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.trailingIcon = false,
    this.isLoading = false,
    this.expand = false,
    this.isCompact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool trailingIcon;
  final bool isLoading;
  final bool expand;
  final bool isCompact;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final theme = shadcn.Theme.of(context);

    final leadingWidget = widget.isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: shadcn.CircularProgressIndicator(strokeWidth: 2),
          )
        : (widget.icon != null && !widget.trailingIcon
            ? Icon(widget.icon, size: 18)
            : null);

    final trailingWidget =
        !widget.isLoading && widget.icon != null && widget.trailingIcon
            ? Icon(widget.icon, size: 18)
            : null;

    final childWidget = Text(
      widget.label,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );

    final VoidCallback? handler = enabled ? widget.onPressed : null;
    final buttonDensity = widget.isCompact
        ? shadcn.ButtonDensity.compact
        : shadcn.ButtonDensity.normal;

    final Widget button = switch (widget.variant) {
      AppButtonVariant.filled => shadcn.PrimaryButton(
          onPressed: handler,
          density: buttonDensity,
          leading: leadingWidget,
          trailing: trailingWidget,
          child: childWidget,
        ),
      AppButtonVariant.elevated => shadcn.SecondaryButton(
          onPressed: handler,
          density: buttonDensity,
          leading: leadingWidget,
          trailing: trailingWidget,
          child: childWidget,
        ),
      AppButtonVariant.outlined => shadcn.OutlineButton(
          onPressed: handler,
          density: buttonDensity,
          leading: leadingWidget,
          trailing: trailingWidget,
          child: childWidget,
        ),
      AppButtonVariant.text => shadcn.GhostButton(
          onPressed: handler,
          density: buttonDensity,
          leading: leadingWidget,
          trailing: trailingWidget,
          child: childWidget,
        ),
      AppButtonVariant.tonal => shadcn.SecondaryButton(
          onPressed: handler,
          density: buttonDensity,
          leading: leadingWidget,
          trailing: trailingWidget,
          child: childWidget,
        ),
      AppButtonVariant.destructive => shadcn.DestructiveButton(
          onPressed: handler,
          density: buttonDensity,
          leading: leadingWidget,
          trailing: trailingWidget,
          child: childWidget,
        ),
    };

    final double height = widget.isCompact
        ? AppDimensions.buttonHeightCompact
        : AppDimensions.buttonHeight;

    final isPrimary = widget.variant == AppButtonVariant.filled;

    final Widget interactiveButton = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.98
              : (_isHovered && enabled ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: height,
            width: widget.expand ? double.infinity : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isHovered && enabled && isPrimary
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: button,
          ),
        ),
      ),
    );

    return interactiveButton.animate().fadeIn(duration: 160.ms);
  }
}
