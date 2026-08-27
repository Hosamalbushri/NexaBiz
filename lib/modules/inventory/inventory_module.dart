import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/sales/inventory_sale_product_catalog_adapter.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/module_settings_definition.dart';
import '../../core/modules/quick_action_definition.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import '../../core/reporting/pdf_document_preview_page.dart';
import '../sales/invoices/presentation/providers/sale_barcode_capture_provider.dart';
import '../sales/invoices/presentation/providers/sale_providers.dart';
import 'inventory_module_quick_actions.dart';
import 'inventory_module_settings.dart';
import 'permissions/inventory_permission_package.dart';
import 'products/presentation/pages/product_barcode_scanner_page.dart';
import 'products/presentation/pages/product_form_page.dart';
import 'products/presentation/pages/products_barcode_page.dart';
import 'products/presentation/pages/products_home_page.dart';
import 'products/presentation/pages/products_import_page.dart';
import 'products/presentation/pages/products_list_page.dart';
import 'products/presentation/pages/products_settings_page.dart';
import 'products/presentation/providers/product_providers.dart';
import 'shared/presentation/pages/inventory_home_page.dart';
import 'shared/presentation/pages/inventory_routes.dart';
import 'stock_count/presentation/pages/inventory_count_page.dart';
import 'stock_count/presentation/pages/inventory_import_page.dart';
import 'stock_count/presentation/pages/inventory_reports_page.dart';
import 'stock_count/presentation/pages/inventory_search_page.dart';
import 'stock_count/presentation/pages/stock_count_home_page.dart';
import 'stock_count/presentation/pages/stock_count_settings_page.dart';

/// Inventory business module — self-contained routes and features.
///
/// Platform service: Inventory. Intra-module services: Stock count + Products.
class InventoryModule extends AppModule {
  const InventoryModule();

  static const String moduleId = 'inventory';

  /// Self-registers InventoryModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const InventoryModule());
  }

  /// Self-unregisters InventoryModule from the global ModuleRegistry.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleInventory';

  @override
  IconData get icon => Icons.inventory_2_outlined;

  @override
  String get rootRoute => InventoryRoutes.root;

  @override
  int get sortOrder => 50;

  @override
  bool get isEnabled => true;

  @override
  List<String> get requiredAnyPermissions => const [
        ...InventoryPermissions.stockView,
        ...InventoryPermissions.productsView,
      ];

  @override
  List<RouteAccessRule> get routeAccessRules => [
        RouteAccessRule(
          pathEquals: InventoryRoutes.productsNew,
          anyOf: InventoryPermissions.productsCreate,
        ),
        RouteAccessRule(
          pathEquals: InventoryRoutes.productsImport,
          anyOf: InventoryPermissions.productsImport,
        ),
        RouteAccessRule(
          pathEquals: InventoryRoutes.productsBarcode,
          anyOf: InventoryPermissions.productsBarcode,
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/inventory/products/\d+/edit$'),
          anyOf: InventoryPermissions.productsUpdate,
        ),
        RouteAccessRule(
          pathPrefix: InventoryRoutes.products,
          anyOf: InventoryPermissions.productsView,
        ),
        RouteAccessRule(
          pathEquals: InventoryRoutes.import,
          anyOf: InventoryPermissions.stockImport,
        ),
        RouteAccessRule(
          pathEquals: InventoryRoutes.reports,
          anyOf: InventoryPermissions.stockExport,
        ),
        RouteAccessRule(
          pathEquals: InventoryRoutes.reportPreview,
          anyOf: InventoryPermissions.stockExport,
        ),
        RouteAccessRule(
          pathPrefix: InventoryRoutes.count,
          anyOf: InventoryPermissions.stockAdjust,
        ),
        RouteAccessRule(
          pathPrefix: InventoryRoutes.stockCount,
          anyOf: InventoryPermissions.stockView,
        ),
        RouteAccessRule(
          pathPrefix: InventoryRoutes.root,
          anyOf: const [
            ...InventoryPermissions.stockView,
            ...InventoryPermissions.productsView,
          ],
        ),
      ];

  @override
  PermissionPackageDef? get permissionPackage => inventoryPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleInventory;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleInventoryDescription;
  }

  @override
  List<QuickActionDefinition> get quickActions =>
      buildInventoryQuickActions(moduleId);

  @override
  List<ModuleSettingsCategoryDefinition> get settingsCategories =>
      buildInventorySettingsCategories(moduleId);

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
            GoRoute(
              path: 'report-preview',
              name: 'inventoryStockCountReportPreview',
              builder: (context, state) => const PdfDocumentPreviewPage(),
            ),
            GoRoute(
              path: 'settings',
              name: 'inventoryStockCountSettings',
              builder: (context, state) => const StockCountSettingsPage(),
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
              path: 'settings',
              name: 'inventoryProductsSettings',
              builder: (context, state) => const ProductsSettingsPage(),
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

  @override
  List<Override> get providerOverrides => [
        saleProductCatalogPortProvider.overrideWith((ref) {
          return InventorySaleProductCatalogAdapter(
            repository: ref.watch(productRepositoryProvider),
            scanResolver: ref.watch(productScanResolverProvider),
          );
        }),
        saleBarcodeCaptureProvider.overrideWithValue(
          (context) => ProductBarcodeScannerPage.open(context),
        ),
      ];
}
