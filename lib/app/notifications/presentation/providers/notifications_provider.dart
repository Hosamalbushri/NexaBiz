import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/app_notification.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/notifications/notification_type.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

/// Maximum simultaneous floating toasts.
const int kMaxVisibleFloatingNotifications = 3;

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl();
});

/// History list (newest first).
final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>(
  (ref) {
    return ref.watch(notificationRepositoryProvider).watchAll();
  },
);

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

/// Active floating toast queue (visible + waiting).
final floatingNotificationsProvider =
    StateNotifierProvider<FloatingNotificationsController, List<FloatingToast>>(
      (ref) => FloatingNotificationsController(),
    );

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl(ref);
});

class FloatingToast {
  const FloatingToast({
    required this.notification,
    this.duration,
  });

  final AppNotification notification;

  /// Null means persistent until dismissed.
  final Duration? duration;
}

class FloatingNotificationsController
    extends StateNotifier<List<FloatingToast>> {
  FloatingNotificationsController() : super(const []);

  final List<FloatingToast> _queue = [];
  final Map<String, Timer> _timers = {};

  void enqueue(FloatingToast toast) {
    if (state.any((t) => t.notification.id == toast.notification.id) ||
        _queue.any((t) => t.notification.id == toast.notification.id)) {
      return;
    }

    if (state.length < kMaxVisibleFloatingNotifications) {
      _show(toast);
    } else {
      _queue.add(toast);
    }
  }

  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    state = [
      for (final toast in state)
        if (toast.notification.id != id) toast,
    ];
    _drainQueue();
  }

  void dismissAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _queue.clear();
    state = const [];
  }

  void _show(FloatingToast toast) {
    state = [...state, toast];
    final duration = toast.duration;
    if (duration != null) {
      _timers[toast.notification.id] = Timer(duration, () {
        dismiss(toast.notification.id);
      });
    }
  }

  void _drainQueue() {
    while (state.length < kMaxVisibleFloatingNotifications &&
        _queue.isNotEmpty) {
      _show(_queue.removeAt(0));
    }
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

class NotificationServiceImpl extends NotificationService {
  NotificationServiceImpl(this._ref);

  final Ref _ref;

  @override
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
  }) async {
    final notification = AppNotification(
      id: _newId(),
      type: type,
      category: category,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
      isPersistent: isPersistent,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
    );

    if (persistToHistory) {
      await _ref.read(notificationRepositoryProvider).add(notification);
    }

    final autoDismiss = isPersistent
        ? null
        : (duration ?? notificationAutoDismissFor(type));

    _ref
        .read(floatingNotificationsProvider.notifier)
        .enqueue(
          FloatingToast(notification: notification, duration: autoDismiss),
        );

    return notification;
  }

  @override
  void dismiss(String id) {
    _ref.read(floatingNotificationsProvider.notifier).dismiss(id);
  }

  @override
  void dismissAll() {
    _ref.read(floatingNotificationsProvider.notifier).dismissAll();
  }

  @override
  Future<void> markAsRead(String id) async {
    final repo = _ref.read(notificationRepositoryProvider);
    final all = await repo.getAll();
    AppNotification? match;
    for (final item in all) {
      if (item.id == id) {
        match = item;
        break;
      }
    }
    if (match == null) {
      return;
    }
    await repo.update(match.copyWith(isRead: true));
  }

  @override
  Future<void> markAllAsRead() async {
    await _ref.read(notificationRepositoryProvider).markAllAsRead();
  }

  @override
  Future<void> remove(String id) async {
    dismiss(id);
    await _ref.read(notificationRepositoryProvider).remove(id);
  }

  @override
  Future<void> clearHistory() async {
    dismissAll();
    await _ref.read(notificationRepositoryProvider).clear();
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_ref.hashCode}';
}
