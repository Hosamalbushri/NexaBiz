import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'module_registry.dart';

/// Provides the [ModuleRegistry].
///
/// Must be overridden at the App composition root with concrete modules.
final moduleRegistryProvider = Provider<ModuleRegistry>((ref) {
  throw UnimplementedError(
    'moduleRegistryProvider must be overridden in the App composition root.',
  );
});
