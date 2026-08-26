import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/modules/sync/domain/entities/sync_conflict_record.dart';

/// Durable store for active and resolved synchronization conflicts.
class SyncConflictStore {
  SyncConflictStore({Box<String>? box}) : _box = box;

  final Box<String>? _box;
  final Map<String, SyncConflictRecord> _memoryFallback = {};
  static const boxName = 'sync_conflicts';

  static Future<SyncConflictStore> open() async {
    final box = await Hive.openBox<String>(boxName);
    return SyncConflictStore(box: box);
  }

  Future<void> save(SyncConflictRecord record) async {
    final box = _box;
    if (box != null && box.isOpen) {
      await box.put(record.operationId, record.toJson());
    } else {
      _memoryFallback[record.operationId] = record;
    }
  }

  Future<SyncConflictRecord?> getByOperationId(String operationId) async {
    final box = _box;
    if (box != null && box.isOpen) {
      final jsonStr = box.get(operationId);
      if (jsonStr == null) {
        return null;
      }
      return SyncConflictRecord.fromJson(jsonStr);
    }
    return _memoryFallback[operationId];
  }

  Future<List<SyncConflictRecord>> getUnresolved() async {
    final box = _box;
    final all = <SyncConflictRecord>[];
    if (box != null && box.isOpen) {
      for (final jsonStr in box.values) {
        final rec = SyncConflictRecord.fromJson(jsonStr);
        if (rec.mergeStatus == 'unresolved' ||
            rec.mergeStatus == 'requires_user_resolution') {
          all.add(rec);
        }
      }
    } else {
      all.addAll(
        _memoryFallback.values.where(
          (rec) =>
              rec.mergeStatus == 'unresolved' ||
              rec.mergeStatus == 'requires_user_resolution',
        ),
      );
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<List<SyncConflictRecord>> getAll() async {
    final box = _box;
    final all = <SyncConflictRecord>[];
    if (box != null && box.isOpen) {
      for (final jsonStr in box.values) {
        all.add(SyncConflictRecord.fromJson(jsonStr));
      }
    } else {
      all.addAll(_memoryFallback.values);
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<void> remove(String operationId) async {
    final box = _box;
    if (box != null && box.isOpen) {
      await box.delete(operationId);
    } else {
      _memoryFallback.remove(operationId);
    }
  }

  Future<void> clear() async {
    final box = _box;
    if (box != null && box.isOpen) {
      await box.clear();
    } else {
      _memoryFallback.clear();
    }
  }
}
