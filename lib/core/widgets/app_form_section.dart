import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

/// Clean, professional section header for forms and input screens.
///
/// Divides long forms into logical, readable groups without cluttering.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.topSpacing = AppSpacing.lg,
    this.bottomSpacing = AppSpacing.sm,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final double topSpacing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  thickness: 1,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
