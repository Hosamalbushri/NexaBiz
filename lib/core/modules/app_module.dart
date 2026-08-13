import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
