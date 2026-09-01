import '../../domain/entities/sync_operation.dart';
import '../../domain/entities/sync_overview.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/services/sync_manager.dart';
import '../../domain/services/sync_queue.dart';

class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl({
    required SyncManager syncManager,
    required SyncQueue syncQueue,
  })  : _syncManager = syncManager,
        _syncQueue = syncQueue;

  final SyncManager _syncManager;
  final SyncQueue _syncQueue;

  @override
  Future<SyncOverview> getSyncOverview() async => _syncManager.overview;

  @override
  Stream<SyncStatus> watchSyncStatus() async* {
    yield (_syncManager.engineState == EngineSyncState.uploading ||
            _syncManager.engineState == EngineSyncState.downloading)
        ? SyncStatus.syncing
        : SyncStatus.pending;
  }

  @override
  Future<void> triggerSync() async {
    await _syncManager.syncNow();
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() => _syncQueue.peekAll();

  @override
  Future<void> clearQueue() => _syncQueue.clearSynced();
}
