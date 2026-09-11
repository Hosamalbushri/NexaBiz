import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

enum AppSurfaceVariant { flat, outlined, raised }

/// Canonical surface/container primitive for NexaBiz ERP screens.
///
/// Supports ERP content panels, forms, tables, filters, summaries, and cards
/// with token-driven padding, margin, radius, elevation, and variant options.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    final Color effectiveBackground = backgroundColor ??
        (variant == AppSurfaceVariant.flat
            ? scheme.surfaceContainerLow
            : scheme.surface);

    final Border? effectiveBorder = variant == AppSurfaceVariant.outlined
        ? Border.all(
            color: borderColor ?? scheme.outlineVariant.withValues(alpha: 0.55),
          )
        : null;

    final List<BoxShadow>? effectiveShadow = variant == AppSurfaceVariant.raised
        ? AppShadows.card(brightness)
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
          : InkWell(
              onTap: onTap,
              borderRadius: effectiveRadius as BorderRadius?,
              child: Padding(padding: padding, child: child),
            ),
    );

    if (!animate) {
      return container;
    }

    return container
        .animate()
        .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
        .moveY(begin: 6, end: 0, duration: 200.ms, curve: Curves.easeOutCubic);
  }
}
