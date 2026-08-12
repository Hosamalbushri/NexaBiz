import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/app_notification.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/notification_tile.dart';
import '../../../localization/app_localizations.dart';
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
            children: [
              if (unread > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton(
                      label: l10n.notificationsMarkAllRead,
                      icon: Icons.done_all_rounded,
                      variant: AppButtonVariant.text,
                      onPressed: () => service.markAllAsRead(),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
      context.push(route);
    }
  }
}
