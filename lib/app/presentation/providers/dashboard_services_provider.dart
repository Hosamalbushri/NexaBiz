import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/modules/app_module.dart';
import '../../../core/modules/module_providers.dart';
import '../../../core/modules/module_registry.dart';
import '../../../core/tenancy/session_company.dart';
import '../../settings/settings_repository.dart';

import '../../../core/tenancy/tenant_context.dart';

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
    StateNotifierProvider.autoDispose<
      DashboardServicesController,
      AsyncValue<List<String>>
    >((ref) {
      return DashboardServicesController(
        repository: ref.watch(settingsRepositoryProvider),
        registry: ref.watch(moduleRegistryProvider),
        companyId: ref.watch(sessionCompanyIdProvider) ?? '',
      );
    });

class DashboardServicesController
    extends StateNotifier<AsyncValue<List<String>>> {
  DashboardServicesController({
    required SettingsRepository repository,
    required ModuleRegistry registry,
    String companyId = '',
  })  : _repository = repository,
        _registry = registry,
        _companyId = companyId,
        super(AsyncValue.data(_defaultIdsForRegistry(registry))) {
    _load();
  }

  final SettingsRepository _repository;
  final ModuleRegistry _registry;
  final String _companyId;

  static List<String> _defaultIdsForRegistry(ModuleRegistry registry) {
    return [
      for (final module in registry.enabledModules) module.id,
    ].take(kMaxDashboardServices).toList(growable: false);
  }

  Future<void> _load() async {
    final saved = await _repository.loadDashboardServiceIds(_companyId);
    if (saved != null) {
      state = AsyncValue.data(_sanitize(saved));
    }
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

  List<AppModule> resolveModules({Set<String>? permissions}) {
    final ids = state.valueOrNull ?? const <String>[];
    final modules = <AppModule>[];
    final perms = permissions;
    for (final id in ids) {
      if (modules.length >= kMaxDashboardServices) {
        break;
      }
      final module = _registry.findById(id);
      if (module == null || !module.isEnabled) {
        continue;
      }
      if (perms != null &&
          module.requiredAnyPermissions.isNotEmpty &&
          !module.requiredAnyPermissions.any(perms.contains)) {
        continue;
      }
      modules.add(module);
    }
    return modules;
  }

  Future<void> save(List<String> ids) async {
    final sanitized = _sanitize(ids);
    state = AsyncValue.data(sanitized);
    await _repository.saveDashboardServiceIds(sanitized, _companyId);
  }

  Future<void> reload() => _load();
}
