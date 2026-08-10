import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

/// Initializes Hive for platform-level persistence.
///
/// Module-specific adapters and boxes are registered by each module in later stages.
class HiveInitializer {
  const HiveInitializer._();

  static Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.openBox<dynamic>(HiveBoxes.settings);
    }
  }
}
