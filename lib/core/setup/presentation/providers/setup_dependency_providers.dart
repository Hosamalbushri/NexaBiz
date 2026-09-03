import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/package_setup_definition.dart';
import '../../domain/services/central_setup_validation_engine.dart';
import '../../domain/services/setup_dependency_engine.dart';
import '../../domain/services/transaction_setup_validator.dart';
import 'account_binding_providers.dart';
import 'setup_registry_providers.dart';

final setupDependencyEngineProvider = Provider<SetupDependencyEngine>((ref) {
  return const SetupDependencyEngine();
});

final centralSetupValidationEngineProvider = Provider<CentralSetupValidationEngine>((ref) {
  return CentralSetupValidationEngine(
    accountLookupPort: ref.watch(setupAccountLookupPortProvider),
    bindingRepository: ref.watch(accountBindingRepositoryProvider),
    dependencyEngine: ref.watch(setupDependencyEngineProvider),
  );
});

final transactionSetupValidatorProvider = Provider<TransactionSetupValidator>((ref) {
  return TransactionSetupValidator(
    accountLookupPort: ref.watch(setupAccountLookupPortProvider),
    bindingRepository: ref.watch(accountBindingRepositoryProvider),
  );
});

/// Exposes all registered package setup definitions sorted in topological dependency order.
final orderedPackageSetupsProvider = Provider<List<PackageSetupDefinition>>((ref) {
  final registry = ref.watch(centralSetupRegistryProvider);
  final engine = ref.watch(setupDependencyEngineProvider);
  final allSetups = registry.getAll();
  return engine.getExecutionOrder(allSetups);
});
