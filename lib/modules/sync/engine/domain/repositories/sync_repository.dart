import '../entities/sync_operation.dart';
import '../entities/sync_overview.dart';
import '../entities/sync_status.dart';

/// Abstract domain contract for synchronization engine.
abstract class SyncRepository {
  Future<SyncOverview> getSyncOverview();
  Stream<SyncStatus> watchSyncStatus();
  Future<void> triggerSync();
  Future<List<SyncOperation>> getPendingOperations();
  Future<void> clearQueue();
}
