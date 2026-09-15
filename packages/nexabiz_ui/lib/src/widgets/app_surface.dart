import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppSurfaceVariant { flat, outlined, raised }

/// Canonical surface/container primitive for NexaBiz ERP screens built on [shadcn_flutter].
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.variant = AppSurfaceVariant.outlined,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.animate = false,
  });

  final Widget child;
  final AppSurfaceVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    final Color effectiveBackground = backgroundColor ??
        (variant == AppSurfaceVariant.flat
            ? colorScheme.muted
            : colorScheme.card);

    final Border? effectiveBorder = variant == AppSurfaceVariant.outlined
        ? Border.all(
            color: borderColor ?? colorScheme.border,
          )
        : null;

    final List<BoxShadow>? effectiveShadow = variant == AppSurfaceVariant.raised
        ? [
            BoxShadow(
              color: colorScheme.foreground.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.18 : 0.04,
              ),
              blurRadius: 12.0,
              offset: const Offset(0, 3),
            ),
          ]
        : null;

    Widget container = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : GestureDetector(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );

    return container;
  }
}
