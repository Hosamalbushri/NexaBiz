import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/app_notification.dart';
import '../../../../core/widgets/notification_tile.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/app_localizations.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../providers/notifications_provider.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

/// Platform Notification Center — history, read state, and actions.
class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final service = ref.read(notificationServiceProvider);

    return AppListPage<AppNotification>(
      title: l10n.notificationsTitle,
      headerActions: [
        if (unread > 0)
          AppIconButton(
            icon: Icons.done_all_rounded,
            tooltip: l10n.notificationsMarkAllRead,
            onPressed: () => service.markAllAsRead(),
          ),
      ],
      isLoading: async.isLoading && !async.hasValue,
      errorText: async.error?.toString(),
      onRetry: () => ref.invalidate(notificationsProvider),
      emptyTitle: l10n.notificationsEmptyTitle,
      emptySubtitle: l10n.notificationsEmptyMessage,
      activeFilterChips: async.valueOrNull != null && async.valueOrNull!.isNotEmpty
          ? [
              Expanded(
                child: _NotificationsSummaryBar(
                  totalCount: async.valueOrNull!.length,
                  unreadCount: unread,
                  onMarkAllRead: unread > 0
                      ? () => service.markAllAsRead()
                      : null,
                ),
              ),
            ]
          : const [],
      items: async.valueOrNull ?? const [],
      contentBuilder: (context, itemList) {
        return ListView.separated(
          padding: AppConstants.pageInsets(
            context,
          ).copyWith(top: AppSpacing.sm),
          itemCount: itemList.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = itemList[index];
            return NotificationTile(
              notification: item,
              onTap: () => service.markAsRead(item.id),
              onDismiss: () => service.remove(item.id),
              onAction: item.actionLabel == null
                  ? null
                  : () => _onAction(context, ref, item),
            );
          },
        );
      },
    );
  }

  void _onAction(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    ref.read(notificationServiceProvider).markAsRead(notification.id);
    final route = notification.actionRoute;
    if (route != null && route.isNotEmpty) {
      context.go(route);
    }
  }
}

class _NotificationsSummaryBar extends StatelessWidget {
  const _NotificationsSummaryBar({
    required this.totalCount,
    required this.unreadCount,
    this.onMarkAllRead,
  });

  final int totalCount;
  final int unreadCount;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notificationsSummaryTotal(totalCount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unreadCount > 0
                        ? l10n.notificationsSummaryUnread(unreadCount)
                        : l10n.notificationsSummaryAllRead,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: unreadCount > 0
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onMarkAllRead != null)
              TextButton.icon(
                onPressed: onMarkAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(l10n.notificationsMarkAllRead),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
