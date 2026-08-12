import '../../../../core/notifications/app_notification.dart';

/// Persistence contract for notification history.
abstract class NotificationRepository {
  Future<List<AppNotification>> getAll();

  Stream<List<AppNotification>> watchAll();

  Future<int> unreadCount();

  Future<void> add(AppNotification notification);

  Future<void> update(AppNotification notification);

  Future<void> remove(String id);

  Future<void> clear();

  Future<void> markAllAsRead();
}
