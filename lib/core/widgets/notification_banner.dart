import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../notifications/app_notification.dart';
import '../notifications/notification_type.dart';
import 'app_button.dart';

/// Visual tokens for a [NotificationType].
class NotificationVisuals {
  const NotificationVisuals({
    required this.accent,
    required this.container,
    required this.icon,
  });

  final Color accent;
  final Color container;
  final IconData icon;

  static NotificationVisuals forType(NotificationType type) {
    return switch (type) {
      NotificationType.success => const NotificationVisuals(
        accent: AppColors.success,
        container: AppColors.successContainer,
        icon: Icons.check_circle_rounded,
      ),
      NotificationType.info => const NotificationVisuals(
        accent: AppColors.info,
        container: AppColors.infoContainer,
        icon: Icons.info_rounded,
      ),
      NotificationType.warning => const NotificationVisuals(
        accent: AppColors.warning,
        container: AppColors.warningContainer,
        icon: Icons.warning_amber_rounded,
      ),
      NotificationType.error => const NotificationVisuals(
        accent: AppColors.error,
        container: AppColors.errorContainer,
        icon: Icons.error_rounded,
      ),
    };
  }
}

/// Card content for a floating or inline notification.
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    super.key,
    required this.notification,
    this.onClose,
    this.onAction,
    this.dense = false,
  });

  final AppNotification notification;
  final VoidCallback? onClose;
  final VoidCallback? onAction;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final visuals = NotificationVisuals.forType(notification.type);
    final cardColor = Color.alphaBlend(
      visuals.accent.withValues(alpha: isDark ? 0.16 : 0.07),
      colorScheme.surface,
    );
    final hasAction =
        notification.actionLabel != null &&
        notification.actionLabel!.trim().isNotEmpty &&
        onAction != null;

    return Semantics(
      liveRegion: true,
      label: '${notification.title}. ${notification.message ?? ''}',
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: visuals.accent.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              dense ? AppSpacing.sm : AppSpacing.md,
              AppSpacing.sm,
              dense ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: dense ? 40 : 44,
                      height: dense ? 40 : 44,
                      decoration: BoxDecoration(
                        color: visuals.container,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        visuals.icon,
                        color: visuals.accent,
                        size: dense ? 22 : 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              height: 1.25,
                            ),
                          ),
                          if (notification.message != null &&
                              notification.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notification.message!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onClose != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Semantics(
                          button: true,
                          label: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          child: IconButton(
                            onPressed: onClose,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasAction) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton(
                      label: notification.actionLabel!,
                      onPressed: onAction,
                      variant: AppButtonVariant.tonal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
