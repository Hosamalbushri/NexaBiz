import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../notifications/app_notification.dart';
import 'notification_banner.dart';

/// List row for the Notification Center.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onAction,
    this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final visuals = NotificationVisuals.forType(notification.type);
    final unread = !notification.isRead;
    final locale = Localizations.localeOf(context).toString();
    final timeLabel = _relativeTime(
      notification.createdAt,
      locale,
      l10n,
    );
    final hasAction =
        notification.actionLabel != null &&
        notification.actionLabel!.trim().isNotEmpty &&
        onAction != null;
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              color: unread
                  ? Color.alphaBlend(
                      visuals.accent.withValues(alpha: isDark ? 0.14 : 0.07),
                      colorScheme.surface,
                    )
                  : colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: unread
                    ? visuals.accent.withValues(alpha: 0.28)
                    : colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: unread
                          ? visuals.accent
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: const BorderRadiusDirectional.only(
                        topStart: Radius.circular(AppRadius.lg),
                        bottomStart: Radius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: visuals.container,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              visuals.icon,
                              color: visuals.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: unread
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              height: 1.25,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      timeLabel,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                if (notification.message != null &&
                                    notification.message!
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                                if (unread || hasAction) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      if (unread)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.pill,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.notificationsUnreadBadge,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                      const Spacer(),
                                      if (hasAction)
                                        TextButton(
                                          onPressed: onAction,
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          ),
                                          child: Text(
                                            notification.actionLabel!,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(
    DateTime createdAt,
    String locale,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) {
      return l10n.notificationsTimeJustNow;
    }
    if (diff.inHours < 1) {
      return l10n.notificationsTimeMinutes(diff.inMinutes);
    }
    if (diff.inDays < 1) {
      return l10n.notificationsTimeHours(diff.inHours);
    }
    if (diff.inDays < 7) {
      return l10n.notificationsTimeDays(diff.inDays);
    }
    return DateFormat.yMMMd(locale).format(createdAt);
  }
}
