import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/hive_boxes.dart';
import '../../../core/notifications/app_notification.dart';
import 'adapters/app_notification_adapter.dart';

/// Platform-owned Hive bootstrap for notification history.
class NotificationHive {
  const NotificationHive._();

  static const String boxName = HiveBoxes.notifications;

  static Future<Box<AppNotification>> openBox() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppNotificationAdapter());
    }

    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<AppNotification>(boxName);
      }
      return await Hive.openBox<AppNotification>(boxName);
    } catch (_) {
      await Hive.deleteBoxFromDisk(boxName);
      return Hive.openBox<AppNotification>(boxName);
    }
  }
}
