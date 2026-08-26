import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/sync_api_config.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../settings/settings_repository.dart';
import 'sync_session_state.dart';

/// Whether the user opted into multi-device sync (persisted; default off).
///
/// Enabling requires a successful remote authentication — see
/// [SyncEnabledController.enableAfterAuthentication] /
/// [SyncEnabledController.beginEnableFlow].
///
/// Session expiry does **not** clear this preference or the remote RBAC
/// snapshot: the user keeps the same module access offline until they renew
/// the session or explicitly disable sync (which restores local full-admin).
final syncEnabledProvider = StateNotifierProvider<SyncEnabledController, bool>((
  ref,
) {
  // Use read for SyncManager — watching it recreates this controller (state
  // resets to false) whenever the remote API identity changes.
  final controller = SyncEnabledController(
    repository: ref.watch(settingsRepositoryProvider),
    syncManager: ref.read(syncManagerProvider),
    readConfig: () => ref.read(syncApiConfigProvider),
    writeConfig: (config) {
      ref.read(syncApiConfigProvider.notifier).state = config;
    },
    readAuth: () => ref.read(authStateProvider),
    returnToLocalMode: () =>
        ref.read(authStateProvider.notifier).returnToLocalMode(),
    enterOfflineExpiredSession: () =>
        ref.read(authStateProvider.notifier).enterOfflineExpiredSession(),
    clearSyncLoginCredentials: () =>
        ref.read(syncLoginCredentialStoreProvider).clear(),
  );
  ref.listen<AuthState>(authStateProvider, (prev, next) {
    if (next.syncDisableApprovedByAdmin &&
        controller.isSyncEnabled &&
        !(prev?.syncDisableApprovedByAdmin ?? false)) {
      Future.microtask(controller.disableSynchronization);
      return;
    }
    if (next.needsSessionRenewal &&
        controller.isSyncEnabled &&
        !(prev?.needsSessionRenewal ?? false)) {
      Future.microtask(controller.pauseForSessionExpiry);
    }
  });
  return controller;
});

/// Derived sync+auth phase for Settings UI and routing.
final syncSessionStateProvider = Provider<SyncSessionState>((ref) {
  final enabled = ref.watch(syncEnabledProvider);
  final auth = ref.watch(authStateProvider);
  final overview =
      ref.watch(syncOverviewProvider).asData?.value ?? SyncOverview.initial();

  if (!enabled) {
    return const SyncSessionState.disabled();
  }

  if (auth.needsSessionRenewal || !auth.canUseRemoteSync) {
    return const SyncSessionState(phase: SyncSessionPhase.sessionExpired);
  }

  if (overview.phase == SyncPhase.failed ||
      overview.phase == SyncPhase.conflict) {
    return const SyncSessionState(phase: SyncSessionPhase.syncError);
  }

  return const SyncSessionState(phase: SyncSessionPhase.enabledAuthenticated);
});

class SyncEnabledController extends StateNotifier<bool> {
  SyncEnabledController({
    required SettingsRepository repository,
    required SyncManager syncManager,
    required SyncApiConfig Function() readConfig,
    required void Function(SyncApiConfig config) writeConfig,
    required AuthState Function() readAuth,
    required Future<void> Function() returnToLocalMode,
    required Future<void> Function() enterOfflineExpiredSession,
    Future<void> Function()? clearSyncLoginCredentials,
  }) : _repository = repository,
       _syncManager = syncManager,
       _readConfig = readConfig,
       _writeConfig = writeConfig,
       _readAuth = readAuth,
       _returnToLocalMode = returnToLocalMode,
       _enterOfflineExpiredSession = enterOfflineExpiredSession,
       _clearSyncLoginCredentials = clearSyncLoginCredentials,
       super(false);

  final SettingsRepository _repository;
  final SyncManager _syncManager;
  final SyncApiConfig Function() _readConfig;
  final void Function(SyncApiConfig config) _writeConfig;
  final AuthState Function() _readAuth;
  final Future<void> Function() _returnToLocalMode;
  final Future<void> Function() _enterOfflineExpiredSession;
  final Future<void> Function()? _clearSyncLoginCredentials;

  bool _handlingExpiry = false;

  bool get isSyncEnabled => state;

  Future<void> hydrate(bool enabled) async {
    final auth = _readAuth();
    final canRun = enabled && auth.canUseRemoteSync;
    // Keep the user preference even when credentials must be renewed.
    state = enabled;
    await _syncManager.setEnabled(canRun);
    _applyHttpEnabled(canRun);
  }

  /// Do not flip the toggle to true here — navigate to login first.
  /// Returns `true` when the caller should open the authentication page.
  Future<bool> beginEnableFlow() async {
    final auth = _readAuth();
    if (auth.canUseRemoteSync) {
      await enableAfterAuthentication(runInitialSync: false);
      return false;
    }
    return true;
  }

  /// Called only after successful remote authentication.
  Future<void> enableAfterAuthentication({bool runInitialSync = false}) async {
    await _repository.saveSyncEnabled(true);
    state = true;
    await _syncManager.setEnabled(true);
    _applyHttpEnabled(true);
    if (runInitialSync) {
      try {
        await _syncManager.syncNow(notify: true);
      } catch (_) {
        // Preference stays on; a later manual/auto pass can retry.
      }
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      final needsLogin = await beginEnableFlow();
      if (needsLogin) {
        return;
      }
      return;
    }
    await disableSynchronization();
  }

  /// Refresh failed: pause sync runtime, keep preference + remote RBAC snapshot.
  Future<void> pauseForSessionExpiry() async {
    if (_handlingExpiry) return;
    _handlingExpiry = true;
    try {
      await _syncManager.setEnabled(false);
      _applyHttpEnabled(false);
      if (!state) {
        state = true;
      }
      await _repository.saveSyncEnabled(true);
      await _enterOfflineExpiredSession();
    } finally {
      _handlingExpiry = false;
    }
  }

  /// Explicit opt-out: stop sync, clear remote session, restore local full-admin.
  /// Disables sync flag without resetting local session or clearing saved credentials.
  Future<void> disableForLocalLogin() async {
    await _syncManager.setEnabled(false);
    await _repository.saveSyncEnabled(false);
    state = false;
    _applyHttpEnabled(false);
  }

  Future<void> disableSynchronization() async {
    await _syncManager.setEnabled(false);
    await _repository.saveSyncEnabled(false);
    state = false;
    _applyHttpEnabled(false);
    try {
      await _clearSyncLoginCredentials?.call();
    } catch (_) {}
    await _returnToLocalMode();
  }

  /// Persists server URL (and optional legacy static token) for the HTTP client.
  Future<void> saveServer({
    required String baseUrl,
    required String apiToken,
  }) async {
    final url = baseUrl.trim();
    final token = apiToken.trim();
    await _repository.saveSyncServerBaseUrl(url.isEmpty ? null : url);
    await _repository.saveSyncServerToken(token.isEmpty ? null : token);

    final current = _readConfig();
    final auth = _readAuth();
    final wantEnabled = state && auth.canUseRemoteSync;
    _writeConfig(
      current.copyWith(
        baseUrl: url.isEmpty ? current.baseUrl : url,
        apiToken: token.isEmpty ? current.apiToken : token,
        enabled: wantEnabled,
      ),
    );
  }

  void _applyHttpEnabled(bool syncRuntimeEnabled) {
    final current = _readConfig();
    _writeConfig(current.copyWith(enabled: syncRuntimeEnabled));
  }
}
