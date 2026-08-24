import '../errors/app_failure.dart';
import '../sync/sync_entity_handler.dart';
import '../sync/sync_operation.dart';

/// Per-operation outcome from [RemoteSyncApi.pushBatch].
class SyncBatchPushItemResult {
  const SyncBatchPushItemResult({
    required this.operationId,
    required this.status,
    this.ack,
    this.failure,
  });

  final String operationId;

  /// `success` | `conflict` | `error`
  final String status;
  final SyncUploadAck? ack;
  final AppFailure? failure;

  bool get isSuccess => status == 'success' && ack != null;
  bool get isConflict => status == 'conflict';
}

/// Minimal remote sync API used by feature handlers.
///
/// Use [HttpRemoteSyncApi] against the experimental FastAPI backend
/// (`SYNC_API_ENABLED=true` with a usable HTTPS endpoint, or HTTP when
/// `SYNC_API_ALLOW_INSECURE_HTTP=true`), or [InMemoryRemoteSyncApi] otherwise.
abstract class RemoteSyncApi {
  Future<SyncUploadAck> push({
    required String entityType,
    required SyncOperation operation,
  });

  /// Push many operations in one round-trip when the backend supports it.
  ///
  /// Default falls back to sequential [push] (tests / in-memory).
  Future<List<SyncBatchPushItemResult>> pushBatch(
    List<SyncOperation> operations,
  ) async {
    final results = <SyncBatchPushItemResult>[];
    for (final op in operations) {
      try {
        final ack = await push(entityType: op.entityType, operation: op);
        results.add(
          SyncBatchPushItemResult(
            operationId: op.id,
            status: 'success',
            ack: ack,
          ),
        );
      } on AppFailure catch (e) {
        results.add(
          SyncBatchPushItemResult(
            operationId: op.id,
            status: e is SyncConflictFailure ? 'conflict' : 'error',
            failure: e,
          ),
        );
      }
    }
    return results;
  }

  Future<List<SyncRemoteChange>> pull({
    String? entityType,
    DateTime? since,
  });

  Future<RemoteEntityMeta?> getMeta({
    required String entityType,
    required String entityId,
  });

  /// Persist the staged pull cursor after local applies succeeded.
  Future<void> acknowledgePull(String entityType) async {}

  /// Discard staged pull cursor when local applies failed.
  Future<void> abandonPull(String entityType) async {}
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

    // Create = ensure UUID exists (idempotent). Never version-conflict creates;
    // dual-device CoA/system seeds share deterministic ids.
    if (operation.type == SyncOperationType.create) {
      if (existing != null) {
        return SyncUploadAck(
          entityId: operation.entityId,
          remoteVersion: existing.version,
          remoteUpdatedAt: existing.updatedAt,
          serverPayload: existing.payload,
        );
      }
      final updatedAt = DateTime.now().toUtc();
      final meta = RemoteEntityMeta(
        entityId: operation.entityId,
        version: 1,
        updatedAt: updatedAt,
        payload: Map<String, dynamic>.from(operation.payload),
      );
      bucket[operation.entityId] = meta;
      return SyncUploadAck(
        entityId: operation.entityId,
        remoteVersion: meta.version,
        remoteUpdatedAt: updatedAt,
        serverPayload: meta.payload,
      );
    }

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
  Future<List<SyncBatchPushItemResult>> pushBatch(
    List<SyncOperation> operations,
  ) async {
    final results = <SyncBatchPushItemResult>[];
    for (final op in operations) {
      try {
        final ack = await push(entityType: op.entityType, operation: op);
        results.add(
          SyncBatchPushItemResult(
            operationId: op.id,
            status: 'success',
            ack: ack,
          ),
        );
      } on AppFailure catch (e) {
        results.add(
          SyncBatchPushItemResult(
            operationId: op.id,
            status: e is SyncConflictFailure ? 'conflict' : 'error',
            failure: e,
          ),
        );
      }
    }
    return results;
  }

  @override
  Future<List<SyncRemoteChange>> pull({
    String? entityType,
    DateTime? since,
  }) async {
    if (simulateOffline) {
      throw const NetworkFailure('Offline');
    }
    final changes = <SyncRemoteChange>[];
    final targetEntries = entityType != null && entityType.isNotEmpty
        ? [
            MapEntry(
              entityType,
              _store[entityType] ?? <String, RemoteEntityMeta>{},
            ),
          ]
        : _store.entries.toList();

    for (final entry in targetEntries) {
      final typeName = entry.key;
      for (final meta in entry.value.values) {
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
            entityType: typeName,
          ),
        );
      }
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
  Future<void> acknowledgePull(String entityType) async {}

  @override
  Future<void> abandonPull(String entityType) async {}
}
