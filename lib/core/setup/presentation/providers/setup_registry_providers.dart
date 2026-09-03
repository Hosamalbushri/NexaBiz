import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../modules/accounting/accounting_module_setup.dart';
import '../../../../modules/customers/customers_module_setup.dart';
import '../../../../modules/inventory/inventory_module_setup.dart';
import '../../../../modules/receipts_payments/receipts_payments_module_setup.dart';
import '../../../../modules/sales/sales_module_setup.dart';
import '../../domain/entities/package_setup_definition.dart';
import '../../domain/services/central_setup_registry.dart';

/// Singleton provider for [CentralSetupRegistry].
///
/// Registers all modular business package setup definitions upon instantiation.
final centralSetupRegistryProvider = Provider<CentralSetupRegistry>((ref) {
  final registry = CentralSetupRegistry();

  // Register modular setup definitions
  registerAccountingSetup(registry);
  registerInventorySetup(registry);
  registerSalesSetup(registry);
  registerCustomersSetup(registry);
  registerReceiptsPaymentsSetup(registry);

  return registry;
});

/// Provider exposing all registered package setup definitions, sorted by sortOrder.
final registeredPackageSetupsProvider =
    Provider<List<PackageSetupDefinition>>((ref) {
  final registry = ref.watch(centralSetupRegistryProvider);
  return registry.getAll();
});
