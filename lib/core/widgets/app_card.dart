import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_spacing.dart';

/// Themed surface card used across modules.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.animate = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      color: color,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              child: content,
            ),
    );

    if (!animate) {
      return card;
    }

    return card
        .animate()
        .fadeIn(duration: 220.ms, curve: Curves.easeOutCubic)
        .moveY(begin: 8, end: 0, duration: 220.ms, curve: Curves.easeOutCubic);
  }
}
