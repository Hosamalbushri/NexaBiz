import '../../../../app/settings/settings_repository.dart';
import '../../domain/entities/system_setup_state.dart';
import '../../domain/repositories/system_setup_state_repository.dart';

/// Hive-backed System Setup state using the platform settings box.
class SystemSetupStateRepositoryImpl implements SystemSetupStateRepository {
  SystemSetupStateRepositoryImpl(this._settings);

  final SettingsRepository _settings;

  @override
  Future<SetupProgress> load() async {
    final hasState = await _settings.hasSystemSetupState();
    if (!hasState) {
      if (await _settings.appearsPreviouslyConfigured()) {
        final grandfathered = _grandfatheredProgress();
        await save(grandfathered);
        await _settings.saveSystemBaseCurrencyLocked(true);
        return grandfathered;
      }
      return _freshProgress();
    }

    final version =
        await _settings.loadSystemSetupVersion() ??
        SystemSetupSchema.currentVersion;
    final status = SystemSetupStatus.fromStorage(
      await _settings.loadSystemSetupStatus(),
    );
    final rawSteps = await _settings.loadSystemSetupSteps();
    final steps = <SetupStepId, SetupStepState>{};
    for (final id in SetupStepId.allIds) {
      final raw = rawSteps[id.storageKey];
      if (raw != null) {
        steps[id] = SetupStepState.fromMap(id, raw);
      } else {
        steps[id] = SetupStepState(
          id: id,
          status: SetupStepStatus.pending,
        );
      }
    }

    var effectiveStatus = status;
    if (version < SystemSetupSchema.currentVersion) {
      effectiveStatus = SystemSetupStatus.inProgress;
    }

    final progress = SetupProgress(
      schemaVersion: SystemSetupSchema.currentVersion,
      status: effectiveStatus,
      steps: steps,
      lastUpdated: await _settings.loadSystemSetupLastUpdated(),
    );

    if (progress.allRequiredComplete &&
        progress.status != SystemSetupStatus.ready) {
      final ready = SetupProgress(
        schemaVersion: SystemSetupSchema.currentVersion,
        status: SystemSetupStatus.ready,
        steps: progress.steps,
        lastUpdated: DateTime.now().toUtc(),
      );
      await save(ready);
      return ready;
    }

    return progress;
  }

  @override
  Future<void> save(SetupProgress progress) async {
    final steps = <String, Map<String, Object?>>{
      for (final id in SetupStepId.allIds)
        id.storageKey: (progress.steps[id] ??
                SetupStepState(id: id, status: SetupStepStatus.pending))
            .toMap(),
    };
    await _settings.saveSystemSetupState(
      version: progress.schemaVersion,
      status: progress.status.storageValue,
      steps: steps,
      lastUpdated: progress.lastUpdated ?? DateTime.now().toUtc(),
    );
  }

  SetupProgress _freshProgress() {
    final steps = <SetupStepId, SetupStepState>{
      for (final id in SetupStepId.allIds)
        id: SetupStepState(id: id, status: SetupStepStatus.pending),
    };
    return SetupProgress(
      schemaVersion: SystemSetupSchema.currentVersion,
      status: SystemSetupStatus.notStarted,
      steps: steps,
    );
  }

  /// Existing installs without setup keys are treated as already initialized.
  SetupProgress _grandfatheredProgress() {
    final now = DateTime.now().toUtc();
    final steps = <SetupStepId, SetupStepState>{
      for (final id in SetupStepId.requiredIds)
        id: SetupStepState(
          id: id,
          status: SetupStepStatus.completed,
          updatedAt: now,
        ),
      for (final id in SetupStepId.optionalIds)
        id: SetupStepState(
          id: id,
          status: SetupStepStatus.skipped,
          updatedAt: now,
        ),
    };
    return SetupProgress(
      schemaVersion: SystemSetupSchema.currentVersion,
      status: SystemSetupStatus.ready,
      steps: steps,
      lastUpdated: now,
    );
  }
}
