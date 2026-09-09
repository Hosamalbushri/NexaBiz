import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Canonical surface card container for detail page sections.
class AppDetailSurfaceCard extends StatelessWidget {
  const AppDetailSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surface,
        borderRadius: effectiveRadius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: padding,
      child: child,
    );
  }
}
