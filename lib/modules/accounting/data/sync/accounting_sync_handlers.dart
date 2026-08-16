import '../../../../core/network/remote_sync_api.dart';
import '../../../../core/sync/conflict_resolver.dart';
import '../../../../core/sync/sync_entity_handler.dart';
import '../../../../core/sync/sync_operation.dart';
import '../repositories/account_repository_impl.dart';
import '../repositories/journal_repository_impl.dart';

/// Chart of Accounts adapter for the shared SyncManager.
class AccountSyncHandler implements SyncEntityHandler {
  AccountSyncHandler({
    required AccountRepositoryImpl repository,
    required RemoteSyncApi remote,
    this.conflictResolver = const ConflictResolver(),
  }) : _repository = repository,
       _remote = remote;

  final AccountRepositoryImpl _repository;
  final RemoteSyncApi _remote;
  final ConflictResolver conflictResolver;

  @override
  String get entityType => AccountRepositoryImpl.entityType;

  @override
  bool get preferServerWhenLocalSynced => true;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    return conflictResolver.resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: preferServerWhenLocalSynced,
      remotePayload: meta.payload,
    );
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) {
    return _remote.pull(entityType: entityType, since: since);
  }

  @override
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    final payload = Map<String, dynamic>.from(change.payload);
    payload['uuid'] = change.entityId;
    payload['version'] = change.version;
    payload['updatedAt'] = change.updatedAt.millisecondsSinceEpoch;
    if (change.deleted) {
      payload['deletedAt'] =
          payload['deletedAt'] ?? change.updatedAt.millisecondsSinceEpoch;
    }
    await _repository.applyRemotePayload(payload);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) {
    return _repository.markSynced(
      uuid: entityId,
      remoteVersion: remoteVersion,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) {
    return _repository.markConflict(entityId);
  }
}

/// Journal entry adapter — offline-first events (ADR-006 / Phase 5).
class JournalSyncHandler implements SyncEntityHandler {
  JournalSyncHandler({
    required JournalRepositoryImpl repository,
    required RemoteSyncApi remote,
    this.conflictResolver = const ConflictResolver(),
  }) : _repository = repository,
       _remote = remote;

  final JournalRepositoryImpl _repository;
  final RemoteSyncApi _remote;
  final ConflictResolver conflictResolver;

  @override
  String get entityType => JournalRepositoryImpl.entityType;

  @override
  bool get preferServerWhenLocalSynced => true;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    return conflictResolver.resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: preferServerWhenLocalSynced,
      remotePayload: meta.payload,
    );
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) {
    return _remote.pull(entityType: entityType, since: since);
  }

  @override
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    final payload = Map<String, dynamic>.from(change.payload);
    payload['uuid'] = change.entityId;
    payload['version'] = change.version;
    payload['updatedAt'] = change.updatedAt.millisecondsSinceEpoch;
    if (change.deleted) {
      payload['deletedAt'] =
          payload['deletedAt'] ?? change.updatedAt.millisecondsSinceEpoch;
    }
    await _repository.applyRemotePayload(payload);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) {
    return _repository.markSynced(
      uuid: entityId,
      remoteVersion: remoteVersion,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) {
    return _repository.markConflict(entityId);
  }
}
