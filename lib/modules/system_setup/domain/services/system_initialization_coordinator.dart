import '../../../authentication/data/local_auth_store.dart';
import '../entities/system_setup_state.dart';
import '../ports/system_setup_seed_port.dart';
import '../repositories/system_setup_state_repository.dart';

/// Determines readiness and advances versioned setup steps.
class SystemInitializationCoordinator {
  SystemInitializationCoordinator({
    required SystemSetupStateRepository stateRepository,
    required SystemSetupSeedPort seedPort,
    LocalAuthStore? authStore,
  })  : _stateRepository = stateRepository,
        _seedPort = seedPort,
        _authStore = authStore ?? LocalAuthStore();

  final SystemSetupStateRepository _stateRepository;
  final SystemSetupSeedPort _seedPort;
  final LocalAuthStore _authStore;

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
