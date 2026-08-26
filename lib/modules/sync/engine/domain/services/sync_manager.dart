import 'dart:async';

import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'conflict_resolver.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_conflict_record.dart';
import 'sync_conflict_store.dart';
import 'sync_entity_handler.dart';
import 'package:stock_count/modules/sync/engine/data/stores/sync_metrics_store.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_overview.dart';
import 'sync_queue.dart';
import 'sync_queue_recovery_service.dart';
import 'sync_request_context.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_status.dart';
import 'sync_error_classifier.dart';
import 'package:stock_count/core/time/domain/services/clock_integrity_service.dart';
import 'package:stock_count/core/logging/security_logger.dart';

/// Coordinates upload / download across registered [SyncEntityHandler]s.
///
/// Contains no feature UI logic. Safe to drive from foreground now and from
/// an OS background wake that drains into [syncNow] (Phase 6).
class SyncManager {
  SyncManager({
    required SyncQueue queue,
    required ConnectivityService connectivity,
    ConflictResolver conflictResolver = const ConflictResolver(),
    RemoteSyncApi Function()? remoteProvider,
    SyncMetricsStore? metricsStore,
    SyncConflictStore? conflictStore,
    void Function(SyncPassResult result)? onMeaningfulPass,
    DateTime Function()? clock,
    /// Returns true when the company entitlement grants sync capability.
    bool Function()? hasSyncCapability,
    /// Returns true when the current user holds the required sync permission.
    ///
    /// G5 fix: SyncManager must check BOTH permission AND entitlement.
    /// Unknown authorization state (null callback) is treated as denied.
    bool Function()? hasSyncPermission,
    String Function()? readCompanyId,
    ClockIntegrityState Function()? readClockState,
    bool Function()? isTimeTrusted,
    bool Function()? requiresReverification,
    bool Function()? isOfflineGraceActive,
    this.batchChunkSize = 50,
  }) : _queue = queue,
       _connectivity = connectivity,
       _conflictResolver = conflictResolver,
       _remoteProvider = remoteProvider,
       _metricsStore = metricsStore,
       _conflictStore = conflictStore,
       _onMeaningfulPass = onMeaningfulPass,
       _clock = clock ?? _defaultClock,
       _hasSyncCapability = hasSyncCapability,
       _hasSyncPermission = hasSyncPermission,
       _readCompanyId = readCompanyId,
       _readClockState = readClockState,
       _isTimeTrusted = isTimeTrusted,
       _requiresReverification = requiresReverification,
       _isOfflineGraceActive = isOfflineGraceActive;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  final SyncQueue _queue;
  final ConnectivityService _connectivity;
  final ConflictResolver _conflictResolver;
  final RemoteSyncApi Function()? _remoteProvider;
  final SyncMetricsStore? _metricsStore;
  final SyncConflictStore? _conflictStore;
  final void Function(SyncPassResult result)? _onMeaningfulPass;
  final DateTime Function() _clock;
  final bool Function()? _hasSyncCapability;
  final bool Function()? _hasSyncPermission;
  final String Function()? _readCompanyId;
  final ClockIntegrityState Function()? _readClockState;
  final bool Function()? _isTimeTrusted;
  final bool Function()? _requiresReverification;
  final bool Function()? _isOfflineGraceActive;

  RemoteSyncApi? get _remote => _remoteProvider?.call();

  /// Max operations per `/sync/push/batch` request.
  final int batchChunkSize;

  final _handlers = <String, SyncEntityHandler>{};
  final _overviewController = StreamController<SyncOverview>.broadcast();
  final _passController = StreamController<SyncPassResult>.broadcast();
  final _engineStateController = StreamController<EngineSyncState>.broadcast();

  StreamSubscription<ConnectivityStatus>? _connectivitySub;
  StreamSubscription<void>? _queueSub;
  var _started = false;
  var _enabled = false;
  var _syncing = false;
  DateTime? _lastSyncedAt;
  SyncOverview _overview = SyncOverview.initial();
  EngineSyncState _engineState = EngineSyncState.idle;
  SyncProgress _currentProgress = const SyncProgress();
  SyncDiagnostics _currentDiagnostics = const SyncDiagnostics();

  EngineSyncState get engineState => _engineState;

  Stream<EngineSyncState> get engineStateStream async* {
    yield _engineState;
    yield* _engineStateController.stream;
  }

  void _setEngineState(EngineSyncState state) {
    _engineState = state;
    if (!_engineStateController.isClosed) {
      _engineStateController.add(state);
    }
  }

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

  SyncEntityHandler? getHandler(String entityType) => _handlers[entityType];

  /// Enables or disables sync without restarting connectivity listeners.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    _setEngineState(enabled ? EngineSyncState.idle : EngineSyncState.disabled);
    await _refreshOverview();
  }

  Future<void> start({bool enabled = false}) async {
    if (_started) {
      _enabled = enabled;
      await _queue.reclaimInFlight(now: _clock());
      await SyncQueueRecoveryService(queue: _queue).recoverOrphanedOperations(_handlers.values);
      await _refreshOverview();
      return;
    }
    _started = true;
    _enabled = enabled;
    await _queue.reclaimInFlight(now: _clock());
    await SyncQueueRecoveryService(queue: _queue).recoverOrphanedOperations(_handlers.values);
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

  Future<SyncPassResult>? _ongoingSync;

  /// Manual or automatic synchronization pass.
  ///
  /// Set [upload] / [download] to run only one direction. The sync page uses
  /// download-only to fetch server changes without pushing local pending work.
  Future<SyncPassResult> syncNow({
    bool notify = true,
    SyncPassTrigger trigger = SyncPassTrigger.manual,
    bool upload = true,
    bool download = true,
  }) {
    if (_ongoingSync != null) {
      return _ongoingSync!;
    }
    final future = _syncNowInternal(
      notify: notify,
      trigger: trigger,
      upload: upload,
      download: download,
    );
    _ongoingSync = future;
    return future;
  }

  Future<SyncPassResult> _syncNowInternal({
    required bool notify,
    required SyncPassTrigger trigger,
    required bool upload,
    required bool download,
  }) async {
    try {
      return await _performSyncPass(
        notify: notify,
        trigger: trigger,
        upload: upload,
        download: download,
      );
    } finally {
      _ongoingSync = null;
    }
  }

  Future<SyncPassResult> _performSyncPass({
    required bool notify,
    required SyncPassTrigger trigger,
    required bool upload,
    required bool download,
  }) async {
    final correlationId = generateUuidV4();
    final started = _clock();

    Future<SyncPassResult> annotate(SyncPassResult result) async {
      final finished = _clock();
      final duration = finished.difference(started).inMilliseconds;
      _currentDiagnostics = _currentDiagnostics.copyWith(
        latencyMs: duration,
      );
      final enriched = SyncPassResult(
        outcome: result.outcome,
        uploaded: result.uploaded,
        downloaded: result.downloaded,
        failed: result.failed,
        conflicts: result.conflicts,
        downloadedByEntity: result.downloadedByEntity,
        correlationId: correlationId,
        durationMs: duration,
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
        if (_readClockState != null && _readClockState!() == ClockIntegrityState.tampered) {
          SecurityLogger.logEvent('clock_integrity_tampered', metadata: {'company_id': _readCompanyId?.call()});
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.clockTampered),
          );
        }
        if (_isTimeTrusted != null && !_isTimeTrusted!()) {
          SecurityLogger.logEvent('temporal_authorization_denied', metadata: {'company_id': _readCompanyId?.call()});
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.temporalAuthorizationFailed),
          );
        }
        if (_requiresReverification != null && _requiresReverification!()) {
          SecurityLogger.logEvent('temporal_reverification_required', metadata: {'company_id': _readCompanyId?.call()});
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.reverificationRequired),
          );
        }
        if (_isOfflineGraceActive != null && !_isOfflineGraceActive!()) {
          SecurityLogger.logEvent('offline_grace_expired', metadata: {'company_id': _readCompanyId?.call()});
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.temporalAuthorizationFailed),
          );
        }

        if (!_enabled || (_hasSyncCapability != null && !_hasSyncCapability!())) {
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.skippedDisabled),
          );
        }
        // G5 fix: require BOTH sync permission AND sync entitlement.
        // Unknown permission state (null callback) fails closed.
        if (_hasSyncPermission != null && !_hasSyncPermission!()) {
          await _refreshOverview();
          return annotate(
            const SyncPassResult(outcome: SyncPassOutcome.skippedDisabled),
          );
        }
        // Plugin "offline" is often wrong on Android. Skip auto passes only;
        // a user tap should still attempt HTTP (TLS/timeouts are the truth).
        if (!_connectivity.isOnline && trigger != SyncPassTrigger.manual) {
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
        _setEngineState(EngineSyncState.preparing);
        _currentProgress = const SyncProgress(
          phaseName: 'Preparing operations',
        );
        _currentDiagnostics = _currentDiagnostics.copyWith(
          lastRequestTime: started,
          serverConnected: true,
          lastStatusCode: 200,
          lastStatusMessage: 'OK',
          lastCorrelationId: correlationId,
        );
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
              _setEngineState(EngineSyncState.downloading);
              _currentProgress = SyncProgress(
                phaseName: 'Pulling server changes',
                currentStep: 0,
                totalSteps: _handlers.length,
                downloadedCount: downloaded,
              );
              await _refreshOverview();
              final pull = await _pullAllHandlers();
              downloaded = pull.downloaded;
              failed = pull.failed;
              downloadedByEntity = pull.downloadedByEntity;
              _currentProgress = SyncProgress(
                phaseName: 'Pulled server changes',
                currentStep: _handlers.length,
                totalSteps: _handlers.length,
                downloadedCount: downloaded,
              );
              await _refreshOverview();
            } on AuthenticationFailure {
              _setEngineState(EngineSyncState.authenticating);
              _currentDiagnostics = _currentDiagnostics.copyWith(
                lastStatusCode: 401,
                lastStatusMessage: 'Unauthorized',
              );
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
            _setEngineState(EngineSyncState.uploading);
            final readyOps = await _queue.peekReady(now: _clock());
            _currentProgress = SyncProgress(
              phaseName: 'Uploading local changes',
              currentStep: 0,
              totalSteps: readyOps.length,
              uploadedCount: 0,
              downloadedCount: downloaded,
            );
            await _refreshOverview();

            final uploadResult = await _uploadReady();
            uploaded = uploadResult.uploaded;
            failed += uploadResult.failed;
            conflicts += uploadResult.conflicts;

            _currentProgress = SyncProgress(
              phaseName: 'Upload finalized',
              currentStep: uploaded,
              totalSteps: readyOps.length,
              uploadedCount: uploaded,
              downloadedCount: downloaded,
            );
            await _refreshOverview();

            if (uploadResult.authRequired) {
              _setEngineState(EngineSyncState.authenticating);
              _currentDiagnostics = _currentDiagnostics.copyWith(
                lastStatusCode: 401,
                lastStatusMessage: 'Unauthorized',
              );
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
          _setEngineState(
            outcome == SyncPassOutcome.completed
                ? EngineSyncState.completed
                : outcome == SyncPassOutcome.partialFailure
                    ? EngineSyncState.partiallyCompleted
                    : EngineSyncState.idle,
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
      // Validate tenant boundary: operation companyId must match current active companyId
      final activeCompanyId = _readCompanyId?.call();
      if (activeCompanyId != null && op.companyId != null && op.companyId != activeCompanyId) {
        failed++;
        await _queue.quarantine(
          op.id,
          error: 'Quarantined: Cross-tenant operation upload blocked. '
              'Operation company ID "${op.companyId}" does not match active company ID "$activeCompanyId".',
        );
        SecurityLogger.logEvent('sync.tenant_mismatch', metadata: {
          'operation_id': op.id,
          'operation_company_id': op.companyId,
          'active_company_id': activeCompanyId,
        });
        continue;
      }

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
          await _queue.quarantine(op.id, error: e.message);
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
          if (_conflictStore != null) {
            final conflictRec = SyncConflictRecord(
              operationId: op.id,
              entityType: op.entityType,
              entityId: op.entityId,
              baseVersion: op.baseVersion,
              serverVersion: failure is SyncConflictFailure ? failure.serverVersion : op.baseVersion + 1,
              localPayload: op.payload,
              remotePayload: failure is SyncConflictFailure ? failure.serverRecord : null,
              mergeStatus: 'requires_user_resolution',
              createdAt: _clock(),
            );
            await _conflictStore!.save(conflictRec);
          }
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

        final err = failure ?? const UnknownFailure();
        final classification = SyncErrorClassifier.classify(err);
        final attempts = op.attemptCount + 1;

        if (classification.securityEvent != null) {
          SecurityLogger.logEvent(classification.securityEvent!, metadata: {
            'operation_id': op.id,
            'company_id': op.companyId,
            'error': err.message,
          });
        }

        if (classification.quarantine || attempts >= 5) {
          failed++;
          await _queue.quarantine(
            op.id,
            error: attempts >= 5
                ? 'Quarantined: Exceeded max retry attempts (5). Last error: ${err.message}'
                : err.message,
          );
          continue;
        }

        failed++;
        final nextRetry = err is RateLimitFailure && err.retryAfterSeconds != null
            ? _clock().add(Duration(seconds: err.retryAfterSeconds!))
            : _clock().add(syncBackoffForAttempt(attempts));
        await _queue.update(
          op.copyWith(
            status: SyncStatus.failed,
            attemptCount: attempts,
            updatedAt: _clock(),
            lastError: err.message,
            nextRetryAt: nextRetry,
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

    final remote = _remote;
    if (remote != null) {
      try {
        final changes = await remote.pull();
        if (changes.isNotEmpty) {
          var appliedAll = true;
          for (final change in changes) {
            final handler = _handlers[change.entityType];
            if (handler == null) {
              continue;
            }
            try {
              await handler.applyRemoteChange(change);
              await _queue.removeCreatesForEntity(
                entityType: handler.entityType,
                entityId: change.entityId,
              );
              downloaded++;
              downloadedByEntity[handler.entityType] =
                  (downloadedByEntity[handler.entityType] ?? 0) + 1;
            } on AuthenticationFailure {
              await remote.abandonPull('__global__');
              rethrow;
            } catch (_) {
              failed++;
              appliedAll = false;
            }
          }
          if (appliedAll) {
            await remote.acknowledgePull('__global__');
          } else {
            await remote.abandonPull('__global__');
          }
          return (
            downloaded: downloaded,
            failed: failed,
            downloadedByEntity:
                Map<String, int>.unmodifiable(downloadedByEntity),
          );
        }
      } on AuthenticationFailure {
        rethrow;
      } catch (_) {
        // Fall back to per-handler pull if unified pull fails.
      }
    }

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
          } on AuthenticationFailure {
            await handler.abandonPull();
            rethrow;
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
    final allOps = await _queue.all();
    final now = _clock();

    var pendingCount = 0;
    var failedCount = 0;
    var conflictCount = 0;
    var pendingRetryCount = 0;
    var pendingBlockedCount = 0;
    var pendingAuthCount = 0;

    for (final op in allOps) {
      switch (op.status) {
        case SyncStatus.pending:
        case SyncStatus.syncing:
          pendingCount++;
          break;
        case SyncStatus.failed:
          failedCount++;
          if (op.nextRetryAt != null && op.nextRetryAt!.isAfter(now)) {
            pendingRetryCount++;
          } else {
            pendingBlockedCount++;
          }
          break;
        case SyncStatus.rejected:
          pendingBlockedCount++;
          break;
        case SyncStatus.conflict:
          conflictCount++;
          pendingBlockedCount++;
          break;
        case SyncStatus.synced:
          break;
        case SyncStatus.quarantined:
          pendingBlockedCount++;
          break;
      }
    }

    final phase = deriveSyncPhase(
      isOnline: _connectivity.isOnline,
      isSyncing: _syncing,
      pendingCount: pendingCount,
      failedCount: failedCount,
      conflictCount: conflictCount,
    );

    _overview = SyncOverview(
      phase: phase,
      isOnline: _connectivity.isOnline,
      pendingCount: pendingCount,
      failedCount: failedCount,
      conflictCount: conflictCount,
      pendingRetryCount: pendingRetryCount,
      pendingBlockedCount: pendingBlockedCount,
      pendingAuthCount: pendingAuthCount,
      lastSyncedAt: _lastSyncedAt,
      isSyncing: _syncing,
      progress: _currentProgress,
      diagnostics: _currentDiagnostics,
    );
    if (!_overviewController.isClosed) {
      _overviewController.add(_overview);
    }
  }

  /// Resolves a recorded conflict by replacing it with a new operation.
  Future<void> resolveConflict({
    required String operationId,
    required String resolutionStrategy,
    Map<String, dynamic>? resolvedPayload,
  }) async {
    final conflictStore = _conflictStore;
    final conflictRec = await conflictStore?.getByOperationId(operationId);
    final allOps = await _queue.all();
    final opIndex = allOps.indexWhere((o) => o.id == operationId);
    if (opIndex == -1) {
      return;
    }
    final op = allOps[opIndex];

    final payloadToUse = resolvedPayload ??
        (resolutionStrategy == 'server_selected'
            ? (conflictRec?.remotePayload ?? op.payload)
            : op.payload);

    final serverVersion = conflictRec?.serverVersion ?? (op.baseVersion + 1);

    final newOp = SyncOperation.create(
      entityType: op.entityType,
      entityId: op.entityId,
      type: SyncOperationType.update,
      payload: payloadToUse,
      baseVersion: serverVersion,
    );

    await _queue.remove(operationId);
    await _queue.enqueue(newOp);

    if (conflictRec != null && conflictStore != null) {
      await conflictStore.save(
        conflictRec.copyWith(
          mergeStatus: resolutionStrategy,
          resolutionStrategy: resolutionStrategy,
          resolvedOperationId: newOp.id,
        ),
      );
    }
    await _refreshOverview();
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _queueSub?.cancel();
    await _overviewController.close();
    await _passController.close();
    await _engineStateController.close();
  }
}
