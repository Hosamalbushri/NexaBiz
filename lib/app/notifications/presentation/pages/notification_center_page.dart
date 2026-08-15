import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/app_notification.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/notification_tile.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/app_localizations.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../providers/notifications_provider.dart';

/// Platform Notification Center — history, read state, and actions.
class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final service = ref.read(notificationServiceProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.notificationsTitle,
        showBackButton: true,
        actions: [
          if (unread > 0)
            CustomAppBarAction(
              icon: Icons.done_all_rounded,
              tooltip: l10n.notificationsMarkAllRead,
              onPressed: () => service.markAllAsRead(),
            ),
        ],
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppEmptyState(
          title: l10n.somethingWentWrong,
          subtitle: error.toString(),
          icon: Icons.error_outline_rounded,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: l10n.notificationsEmptyTitle,
              subtitle: l10n.notificationsEmptyMessage,
              icon: Icons.notifications_none_rounded,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: _NotificationsSummaryBar(
                  totalCount: items.length,
                  unreadCount: unread,
                  onMarkAllRead: unread > 0
                      ? () => service.markAllAsRead()
                      : null,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: AppConstants.pageInsets(context).copyWith(
                    top: AppSpacing.sm,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return NotificationTile(
                      notification: item,
                      onTap: () => service.markAsRead(item.id),
                      onDismiss: () => service.remove(item.id),
                      onAction: item.actionLabel == null
                          ? null
                          : () => _onAction(context, ref, item),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
