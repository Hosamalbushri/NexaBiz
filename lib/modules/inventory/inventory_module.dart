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
import 'presentation/pages/product_form_page.dart';
import 'presentation/pages/products_barcode_page.dart';
import 'presentation/pages/products_home_page.dart';
import 'presentation/pages/products_import_page.dart';
import 'presentation/pages/products_list_page.dart';
import 'presentation/pages/stock_count_home_page.dart';

/// Inventory business module — self-contained routes and features.
///
/// Platform service: Inventory. Intra-module services: Stock count + Products.
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
            // Legacy flat paths → stock-count service.
            GoRoute(
              path: 'count',
              redirect: (context, state) => InventoryRoutes.count,
              routes: [
                GoRoute(
                  path: 'details',
                  redirect: (context, state) => InventoryRoutes.countDetails,
                ),
              ],
            ),
            GoRoute(
              path: 'import',
              redirect: (context, state) => InventoryRoutes.import,
            ),
            GoRoute(
              path: 'reports',
              redirect: (context, state) => InventoryRoutes.reports,
            ),
            GoRoute(
              path: 'stock-count',
              name: 'inventoryStockCount',
              builder: (context, state) => const StockCountHomePage(),
              routes: [
                GoRoute(
                  path: 'count',
                  name: 'inventoryStockCountSearch',
                  builder: (context, state) => const InventorySearchPage(),
                  routes: [
                    GoRoute(
                      path: 'details',
                      name: 'inventoryStockCountDetails',
                      builder: (context, state) => const InventoryCountPage(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'import',
                  name: 'inventoryStockCountImport',
                  builder: (context, state) => const InventoryImportPage(),
                ),
                GoRoute(
                  path: 'reports',
                  name: 'inventoryStockCountReports',
                  builder: (context, state) => const InventoryReportsPage(),
                ),
              ],
            ),
            GoRoute(
              path: 'products',
              name: 'inventoryProducts',
              builder: (context, state) => const ProductsHomePage(),
              routes: [
                GoRoute(
                  path: 'list',
                  name: 'inventoryProductsList',
                  builder: (context, state) => const ProductsListPage(),
                ),
                GoRoute(
                  path: 'new',
                  name: 'inventoryProductsNew',
                  builder: (context, state) => const ProductFormPage(),
                ),
                GoRoute(
                  path: 'import',
                  name: 'inventoryProductsImport',
                  builder: (context, state) => const ProductsImportPage(),
                ),
                GoRoute(
                  path: 'barcode',
                  name: 'inventoryProductsBarcode',
                  builder: (context, state) => ProductsBarcodePage(
                    autoScan: state.uri.queryParameters['scan'] == '1',
                  ),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: 'inventoryProductsEdit',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    if (id == null) {
                      return const ProductFormPage(productId: -1);
                    }
                    return ProductFormPage(productId: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ];
}
