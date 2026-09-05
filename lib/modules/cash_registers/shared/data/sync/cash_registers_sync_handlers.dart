import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../../data/repositories/cash_register_repository_impl.dart';

/// Cash Register adapter for the shared SyncManager (CR-08).
class CashRegisterSyncHandler implements SyncEntityHandler {
  CashRegisterSyncHandler({
    required this.repository,
    required this.remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  });

  final CashRegisterRepositoryImpl repository;
  final RemoteSyncApi Function() remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => remoteProvider();

  @override
  String get entityType => CashRegisterRepositoryImpl.entityType;

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
    await repository.applyRemotePayload(payload);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) {
    return repository.markSynced(
      uuid: entityId,
      remoteVersion: remoteVersion,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) {
    return repository.markConflict(entityId);
  }
}
