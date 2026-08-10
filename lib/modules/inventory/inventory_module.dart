import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import 'presentation/pages/inventory_count_page.dart';
import 'presentation/pages/inventory_home_page.dart';
import 'presentation/pages/inventory_import_page.dart';
import 'presentation/pages/inventory_reports_page.dart';
import 'presentation/pages/inventory_routes.dart';
import 'presentation/pages/inventory_search_page.dart';

/// Inventory business module — self-contained routes and features.
class InventoryModule implements AppModule {
  const InventoryModule();

  static const String moduleId = 'inventory';

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleInventory';

  @override
  IconData get icon => Icons.inventory_2_outlined;

  @override
  String get rootRoute => InventoryRoutes.root;

  @override
  bool get isEnabled => true;

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleInventory;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleInventoryDescription;
  }

  @override
  List<Override> get providerOverrides => const [];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: InventoryRoutes.root,
          name: 'inventory',
          builder: (context, state) => const InventoryHomePage(),
          routes: [
            GoRoute(
              path: 'count',
              name: 'inventoryCount',
              builder: (context, state) => const InventorySearchPage(),
              routes: [
                GoRoute(
                  path: 'details',
                  name: 'inventoryCountDetails',
                  builder: (context, state) => const InventoryCountPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'import',
              name: 'inventoryImport',
              builder: (context, state) => const InventoryImportPage(),
            ),
            GoRoute(
              path: 'reports',
              name: 'inventoryReports',
              builder: (context, state) => const InventoryReportsPage(),
            ),
          ],
        ),
      ];
}
