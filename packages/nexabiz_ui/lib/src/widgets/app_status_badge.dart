import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// ERP status tone categories mapping to visual hierarchy.
enum AppStatusTone { success, warning, error, info, neutral }

/// Status badge that pairs color and semantic tone with a text label,
/// built natively on top of `shadcn_flutter` badge primitives.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.animate = true,
    this.leading,
    this.trailing,
    this.onPressed,
  });

  /// Text label displayed inside the badge.
  final String label;

  /// Semantic ERP status tone.
  final AppStatusTone tone;

  /// Whether to play entrance animation.
  final bool animate;

  /// Optional leading icon or widget.
  final Widget? leading;

  /// Optional trailing icon or widget.
  final Widget? trailing;

  /// Optional press handler for interactive badges.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(label);

    Widget badge;
    switch (tone) {
      case AppStatusTone.success:
        badge = shadcn.PrimaryBadge(
          leading: leading,
          trailing: trailing,
          onPressed: onPressed,
          child: labelWidget,
        );
        break;
      case AppStatusTone.warning:
        badge = shadcn.SecondaryBadge(
          leading: leading,
          trailing: trailing,
          onPressed: onPressed,
          child: labelWidget,
        );
        break;
      case AppStatusTone.error:
        badge = shadcn.DestructiveBadge(
          leading: leading,
          trailing: trailing,
          onPressed: onPressed,
          child: labelWidget,
        );
        break;
      case AppStatusTone.info:
      case AppStatusTone.neutral:
        badge = shadcn.OutlineBadge(
          leading: leading,
          trailing: trailing,
          onPressed: onPressed,
          child: labelWidget,
        );
        break;
    }

    final semanticBadge = Semantics(
      label: label,
      child: badge,
    );

    if (!animate) {
      return semanticBadge;
    }

    return semanticBadge
        .animate()
        .fadeIn(duration: 160.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 180.ms,
          curve: Curves.easeOutBack,
        );
  }
}
