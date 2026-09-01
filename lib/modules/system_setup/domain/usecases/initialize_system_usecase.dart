import '../entities/system_setup_state.dart';
import '../services/system_initialization_coordinator.dart';

class InitializeSystemUseCase {
  const InitializeSystemUseCase(this._coordinator);

  final SystemInitializationCoordinator _coordinator;

  Future<bool> isReady() => _coordinator.isReady();

  Future<SetupProgress> loadProgress() => _coordinator.loadProgress();
}

