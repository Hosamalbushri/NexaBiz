import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/modules/module_providers.dart';
import '../../core/modules/module_registry.dart';
import 'module_bootstrap_manifest.dart';

/// App composition root: reads self-registered business modules from [ModuleRegistry].
///
/// Business modules self-register into [ModuleRegistry] via static `register()` methods,
/// and supply their own Riverpod provider overrides via `AppModule.providerOverrides`.
/// `module_bootstrap.dart` is strictly READ-ONLY and contains NO hardcoded module definitions or overrides.
List<Override> moduleRegistryOverrides() {
  initializeModuleCatalog();

  final registry = ModuleRegistry();

  return [
    moduleRegistryProvider.overrideWithValue(registry),
    ...registry.allModuleOverrides,
  ];
}
