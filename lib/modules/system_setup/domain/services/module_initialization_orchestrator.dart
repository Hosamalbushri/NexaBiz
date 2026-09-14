import '../../../../app/settings/settings_repository.dart';
import '../ports/module_initializer.dart';

/// Single orchestration mechanism for NexaBiz business module initializations.
class ModuleInitializationOrchestrator {
  ModuleInitializationOrchestrator({
    required List<NexaBizModuleInitializer> initializers,
    required this._settingsRepository,
  }) : _initializers = {for (final m in initializers) m.id: m};

  final Map<ModuleId, NexaBizModuleInitializer> _initializers;
  final SettingsRepository _settingsRepository;

  /// Returns initializers ordered strictly by dependency topological sort.
  List<NexaBizModuleInitializer> get executionOrder {
    final visited = <ModuleId>{};
    final visiting = <ModuleId>{};
    final ordered = <NexaBizModuleInitializer>[];

    void visit(ModuleId id) {
      if (visited.contains(id)) return;
      if (visiting.contains(id)) {
        throw StateError(
          'Circular dependency detected involving module ${id.name}',
        );
      }
      visiting.add(id);

      final initializer = _initializers[id];
      if (initializer != null) {
        for (final dep in initializer.dependencies) {
          visit(dep);
        }
        ordered.add(initializer);
      }

      visiting.remove(id);
      visited.add(id);
    }

    for (final id in _initializers.keys) {
      visit(id);
    }

    return ordered;
  }

  /// Checks if a module is completed and verified for a specific company.
  Future<bool> isModuleInitialized(String companyId, ModuleId moduleId) async {
    final key = _moduleStorageKey(companyId, moduleId);
    final box = await _settingsRepository.settingsBox;
    final stored = box.get(key) as bool? ?? false;
    if (!stored) return false;

    final initializer = _initializers[moduleId];
    if (initializer != null) {
      return initializer.verify(companyId);
    }
    return stored;
  }

  /// Initializes all registered modules for [companyId] in topological order.
  Future<void> initializeModules(String companyId) async {
    if (companyId.trim().isEmpty) {
      throw ArgumentError(
        'companyId cannot be empty for module initialization',
      );
    }

    final order = executionOrder;

    for (final initializer in order) {
      final alreadyDone = await isModuleInitialized(companyId, initializer.id);
      if (alreadyDone) {
        continue;
      }

      // Check prerequisites
      for (final dep in initializer.dependencies) {
        final depDone = await isModuleInitialized(companyId, dep);
        if (!depDone) {
          throw StateError(
            'Cannot initialize module ${initializer.id.name}: prerequisite module ${dep.name} is not initialized for company $companyId',
          );
        }
      }

      // Execute initialization
      await initializer.initialize(companyId);

      // Verify initialization
      final verified = await initializer.verify(companyId);
      if (!verified) {
        throw StateError(
          'Verification failed for module ${initializer.id.name} under company $companyId',
        );
      }

      // Mark module initialized for tenant
      final box = await _settingsRepository.settingsBox;
      await box.put(_moduleStorageKey(companyId, initializer.id), true);
    }
  }

  String _moduleStorageKey(String companyId, ModuleId moduleId) {
    return 'module_init_${companyId.trim()}_${moduleId.storageKey}';
  }
}
