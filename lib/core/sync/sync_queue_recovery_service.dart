import 'dart:async';
import 'package:flutter/foundation.dart';

import 'sync_entity_handler.dart';
import 'sync_operation.dart';
import 'sync_queue.dart';

/// Optional contract implemented by handlers capable of scanning local storage
/// for pending entities that lack a corresponding queue entry.
abstract class SyncRecoverableEntityHandler implements SyncEntityHandler {
  /// Returns reconstructed outbound operations for local pending records
  /// whose entity ID is not in [queuedEntityIds].
  Future<List<SyncOperation>> findOrphanedPendingOperations(
    Set<String> queuedEntityIds,
  );
}

/// Startup service that audits domain persistence against Hive [SyncQueue]
/// and deterministically reconstructs missing queue entries for orphaned pending records.
class SyncQueueRecoveryService {
  SyncQueueRecoveryService({required SyncQueue queue}) : _queue = queue;

  final SyncQueue _queue;

  /// Scans [handlers] for orphaned pending records and enqueues missing operations.
  Future<int> recoverOrphanedOperations(
    Iterable<SyncEntityHandler> handlers,
  ) async {
    final existingOps = await _queue.all();
    final queuedKeys = <String>{
      for (final op in existingOps) '${op.entityType}:${op.entityId}',
    };

    var recoveredCount = 0;

    for (final handler in handlers) {
      if (handler is! SyncRecoverableEntityHandler) {
        continue;
      }
      try {
        final missingOps = await handler.findOrphanedPendingOperations(queuedKeys);
        for (final op in missingOps) {
          await _queue.enqueue(op);
          recoveredCount++;
          if (kDebugMode) {
            debugPrint(
              'SYNC_RECOVERY_RECONSTRUCTED operation_id=${op.id} '
              'entity=${op.entityType} entity_id=${op.entityId}',
            );
          }
        }
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint(
            'SYNC_RECOVERY_ERROR entity=${handler.entityType} error=$e\n$stack',
          );
        }
      }
    }

    return recoveredCount;
  }
}
