/// Standard module identifiers for NexaBiz ERP.
enum ModuleId {
  administration,
  authentication,
  accounting,
  cashRegisters,
  customers,
  inventory,
  sales,
  receiptsPayments,
  reports,
  sync;

  String get storageKey => name;

  static ModuleId? tryParse(String raw) {
    for (final id in ModuleId.values) {
      if (id.name == raw || id.storageKey == raw) {
        return id;
      }
    }
    return null;
  }
}

/// Abstract contract that every NexaBiz module requiring initialization must implement.
abstract class NexaBizModuleInitializer {
  /// Unique module identifier.
  ModuleId get id;

  /// Prerequisites / dependencies that must be initialized before this module.
  Set<ModuleId> get dependencies;

  /// Executes the module-specific initialization logic.
  Future<void> initialize(String companyId);

  /// Verifies whether the module's required persisted state exists for [companyId].
  Future<bool> verify(String companyId);

  /// Checks whether the module is currently marked as initialized.
  Future<bool> isInitialized(String companyId);
}
