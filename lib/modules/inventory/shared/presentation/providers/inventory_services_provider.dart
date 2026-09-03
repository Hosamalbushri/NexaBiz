import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/tenancy/session_company.dart';
import '../models/inventory_service_definition.dart';

/// Ordered inventory service ids pinned on the Inventory hub.
///
/// Defaults to the full catalog until the user customizes the list.
final inventoryServicesProvider =
    StateNotifierProvider.autoDispose<
      InventoryServicesController,
      AsyncValue<List<String>>
    >((ref) {
      return InventoryServicesController(
        repository: ref.watch(settingsRepositoryProvider),
        companyId: ref.watch(sessionCompanyIdProvider) ?? '',
      );
    });

class InventoryServicesController
    extends StateNotifier<AsyncValue<List<String>>> {
  InventoryServicesController({
    required SettingsRepository repository,
    String companyId = '',
  })  : _repository = repository,
        _companyId = companyId,
        super(AsyncValue.data(_defaultCatalogIds())) {
    _load();
  }

  final SettingsRepository _repository;
  final String _companyId;

  static List<String> _defaultCatalogIds() {
    return [for (final service in inventoryServiceCatalog()) service.id];
  }

  Future<void> _load() async {
    final saved = await _repository.loadInventoryServiceIds(_companyId);
    if (saved != null) {
      state = AsyncValue.data(_sanitize(saved));
    }
  }

  List<String> _defaultIds() {
    return [for (final service in inventoryServiceCatalog()) service.id];
  }

  List<String> _sanitize(List<String> ids) {
    final known = {for (final service in inventoryServiceCatalog()) service.id};
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      if (known.contains(id) && seen.add(id)) {
        result.add(id);
      }
    }
    return result;
  }

  List<InventoryServiceDefinition> resolveServices() {
    final ids = state.valueOrNull ?? const <String>[];
    final services = <InventoryServiceDefinition>[];
    for (final id in ids) {
      final service = findInventoryServiceById(id);
      if (service != null) {
        services.add(service);
      }
    }
    return services;
  }

  Future<void> save(List<String> ids) async {
    final sanitized = _sanitize(ids);
    state = AsyncValue.data(sanitized);
    await _repository.saveInventoryServiceIds(sanitized, _companyId);
  }

  /// Persists a new order for the currently visible services.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = List<String>.from(state.valueOrNull ?? _defaultIds());
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex > current.length) {
      return;
    }
    var target = newIndex;
    if (target > oldIndex) {
      target -= 1;
    }
    final id = current.removeAt(oldIndex);
    current.insert(target, id);
    await save(current);
  }

  Future<void> reload() => _load();
}
