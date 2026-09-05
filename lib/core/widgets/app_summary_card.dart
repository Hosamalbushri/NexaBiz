import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';
import 'app_card.dart';

/// Canonical KPI / metric summary card composite for NexaBiz dashboards & modules.
class AppSummaryCard extends StatelessWidget {
  const AppSummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trendLabel,
    this.isPositiveTrend,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? trendLabel;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveIconColor = iconColor ?? scheme.primary;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: AppIcons.sm, color: effectiveIconColor),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (subtitle != null || trendLabel != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                if (trendLabel != null && isPositiveTrend != null) ...[
                  Icon(
                    isPositiveTrend!
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: isPositiveTrend!
                        ? AppColors.success
                        : scheme.error,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trendLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isPositiveTrend!
                          ? AppColors.success
                          : scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) const SizedBox(width: AppSpacing.xs),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
