import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/app_spacing.dart';

/// Canonical card primitive for NexaBiz ERP built natively on [shadcn.Card].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.animate = false,
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

    final card = shadcn.Card(
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: onTap,
              child: content,
            ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: card,
      );
    }

    return card;
  }
}
