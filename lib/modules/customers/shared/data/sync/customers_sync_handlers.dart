import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';

/// Customers adapter for the shared SyncManager.
class CustomerSyncHandler implements SyncEntityHandler {
  CustomerSyncHandler({
    required CustomerRepositoryImpl repository,
    required RemoteSyncApi Function() remoteProvider,
    this.conflictResolver = const ConflictResolver(),
    Future<void> Function(Map<String, dynamic> payload)? ensureLinkedAccount,
  }) : _repository = repository,
       _remoteProvider = remoteProvider,
       _ensureLinkedAccount = ensureLinkedAccount;

  final CustomerRepositoryImpl _repository;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;
  final Future<void> Function(Map<String, dynamic> payload)?
  _ensureLinkedAccount;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => CustomerRepositoryImpl.entityType;

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
    final ensure = _ensureLinkedAccount;
    if (ensure != null) {
      await ensure(payload);
    }
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
