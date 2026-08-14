import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/modules/module_providers.dart';
import '../../../core/modules/module_registry.dart';
import '../../settings/settings_repository.dart';

/// Maximum service shortcuts shown on the dashboard grid.
const int kMaxDashboardServices = 6;

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// Ordered module ids pinned on the Dashboard.
///
/// Defaults to the first [kMaxDashboardServices] enabled modules until the
/// user customizes the list.
final dashboardServicesProvider =
    StateNotifierProvider<
      DashboardServicesController,
      AsyncValue<List<String>>
    >((ref) {
      return DashboardServicesController(
        repository: ref.watch(settingsRepositoryProvider),
        registry: ref.watch(moduleRegistryProvider),
      );
    });

class DashboardServicesController
    extends StateNotifier<AsyncValue<List<String>>> {
  DashboardServicesController({
    required this._repository,
    required this._registry,
  }) : super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;
  final ModuleRegistry _registry;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final saved = await _repository.loadDashboardServiceIds();
      return _sanitize(saved ?? _defaultIds());
    });
  }

  List<String> _defaultIds() {
    return [
      for (final module in _registry.enabledModules) module.id,
    ].take(kMaxDashboardServices).toList(growable: false);
  }

  List<String> _sanitize(List<String> ids) {
    final enabledIds = {
      for (final module in _registry.enabledModules) module.id,
    };
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      if (result.length >= kMaxDashboardServices) {
        break;
      }
      if (enabledIds.contains(id) && seen.add(id)) {
        result.add(id);
      }
    }
    return result;
  }

  List<AppModule> resolveModules() {
    final ids = state.valueOrNull ?? const <String>[];
    final modules = <AppModule>[];
    for (final id in ids) {
      if (modules.length >= kMaxDashboardServices) {
        break;
      }
      final module = _registry.findById(id);
      if (module != null && module.isEnabled) {
        modules.add(module);
      }
    }
    return modules;
  }

  Future<void> save(List<String> ids) async {
    final sanitized = _sanitize(ids);
    state = AsyncValue.data(sanitized);
    await _repository.saveDashboardServiceIds(sanitized);
  }

  Future<void> reload() => _load();
}
