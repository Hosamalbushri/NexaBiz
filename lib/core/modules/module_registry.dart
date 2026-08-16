import 'package:go_router/go_router.dart';

import '../permissions/permission_defs.dart';
import 'app_module.dart';
import 'route_access_rule.dart';

/// Holds the ordered list of registered [AppModule] instances.
///
/// Constructed by the App composition root so Core never imports modules.
class ModuleRegistry {
  ModuleRegistry(List<AppModule> modules)
    : _modules = List<AppModule>.unmodifiable(modules);

  final List<AppModule> _modules;

  /// All registered modules (including disabled).
  List<AppModule> get modules => _modules;

  /// Modules shown on the Service Launcher / Dashboard grids.
  List<AppModule> get enabledModules => [
    for (final module in _modules)
      if (module.isEnabled && module.showInLauncher) module,
  ];

  /// Launcher modules filtered by the caller's permission snapshot (any-of).
  List<AppModule> modulesVisibleTo(Set<String> permissions) {
    return [
      for (final module in enabledModules)
        if (module.requiredAnyPermissions.isEmpty ||
            module.requiredAnyPermissions.any(permissions.contains))
          module,
    ];
  }

  /// RBAC packages from registered modules (enabled only), sorted for UI.
  ///
  /// Adding/removing a module in bootstrap automatically changes this list.
  List<PermissionPackageDef> get permissionPackages {
    final packages = <PermissionPackageDef>[
      for (final module in _modules)
        if (module.isEnabled && module.permissionPackage != null)
          module.permissionPackage!,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(packages);
  }

  /// Primary (canonical) permission codes across registered packages.
  Set<String> get primaryPermissionCodes => {
        for (final pkg in permissionPackages)
          for (final svc in pkg.services)
            for (final op in svc.operations) op.code,
      };

  /// Resolve a primary or legacy code to its operation definition.
  PermissionOperationDef? findPermissionOperation(String code) {
    for (final pkg in permissionPackages) {
      for (final svc in pkg.services) {
        for (final op in svc.operations) {
          if (op.code == code || op.legacyCodes.contains(code)) {
            return op;
          }
        }
      }
    }
    return null;
  }

  /// Flat list of routes from every enabled module (including non-launcher).
  List<RouteBase> get routes {
    return [
      for (final module in _modules)
        if (module.isEnabled) ...module.routes,
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

  /// Module whose [AppModule.rootRoute] owns [path], if any.
  AppModule? findByPath(String path) {
    AppModule? best;
    var bestLen = -1;
    for (final module in _modules) {
      if (!module.isEnabled) {
        continue;
      }
      final root = module.rootRoute;
      if (path == root || path.startsWith('$root/')) {
        if (root.length > bestLen) {
          best = module;
          bestLen = root.length;
        }
      }
    }
    return best;
  }

  /// Permissions required to stay on [path], or `null` when ungated.
  List<String>? requiredPermissionsForPath(String path) {
    final module = findByPath(path);
    if (module == null) {
      return null;
    }

    RouteAccessRule? best;
    for (final rule in module.routeAccessRules) {
      if (!rule.matches(path)) {
        continue;
      }
      if (best == null || rule.specificity > best.specificity) {
        best = rule;
      }
    }
    if (best != null) {
      return best.anyOf;
    }
    if (module.requiredAnyPermissions.isEmpty) {
      return null;
    }
    return module.requiredAnyPermissions;
  }
}
