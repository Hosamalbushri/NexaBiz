import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/modules/module_providers.dart';
import '../../core/modules/module_registry.dart';
import '../../modules/inventory/inventory_module.dart';

/// App composition root: registers enabled business modules.
///
/// Add future modules here (Sales, Purchases, …) without changing Core
/// or the Dashboard.
List<Override> moduleRegistryOverrides() {
  return [
    moduleRegistryProvider.overrideWithValue(
      ModuleRegistry(const [InventoryModule()]),
    ),
  ];
}
