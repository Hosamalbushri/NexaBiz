import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';

/// Cross-isolate wake signal: WorkManager (or other OS jobs) stamps a request
/// that the foreground [SyncBackgroundScheduler] drains into `syncNow`.
///
/// Full headless Drift+HTTP sync inside a WorkManager isolate is deferred;
/// this keeps OS background support optional and safe.
class SyncOsWakeSignal {
  SyncOsWakeSignal._();

  static const _key = 'requested_at_ms';

  static Future<Box<int>> _box() async {
    if (Hive.isBoxOpen(HiveBoxes.syncOsWake)) {
      return Hive.box<int>(HiveBoxes.syncOsWake);
    }
    return Hive.openBox<int>(HiveBoxes.syncOsWake);
  }

  static Future<void> markRequested({DateTime? at}) async {
    final box = await _box();
    await box.put(
      _key,
      (at ?? DateTime.now().toUtc()).millisecondsSinceEpoch,
    );
  }

  /// Returns and clears the wake timestamp when present.
  static Future<DateTime?> consume() async {
    final box = await _box();
    final ms = box.get(_key);
    if (ms == null) {
      return null;
    }
    await box.delete(_key);
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static Future<bool> isPending() async {
    final box = await _box();
    return box.containsKey(_key);
  }
}

Future<void> openSyncOsWakeBox() async {
  if (!Hive.isBoxOpen(HiveBoxes.syncOsWake)) {
    await Hive.openBox<int>(HiveBoxes.syncOsWake);
  }
}
