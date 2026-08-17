import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../database/encrypted_hive_box.dart';
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
    if (Hive.isBoxOpen(HiveBoxes.syncQueueEncrypted)) {
      _box = Hive.box<SyncOperation>(HiveBoxes.syncQueueEncrypted);
    } else {
      _box = await EncryptedHive.openMigrated<SyncOperation>(
        encryptedBoxName: HiveBoxes.syncQueueEncrypted,
        legacyPlainBoxName: HiveBoxes.syncQueue,
      );
    }
    return _box!;
  }

  Future<void> enqueue(SyncOperation operation) async {
    final box = await _ensureBox();
    // Coalesce: replace older pending/failed/conflict ops for the same entity.
    final existingKeys = <dynamic>[];
    var hadCreate = false;
    var earliestCreatedAt = operation.createdAt;
    for (final entry in box.toMap().entries) {
      final op = entry.value;
      if (op.entityType == operation.entityType &&
          op.entityId == operation.entityId &&
          (op.status == SyncStatus.pending ||
              op.status == SyncStatus.failed ||
              op.status == SyncStatus.conflict)) {
        existingKeys.add(entry.key);
        if (op.type == SyncOperationType.create) {
          hadCreate = true;
        }
        if (op.createdAt.isBefore(earliestCreatedAt)) {
          earliestCreatedAt = op.createdAt;
        }
      }
    }

    // Never-uploaded create + local delete → drop queue entry (nothing to push).
    if (hadCreate && operation.type == SyncOperationType.delete) {
      for (final key in existingKeys) {
        await box.delete(key);
      }
      _changes.add(null);
      return;
    }

    for (final key in existingKeys) {
      await box.delete(key);
    }

    // create then update before remote ack → keep create with latest payload.
    final effectiveType =
        hadCreate && operation.type == SyncOperationType.update
        ? SyncOperationType.create
        : operation.type;

    final coalesced = operation.copyWith(
      type: effectiveType,
      createdAt: earliestCreatedAt,
      attemptCount: 0,
      clearLastError: true,
      clearNextRetryAt: true,
      status: SyncStatus.pending,
    );
    await box.put(coalesced.id, coalesced);
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

  /// Drop queued ops for an entity (used when remapping local UUID → remote).
  Future<void> removeForEntity({
    required String entityType,
    required String entityId,
  }) async {
    final box = await _ensureBox();
    final keys = <dynamic>[];
    for (final entry in box.toMap().entries) {
      final op = entry.value;
      if (op.entityType == entityType && op.entityId == entityId) {
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

  /// Drop pending/failed/conflict **create** ops after a remote row was applied.
  ///
  /// Dual-device system seeds enqueue creates for the same UUID; once pull
  /// materializes the server row, local creates are redundant.
  Future<void> removeCreatesForEntity({
    required String entityType,
    required String entityId,
  }) async {
    final box = await _ensureBox();
    final keys = <dynamic>[];
    for (final entry in box.toMap().entries) {
      final op = entry.value;
      if (op.entityType != entityType || op.entityId != entityId) {
        continue;
      }
      if (op.type != SyncOperationType.create) {
        continue;
      }
      if (op.status == SyncStatus.syncing) {
        continue;
      }
      keys.add(entry.key);
    }
    for (final key in keys) {
      await box.delete(key);
    }
    if (keys.isNotEmpty) {
      _changes.add(null);
    }
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

  /// Reset crash-interrupted uploads (`syncing`) back to `pending`.
  ///
  /// Call on app start and before each sync pass so peekReady can see them.
  Future<int> reclaimInFlight({DateTime? now}) async {
    final box = await _ensureBox();
    final stamp = now ?? DateTime.now().toUtc();
    var count = 0;
    for (final entry in box.toMap().entries) {
      final op = entry.value;
      if (op.status != SyncStatus.syncing) {
        continue;
      }
      await box.put(
        entry.key,
        op.copyWith(
          status: SyncStatus.pending,
          updatedAt: stamp,
          clearNextRetryAt: true,
          lastError: op.lastError ?? 'Interrupted sync recovered',
        ),
      );
      count++;
    }
    if (count > 0) {
      _changes.add(null);
    }
    return count;
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}
