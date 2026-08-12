import 'app_notification.dart';
import 'notification_type.dart';

/// Platform notification API — call from any feature via Riverpod.
abstract class NotificationService {
  /// Shows a floating toast and (by default) persists to history.
  Future<AppNotification> show({
    required NotificationType type,
    required String title,
    String? message,
    NotificationCategory category = NotificationCategory.general,
    Duration? duration,
    bool isPersistent = false,
    bool persistToHistory = true,
    String? actionLabel,
    String? actionRoute,
  });

  Future<AppNotification> showSuccess({
    required String title,
    String? message,
    NotificationCategory category = NotificationCategory.general,
    Duration? duration,
    bool isPersistent = false,
    bool persistToHistory = true,
    String? actionLabel,
    String? actionRoute,
  }) {
    return show(
      type: NotificationType.success,
      title: title,
      message: message,
      category: category,
      duration: duration,
      isPersistent: isPersistent,
      persistToHistory: persistToHistory,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
    );
  }

  Future<AppNotification> showInfo({
    required String title,
    String? message,
    NotificationCategory category = NotificationCategory.general,
    Duration? duration,
    bool isPersistent = false,
    bool persistToHistory = true,
    String? actionLabel,
    String? actionRoute,
  }) {
    return show(
      type: NotificationType.info,
      title: title,
      message: message,
      category: category,
      duration: duration,
      isPersistent: isPersistent,
      persistToHistory: persistToHistory,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
    );
  }

  Future<AppNotification> showWarning({
    required String title,
    String? message,
    NotificationCategory category = NotificationCategory.general,
    Duration? duration,
    bool isPersistent = false,
    bool persistToHistory = true,
    String? actionLabel,
    String? actionRoute,
  }) {
    return show(
      type: NotificationType.warning,
      title: title,
      message: message,
      category: category,
      duration: duration,
      isPersistent: isPersistent,
      persistToHistory: persistToHistory,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
    );
  }

  Future<AppNotification> showError({
    required String title,
    String? message,
    NotificationCategory category = NotificationCategory.general,
    Duration? duration,
    bool isPersistent = false,
    bool persistToHistory = true,
    String? actionLabel,
    String? actionRoute,
  }) {
    return show(
      type: NotificationType.error,
      title: title,
      message: message,
      category: category,
      duration: duration,
      isPersistent: isPersistent,
      persistToHistory: persistToHistory,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
    );
  }

  /// Dismisses a floating toast (does not delete history).
  void dismiss(String id);

  void dismissAll();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> remove(String id);

  Future<void> clearHistory();
}
