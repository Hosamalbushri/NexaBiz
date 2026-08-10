import 'package:go_router/go_router.dart';

import 'app_module.dart';

/// Holds the ordered list of registered [AppModule] instances.
///
/// Constructed by the App composition root so Core never imports modules.
class ModuleRegistry {
  ModuleRegistry(List<AppModule> modules)
      : _modules = List<AppModule>.unmodifiable(modules);

  final List<AppModule> _modules;

  /// All registered modules (including disabled).
  List<AppModule> get modules => _modules;

  /// Modules shown on the Service Launcher.
  List<AppModule> get enabledModules =>
      [for (final module in _modules) if (module.isEnabled) module];

  /// Flat list of routes from enabled modules only.
  List<RouteBase> get routes {
    return [
      for (final module in enabledModules) ...module.routes,
    ];
  }

  AppModule? findById(String id) {
    for (final module in _modules) {
      if (module.id == id) {
        return module;
      }
    }
    return null;
  }
}
