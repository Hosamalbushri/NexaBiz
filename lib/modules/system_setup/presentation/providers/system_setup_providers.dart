import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../data/repositories/system_setup_state_repository_impl.dart';
import '../../domain/entities/system_setup_state.dart';
import '../../domain/ports/system_setup_seed_port.dart';
import '../../domain/repositories/system_setup_state_repository.dart';
import '../../domain/services/system_initialization_coordinator.dart';

final systemSetupSeedPortProvider = Provider<SystemSetupSeedPort>((ref) {
  return const NoOpSystemSetupSeedPort();
});

final systemSetupStateRepositoryProvider =
    Provider<SystemSetupStateRepository>((ref) {
      return SystemSetupStateRepositoryImpl(
        ref.watch(settingsRepositoryProvider),
      );
    });

final systemInitializationCoordinatorProvider =
    Provider<SystemInitializationCoordinator>((ref) {
      return SystemInitializationCoordinator(
        stateRepository: ref.watch(systemSetupStateRepositoryProvider),
        seedPort: ref.watch(systemSetupSeedPortProvider),
      );
    });

final systemSetupProgressProvider =
    FutureProvider.autoDispose<SetupProgress>((ref) {
      return ref.watch(systemInitializationCoordinatorProvider).loadProgress();
    });

final systemSetupReadyProvider = FutureProvider.autoDispose<bool>((ref) async {
  final progress = await ref.watch(systemSetupProgressProvider.future);
  return progress.isReady;
});
