import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_spacing.dart';
import 'app_button.dart';

/// Reusable empty-state block for lists and tabs.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh_rounded,
    this.actionVariant = AppButtonVariant.filled,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final AppButtonVariant actionVariant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final compact = maxH.isFinite && maxH < 200;
        final iconSize = compact ? 36.0 : 64.0;
        final padding = compact ? AppSpacing.sm : AppSpacing.xl;
        final gapAfterIcon = compact ? AppSpacing.xs : AppSpacing.md;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                SizedBox(height: gapAfterIcon),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 14 : null,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: compact ? 3 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: compact ? 12 : null,
                      ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                  AppButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    icon: actionIcon,
                    variant: actionVariant,
                  ),
                ],
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 220.ms)
            .moveY(begin: 10, end: 0, duration: 220.ms);
      },
    );
  }
}
