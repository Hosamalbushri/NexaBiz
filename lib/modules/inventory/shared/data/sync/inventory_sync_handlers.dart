import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/inventory/stock_count/data/repositories/inventory_movement_ledger.dart';
import 'package:stock_count/modules/inventory/stock_count/data/repositories/inventory_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';

/// Inventory products adapter for the shared SyncManager.
class ProductSyncHandler implements SyncEntityHandler {
  ProductSyncHandler({
    required ProductRepositoryImpl repository,
    required RemoteSyncApi Function() remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  }) : _repository = repository,
       _remoteProvider = remoteProvider;

  final ProductRepositoryImpl _repository;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => ProductRepositoryImpl.entityType;

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

/// Stock-count lines — divergent quantities are never auto-overwritten.
class InventoryItemSyncHandler implements SyncEntityHandler {
  InventoryItemSyncHandler({
    required InventoryRepositoryImpl repository,
    required RemoteSyncApi Function() remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  }) : _repository = repository,
       _remoteProvider = remoteProvider;

  final InventoryRepositoryImpl _repository;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => InventoryRepositoryImpl.entityType;

  @override
  bool get preferServerWhenLocalSynced => false;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    if (meta.version > operation.baseVersion) {
      final remoteQty = meta.payload?['actualQuantity']?.toString();
      final localQty = operation.payload['actualQuantity']?.toString();
      if (remoteQty != localQty) {
        return ConflictDecision.markConflict;
      }
    }
    return conflictResolver.resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: false,
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
    payload['id'] = change.entityId;
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
      id: entityId,
      remoteVersion: remoteVersion,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) {
    return _repository.markConflict(entityId);
  }
}

/// Append-only movement events adapter for the shared SyncManager.
class InventoryMovementSyncHandler implements SyncEntityHandler {
  InventoryMovementSyncHandler({
    required InventoryMovementLedger ledger,
    required RemoteSyncApi Function() remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  }) : _ledger = ledger,
       _remoteProvider = remoteProvider;

  final InventoryMovementLedger _ledger;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => InventoryMovementLedger.entityType;

  @override
  bool get preferServerWhenLocalSynced => true;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    // Append-only events never conflict on create
    return ConflictDecision.uploadLocal;
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
    await _ledger.applyRemoteMovement(payload);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {}

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {}
}

