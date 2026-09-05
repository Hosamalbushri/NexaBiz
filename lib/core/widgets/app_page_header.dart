import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';

/// Canonical page header composite for NexaBiz ERP screens.
///
/// Displays screen title, subtitle, optional breadcrumb trail, and action buttons.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            Row(
              children: [
                for (int i = 0; i < breadcrumbs!.length; i++) ...[
                  Text(
                    breadcrumbs![i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: i == breadcrumbs!.length - 1
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: i == breadcrumbs!.length - 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  if (i < breadcrumbs!.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: actions!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
