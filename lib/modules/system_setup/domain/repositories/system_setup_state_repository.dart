import '../entities/system_setup_state.dart';

/// Persistence for versioned System Setup progress.
abstract class SystemSetupStateRepository {
  /// Loads progress, applying grandfather migration when keys are missing.
  Future<SetupProgress> load();

  Future<void> save(SetupProgress progress);
}
