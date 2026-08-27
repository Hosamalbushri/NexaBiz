import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/settings/data_sync_settings_page.dart';
import '../../app/sync/app_sync_adapters.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/module_settings_definition.dart';
import '../authentication/presentation/pages/sync_login_page.dart';
import 'sync.dart';
import 'sync_module_settings.dart';

/// Sync module — encapsulates offline-first synchronization infrastructure.
class SyncModule extends AppModule {
  const SyncModule();

  static const String moduleId = 'sync';

  /// Self-registers SyncModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const SyncModule());
  }

  /// Self-unregisters SyncModule from the global ModuleRegistry.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleSync';

  @override
  IconData get icon => Icons.sync_outlined;

  @override
  String get rootRoute => AppRoutes.settingsDataSync;

  @override
  int get sortOrder => 90;

  @override
  bool get isEnabled => false;

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
        const SyncSettingsTileSection(),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: AppRoutes.settingsDataSync,
          name: 'settingsDataSync',
          builder: (context, state) => const DataSyncSettingsPage(),
          routes: [
            GoRoute(
              path: 'login',
              name: 'settingsDataSyncLogin',
              builder: (context, state) => const SyncLoginPage(),
            ),
          ],
        ),
      ];

  @override
  String label(BuildContext context) => 'المزامنة';

  @override
  String? description(BuildContext context) => 'مزامنة البيانات السحابية';

  @override
  List<Override> get providerOverrides => [
        localDatasetRecordCountersProvider.overrideWith((ref) => [
              AccountingRecordCounter(ref),
              InventoryRecordCounter(ref),
              CustomerRecordCounter(ref),
              SaleRecordCounter(ref),
              RpRecordCounter(ref),
            ]),
        initialCloudEntityScannersProvider.overrideWith((ref) => [
              AccountInitialCloudScanner(),
              CustomerInitialCloudScanner(),
              ProductInitialCloudScanner(),
              SaleInitialCloudScanner(),
              FinancialTransactionInitialCloudScanner(),
              JournalEntryInitialCloudScanner(),
            ]),
      ];
}
