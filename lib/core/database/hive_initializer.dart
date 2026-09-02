import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

/// Initializes Hive for platform-level persistence.
///
/// Module-specific adapters and boxes are registered by each module in later stages.
class HiveInitializer {
  const HiveInitializer._();

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
    } catch (_) {
      // In headless unit tests without Flutter engine path_provider channel, Hive.init() is used.
    }
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.openBox<dynamic>(HiveBoxes.settings);
    }
  }
}
