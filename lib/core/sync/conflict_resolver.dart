import 'sync_operation.dart';
import 'sync_status.dart';

/// Outcome of conflict evaluation for a single sync operation.
enum ConflictDecision {
  /// Safe to apply local change to the remote.
  uploadLocal,

  /// Apply remote snapshot to local storage.
  applyRemote,

  /// Leave both sides; mark conflict for user / domain resolution.
  markConflict,
}

/// Deterministic conflict policy shared across features.
///
/// Inventory count lines prefer [ConflictDecision.markConflict] when both
/// sides changed the same entity (count events must not silently overwrite).
/// Product master data may pass [preferServerWhenLocalSynced] = true so a
/// clean local row accepts a newer server revision.
class ConflictResolver {
  const ConflictResolver();

  ConflictDecision resolve({
    required SyncOperation localOperation,
    required int remoteVersion,
    required DateTime? remoteUpdatedAt,
    required bool preferServerWhenLocalSynced,
    Map<String, dynamic>? remotePayload,
  }) {
    final localVersion = localOperation.baseVersion;
    if (remoteVersion <= localVersion) {
      return ConflictDecision.uploadLocal;
    }

    // Remote advanced past the version this mutation was based on.
    if (preferServerWhenLocalSynced &&
        localOperation.status == SyncStatus.synced) {
      return ConflictDecision.applyRemote;
    }

    if (remotePayload != null &&
        !_payloadEquals(localOperation.payload, remotePayload)) {
      return ConflictDecision.markConflict;
    }

    if (remoteUpdatedAt != null &&
        remoteUpdatedAt.isAfter(localOperation.updatedAt)) {
      return ConflictDecision.markConflict;
    }

    return ConflictDecision.markConflict;
  }

  bool _payloadEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key]?.toString() != entry.value?.toString()) {
        return false;
      }
    }
    return true;
  }
}
