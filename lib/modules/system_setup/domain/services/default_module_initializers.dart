import '../ports/module_initializer.dart';

/// Base class for simple module initializers with custom verification logic.
class BaseModuleInitializer implements NexaBizModuleInitializer {
  const BaseModuleInitializer({
    required this.id,
    this.dependencies = const {},
    this.onInitialize,
    this.onVerify,
  });

  @override
  final ModuleId id;

  @override
  final Set<ModuleId> dependencies;

  final Future<void> Function(String companyId)? onInitialize;
  final Future<bool> Function(String companyId)? onVerify;

  @override
  Future<void> initialize(String companyId) async {
    if (onInitialize != null) {
      await onInitialize!(companyId);
    }
  }

  @override
  Future<bool> verify(String companyId) async {
    if (onVerify != null) {
      return onVerify!(companyId);
    }
    return true;
  }

  @override
  Future<bool> isInitialized(String companyId) async {
    return verify(companyId);
  }
}

/// Provides the canonical dependency-ordered NexaBiz module initializers.
List<NexaBizModuleInitializer> buildDefaultModuleInitializers() {
  return [
    const BaseModuleInitializer(id: ModuleId.administration, dependencies: {}),
    const BaseModuleInitializer(
      id: ModuleId.authentication,
      dependencies: {ModuleId.administration},
    ),
    const BaseModuleInitializer(
      id: ModuleId.accounting,
      dependencies: {ModuleId.authentication},
    ),
    const BaseModuleInitializer(
      id: ModuleId.cashRegisters,
      dependencies: {ModuleId.accounting},
    ),
    const BaseModuleInitializer(
      id: ModuleId.customers,
      dependencies: {ModuleId.accounting},
    ),
    const BaseModuleInitializer(
      id: ModuleId.inventory,
      dependencies: {ModuleId.accounting},
    ),
    const BaseModuleInitializer(
      id: ModuleId.sales,
      dependencies: {
        ModuleId.inventory,
        ModuleId.customers,
        ModuleId.cashRegisters,
      },
    ),
    const BaseModuleInitializer(
      id: ModuleId.receiptsPayments,
      dependencies: {
        ModuleId.sales,
        ModuleId.cashRegisters,
        ModuleId.customers,
      },
    ),
    const BaseModuleInitializer(
      id: ModuleId.reports,
      dependencies: {ModuleId.sales, ModuleId.receiptsPayments},
    ),
    const BaseModuleInitializer(
      id: ModuleId.sync,
      dependencies: {ModuleId.reports},
    ),
  ];
}
