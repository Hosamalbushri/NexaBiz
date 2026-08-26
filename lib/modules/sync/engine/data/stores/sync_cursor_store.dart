import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/database/hive_boxes.dart';

/// Durable pull sequence cursors keyed by entity type.
///
/// Survives process restarts so devices resume from the last acknowledged
/// server cursor instead of re-pulling from zero.
class SyncCursorStore {
  SyncCursorStore({Box<int>? box, String? boxName})
    : _boxOverride = box,
      _boxName = boxName ?? HiveBoxes.syncCursors;

  final Box<int>? _boxOverride;
  final String _boxName;
  Box<int>? _box;

  Future<Box<int>> _ensureBox() async {
    final override = _boxOverride;
    if (override != null) {
      return override;
    }
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<int>(_boxName);
    } else {
      _box = await Hive.openBox<int>(_boxName);
    }
    return _box!;
  }

  Future<int?> read(String entityType) async {
    final box = await _ensureBox();
    return box.get(entityType);
  }

  Future<void> write(String entityType, int cursor) async {
    final box = await _ensureBox();
    await box.put(entityType, cursor);
  }

  Future<void> clear(String entityType) async {
    final box = await _ensureBox();
    await box.delete(entityType);
  }

  Future<void> clearAll() async {
    final box = await _ensureBox();
    await box.clear();
  }
}

/// Opens the durable sync cursor box during app bootstrap.
Future<void> openSyncCursorBox() async {
  if (!Hive.isBoxOpen(HiveBoxes.syncCursors)) {
    await Hive.openBox<int>(HiveBoxes.syncCursors);
  }
}
