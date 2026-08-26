import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/quick_action_definition.dart';
import '../../core/modules/report_category_definition.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import '../../core/reporting/pdf_document_preview_page.dart';
import 'permissions/sales_permission_package.dart';
import 'presentation/pages/sale_details_page.dart';
import 'presentation/pages/sale_form_page.dart';
import 'presentation/pages/sales_home_page.dart';
import 'presentation/pages/sales_list_page.dart';
import 'presentation/pages/sales_routes.dart';

/// Sales business module — operational sales documents (offline-first).
///
/// Customers and products are resolved via App-wired ports (modules ↛ modules).
class SalesModule extends AppModule {
  const SalesModule();

  static const String moduleId = 'sales';

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleSales';

  @override
  IconData get icon => Icons.point_of_sale_outlined;

  @override
  String get rootRoute => SalesRoutes.root;

  @override
  int get sortOrder => 10;

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
  List<QuickActionDefinition> get quickActions => [
        QuickActionDefinition(
          id: 'create_sale',
          icon: Icons.receipt_long_outlined,
          kind: QuickActionKind.route,
          routePath: SalesRoutes.create,
          titleBuilder: (l10n) => l10n.salesCreateTitle,
          subtitleBuilder: (l10n) => l10n.salesCreateCardSubtitle,
          requiredPermissions: const ['sales.documents.create', 'sales.create'],
        ),
      ];

  @override
  List<ReportCategoryDefinition> get reportCategories => [
        ReportCategoryDefinition(
          id: 'sales_reports',
          moduleId: moduleId,
          icon: Icons.point_of_sale_outlined,
          titleBuilder: (l10n) => l10n.moduleSales,
          subtitleBuilder: (l10n) => l10n.moduleSalesDescription,
          reports: [
            ReportItemDefinition(
              id: 'reports_sales_period',
              moduleId: moduleId,
              icon: Icons.receipt_long_outlined,
              path: '/reports/sales-period',
              titleBuilder: (l10n) => l10n.reportsSalesPeriodTitle,
              subtitleBuilder: (l10n) => l10n.reportsSalesPeriodSubtitle,
            ),
          ],
        ),
      ];

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
}
