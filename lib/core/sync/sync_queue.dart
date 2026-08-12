import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import 'sync_operation.dart';
import 'sync_operation_adapter.dart';
import 'sync_status.dart';

/// Persistent synchronization queue (survives process restarts).
class SyncQueue {
  SyncQueue({Box<SyncOperation>? box}) : _boxOverride = box;

  final Box<SyncOperation>? _boxOverride;
  Box<SyncOperation>? _box;
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  static Future<void> registerAdapter() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  }

  Future<Box<SyncOperation>> _ensureBox() async {
    final override = _boxOverride;
    if (override != null) {
      return override;
    }
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    await registerAdapter();
    if (Hive.isBoxOpen(HiveBoxes.syncQueue)) {
      _box = Hive.box<SyncOperation>(HiveBoxes.syncQueue);
    } else {
      _box = await Hive.openBox<SyncOperation>(HiveBoxes.syncQueue);
    }
    return _box!;
  }

  Future<void> enqueue(SyncOperation operation) async {
    final box = await _ensureBox();
    // Coalesce: replace older pending/failed ops for the same entity.
    final existingKeys = <dynamic>[];
    for (final entry in box.toMap().entries) {
      final op = entry.value;
      if (op.entityType == operation.entityType &&
          op.entityId == operation.entityId &&
          (op.status == SyncStatus.pending ||
              op.status == SyncStatus.failed ||
              op.status == SyncStatus.conflict)) {
        existingKeys.add(entry.key);
      }
    }
    for (final key in existingKeys) {
      await box.delete(key);
    }
    await box.put(operation.id, operation);
    _changes.add(null);
  }

  Future<List<SyncOperation>> peekReady({DateTime? now}) async {
    final box = await _ensureBox();
    final stamp = (now ?? DateTime.now().toUtc());
    final ready = box.values
        .where((op) {
          if (op.status != SyncStatus.pending &&
              op.status != SyncStatus.failed) {
            return false;
          }
          final retryAt = op.nextRetryAt;
          if (retryAt != null && retryAt.isAfter(stamp)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    ready.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ready;
  }

  Future<List<SyncOperation>> all() async {
    final box = await _ensureBox();
    return box.values.toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<int> countByStatus(SyncStatus status) async {
    final box = await _ensureBox();
    return box.values.where((op) => op.status == status).length;
  }

  Future<void> update(SyncOperation operation) async {
    final box = await _ensureBox();
    await box.put(operation.id, operation);
    _changes.add(null);
  }

  Future<void> remove(String id) async {
    final box = await _ensureBox();
    await box.delete(id);
    _changes.add(null);
  }

  Future<void> clearSynced() async {
    final box = await _ensureBox();
    final keys = <dynamic>[];
    for (final entry in box.toMap().entries) {
      if (entry.value.status == SyncStatus.synced) {
        keys.add(entry.key);
      }
    }
    for (final key in keys) {
      await box.delete(key);
    }
    if (keys.isNotEmpty) {
      _changes.add(null);
    }
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}
