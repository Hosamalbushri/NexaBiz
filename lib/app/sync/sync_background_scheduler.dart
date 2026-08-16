import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/sync_os_background_bridge.dart';
import '../../core/sync/sync_os_wake_signal.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_request_context.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../settings/settings_repository.dart';
import 'sync_auto_preferences.dart';
import 'sync_enabled_provider.dart';

/// Persisted auto-sync preferences (toggle + interval).
final syncAutoPreferencesProvider =
    StateNotifierProvider<SyncAutoPreferencesController, SyncAutoPreferences>(
  (ref) {
    return SyncAutoPreferencesController(
      repository: ref.watch(settingsRepositoryProvider),
    );
  },
);

class SyncAutoPreferencesController
    extends StateNotifier<SyncAutoPreferences> {
  SyncAutoPreferencesController({
    required SettingsRepository repository,
  })  : _repository = repository,
        super(SyncAutoPreferences.defaults);

  final SettingsRepository _repository;

  Future<void> hydrate() async {
    final enabled = await _repository.loadSyncAutoEnabled();
    final minutes = await _repository.loadSyncAutoIntervalMinutes();
    state = SyncAutoPreferences(
      enabled: enabled,
      intervalMinutes: minutes,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _repository.saveSyncAutoEnabled(enabled);
  }

  Future<void> setIntervalMinutes(int minutes) async {
    final allowed = SyncAutoPreferences.intervalChoices.contains(minutes)
        ? minutes
        : SyncAutoPreferences.defaults.intervalMinutes;
    state = state.copyWith(intervalMinutes: allowed);
    await _repository.saveSyncAutoIntervalMinutes(allowed);
  }
}

/// Runs sync passes in the background without blocking the UI.
///
/// Triggers (when auto-sync is enabled and the remote session is live):
/// - Debounced queue changes (pending local mutations)
/// - Connectivity restored
/// - Periodic interval (optional)
/// - OS wake signal from WorkManager (Phase 6)
/// - App resumed from background
///
/// Manual Sync Now also goes through [requestSync] so re-entrancy stays safe.
final syncBackgroundSchedulerProvider = Provider<SyncBackgroundScheduler>((ref) {
  final scheduler = SyncBackgroundScheduler(
    syncManager: ref.watch(syncManagerProvider),
    queue: ref.watch(syncQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    osBridge: ref.watch(syncOsBackgroundBridgeProvider),
    readPrefs: () => ref.read(syncAutoPreferencesProvider),
    canRun: () {
      if (!ref.read(syncEnabledProvider)) return false;
      return ref.read(authStateProvider).canUseRemoteSync;
    },
  );
  ref.listen<SyncAutoPreferences>(syncAutoPreferencesProvider, (_, __) {
    scheduler.reconfigure();
  });
  ref.listen<bool>(syncEnabledProvider, (_, __) {
    scheduler.reconfigure();
  });
  ref.listen<AuthState>(authStateProvider, (_, __) {
    scheduler.reconfigure();
  });
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

class SyncBackgroundScheduler with WidgetsBindingObserver {
  SyncBackgroundScheduler({
    required SyncManager syncManager,
    required SyncQueue queue,
    required ConnectivityService connectivity,
    required SyncOsBackgroundBridge osBridge,
    required SyncAutoPreferences Function() readPrefs,
    required bool Function() canRun,
  })  : _syncManager = syncManager,
        _queue = queue,
        _connectivity = connectivity,
        _osBridge = osBridge,
        _readPrefs = readPrefs,
        _canRun = canRun;

  final SyncManager _syncManager;
  final SyncQueue _queue;
  final ConnectivityService _connectivity;
  final SyncOsBackgroundBridge _osBridge;
  final SyncAutoPreferences Function() _readPrefs;
  final bool Function() _canRun;

  StreamSubscription<void>? _queueSub;
  StreamSubscription<ConnectivityStatus>? _connectivitySub;
  Timer? _debounce;
  Timer? _periodic;
  var _started = false;

  /// Wire listeners after bootstrap (idempotent).
  void start() {
    if (_started) {
      reconfigure();
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _queueSub = _queue.changes.listen((_) => _onQueueChanged());
    _connectivitySub = _connectivity.onStatusChanged.listen(_onConnectivity);
    unawaited(_osBridge.initialize());
    reconfigure();
    unawaited(_drainOsWake());
  }

  void reconfigure() {
    _periodic?.cancel();
    _periodic = null;
    final prefs = _readPrefs();
    final can = _canRun();
    if (!can || !prefs.enabled) {
      _debounce?.cancel();
      _debounce = null;
      unawaited(_osBridge.cancel());
      return;
    }
    if (prefs.intervalMinutes > 0) {
      _periodic = Timer.periodic(
        Duration(minutes: prefs.intervalMinutes),
        (_) => unawaited(
          requestSync(notify: false, trigger: SyncPassTrigger.auto),
        ),
      );
    }
    unawaited(
      _osBridge.ensureScheduled(
        enabled: true,
        intervalMinutes: prefs.intervalMinutes,
      ),
    );
  }

  /// Fire-and-forget sync pass; never shows a blocking overlay.
  Future<void> requestSync({
    bool notify = true,
    SyncPassTrigger trigger = SyncPassTrigger.manual,
  }) async {
    if (!_canRun()) return;
    if (!_connectivity.isOnline) return;
    await _syncManager.syncNow(notify: notify, trigger: trigger);
  }

  /// Download server→device changes only (no local upload).
  Future<SyncPassResult?> requestIncomingChanges({bool notify = true}) async {
    if (!_canRun()) return null;
    if (!_connectivity.isOnline) return null;
    return _syncManager.syncNow(
      notify: notify,
      trigger: SyncPassTrigger.manual,
      upload: false,
      download: true,
    );
  }

  Future<void> _drainOsWake() async {
    final wake = await SyncOsWakeSignal.consume();
    if (wake == null) {
      return;
    }
    await requestSync(
      notify: false,
      trigger: SyncPassTrigger.osBackground,
    );
  }

  void _onQueueChanged() {
    final prefs = _readPrefs();
    if (!_canRun() || !prefs.enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      unawaited(requestSync(notify: false, trigger: SyncPassTrigger.auto));
    });
  }

  void _onConnectivity(ConnectivityStatus status) {
    if (status != ConnectivityStatus.online) return;
    final prefs = _readPrefs();
    if (!_canRun() || !prefs.enabled) return;
    unawaited(
      requestSync(notify: false, trigger: SyncPassTrigger.connectivity),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_drainOsWake());
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _periodic?.cancel();
    unawaited(_queueSub?.cancel());
    unawaited(_connectivitySub?.cancel());
  }
}
