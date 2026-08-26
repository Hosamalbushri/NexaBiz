import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/modules/inventory/stock_count/domain/entities/inventory_item.dart';
import 'adapters/inventory_item_adapter.dart';

/// Module-owned Hive bootstrap for inventory persistence.
class InventoryHive {
  const InventoryHive._();

  static const String boxName = 'inventory_items';

  static Future<Box<InventoryItem>> openBox() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(InventoryItemAdapter());
    }

    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<InventoryItem>(boxName);
      }
      return await Hive.openBox<InventoryItem>(boxName);
    } catch (_) {
      // Corrupt / incompatible legacy data — reset the module box.
      await Hive.deleteBoxFromDisk(boxName);
      return Hive.openBox<InventoryItem>(boxName);
    }
  }
}
