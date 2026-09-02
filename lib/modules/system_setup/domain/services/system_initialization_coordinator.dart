import '../../../authentication/data/local_auth_store.dart';
import '../entities/system_setup_state.dart';
import '../ports/system_setup_seed_port.dart';
import '../repositories/system_setup_state_repository.dart';

enum SystemInitializationState {
  uninitialized,
  initializing,
  initialized,
  initializationFailed,
}

class SystemAlreadyInitializedException implements Exception {
  const SystemAlreadyInitializedException();

  @override
  String toString() => 'System initialization has already been completed.';
}

/// Determines readiness and advances versioned setup steps.
class SystemInitializationCoordinator {
  SystemInitializationCoordinator({
    required this._stateRepository,
    required this._seedPort,
    LocalAuthStore? authStore,
  })  : _authStore = authStore ?? LocalAuthStore();

  final SystemSetupStateRepository _stateRepository;
  final SystemSetupSeedPort _seedPort;
  final LocalAuthStore _authStore;
  SystemInitializationState _initState = SystemInitializationState.uninitialized;

  SystemInitializationState get currentState => _initState;

  Future<SystemInitializationState> getInitializationState() async {
    final hasAdmin = await _authStore.hasConfiguredAdmin();
    final progress = await loadProgress();
    if (hasAdmin || progress.isReady) {
      _initState = SystemInitializationState.initialized;
      return SystemInitializationState.initialized;
    }
    return _initState;
  }

  /// Authoritative Phase 4 First-Run System Initialization.
  ///
  /// Executes base data seeding and initial System Administrator creation (company-less).
  /// Enforces idempotency and closed-path security (throws if already initialized).
  Future<void> initializeSystem({
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    final current = await getInitializationState();
    if (current == SystemInitializationState.initialized) {
      throw const SystemAlreadyInitializedException();
    }

    _initState = SystemInitializationState.initializing;

    try {
      // 1. Base data initialization
      await _seedPort.ensureLocalDefaults();

      // 2. Initial System Administrator creation (NO company context)
      await _authStore.createInitialSystemAdmin(
        name: adminName,
        email: adminEmail,
        password: adminPassword,
      );

      // 3. Complete system initialization
      var progress = await loadProgress();
      progress = _maybeMarkReady(progress);
      await _stateRepository.save(progress);

      _initState = SystemInitializationState.initialized;
    } catch (e) {
      _initState = SystemInitializationState.initializationFailed;
      rethrow;
    }
  }

  Future<SetupProgress> loadProgress() => _stateRepository.load();

  Future<bool> isReady() async {
    final progress = await loadProgress();
    return progress.isReady;
  }

  /// Marks a step in-progress, runs [action], then completes or fails.
  Future<SetupProgress> runStep(
    SetupStepId id,
    Future<void> Function() action,
  ) async {
    var progress = await loadProgress();
    progress = _withStatus(progress, SystemSetupStatus.inProgress);
    progress = _updateStep(
      progress,
      id,
      SetupStepStatus.inProgress,
      clearError: true,
    );
    await _stateRepository.save(progress);

    try {
      await action();
      progress = await loadProgress();
      progress = _updateStep(
        progress,
        id,
        SetupStepStatus.completed,
        clearError: true,
      );
      progress = _maybeMarkReady(progress);
      await _stateRepository.save(progress);
      return progress;
    } catch (e) {
      progress = await loadProgress();
      progress = _updateStep(
        progress,
        id,
        SetupStepStatus.failed,
        errorMessage: e.toString(),
      );
      await _stateRepository.save(progress);
      rethrow;
    }
  }

  Future<SetupProgress> markStepCompleted(SetupStepId id) async {
    var progress = await loadProgress();
    progress = _withStatus(progress, SystemSetupStatus.inProgress);
    progress = _updateStep(
      progress,
      id,
      SetupStepStatus.completed,
      clearError: true,
    );
    progress = _maybeMarkReady(progress);
    await _stateRepository.save(progress);
    return progress;
  }

  /// Runs the local account step (sets email/password).
  Future<SetupProgress> runLocalAccountStep({
    required String email,
    required String password,
    String? name,
  }) async {
    await _authStore.updateLocalAdminCredentials(
      newEmail: email,
      newPassword: password,
      newName: name,
    );
    return markStepCompleted(SetupStepId.localAccount);
  }

  /// Runs the seed data step. If [seedDefaults] is true, populates default chart of accounts.
  Future<SetupProgress> runSeedDataStep({bool seedDefaults = false}) async {
    return runStep(SetupStepId.seedData, () async {
      if (seedDefaults) {
        await _seedPort.ensureLocalDefaults();
      }
    });
  }

  /// Runs the local seed step via [SystemSetupSeedPort].
  Future<SetupProgress> runSeedLocal() {
    return runSeedDataStep(seedDefaults: false);
  }

  /// Runs Chart of Accounts bootstrap by pulling from the remote company.
  Future<SetupProgress> runSeedFromSync() {
    return runStep(SetupStepId.seedData, _seedPort.pullRemoteDefaults);
  }

  /// After all required steps succeed, mark application ready.
  Future<SetupProgress> completeRequiredAndContinue() async {
    var progress = await loadProgress();
    if (!progress.allRequiredComplete) {
      throw StateError('Required setup steps are incomplete');
    }
    progress = _maybeMarkReady(progress);
    await _stateRepository.save(progress);
    return progress;
  }

  SetupProgress _maybeMarkReady(SetupProgress progress) {
    if (!progress.allRequiredComplete) {
      return _withStatus(progress, SystemSetupStatus.inProgress);
    }
    return SetupProgress(
      schemaVersion: SystemSetupSchema.currentVersion,
      status: SystemSetupStatus.ready,
      steps: progress.steps,
      lastUpdated: DateTime.now().toUtc(),
    );
  }

  SetupProgress _withStatus(SetupProgress progress, SystemSetupStatus status) {
    return SetupProgress(
      schemaVersion: SystemSetupSchema.currentVersion,
      status: status,
      steps: progress.steps,
      lastUpdated: DateTime.now().toUtc(),
    );
  }

  SetupProgress _updateStep(
    SetupProgress progress,
    SetupStepId id,
    SetupStepStatus status, {
    String? errorMessage,
    bool clearError = false,
  }) {
    final steps = Map<SetupStepId, SetupStepState>.from(progress.steps);
    final previous = steps[id] ??
        SetupStepState(id: id, status: SetupStepStatus.pending);
    steps[id] = previous.copyWith(
      status: status,
      updatedAt: DateTime.now().toUtc(),
      errorMessage: errorMessage,
      clearError: clearError,
    );
    return SetupProgress(
      schemaVersion: SystemSetupSchema.currentVersion,
      status: progress.status,
      steps: steps,
      lastUpdated: DateTime.now().toUtc(),
    );
  }
}
