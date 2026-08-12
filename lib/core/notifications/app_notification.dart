import 'notification_type.dart';

/// Durable in-app notification entity (history + floating toast payload).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.message,
    this.category = NotificationCategory.general,
    this.isRead = false,
    this.isPersistent = false,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String? message;
  final DateTime createdAt;
  final bool isRead;
  final bool isPersistent;
  final String? actionLabel;

  /// Optional go_router location for the action button.
  final String? actionRoute;

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    bool? isPersistent,
    String? actionLabel,
    String? actionRoute,
    bool clearMessage = false,
    bool clearActionLabel = false,
    bool clearActionRoute = false,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: clearMessage ? null : (message ?? this.message),
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isPersistent: isPersistent ?? this.isPersistent,
      actionLabel: clearActionLabel ? null : (actionLabel ?? this.actionLabel),
      actionRoute: clearActionRoute ? null : (actionRoute ?? this.actionRoute),
    );
  }
}
