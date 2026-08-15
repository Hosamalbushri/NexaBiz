import '../errors/app_failure.dart';
import '../sync/sync_entity_handler.dart';
import '../sync/sync_operation.dart';

/// Minimal remote sync API used by feature handlers.
///
/// Use [HttpRemoteSyncApi] against the experimental FastAPI backend
/// (`SYNC_API_ENABLED=true`), or [InMemoryRemoteSyncApi] for offline tests.
/// SyncManager and queue stay unchanged.
abstract class RemoteSyncApi {
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  });

  Future<List<SyncRemoteChange>> pull({
    required String entityType,
    DateTime? since,
  });

  Future<RemoteEntityMeta?> getMeta({
    required String entityType,
    required String entityId,
  });

  /// Persist the staged pull cursor after local applies succeeded.
  void acknowledgePull(String entityType) {}

  /// Discard staged pull cursor when local applies failed.
  void abandonPull(String entityType) {}
}

class RemoteEntityMeta {
  const RemoteEntityMeta({
    required this.entityId,
    required this.version,
    required this.updatedAt,
    this.payload,
  });

  final String entityId;
  final int version;
  final DateTime updatedAt;
  final Map<String, dynamic>? payload;
}

/// Dev / test remote that stores entities in memory and detects conflicts.
class InMemoryRemoteSyncApi implements RemoteSyncApi {
  InMemoryRemoteSyncApi({this.simulateOffline = false});

  final bool simulateOffline;
  final _store = <String, Map<String, RemoteEntityMeta>>{};

  Map<String, RemoteEntityMeta> _bucket(String entityType) =>
      _store.putIfAbsent(entityType, () => <String, RemoteEntityMeta>{});

  @override
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  }) async {
    if (simulateOffline) {
      throw const NetworkFailure('Offline');
    }

    final bucket = _bucket(entityType);
    final existing = bucket[operation.entityId];
    if (existing != null && existing.version > operation.baseVersion) {
      throw SyncConflictFailure.forEntity(
        message:
            'Remote version ${existing.version} > base ${operation.baseVersion}',
        entityType: entityType,
        entityId: operation.entityId,
      );
    }

    final nextVersion = (existing?.version ?? operation.baseVersion) + 1;
    final updatedAt = DateTime.now().toUtc();
    final meta = RemoteEntityMeta(
      entityId: operation.entityId,
      version: nextVersion,
      updatedAt: updatedAt,
      payload: Map<String, dynamic>.from(operation.payload),
    );
    if (operation.type == SyncOperationType.delete) {
      bucket[operation.entityId] = RemoteEntityMeta(
        entityId: operation.entityId,
        version: nextVersion,
        updatedAt: updatedAt,
        payload: {'deleted': true, ...operation.payload},
      );
    } else {
      bucket[operation.entityId] = meta;
    }

    return SyncUploadAck(
      entityId: operation.entityId,
      remoteVersion: nextVersion,
      remoteUpdatedAt: updatedAt,
      serverPayload: bucket[operation.entityId]?.payload,
    );
  }

  @override
  Future<List<SyncRemoteChange>> pull({
    required String entityType,
    DateTime? since,
  }) async {
    if (simulateOffline) {
      throw const NetworkFailure('Offline');
    }
    final bucket = _bucket(entityType);
    final changes = <SyncRemoteChange>[];
    for (final meta in bucket.values) {
      if (since != null && !meta.updatedAt.isAfter(since)) {
        continue;
      }
      final deleted = meta.payload?['deleted'] == true;
      changes.add(
        SyncRemoteChange(
          entityId: meta.entityId,
          version: meta.version,
          updatedAt: meta.updatedAt,
          payload: Map<String, dynamic>.from(meta.payload ?? const {}),
          deleted: deleted,
        ),
      );
    }
    return changes;
  }

  @override
  Future<RemoteEntityMeta?> getMeta({
    required String entityType,
    required String entityId,
  }) async {
    if (simulateOffline) {
      throw const NetworkFailure('Offline');
    }
    return _bucket(entityType)[entityId];
  }

  /// Seed remote state for tests.
  void seed(String entityType, RemoteEntityMeta meta) {
    _bucket(entityType)[meta.entityId] = meta;
  }

  @override
  void acknowledgePull(String entityType) {}

  @override
  void abandonPull(String entityType) {}
}
