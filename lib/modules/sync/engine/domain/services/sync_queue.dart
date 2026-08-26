import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/auth/domain/services/local_access_policy.dart';
import 'package:stock_count/core/database/encrypted_hive_box.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/data/stores/sync_operation_adapter.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';

/// Persistent synchronization queue (survives process restarts).
class SyncQueue {
  SyncQueue({
    Box<SyncOperation>? box,
    this.companyId,
    this.deviceId,
    String? encryptedBoxName,
    String? legacyPlainBoxName,
  }) : _boxOverride = box,
       _encryptedBoxName = encryptedBoxName ?? HiveBoxes.syncQueueEncrypted,
       _legacyPlainBoxName = legacyPlainBoxName ?? HiveBoxes.syncQueue;

  final Box<SyncOperation>? _boxOverride;
  final String? companyId;
  final String? deviceId;
  final String _encryptedBoxName;
  final String _legacyPlainBoxName;
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
    if (Hive.isBoxOpen(_encryptedBoxName)) {
      _box = Hive.box<SyncOperation>(_encryptedBoxName);
    } else {
      _box = await EncryptedHive.openMigrated<SyncOperation>(
        encryptedBoxName: _encryptedBoxName,
        legacyPlainBoxName: _legacyPlainBoxName,
      );
    }
    return _box!;
  }

  Future<void> enqueue(SyncOperation operation) async {
    final box = await _ensureBox();

    // Verify tenant boundary
    if (companyId != null && operation.companyId != null && operation.companyId != companyId) {
      throw SecurityException(
        'Cross-tenant enqueue blocked: Operation belongs to company "${operation.companyId}" '
        'but the active queue is scoped to company "$companyId".'
      );
    }

    final enriched = operation.copyWith(
      companyId: operation.companyId ?? companyId,
      deviceId: operation.deviceId ?? deviceId,
    );

    // Coalesce: replace older pending/failed/conflict ops for the same entity.
    final existingKeys = <dynamic>[];
    var hadCreate = false;
    var earliestCreatedAt = enriched.createdAt;
    for (final entry in box.toMap().entries) {
      final op = entry.value;
      if (op.entityType == enriched.entityType &&
          op.entityId == enriched.entityId &&
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
    if (hadCreate && enriched.type == SyncOperationType.delete) {
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
        hadCreate && enriched.type == SyncOperationType.update
        ? SyncOperationType.create
        : enriched.type;

    final coalesced = enriched.copyWith(
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

  static int _entityTypePriority(String entityType) {
    return switch (entityType) {
      'company_profile' || 'fiscal_year' || 'currency_rate' => 1,
      'account' || 'customer' || 'product' => 2,
      'inventory_item' || 'sale' || 'receipt_payment' => 3,
      'journal_entry' => 4,
      _ => 5,
    };
  }

  Future<List<SyncOperation>> peekReady({DateTime? now}) async {
    final box = await _ensureBox();
    final stamp = (now ?? DateTime.now().toUtc());
    final ready = box.values
        .where((op) {
          // Reject operations belonging to a different tenant (defense-in-depth)
          if (companyId != null && op.companyId != companyId) {
            return false;
          }
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
        .toList(growable: true);
    ready.sort((a, b) {
      final prioA = _entityTypePriority(a.entityType);
      final prioB = _entityTypePriority(b.entityType);
      if (prioA != prioB) {
        return prioA.compareTo(prioB);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
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
  Future<int> reclaimInFlight({DateTime? now, Duration lease = const Duration(minutes: 5)}) async {
    final box = await _ensureBox();
    final stamp = now ?? DateTime.now().toUtc();
    var count = 0;
    for (final entry in box.toMap().entries) {
      final op = entry.value;
      if (op.status != SyncStatus.syncing) {
        continue;
      }
      final age = stamp.difference(op.updatedAt);
      if (age >= lease) {
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
    }
    if (count > 0) {
      _changes.add(null);
    }
    return count;
  }

  Future<void> resetQuarantine(String id) async {
    final box = await _ensureBox();
    final ops = box.values.where((op) => op.id == id);
    if (ops.isNotEmpty) {
      final op = ops.first;
      if (op.status == SyncStatus.quarantined) {
        await box.put(
          id,
          op.copyWith(
            status: SyncStatus.pending,
            attemptCount: 0,
            clearLastError: true,
            clearNextRetryAt: true,
            clearQuarantine: true,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        _changes.add(null);
      }
    }
  }

  Future<void> quarantine(String id, {required String error}) async {
    final box = await _ensureBox();
    final ops = box.values.where((op) => op.id == id);
    if (ops.isNotEmpty) {
      final op = ops.first;
      final now = DateTime.now().toUtc();
      await box.put(
        id,
        op.copyWith(
          status: SyncStatus.quarantined,
          lastError: error,
          quarantinedAt: now,
          firstFailureAt: op.firstFailureAt ?? now,
          lastFailureAt: now,
          clearNextRetryAt: true,
          updatedAt: now,
        ),
      );
      _changes.add(null);
    }
  }

  /// Returns all operations currently stored in outbox for inspection.
  Future<List<SyncOperation>> peekAll() async {
    final box = await _ensureBox();
    final list = box.values.toList(growable: true);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void dispose() {
    _changes.close();
  }
}
