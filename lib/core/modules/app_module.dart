import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../permissions/permission_defs.dart';
import 'route_access_rule.dart';

/// Base contract every business module must extend.
///
/// Prefer `extends AppModule` (not `implements`) so default settings / enable
/// hooks are inherited. The application shell depends only on this abstraction—
/// never on concrete module types.
abstract class AppModule {
  const AppModule();

  /// Stable unique identifier (e.g. `inventory`).
  String get id;

  /// Localization / analytics key (not shown directly in UI).
  String get nameKey;

  /// Icon shown on the service launcher card.
  IconData get icon;

  /// Root path contributed by this module (e.g. `/inventory`).
  String get rootRoute;

  /// Whether the module is available in the launcher.
  bool get isEnabled => true;

  /// Whether the module appears on Dashboard / Services grids.
  ///
  /// Defaults to [isEnabled]. Infrastructure modules (e.g. System Setup) can
  /// keep routes enabled while staying off the launcher.
  bool get showInLauncher => isEnabled;

  /// Permission codes that grant launcher visibility (any-of).
  ///
  /// Empty means always visible when the module is enabled (local offline mode
  /// uses a full-permission snapshot). Prefer codes like `sales.view`.
  ///
  /// Tip: derive from [permissionPackage] view operations when possible.
  List<String> get requiredAnyPermissions => const [];

  /// Path-level permission rules for GoRouter redirects.
  ///
  /// When empty, any path under [rootRoute] uses [requiredAnyPermissions].
  /// More specific rules (create/edit/import) should be listed here; the
  /// router picks the highest-specificity match.
  List<RouteAccessRule> get routeAccessRules => const [];

  /// Optional RBAC package contributed to Administration (Package → Service → Op).
  ///
  /// Return `null` when the module has no permission surface. Registering or
  /// unregistering the module in [ModuleRegistry] adds/removes this package
  /// from role editors automatically.
  PermissionPackageDef? get permissionPackage => null;

  /// Localized display name for UI surfaces.
  String label(BuildContext context);

  /// Optional short description for the launcher card.
  String? description(BuildContext context) => null;

  /// Routes owned by this module. Composed by the app router.
  List<RouteBase> get routes;

  /// Optional Riverpod overrides contributed at module bootstrap.
  List<Override> get providerOverrides => const [];

  /// Module-owned settings blocks for the platform Settings screen.
  ///
  /// Keep empty when the module has no settings. The App page never imports
  /// concrete module settings widgets — only this contract.
  List<Widget> buildSettingsSections(BuildContext context) => const [];

  /// Whether [buildSettingsSections] contributes anything.
  bool get hasSettings => false;

  /// Invalidate module settings state after a platform settings reset.
  void onSettingsReset(WidgetRef ref) {}
}
