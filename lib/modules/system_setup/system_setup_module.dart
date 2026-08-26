import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/permissions/permission_defs.dart';
import 'permissions/platform_permission_package.dart';
import 'presentation/pages/system_setup_routes.dart';

/// System settings / initialization module.
///
/// Shown on the services launcher; first-launch also enters via splash gate.
/// The wizard route is registered on the App shell navigator (same level as
/// other modules). Launchers use [GoRouter.go] so the route replaces the
/// shell branch instead of stacking over [StatefulShellRoute].
class SystemSetupModule extends AppModule {
  const SystemSetupModule();

  static const String moduleId = 'system_setup';

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleSystemSetup';

  @override
  IconData get icon => Icons.settings_suggest_outlined;

  @override
  String get rootRoute => SystemSetupRoutes.root;

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
