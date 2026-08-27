import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/sales/accounting_sale_cogs_adapter.dart';
import '../../app/sales/perpetual_sale_inventory_effect_adapter.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/module_settings_definition.dart';
import '../../core/modules/quick_action_definition.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import '../../core/reporting/pdf_document_preview_page.dart';
import '../accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../accounting/journals/presentation/providers/journal_providers.dart';
import '../inventory/products/presentation/providers/product_providers.dart';
import 'invoices/presentation/pages/sale_details_page.dart';
import 'invoices/presentation/pages/sale_form_page.dart';
import 'invoices/presentation/pages/sales_home_page.dart';
import 'invoices/presentation/pages/sales_list_page.dart';
import 'invoices/presentation/providers/sale_providers.dart';
import 'permissions/sales_permission_package.dart';
import 'sales_module_quick_actions.dart';
import 'sales_module_settings.dart';
import 'shared/presentation/pages/sales_routes.dart';

/// Sales business module — operational sales documents (offline-first).
///
/// Customers and products are resolved via App-wired ports (modules ↛ modules).
class SalesModule extends AppModule {
  const SalesModule();

  static const String moduleId = 'sales';

  /// Self-registers SalesModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const SalesModule());
  }

  /// Self-unregisters SalesModule from the global ModuleRegistry.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleSales';

  @override
  IconData get icon => Icons.point_of_sale_outlined;

  @override
  String get rootRoute => SalesRoutes.root;

  @override
  int get sortOrder => 30;

  @override
  bool get isEnabled => true;

  @override
  List<String> get requiredAnyPermissions => SalesPermissions.view;

  @override
  List<RouteAccessRule> get routeAccessRules => [
        RouteAccessRule(
          pathEquals: SalesRoutes.create,
          anyOf: SalesPermissions.create,
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/sales/\d+/edit$'),
          anyOf: SalesPermissions.update,
        ),
        RouteAccessRule(
          pathPrefix: SalesRoutes.root,
          anyOf: SalesPermissions.view,
        ),
      ];

  @override
  PermissionPackageDef? get permissionPackage => salesPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleSales;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleSalesDescription;
  }

  @override
  List<QuickActionDefinition> get quickActions =>
      buildSalesQuickActions(moduleId);

  @override
  List<ModuleSettingsCategoryDefinition> get settingsCategories =>
      buildSalesSettingsCategories(moduleId);

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: SalesRoutes.root,
      name: 'sales',
      builder: (context, state) => const SalesHomePage(),
      routes: [
        GoRoute(
          path: 'list',
          name: 'salesList',
          builder: (context, state) => const SalesListPage(),
        ),
        GoRoute(
          path: 'create',
          name: 'salesCreate',
          builder: (context, state) => const SaleFormPage(),
        ),
        GoRoute(
          path: 'invoice-preview',
          name: 'salesInvoicePreview',
          builder: (context, state) => const PdfDocumentPreviewPage(),
        ),
        GoRoute(
          path: ':id',
          name: 'salesDetails',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return const SaleDetailsPage(saleId: -1);
            }
            return SaleDetailsPage(saleId: id);
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'salesEdit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) {
                  return const SaleFormPage(saleId: -1);
                }
                return SaleFormPage(saleId: id);
              },
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  List<Override> get providerOverrides => [
        saleInventoryEffectPortProvider.overrideWith((ref) {
          return PerpetualSaleInventoryEffectAdapter(
            stock: ref.watch(productStockServiceProvider),
            cogs: AccountingSaleCogsAdapter(
              posting: ref.watch(journalPostingServiceProvider),
              accounts: ref.watch(accountRepositoryProvider),
              stock: ref.watch(productStockServiceProvider),
            ),
          );
        }),
      ];
}
