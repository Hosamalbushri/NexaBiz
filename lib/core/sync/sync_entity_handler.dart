import '../errors/app_failure.dart';
import 'conflict_resolver.dart';
import 'sync_operation.dart';

/// Result of a successful upload acknowledged by the remote.
class SyncUploadAck {
  const SyncUploadAck({
    required this.entityId,
    required this.remoteVersion,
    this.remoteUpdatedAt,
    this.serverPayload,
  });

  final String entityId;
  final int remoteVersion;
  final DateTime? remoteUpdatedAt;
  final Map<String, dynamic>? serverPayload;
}

/// A remote change to merge into local storage.
class SyncRemoteChange {
  const SyncRemoteChange({
    required this.entityId,
    required this.version,
    required this.updatedAt,
    required this.payload,
    this.deleted = false,
    this.entityType = '',
  });

  final String entityId;
  final int version;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;
  final bool deleted;
  final String entityType;
}

/// Feature-specific adapter used by [SyncManager].
///
/// Handlers live in modules; Core only depends on this contract.
abstract class SyncEntityHandler {
  /// Stable type key, e.g. `product`, `inventory_item`.
  String get entityType;

  /// When true, clean local rows may accept newer server data automatically.
  bool get preferServerWhenLocalSynced => false;

  /// Upload one queue operation. Must throw [AppFailure] on failure.
  ///
  /// Only call local `markSynced` after this returns successfully.
  Future<SyncUploadAck> upload(SyncOperation operation);

  /// Pull remote changes for this entity type since [since] (UTC).
  Future<List<SyncRemoteChange>> pull({DateTime? since});

  /// Apply a remote snapshot / deletion to local storage.
  Future<void> applyRemoteChange(SyncRemoteChange change);

  /// Mark the local entity as synced after server confirmation.
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  });

  /// Mark the local entity as conflicted.
  Future<void> markLocalConflict({required String entityId, String? message});

  /// Commit pull cursor after all remote changes for this type applied OK.
  Future<void> confirmPull() async {}

  /// Drop staged pull cursor when one or more applies failed.
  Future<void> abandonPull() async {}

  /// Optional pre-upload conflict probe against remote metadata.
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    return null;
  }
}
