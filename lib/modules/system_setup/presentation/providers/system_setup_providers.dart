import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/settings_repository.dart';
import '../../data/repositories/system_setup_state_repository_impl.dart';
import '../../domain/entities/system_setup_state.dart';
import '../../domain/ports/system_setup_seed_port.dart';
import '../../domain/repositories/system_setup_state_repository.dart';
import '../../domain/services/system_initialization_coordinator.dart';

import '../../domain/services/installation_integrity_validator.dart';
import '../../domain/services/first_run_setup_coordinator.dart';
import '../../../authentication/data/local_auth_store.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/company_initialization_repository_impl.dart';
import '../../domain/repositories/company_initialization_repository.dart';

import '../../../../core/modules/module_providers.dart';
import '../../../../core/modules/module_setup_definition.dart';
import '../../domain/services/initialization_guard.dart';

import '../../domain/entities/company_accounting_config.dart';
import '../../domain/entities/company_inventory_config.dart';
import '../../data/services/system_setup_seed_port_impl.dart';

import '../../../../core/tenancy/tenant_context.dart';

final installationIntegrityValidatorProvider =
    Provider<InstallationIntegrityValidator>((ref) {
      return InstallationIntegrityValidator(
        settingsRepository: ref.watch(settingsRepositoryProvider),
        authStore: ref.watch(localAuthStoreProvider),
        initRepository: ref.watch(companyInitializationRepositoryProvider),
      );
    });

final companyInitializationRepositoryProvider =
    Provider<CompanyInitializationRepository>((ref) {
      return CompanyInitializationRepositoryImpl(
        box: null,
        readCompanyId: () => ref.read(currentCompanyIdProvider),
      );
    });

final companyAccountingConfigProvider =
    FutureProvider<CompanyAccountingConfig?>((ref) async {
  final repo = ref.watch(companyInitializationRepositoryProvider);
  return repo.getAccountingConfig();
});

final companyInventoryConfigProvider =
    FutureProvider<CompanyInventoryConfig?>((ref) async {
  final repo = ref.watch(companyInitializationRepositoryProvider);
  return repo.getInventoryConfig();
});

final initializationGuardProvider = Provider<InitializationGuard>((ref) {
  return InitializationGuard(
    initRepository: ref.watch(companyInitializationRepositoryProvider),
  );
});

final systemSetupSeedPortProvider = Provider<SystemSetupSeedPort>((ref) {
  return SystemSetupSeedPortImpl(ref);
});

final systemSetupStateRepositoryProvider = Provider<SystemSetupStateRepository>(
  (ref) {
    return SystemSetupStateRepositoryImpl(
      ref.watch(settingsRepositoryProvider),
    );
  },
);

final systemInitializationCoordinatorProvider =
    Provider<SystemInitializationCoordinator>((ref) {
      return SystemInitializationCoordinator(
        stateRepository: ref.watch(systemSetupStateRepositoryProvider),
        seedPort: ref.watch(systemSetupSeedPortProvider),
        authStore: ref.watch(localAuthStoreProvider),
      );
    });

final systemSetupProgressProvider = FutureProvider<SetupProgress>((ref) {
  return ref.watch(systemInitializationCoordinatorProvider).loadProgress();
});

final firstRunSetupCoordinatorProvider = Provider<FirstRunSetupCoordinator>((
  ref,
) {
  return FirstRunSetupCoordinator(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    authStore: ref.watch(localAuthStoreProvider),
    seedPort: ref.watch(systemSetupSeedPortProvider),
    initRepository: ref.watch(companyInitializationRepositoryProvider),
  );
});

class FirstRunCompletedNotifier extends StateNotifier<AsyncValue<bool>> {
  FirstRunCompletedNotifier(
    this._settingsRepository,
    this._authStore,
    this._validator,
  ) : super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _settingsRepository;
  final LocalAuthStore _authStore;
  final InstallationIntegrityValidator _validator;

  Future<void> _load() async {
    state = await AsyncValue.guard(() async {
      final integrity = await _validator.validate();
      if (integrity.isValid) return true;
      if (integrity.isCorrupted) return false;
      final onboardingDone =
          await _settingsRepository.loadOnboardingCompleted();
      if (!onboardingDone) return false;
      final hasAdmin = await _authStore.hasConfiguredAdmin();
      return hasAdmin;
    });
  }

  void markCompleted() {
    state = const AsyncValue.data(true);
  }

  Future<void> refresh() => _load();
}

final firstRunCompletedProvider =
    StateNotifierProvider<FirstRunCompletedNotifier, AsyncValue<bool>>((ref) {
  return FirstRunCompletedNotifier(
    ref.watch(settingsRepositoryProvider),
    ref.watch(localAuthStoreProvider),
    ref.watch(installationIntegrityValidatorProvider),
  );
});

class SystemSetupReadyNotifier extends StateNotifier<AsyncValue<bool>> {
  SystemSetupReadyNotifier(
    this._initRepository,
    this._coordinator,
    this._settingsRepository,
    this._authStore,
    this._validator,
  ) : super(const AsyncValue.loading()) {
    _load();
  }

  final CompanyInitializationRepository _initRepository;
  final SystemInitializationCoordinator _coordinator;
  final SettingsRepository _settingsRepository;
  final LocalAuthStore _authStore;
  final InstallationIntegrityValidator _validator;

  Future<void> _load() async {
    state = await AsyncValue.guard(() async {
      final integrity = await _validator.validate();
      if (integrity.isValid) return true;
      if (integrity.isCorrupted) return false;

      // 1. Device or onboarding setup completion check
      final onboardingDone =
          await _settingsRepository.loadOnboardingCompleted();
      final hasAdmin = await _authStore.hasConfiguredAdmin();
      if (onboardingDone && hasAdmin) {
        return true;
      }

      final deviceInit =
          await _settingsRepository.loadDeviceInitialization();
      if (deviceInit.initialized) {
        return true;
      }

      // 2. Company initialization state check
      final s = await _initRepository.getState();
      if (s.initializationCompleted) return true;

      // 3. Fallback progress check
      final progress = await _coordinator.loadProgress();
      return progress.isReady;
    });
  }

  void markReady() {
    state = const AsyncValue.data(true);
  }

  Future<void> refresh() => _load();
}

final systemSetupReadyProvider =
    StateNotifierProvider<SystemSetupReadyNotifier, AsyncValue<bool>>((ref) {
  return SystemSetupReadyNotifier(
    ref.watch(companyInitializationRepositoryProvider),
    ref.watch(systemInitializationCoordinatorProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(localAuthStoreProvider),
    ref.watch(installationIntegrityValidatorProvider),
  );
});

final registeredModuleSetupStepsProvider =
    Provider<List<ModuleSetupStepDefinition>>((ref) {
  final modules = ref.watch(moduleRegistryProvider).modules;
  final steps = <ModuleSetupStepDefinition>[];
  for (final module in modules) {
    if (module.isEnabled && module.hasSetupSteps) {
      steps.addAll(module.setupSteps);
    }
  }
  steps.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return steps;
});
