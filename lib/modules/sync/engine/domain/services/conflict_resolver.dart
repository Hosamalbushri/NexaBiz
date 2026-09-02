import 'conflict_strategy.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';
import 'three_way_merger.dart';

/// Outcome of conflict evaluation for a single sync operation.
enum ConflictDecision {
  /// Safe to apply local change to the remote.
  uploadLocal,

  /// Apply remote snapshot to local storage.
  applyRemote,

  /// Apply merged snapshot resulting from deterministic 3-way merge.
  applyMerged,

  /// Leave both sides; mark conflict for user / domain resolution.
  markConflict,
}

/// Result of detailed conflict evaluation.
class ConflictEvaluationResult {
  const ConflictEvaluationResult({
    required this.decision,
    this.mergedPayload,
    this.conflictingFields = const [],
    this.message,
  });

  final ConflictDecision decision;
  final Map<String, dynamic>? mergedPayload;
  final List<String> conflictingFields;
  final String? message;
}

/// Deterministic conflict policy shared across features.
class ConflictResolver {
  const ConflictResolver({
    this._merger = const ThreeWayMerger(),
  });

  final ThreeWayMerger _merger;

  ConflictDecision resolve({
    required SyncOperation localOperation,
    required int remoteVersion,
    required DateTime? remoteUpdatedAt,
    required bool preferServerWhenLocalSynced,
    Map<String, dynamic>? remotePayload,
    Map<String, dynamic>? basePayload,
  }) {
    return evaluate(
      localOperation: localOperation,
      remoteVersion: remoteVersion,
      remoteUpdatedAt: remoteUpdatedAt,
      preferServerWhenLocalSynced: preferServerWhenLocalSynced,
      remotePayload: remotePayload,
      basePayload: basePayload,
    ).decision;
  }

  ConflictEvaluationResult evaluate({
    required SyncOperation localOperation,
    required int remoteVersion,
    required DateTime? remoteUpdatedAt,
    required bool preferServerWhenLocalSynced,
    Map<String, dynamic>? remotePayload,
    Map<String, dynamic>? basePayload,
  }) {
    // Create is ensure-exists: never markConflict against an existing UUID.
    if (localOperation.type == SyncOperationType.create) {
      return const ConflictEvaluationResult(decision: ConflictDecision.uploadLocal);
    }

    final policy = EntityConflictPolicy.getForEntity(localOperation.entityType);

    // Immutable entries reject updates/deletes immediately
    if (policy.strategy == ConflictStrategy.immutableReject) {
      return const ConflictEvaluationResult(
        decision: ConflictDecision.markConflict,
        message: 'Immutable entity cannot be updated or deleted',
      );
    }

    // Append-only events (e.g. inventory movements) always upload
    if (policy.strategy == ConflictStrategy.appendOnly) {
      return const ConflictEvaluationResult(decision: ConflictDecision.uploadLocal);
    }

    final localVersion = localOperation.baseVersion;
    if (remoteVersion <= localVersion) {
      return const ConflictEvaluationResult(decision: ConflictDecision.uploadLocal);
    }

    // Remote advanced past local version
    if (preferServerWhenLocalSynced &&
        localOperation.status == SyncStatus.synced) {
      return const ConflictEvaluationResult(decision: ConflictDecision.applyRemote);
    }

    // Evaluate 3-way merge if remotePayload and basePayload are available
    if (remotePayload != null) {
      final base = basePayload ?? {};
      final mergeResult = _merger.merge(
        basePayload: base,
        localPayload: localOperation.payload,
        remotePayload: remotePayload,
        policy: policy,
      );

      if (mergeResult.isSuccess && mergeResult.mergedPayload != null) {
        return ConflictEvaluationResult(
          decision: ConflictDecision.applyMerged,
          mergedPayload: mergeResult.mergedPayload,
          message: mergeResult.message,
        );
      }

      return ConflictEvaluationResult(
        decision: ConflictDecision.markConflict,
        conflictingFields: mergeResult.conflictingFields,
        message: mergeResult.message ?? 'Conflict detected during evaluation',
      );
    }

    if (remoteUpdatedAt != null &&
        remoteUpdatedAt.isAfter(localOperation.updatedAt)) {
      return const ConflictEvaluationResult(decision: ConflictDecision.markConflict);
    }

    return const ConflictEvaluationResult(decision: ConflictDecision.markConflict);
  }
}
