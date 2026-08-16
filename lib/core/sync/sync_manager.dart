import 'dart:async';

import '../connectivity/connectivity_service.dart';
import '../errors/app_failure.dart';
import '../network/remote_sync_api.dart';
import '../utils/id_generator.dart';
import 'conflict_resolver.dart';
import 'sync_entity_handler.dart';
import 'sync_metrics_store.dart';
import 'sync_operation.dart';
import 'sync_overview.dart';
import 'sync_queue.dart';
import 'sync_request_context.dart';
import 'sync_status.dart';

/// Coordinates upload / download across registered [SyncEntityHandler]s.
///
/// Contains no feature UI logic. Safe to drive from foreground now and from
/// an OS background wake that drains into [syncNow] (Phase 6).
class SyncManager {
  SyncManager({
    required SyncQueue queue,
    required ConnectivityService connectivity,
    ConflictResolver conflictResolver = const ConflictResolver(),
    RemoteSyncApi? remote,
    SyncMetricsStore? metricsStore,
    void Function(SyncPassResult result)? onMeaningfulPass,
    DateTime Function()? clock,
    this.batchChunkSize = 50,
  }) : _queue = queue,
       _connectivity = connectivity,
       _conflictResolver = conflictResolver,
       _remote = remote,
       _metricsStore = metricsStore,
       _onMeaningfulPass = onMeaningfulPass,
       _clock = clock ?? _defaultClock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  final SyncQueue _queue;
  final ConnectivityService _connectivity;
  final ConflictResolver _conflictResolver;
  final RemoteSyncApi? _remote;
  final SyncMetricsStore? _metricsStore;
  final void Function(SyncPassResult result)? _onMeaningfulPass;
  final DateTime Function() _clock;

  /// Max operations per `/sync/push/batch` request.
  final int batchChunkSize;

  final _handlers = <String, SyncEntityHandler>{};
  final _overviewController = StreamController<SyncOverview>.broadcast();
  final _passController = StreamController<SyncPassResult>.broadcast();

  StreamSubscription<ConnectivityStatus>? _connectivitySub;
  StreamSubscription<void>? _queueSub;
  var _started = false;
  var _enabled = false;
  var _syncing = false;
  DateTime? _lastSyncedAt;
  SyncOverview _overview = SyncOverview.initial();

  Stream<SyncOverview> get overviewStream async* {
    yield _overview;
    yield* _overviewController.stream;
  }

  /// Meaningful sync outcomes for optional UI notifications.
  ///
  /// Also emits every annotated pass (including idle) so metrics UIs can refresh.
  Stream<SyncPassResult> get meaningfulPasses => _passController.stream;

  SyncOverview get overview => _overview;

  /// Whether the user opted into multi-device synchronization.
  bool get isEnabled => _enabled;

  void registerHandler(SyncEntityHandler handler) {
    _handlers[handler.entityType] = handler;
  }

  /// Enables or disables sync without restarting connectivity listeners.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _refreshOverview();
  }

  Future<void> start({bool enabled = false}) async {
    if (_started) {
      _enabled = enabled;
      await _queue.reclaimInFlight(now: _clock());
      await _refreshOverview();
      return;
    }
    _started = true;
    _enabled = enabled;
    await _queue.reclaimInFlight(now: _clock());
    await _connectivity.start();
    await _refreshOverview();

    _connectivitySub = _connectivity.onStatusChanged.listen((status) {
      unawaited(_onConnectivity(status));
    });
    _queueSub = _queue.changes.listen((_) {
      unawaited(_refreshOverview());
    });
  }

  Future<void> _onConnectivity(ConnectivityStatus status) async {
    await _refreshOverview();
  }

  /// Manual or automatic synchronization pass.
  ///
  /// Set [upload] / [download] to run only one direction. The sync page uses
  /// download-only to fetch server changes without pushing local pending work.
  Future<SyncPassResult> syncNow({
    bool notify = true,
    SyncPassTrigger trigger = SyncPassTrigger.manual,
    bool upload = true,
    bool download = true,
  }) async {
    final correlationId = generateUuidV4();
    final started = _clock();

    Future<SyncPassResult> annotate(SyncPassResult result) async {
      final finished = _clock();
      final enriched = SyncPassResult(
        outcome: result.outcome,
        uploaded: result.uploaded,
        downloaded: result.downloaded,
        failed: result.failed,
        conflicts: result.conflicts,
        downloadedByEntity: result.downloadedByEntity,
        correlationId: correlationId,
        durationMs: finished.difference(started).inMilliseconds,
        trigger: trigger,
        shouldNotify: notify && result.isMeaningful,
      );
      await _metricsStore?.record(
        SyncPassMetrics.fromResult(enriched, finishedAt: finished),
      );
      if (!_passController.isClosed) {
        _passController.add(enriched);
      }
      if (enriched.shouldNotify) {
        _onMeaningfulPass?.call(enriched);
      }
      return enriched;
    }

    return SyncRequestContext.run(
      correlationId: correlationId,
      trigger: trigger,
      body: () async {
        if (!_enabled) {
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.skippedDisabled),
          );
        }
        if (!_connectivity.isOnline) {
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.skippedOffline),
          );
        }
        if (_syncing) {
          return annotate(const SyncPassResult(outcome: SyncPassOutcome.idle));
        }
        if (!upload && !download) {
          return annotate(const SyncPassResult(outcome: SyncPassOutcome.idle));
        }

        _syncing = true;
        await _queue.reclaimInFlight(now: _clock());
        await _refreshOverview();

        var uploaded = 0;
        var downloaded = 0;
        var failed = 0;
        var conflicts = 0;
        var downloadedByEntity = const <String, int>{};

        try {
          if (download) {
            try {
              final pull = await _pullAllHandlers();
              downloaded = pull.downloaded;
              failed = pull.failed;
              downloadedByEntity = pull.downloadedByEntity;
            } on AuthenticationFailure {
              return annotate(
                SyncPassResult(
                  outcome: SyncPassOutcome.authRequired,
                  downloaded: downloaded,
                  failed: failed + 1,
                  downloadedByEntity: downloadedByEntity,
                ),
              );
            }
          }

          if (upload) {
            final uploadResult = await _uploadReady();
            uploaded = uploadResult.uploaded;
            failed += uploadResult.failed;
            conflicts += uploadResult.conflicts;
            if (uploadResult.authRequired) {
              return annotate(
                SyncPassResult(
                  outcome: SyncPassOutcome.authRequired,
                  uploaded: uploaded,
                  downloaded: downloaded,
                  failed: failed,
                  conflicts: conflicts,
                  downloadedByEntity: downloadedByEntity,
                ),
              );
            }
          }

          if (uploaded > 0 || downloaded > 0) {
            _lastSyncedAt = _clock();
          }

          final outcome = _outcome(
            uploaded: uploaded,
            downloaded: downloaded,
            failed: failed,
            conflicts: conflicts,
          );
          return annotate(
            SyncPassResult(
              outcome: outcome,
              uploaded: uploaded,
              downloaded: downloaded,
              failed: failed,
              conflicts: conflicts,
              downloadedByEntity: downloadedByEntity,
            ),
          );
        } finally {
          _syncing = false;
          await _refreshOverview();
        }
      },
    );
  }

  Future<
      ({
        int uploaded,
        int failed,
        int conflicts,
        bool authRequired,
      })> _uploadReady() async {
    var uploaded = 0;
    var failed = 0;
    var conflicts = 0;

    final ready = await _queue.peekReady(now: _clock());
    final toUpload = <SyncOperation>[];
    final handlersByOp = <String, SyncEntityHandler>{};

    for (final op in ready) {
      final handler = _handlers[op.entityType];
      if (handler == null) {
        continue;
      }

      // Creates are ensure-exists: never probe getMeta / markConflict.
      // (baseVersion is forced to 0 on enqueue; type check covers legacy queue.)
      ConflictDecision decision;
      if (op.type == SyncOperationType.create || op.baseVersion <= 0) {
        decision = ConflictDecision.uploadLocal;
      } else {
        try {
          final probed = await handler.evaluateConflict(op);
          decision = probed ??
              _conflictResolver.resolve(
                localOperation: op,
                remoteVersion: op.baseVersion,
                remoteUpdatedAt: null,
                preferServerWhenLocalSynced:
                    handler.preferServerWhenLocalSynced,
              );
        } on AuthenticationFailure {
          return (
            uploaded: uploaded,
            failed: failed + 1,
            conflicts: conflicts,
            authRequired: true,
          );
        } on AuthorizationFailure catch (e) {
          failed++;
          await _queue.update(
            op.copyWith(
              status: SyncStatus.rejected,
              updatedAt: _clock(),
              lastError: e.message,
              clearNextRetryAt: true,
            ),
          );
          continue;
        } catch (e) {
          failed++;
          final attempts = op.attemptCount + 1;
          await _queue.update(
            op.copyWith(
              status: SyncStatus.failed,
              attemptCount: attempts,
              updatedAt: _clock(),
              lastError: mapToAppFailure(e).message,
              nextRetryAt: _clock().add(syncBackoffForAttempt(attempts)),
            ),
          );
          continue;
        }
      }

      if (decision == ConflictDecision.markConflict) {
        conflicts++;
        await _queue.update(
          op.copyWith(
            status: SyncStatus.conflict,
            updatedAt: _clock(),
            lastError: 'Conflict detected',
          ),
        );
        await handler.markLocalConflict(entityId: op.entityId);
        continue;
      }

      if (decision == ConflictDecision.applyRemote) {
        await _queue.remove(op.id);
        continue;
      }

      await _queue.update(
        op.copyWith(
          status: SyncStatus.syncing,
          updatedAt: _clock(),
          clearLastError: true,
        ),
      );
      toUpload.add(op);
      handlersByOp[op.id] = handler;
    }

    if (toUpload.isEmpty) {
      return (
        uploaded: uploaded,
        failed: failed,
        conflicts: conflicts,
        authRequired: false,
      );
    }

    final remote = _remote;
    final chunkSize = batchChunkSize < 1 ? toUpload.length : batchChunkSize;

    for (var i = 0; i < toUpload.length; i += chunkSize) {
      final end = (i + chunkSize > toUpload.length)
          ? toUpload.length
          : i + chunkSize;
      final chunk = toUpload.sublist(i, end);

      List<SyncBatchPushItemResult> results;
      try {
        if (remote != null) {
          results = await remote.pushBatch(chunk);
        } else {
          // Fallback: sequential handler uploads (no remote injected).
          results = [];
          for (final op in chunk) {
            final handler = handlersByOp[op.id]!;
            try {
              final ack = await handler.upload(op);
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
        }
      } on AuthenticationFailure {
        for (final op in chunk) {
          await _queue.update(
            op.copyWith(
              status: SyncStatus.pending,
              updatedAt: _clock(),
              clearNextRetryAt: true,
            ),
          );
        }
        return (
          uploaded: uploaded,
          failed: failed + 1,
          conflicts: conflicts,
          authRequired: true,
        );
      } catch (e) {
        final failure = mapToAppFailure(e);
        for (final op in chunk) {
          final attempts = op.attemptCount + 1;
          await _queue.update(
            op.copyWith(
              status: SyncStatus.failed,
              attemptCount: attempts,
              updatedAt: _clock(),
              lastError: failure.message,
              nextRetryAt: _clock().add(syncBackoffForAttempt(attempts)),
            ),
          );
          failed++;
        }
        continue;
      }

      final byId = {
        for (final r in results) r.operationId: r,
      };

      for (final op in chunk) {
        final handler = handlersByOp[op.id]!;
        final item = byId[op.id] ??
            SyncBatchPushItemResult(
              operationId: op.id,
              status: 'error',
              failure: const ServerFailure('Missing batch result'),
            );

        if (item.isSuccess) {
          final ack = item.ack!;
          await handler.markLocalSynced(
            entityId: op.entityId,
            remoteVersion: ack.remoteVersion,
            syncedAt: _clock(),
          );
          await _queue.remove(op.id);
          uploaded++;
          continue;
        }

        final failure = item.failure;
        if (item.isConflict || failure is SyncConflictFailure) {
          conflicts++;
          final message = failure?.message ?? 'Conflict detected';
          await _queue.update(
            op.copyWith(
              status: SyncStatus.conflict,
              updatedAt: _clock(),
              lastError: message,
            ),
          );
          await handler.markLocalConflict(
            entityId: op.entityId,
            message: message,
          );
          continue;
        }

        if (failure is AuthenticationFailure) {
          var reachedFailure = false;
          for (final pendingOp in chunk) {
            if (pendingOp.id == op.id) {
              reachedFailure = true;
            }
            if (!reachedFailure) {
              continue;
            }
            await _queue.update(
              pendingOp.copyWith(
                status: SyncStatus.pending,
                updatedAt: _clock(),
                lastError:
                    pendingOp.id == op.id ? failure.message : pendingOp.lastError,
                clearNextRetryAt: true,
              ),
            );
          }
          return (
            uploaded: uploaded,
            failed: failed + 1,
            conflicts: conflicts,
            authRequired: true,
          );
        }

        if (failure is AuthorizationFailure) {
          failed++;
          await _queue.update(
            op.copyWith(
              status: SyncStatus.rejected,
              updatedAt: _clock(),
              lastError: failure.message,
              clearNextRetryAt: true,
            ),
          );
          continue;
        }

        failed++;
        final attempts = op.attemptCount + 1;
        await _queue.update(
          op.copyWith(
            status: SyncStatus.failed,
            attemptCount: attempts,
            updatedAt: _clock(),
            lastError: failure?.message ?? 'Upload failed',
            nextRetryAt: _clock().add(syncBackoffForAttempt(attempts)),
          ),
        );
      }
    }

    return (
      uploaded: uploaded,
      failed: failed,
      conflicts: conflicts,
      authRequired: false,
    );
  }

  Future<({int downloaded, int failed, Map<String, int> downloadedByEntity})>
      _pullAllHandlers() async {
    var downloaded = 0;
    var failed = 0;
    final downloadedByEntity = <String, int>{};
    for (final handler in _handlers.values) {
      try {
        final changes = await handler.pull();
        var appliedAll = true;
        var appliedForType = 0;
        for (final change in changes) {
          try {
            await handler.applyRemoteChange(change);
            await _queue.removeCreatesForEntity(
              entityType: handler.entityType,
              entityId: change.entityId,
            );
            downloaded++;
            appliedForType++;
          } catch (_) {
            failed++;
            appliedAll = false;
          }
        }
        if (appliedForType > 0) {
          downloadedByEntity[handler.entityType] =
              (downloadedByEntity[handler.entityType] ?? 0) + appliedForType;
        }
        if (appliedAll) {
          await handler.confirmPull();
        } else {
          await handler.abandonPull();
        }
      } on AuthenticationFailure {
        await handler.abandonPull();
        rethrow;
      } on AuthorizationFailure {
        failed++;
        await handler.abandonPull();
      } catch (_) {
        failed++;
        await handler.abandonPull();
      }
    }
    return (
      downloaded: downloaded,
      failed: failed,
      downloadedByEntity: Map<String, int>.unmodifiable(downloadedByEntity),
    );
  }

  SyncPassOutcome _outcome({
    required int uploaded,
    required int downloaded,
    required int failed,
    required int conflicts,
  }) {
    if (failed > 0 && uploaded == 0 && downloaded == 0) {
      return SyncPassOutcome.failed;
    }
    if (failed > 0 || conflicts > 0) {
      return SyncPassOutcome.partialFailure;
    }
    if (uploaded > 0 || downloaded > 0) {
      return SyncPassOutcome.completed;
    }
    return SyncPassOutcome.idle;
  }

  Future<void> retryFailed() async {
    final all = await _queue.all();
    for (final op in all) {
      if (op.status == SyncStatus.failed) {
        await _queue.update(
          op.copyWith(
            status: SyncStatus.pending,
            clearNextRetryAt: true,
            clearLastError: true,
            updatedAt: _clock(),
          ),
        );
      }
    }
    await syncNow(notify: true);
  }

  Future<void> _refreshOverview() async {
    final pending = await _queue.countByStatus(SyncStatus.pending);
    final failed = await _queue.countByStatus(SyncStatus.failed);
    final conflicts = await _queue.countByStatus(SyncStatus.conflict);
    final syncingCount = await _queue.countByStatus(SyncStatus.syncing);

    final phase = deriveSyncPhase(
      isOnline: _connectivity.isOnline,
      isSyncing: _syncing,
      pendingCount: pending + syncingCount,
      failedCount: failed,
      conflictCount: conflicts,
    );

    _overview = SyncOverview(
      phase: phase,
      isOnline: _connectivity.isOnline,
      pendingCount: pending + syncingCount,
      failedCount: failed,
      conflictCount: conflicts,
      lastSyncedAt: _lastSyncedAt,
      isSyncing: _syncing,
    );
    if (!_overviewController.isClosed) {
      _overviewController.add(_overview);
    }
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _queueSub?.cancel();
    await _overviewController.close();
    await _passController.close();
  }
}
