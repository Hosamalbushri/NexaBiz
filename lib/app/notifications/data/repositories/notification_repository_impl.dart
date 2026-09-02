import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/notifications/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../notification_hive.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({this._box});

  Box<AppNotification>? _box;

  /// Returns an already-open box only (safe before bootstrap / in widget tests).
  Box<AppNotification>? get _openBoxOrNull {
    final existing = _box;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    if (Hive.isBoxOpen(NotificationHive.boxName)) {
      final box = Hive.box<AppNotification>(NotificationHive.boxName);
      _box = box;
      return box;
    }
    return null;
  }

  /// Opens the box when persistence is required (after Hive init / bootstrap).
  Future<Box<AppNotification>> _ensureBox() async {
    final open = _openBoxOrNull;
    if (open != null) {
      return open;
    }
    final opened = await NotificationHive.openBox();
    _box = opened;
    return opened;
  }

  @override
  Future<List<AppNotification>> getAll() async {
    final box = _openBoxOrNull;
    if (box == null) {
      return const [];
    }
    final items = box.values.toList(growable: false);
    return List<AppNotification>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<AppNotification>> watchAll() async* {
    final box = _openBoxOrNull;
    if (box == null) {
      yield const <AppNotification>[];
      return;
    }
    yield await getAll();
    yield* box.watch().asyncMap((_) => getAll());
  }

  @override
  Future<int> unreadCount() async {
    final box = _openBoxOrNull;
    if (box == null) {
      return 0;
    }
    var count = 0;
    for (final item in box.values) {
      if (!item.isRead) {
        count++;
      }
    }
    return count;
  }

  @override
  Future<void> add(AppNotification notification) async {
    final box = await _ensureBox();
    await box.put(notification.id, notification);
  }

  @override
  Future<void> update(AppNotification notification) async {
    final box = await _ensureBox();
    await box.put(notification.id, notification);
  }

  @override
  Future<void> remove(String id) async {
    final box = await _ensureBox();
    await box.delete(id);
  }

  @override
  Future<void> clear() async {
    final box = await _ensureBox();
    await box.clear();
  }

  @override
  Future<void> markAllAsRead() async {
    final box = await _ensureBox();
    for (final entry in box.toMap().entries) {
      final value = entry.value;
      if (!value.isRead) {
        await box.put(entry.key, value.copyWith(isRead: true));
      }
    }
  }
}
