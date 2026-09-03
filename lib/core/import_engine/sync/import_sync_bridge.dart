import 'package:stock_count/modules/sync/sync.dart';
import '../domain/entities/import_sync_mode.dart';
import '../domain/exceptions/tenant_isolation_exception.dart';

/// Resolved metadata for an entity ready to be persisted by an import executor.
class ImportSyncEntityMetadata {
  const ImportSyncEntityMetadata({
    required this.uuid,
    required this.companyId,
    required this.syncStatus,
    required this.version,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uuid;
  final String companyId;
  final SyncStatus syncStatus;
  final int version;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Bridge orchestrating synchronization metadata preservation and selective outbox enqueueing.
class ImportSyncBridge {
  const ImportSyncBridge({
    this.syncQueue,
  });

  final SyncQueue? syncQueue;

  /// Resolves standard synchronization metadata based on [syncMode].
  ImportSyncEntityMetadata resolveMetadata({
    required String uuid,
    required String companyId,
    required ImportSyncMode syncMode,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    final now = DateTime.now().toUtc();
    final resolvedSyncStatus = syncMode == ImportSyncMode.local
        ? SyncStatus.pending
        : SyncStatus.synced;

    return ImportSyncEntityMetadata(
      uuid: uuid,
      companyId: companyId,
      syncStatus: resolvedSyncStatus,
      version: version ?? (syncMode == ImportSyncMode.remote ? 1 : 1),
      deletedAt: deletedAt,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Evaluates whether an imported record should be enqueued into [SyncQueue].
  ///
  /// - `ImportSyncMode.local`: Enqueues `SyncOperation` as `pending`.
  /// - `ImportSyncMode.synced` & `ImportSyncMode.remote`: Bypasses outbox to prevent duplicate uploads.
  Future<void> processSyncQueue({
    required String entityType,
    required String entityId,
    required String companyId,
    required ImportSyncMode syncMode,
    required SyncOperationType operationType,
    required Map<String, dynamic> payload,
    int baseVersion = 0,
  }) async {
    // Only LOCAL imports populate the outbox (SyncQueue)
    if (!syncMode.shouldEnqueueSync) {
      return;
    }

    final queue = syncQueue;
    if (queue == null) {
      return;
    }

    // Verify company isolation before enqueueing
    if (queue.companyId != null && queue.companyId != companyId) {
      throw TenantIsolationException(
        'Cross-tenant outbox enqueue blocked: SyncQueue is scoped to "${queue.companyId}" but record belongs to "$companyId".',
        expectedCompanyId: queue.companyId,
        attemptedCompanyId: companyId,
      );
    }

    final op = SyncOperation.create(
      entityType: entityType,
      entityId: entityId,
      type: operationType,
      baseVersion: baseVersion,
      companyId: companyId,
      payload: payload,
    );

    await queue.enqueue(op);
  }
}
