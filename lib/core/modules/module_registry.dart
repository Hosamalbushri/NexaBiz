import 'package:go_router/go_router.dart';

import '../permissions/permission_defs.dart';
import 'app_module.dart';
import 'module_settings_definition.dart';
import 'quick_action_definition.dart';
import 'report_category_definition.dart';
import 'route_access_rule.dart';

/// Holds the ordered list of registered [AppModule] instances.
///
/// Supports self-registration via [register] / [registeredModules] or explicit injection.
class ModuleRegistry {
  ModuleRegistry([List<AppModule>? modules])
      : _modules = List<AppModule>.unmodifiable(
          List<AppModule>.from(modules ?? registeredModules)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        );

  static final List<AppModule> _catalog = [];

  /// Dynamically register a module into the global catalog (Self-Registration pattern).
  static void register(AppModule module) {
    final index = _catalog.indexWhere((m) => m.id == module.id);
    if (index >= 0) {
      _catalog[index] = module;
    } else {
      _catalog.add(module);
    }
  }

  /// Dynamically register multiple modules at once.
  static void registerAll(List<AppModule> modules) {
    for (final m in modules) {
      register(m);
    }
  }

  /// Dynamically unregister/disable a module by id from the global catalog (Self-Unregistration).
  static void unregister(String id) {
    _catalog.removeWhere((m) => m.id == id);
  }

  /// Dynamically unregister a module instance from the global catalog.
  static void unregisterModule(AppModule module) {
    unregister(module.id);
  }

  /// Clear the self-registration catalog (useful for testing or profile switches).
  static void clearCatalog() {
    _catalog.clear();
  }

  /// Returns all self-registered modules sorted by [AppModule.sortOrder].
  static List<AppModule> get registeredModules {
    final list = List<AppModule>.from(_catalog);
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(list);
  }

  final List<AppModule> _modules;

  /// All registered modules (including disabled).
  List<AppModule> get modules => _modules;

  /// Modules shown on the Service Launcher / Dashboard grids, sorted by [AppModule.sortOrder].
  List<AppModule> get enabledModules {
    final list = [
      for (final module in _modules)
        if (module.isEnabled && module.showInLauncher) module,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(list);
  }

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

  /// All quick actions contributed by enabled modules.
  List<QuickActionDefinition> get allQuickActions {
    return [
      for (final module in enabledModules) ...module.quickActions,
    ];
  }

  /// Find a quick action definition across all registered modules by id.
  QuickActionDefinition? findQuickActionById(String id) {
    for (final action in allQuickActions) {
      if (action.id == id) {
        return action;
      }
    }
    return null;
  }

  /// All report categories contributed by enabled modules.
  List<ReportCategoryDefinition> get allReportCategories {
    return [
      for (final module in enabledModules) ...module.reportCategories,
    ];
  }

  /// All settings categories contributed by enabled modules, sorted by [AppModule.sortOrder].
  List<ModuleSettingsCategoryDefinition> get allSettingsCategories {
    final list = <ModuleSettingsCategoryDefinition>[];
    for (final module in enabledModules) {
      list.addAll(module.settingsCategories);
    }
    list.sort((a, b) {
      final moduleA = findById(a.moduleId);
      final moduleB = findById(b.moduleId);
      final sortA = moduleA?.sortOrder ?? a.sortOrder;
      final sortB = moduleB?.sortOrder ?? b.sortOrder;
      if (sortA != sortB) {
        return sortA.compareTo(sortB);
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return List.unmodifiable(list);
  }

  /// Check if a module is registered by id in this registry instance.
  bool isRegistered(String id) => findById(id) != null;

  /// Check if a module is in the global self-registration catalog.
  static bool isModuleRegistered(String id) =>
      _catalog.any((m) => m.id == id);

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
