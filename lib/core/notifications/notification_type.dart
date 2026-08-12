/// Severity of an in-app notification.
enum NotificationType { success, info, warning, error }

/// Extensible source category — not tied to a single business module.
enum NotificationCategory {
  general,
  system,
  inventory,
  products,
  reports,
  updates,
  sync,
}

/// Default auto-dismiss durations for floating toasts.
Duration notificationAutoDismissFor(NotificationType type) {
  return switch (type) {
    NotificationType.success => const Duration(seconds: 3),
    NotificationType.info => const Duration(seconds: 4),
    NotificationType.warning => const Duration(seconds: 5),
    NotificationType.error => const Duration(seconds: 6),
  };
}
