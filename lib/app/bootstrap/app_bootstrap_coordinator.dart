import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_error_log.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../settings/settings_repository.dart';
import 'app_bootstrap.dart';

/// Explicit high-level bootstrap status values for Phase 2 application bootstrap.
enum AppBootstrapStatus {
  /// App infrastructure & local storage currently booting.
  initializing,

  /// UNINITIALIZED installation: First-Run setup & initial System Admin creation required.
  firstRunRequired,

  /// INITIALIZED installation: Restoring persisted session.
  restoringSession,

  /// User authenticated in System Scope (System Admin with no active company context).
  authenticatedSystemScope,

  /// User authenticated in Company Scope (active company context established).
  authenticatedCompanyScope,

  /// INITIALIZED installation: No valid user session found, login required.
  unauthenticated,

  /// Backward-compatible ready state indicator.
  ready,

  /// Fatal infrastructure or initialization failure.
  error,

  /// Alias for error (backward compatible).
  failed,
}

/// Explicit immutable state produced by [AppBootstrapCoordinator].
@immutable
class AppBootstrapState {
  const AppBootstrapState({
    required this.status,
    this.activeCompanyId,
    this.isSystemScope = false,
    this.error,
    this.stageDetails = '',
  });

  final AppBootstrapStatus status;
  final String? activeCompanyId;
  final bool isSystemScope;
  final Object? error;
  final String stageDetails;

  bool get isInitializing => status == AppBootstrapStatus.initializing;
  bool get isFirstRunRequired => status == AppBootstrapStatus.firstRunRequired;
  bool get isRestoringSession => status == AppBootstrapStatus.restoringSession;
  bool get isAuthenticated =>
      status == AppBootstrapStatus.authenticatedSystemScope ||
      status == AppBootstrapStatus.authenticatedCompanyScope ||
      status == AppBootstrapStatus.ready;
  bool get isAuthenticatedSystemScope =>
      status == AppBootstrapStatus.authenticatedSystemScope ||
      (status == AppBootstrapStatus.ready && isSystemScope);
  bool get isAuthenticatedCompanyScope =>
      status == AppBootstrapStatus.authenticatedCompanyScope ||
      (status == AppBootstrapStatus.ready && !isSystemScope && activeCompanyId != null);
  bool get isUnauthenticated => status == AppBootstrapStatus.unauthenticated;
  bool get isReady =>
      status == AppBootstrapStatus.ready ||
      status == AppBootstrapStatus.authenticatedSystemScope ||
      status == AppBootstrapStatus.authenticatedCompanyScope;
  bool get isFailed =>
      status == AppBootstrapStatus.failed || status == AppBootstrapStatus.error;
  bool get isError => isFailed;

  AppBootstrapState copyWith({
    AppBootstrapStatus? status,
    String? activeCompanyId,
    bool clearActiveCompanyId = false,
    bool? isSystemScope,
    Object? error,
    bool clearError = false,
    String? stageDetails,
  }) {
    return AppBootstrapState(
      status: status ?? this.status,
      activeCompanyId: clearActiveCompanyId
          ? null
          : (activeCompanyId ?? this.activeCompanyId),
      isSystemScope: isSystemScope ?? this.isSystemScope,
      error: clearError ? null : (error ?? this.error),
      stageDetails: stageDetails ?? this.stageDetails,
    );
  }

  @override
  String toString() =>
      'AppBootstrapState(status: $status, activeCompanyId: $activeCompanyId, isSystemScope: $isSystemScope, stageDetails: $stageDetails)';
}

/// Single authoritative coordinator for Phase 2 Application Bootstrap.
///
/// Persistence Authorities:
/// - SettingsRepository: Onboarding status & system configuration flags.
/// - LocalAuthStore: User identity, sessions, and active company context.
/// - CompanyInitializationRepository: Operational company setup completion.
///
/// Runtime Orchestration:
/// - AppBootstrapCoordinator: Manages state machine transitions without persisting runtime status.
class AppBootstrapCoordinator extends StateNotifier<AppBootstrapState> {
  AppBootstrapCoordinator(this._ref)
      : super(
          const AppBootstrapState(
            status: AppBootstrapStatus.initializing,
            stageDetails: 'Starting application bootstrap',
          ),
        ) {
    _listenToAuthChanges();
  }

  final Ref _ref;
  Future<void>? _ongoingBootstrap;
  AuthState? _queuedAuthState;

  void _listenToAuthChanges() {
    _ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (state.status == AppBootstrapStatus.initializing ||
          state.status == AppBootstrapStatus.firstRunRequired ||
          state.status == AppBootstrapStatus.restoringSession) {
        // Queue incoming auth changes during bootstrapping/session restoration
        // to prevent race conditions or missed events.
        _queuedAuthState = next;
        return;
      }
      _syncWithAuthState(next);
    });
  }

  /// Master deterministic startup entry point.
  Future<void> startBootstrap() {
    if (_ongoingBootstrap != null) {
      return _ongoingBootstrap!;
    }
    final future = _startBootstrapInternal();
    _ongoingBootstrap = future;
    return future;
  }

  Future<void> _startBootstrapInternal() async {
    _queuedAuthState = null;

    try {
      if (!mounted) return;
      state = const AppBootstrapState(
        status: AppBootstrapStatus.initializing,
        stageDetails: 'Bootstrapping local infrastructure',
      );

      // 1. Infrastructure Initialization
      await AppBootstrap.bootstrapStorage();
      await AppBootstrap.bootstrapDatabase();
      await AppBootstrap.bootstrapConfig(_ref);

      // 2. Detect Persistence Authority Initialization State
      final firstRunCoordinator = _ref.read(firstRunSetupCoordinatorProvider);
      final isInitialized = await firstRunCoordinator.isFirstRunCompleted();

      if (!isInitialized) {
        if (!mounted) return;
        state = const AppBootstrapState(
          status: AppBootstrapStatus.firstRunRequired,
          stageDetails: 'First-run application setup required',
        );
        return;
      }

      // 3. Restore Session for Initialized System
      await _restoreSession();
    } catch (e, stack) {
      AppErrorLog.record(e, stack, source: 'AppBootstrapCoordinator.startBootstrap');
      if (!mounted) return;
      state = AppBootstrapState(
        status: AppBootstrapStatus.error,
        error: e,
        stageDetails: 'Initialization failed: $e',
      );
    } finally {
      _ongoingBootstrap = null;
    }
  }

  /// Reset & retry initialization after an error.
  Future<void> retryBootstrap() async {
    state = const AppBootstrapState(
      status: AppBootstrapStatus.initializing,
      stageDetails: 'Retrying application bootstrap',
    );
    await startBootstrap();
  }

  /// Advances initialization when First-Run setup completes.
  Future<void> onFirstRunCompleted() async {
    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (!mounted) return;
    state = const AppBootstrapState(
      status: AppBootstrapStatus.restoringSession,
      stageDetails: 'Restoring user session',
    );

    try {
      final syncEnabled = await SettingsRepository().loadSyncEnabled();
      await _ref.read(authStateProvider.notifier).bootstrap(
            preferRemote: syncEnabled,
          );
    } catch (e, stack) {
      AppErrorLog.record(e, stack, source: 'AppBootstrapCoordinator._restoreSession');
    }

    // Process queued auth events or read current state
    final queued = _queuedAuthState;
    final AuthState authState = queued ?? _ref.read(authStateProvider);
    _queuedAuthState = null;
    _syncWithAuthState(authState);
  }

  void _syncWithAuthState(AuthState authState) {
    if (!mounted) return;
    if (authState.status == AuthStatus.unauthenticated) {
      state = const AppBootstrapState(
        status: AppBootstrapStatus.unauthenticated,
        stageDetails: 'Unauthenticated session',
      );
      return;
    }

    if (authState.isAuthenticated) {
      final session = authState.session;
      final activeCompanyContext = session?.activeCompanyContext;
      final user = session?.user;

      final isSystemAdmin = user?.isSystemAdmin == true;
      final hasActiveCompany = activeCompanyContext != null;
      final activeCompanyId = activeCompanyContext?.companyId;

      final status = hasActiveCompany
          ? AppBootstrapStatus.authenticatedCompanyScope
          : (isSystemAdmin
              ? AppBootstrapStatus.authenticatedSystemScope
              : AppBootstrapStatus.unauthenticated);

      state = AppBootstrapState(
        status: status,
        activeCompanyId: activeCompanyId,
        isSystemScope: isSystemAdmin && !hasActiveCompany,
        stageDetails: hasActiveCompany
            ? 'Company Scope ready ($activeCompanyId)'
            : (isSystemAdmin
                ? 'System Scope ready (System Admin)'
                : 'Company selection required'),
      );
    }
  }
}

/// Provider for watching/reading Phase 2 bootstrap coordinator state.
final appBootstrapCoordinatorProvider =
    StateNotifierProvider<AppBootstrapCoordinator, AppBootstrapState>((ref) {
  final coordinator = AppBootstrapCoordinator(ref);
  coordinator.startBootstrap();
  return coordinator;
});
