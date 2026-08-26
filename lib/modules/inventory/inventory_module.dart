import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/quick_action_definition.dart';
import '../../core/modules/report_category_definition.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import '../../core/reporting/pdf_document_preview_page.dart';
import 'permissions/inventory_permission_package.dart';
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
class InventoryModule extends AppModule {
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
  int get sortOrder => 30;

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
  List<QuickActionDefinition> get quickActions => [
        QuickActionDefinition(
          id: 'scan_barcode',
          icon: Icons.qr_code_scanner_outlined,
          kind: QuickActionKind.route,
          routePath: '/inventory/products/barcode?scan=1',
          titleBuilder: (l10n) => l10n.quickActionsScanBarcode,
          subtitleBuilder: (l10n) => l10n.quickActionsScanBarcodeSubtitle,
          requiredPermissions: const [
            'inventory.products.barcode',
            'inventory.products.view',
            'products.view',
          ],
        ),
        QuickActionDefinition(
          id: 'create_product',
          icon: Icons.add_box_outlined,
          kind: QuickActionKind.route,
          routePath: InventoryRoutes.productsNew,
          titleBuilder: (l10n) => l10n.quickActionsCreateProduct,
          subtitleBuilder: (l10n) => l10n.quickActionsCreateProductSubtitle,
          requiredPermissions: const ['inventory.products.create', 'products.create'],
        ),
        QuickActionDefinition(
          id: 'products_list',
          icon: Icons.list_alt_outlined,
          kind: QuickActionKind.route,
          routePath: InventoryRoutes.productsList,
          titleBuilder: (l10n) => l10n.productsListTitle,
          subtitleBuilder: (l10n) => l10n.productsListSubtitle,
          requiredPermissions: const ['inventory.products.view', 'products.view'],
        ),
        QuickActionDefinition(
          id: 'products_barcode',
          icon: Icons.qr_code_2_outlined,
          kind: QuickActionKind.route,
          routePath: InventoryRoutes.productsBarcode,
          titleBuilder: (l10n) => l10n.productsBarcodeTitle,
          subtitleBuilder: (l10n) => l10n.productsBarcodeSubtitle,
          requiredPermissions: const [
            'inventory.products.barcode',
            'inventory.products.view',
            'products.view',
          ],
        ),
        QuickActionDefinition(
          id: 'products_import',
          icon: Icons.upload_file_outlined,
          kind: QuickActionKind.route,
          routePath: InventoryRoutes.productsImport,
          titleBuilder: (l10n) => l10n.productsImportTitle,
          subtitleBuilder: (l10n) => l10n.productsImportSubtitle,
          requiredPermissions: const ['inventory.products.import', 'products.create'],
        ),
        QuickActionDefinition(
          id: 'stock_count',
          icon: Icons.fact_check_outlined,
          kind: QuickActionKind.route,
          routePath: InventoryRoutes.count,
          titleBuilder: (l10n) => l10n.inventoryCountTitle,
          subtitleBuilder: (l10n) => l10n.inventoryCountSubtitle,
          requiredPermissions: const ['inventory.stock_count.view', 'inventory.view'],
        ),
        QuickActionDefinition(
          id: 'stock_import',
          icon: Icons.file_upload_outlined,
          kind: QuickActionKind.route,
          routePath: InventoryRoutes.import,
          titleBuilder: (l10n) => l10n.importPageTitle,
          subtitleBuilder: (l10n) => l10n.inventoryStockCountServiceDescription,
          requiredPermissions: const ['inventory.stock_count.import', 'inventory.create'],
        ),
        QuickActionDefinition(
          id: 'stock_reports',
          icon: Icons.assessment_outlined,
          kind: QuickActionKind.route,
          routePath: InventoryRoutes.reports,
          titleBuilder: (l10n) => l10n.reportsTitle,
          subtitleBuilder: (l10n) => l10n.inventoryStockCountServiceDescription,
          requiredPermissions: const ['inventory.stock_count.export', 'inventory.view'],
        ),
      ];

  @override
  List<ReportCategoryDefinition> get reportCategories => [
        ReportCategoryDefinition(
          id: 'inventory_reports',
          moduleId: moduleId,
          icon: Icons.inventory_2_outlined,
          titleBuilder: (l10n) => l10n.platformReportsInventory,
          subtitleBuilder: (l10n) => l10n.platformReportsInventorySubtitle,
          reports: [
            ReportItemDefinition(
              id: 'inventory_stock_count',
              moduleId: moduleId,
              icon: Icons.fact_check_outlined,
              path: InventoryRoutes.reports,
              titleBuilder: (l10n) => l10n.platformReportsStockCountTitle,
              subtitleBuilder: (l10n) => l10n.platformReportsStockCountSubtitle,
            ),
            ReportItemDefinition(
              id: 'inventory_products',
              moduleId: moduleId,
              icon: Icons.inventory_2_outlined,
              path: null,
              titleBuilder: (l10n) => l10n.platformReportsProductsTitle,
              subtitleBuilder: (l10n) => l10n.platformReportsServiceComingSoon,
            ),
          ],
        ),
      ];

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
            GoRoute(
              path: 'report-preview',
              name: 'inventoryStockCountReportPreview',
              builder: (context, state) => const PdfDocumentPreviewPage(),
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
