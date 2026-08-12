import 'dart:async';

import '../connectivity/connectivity_service.dart';
import '../errors/app_failure.dart';
import 'conflict_resolver.dart';
import 'sync_entity_handler.dart';
import 'sync_overview.dart';
import 'sync_queue.dart';
import 'sync_status.dart';

/// Coordinates upload / download across registered [SyncEntityHandler]s.
///
/// Contains no feature UI logic. Safe to drive from foreground now and from
/// a future background isolate / workmanager entrypoint later.
class SyncManager {
  SyncManager({
    required SyncQueue queue,
    required ConnectivityService connectivity,
    ConflictResolver conflictResolver = const ConflictResolver(),
    void Function(SyncPassResult result)? onMeaningfulPass,
    DateTime Function()? clock,
  }) : _queue = queue,
       _connectivity = connectivity,
       _conflictResolver = conflictResolver,
       _onMeaningfulPass = onMeaningfulPass,
       _clock = clock ?? _defaultClock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  final SyncQueue _queue;
  final ConnectivityService _connectivity;
  final ConflictResolver _conflictResolver;
  final void Function(SyncPassResult result)? _onMeaningfulPass;
  final DateTime Function() _clock;

  final _handlers = <String, SyncEntityHandler>{};
  final _overviewController = StreamController<SyncOverview>.broadcast();
  final _passController = StreamController<SyncPassResult>.broadcast();

  StreamSubscription<ConnectivityStatus>? _connectivitySub;
  StreamSubscription<void>? _queueSub;
  var _started = false;
  var _syncing = false;
  DateTime? _lastSyncedAt;
  SyncOverview _overview = SyncOverview.initial();

  Stream<SyncOverview> get overviewStream async* {
    yield _overview;
    yield* _overviewController.stream;
  }

  /// Meaningful sync outcomes for optional UI notifications.
  Stream<SyncPassResult> get meaningfulPasses => _passController.stream;

  SyncOverview get overview => _overview;

  void registerHandler(SyncEntityHandler handler) {
    _handlers[handler.entityType] = handler;
  }

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await _connectivity.start();
    await _refreshOverview();

    _connectivitySub = _connectivity.onStatusChanged.listen((status) {
      unawaited(_onConnectivity(status));
    });
    _queueSub = _queue.changes.listen((_) {
      unawaited(_refreshOverview());
    });

    if (_connectivity.isOnline) {
      unawaited(syncNow(notify: false));
    }
  }

  Future<void> _onConnectivity(ConnectivityStatus status) async {
    await _refreshOverview();
    if (status == ConnectivityStatus.online) {
      await syncNow(notify: true);
    }
  }

  /// Manual or automatic synchronization pass.
  Future<SyncPassResult> syncNow({bool notify = true}) async {
    if (!_connectivity.isOnline) {
      final result = const SyncPassResult(
        outcome: SyncPassOutcome.skippedOffline,
      );
      await _refreshOverview();
      return result;
    }
    if (_syncing) {
      return const SyncPassResult(outcome: SyncPassOutcome.idle);
    }

    _syncing = true;
    await _refreshOverview();

    var uploaded = 0;
    var downloaded = 0;
    var failed = 0;
    var conflicts = 0;

    try {
      // 1) Upload pending local changes.
      final ready = await _queue.peekReady(now: _clock());
      for (final op in ready) {
        final handler = _handlers[op.entityType];
        if (handler == null) {
          continue;
        }
        await _queue.update(
          op.copyWith(
            status: SyncStatus.syncing,
            updatedAt: _clock(),
            clearLastError: true,
          ),
        );

        try {
          final probed = await handler.evaluateConflict(op);
          final decision =
              probed ??
              _conflictResolver.resolve(
                localOperation: op,
                remoteVersion: op.baseVersion,
                remoteUpdatedAt: null,
                preferServerWhenLocalSynced:
                    handler.preferServerWhenLocalSynced,
              );

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
            // Pull path below will refresh; drop this upload.
            await _queue.remove(op.id);
            continue;
          }

          final ack = await handler.upload(op);
          await handler.markLocalSynced(
            entityId: op.entityId,
            remoteVersion: ack.remoteVersion,
            syncedAt: _clock(),
          );
          await _queue.remove(op.id);
          uploaded++;
        } on SyncConflictFailure catch (e) {
          conflicts++;
          await _queue.update(
            op.copyWith(
              status: SyncStatus.conflict,
              updatedAt: _clock(),
              lastError: e.message,
            ),
          );
          await handler.markLocalConflict(
            entityId: op.entityId,
            message: e.message,
          );
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
        }
      }

      // 2) Download remote changes per handler.
      for (final handler in _handlers.values) {
        try {
          final changes = await handler.pull(since: _lastSyncedAt);
          for (final change in changes) {
            await handler.applyRemoteChange(change);
            downloaded++;
          }
        } catch (_) {
          failed++;
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
      final result = SyncPassResult(
        outcome: outcome,
        uploaded: uploaded,
        downloaded: downloaded,
        failed: failed,
        conflicts: conflicts,
      );

      if (notify && result.isMeaningful) {
        _onMeaningfulPass?.call(result);
        if (!_passController.isClosed) {
          _passController.add(result);
        }
      }
      return result;
    } finally {
      _syncing = false;
      await _refreshOverview();
    }
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
    // Treat syncing queue rows as pending for the badge.
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
