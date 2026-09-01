import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/router/app_routes.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/permissions/permission_defs.dart';
import 'permissions/platform_permission_package.dart';

/// System settings / initialization module.
///
/// Shown on the services launcher; opens platform settings.
class SystemSetupModule extends AppModule {
  const SystemSetupModule();

  static const String moduleId = 'system_setup';

  /// Self-registers SystemSetupModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const SystemSetupModule());
  }

  /// Self-unregisters SystemSetupModule from the global ModuleRegistry.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleSystemSetup';

  @override
  IconData get icon => Icons.settings_suggest_outlined;

  @override
  String get rootRoute => AppRoutes.settingsSetup;

  @override
  int get sortOrder => 80;

  @override
  bool get isEnabled => true;

  @override
  bool get showInLauncher => true;

  @override
  PermissionPackageDef? get permissionPackage => platformPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleSystemSetup;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleSystemSetupDescription;
  }

  /// Routes are owned by App router (shell navigator).
  @override
  List<RouteBase> get routes => const [];
}
