import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/settings_repository.dart';
import '../models/inventory_service_definition.dart';

/// Ordered inventory service ids pinned on the Inventory hub.
///
/// Defaults to the full catalog until the user customizes the list.
final inventoryServicesProvider =
    StateNotifierProvider<
      InventoryServicesController,
      AsyncValue<List<String>>
    >((ref) {
      return InventoryServicesController(
        repository: ref.watch(settingsRepositoryProvider),
      );
    });

class InventoryServicesController
    extends StateNotifier<AsyncValue<List<String>>> {
  InventoryServicesController({required this._repository})
    : super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final saved = await _repository.loadInventoryServiceIds();
      return _sanitize(saved ?? _defaultIds());
    });
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
    await _repository.saveInventoryServiceIds(sanitized);
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
