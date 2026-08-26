import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/sync/sync_settings_section.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/module_settings_definition.dart';
import 'sync_module_settings.dart';

/// Sync module — encapsulates offline-first synchronization infrastructure.
class SyncModule extends AppModule {
  const SyncModule();

  static const String moduleId = 'sync';

  /// Self-registers SyncModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const SyncModule());
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleSync';

  @override
  IconData get icon => Icons.sync_outlined;

  @override
  String get rootRoute => '/sync';

  @override
  int get sortOrder => 90;

  @override
  bool get isEnabled => true;

  @override
  bool get showInLauncher => false;

  @override
  List<String> get requiredAnyPermissions => const ['sync.view', 'sync.execute'];

  @override
  bool get hasSettings => true;

  @override
  List<ModuleSettingsCategoryDefinition> get settingsCategories =>
      buildSyncSettingsCategories(moduleId);

  @override
  List<Widget> buildSettingsSections(BuildContext context) => [
        const SyncSettingsSection(),
      ];

  @override
  List<RouteBase> get routes => const [];

  @override
  String label(BuildContext context) => 'المزامنة';

  @override
  String? description(BuildContext context) => 'مزامنة البيانات السحابية';
}
