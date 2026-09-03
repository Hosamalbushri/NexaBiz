import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/presentation/providers/dashboard_services_provider.dart';
import '../../app/receipts_payments/customers_rp_lookup_adapter.dart';
import '../../app/sales/customers_sale_lookup_adapter.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/module_settings_definition.dart';
import '../../core/modules/quick_action_definition.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import '../receipts_payments/transactions/presentation/providers/rp_providers.dart';
import '../sales/invoices/presentation/providers/sale_providers.dart';
import '../../core/setup/setup.dart';
import 'accounts/presentation/pages/customers_accounts_page.dart';
import 'customers_module_quick_actions.dart';
import 'customers_module_settings.dart';
import 'customers_module_setup.dart';
import 'directory/presentation/pages/customer_details_page.dart';
import 'directory/presentation/pages/customer_form_page.dart';
import 'directory/presentation/pages/customers_home_page.dart';
import 'directory/presentation/pages/customers_import_page.dart';
import 'directory/presentation/pages/customers_list_page.dart';
import 'directory/presentation/providers/customer_providers.dart';
import 'permissions/customers_permission_package.dart';
import 'shared/presentation/pages/customers_routes.dart';
import 'shared/presentation/pages/customers_settings_page.dart';
import 'shared/presentation/widgets/customers_settings_panel.dart';

/// Customers business module — master data for business partners.
///
/// Links to Chart of Accounts via opaque [Customer.accountId] (Account.uuid);
/// App wires [CustomerAccountLinkPort] to Accounting without module imports.
class CustomersModule extends AppModule {
  const CustomersModule();

  static const String moduleId = 'customers';

  /// Self-registers CustomersModule into the global ModuleRegistry via injection.
  /// Optionally registers customers setup definition if [setupRegistry] is provided.
  static void register({CentralSetupRegistry? setupRegistry}) {
    ModuleRegistry.register(const CustomersModule());
    if (setupRegistry != null) {
      registerCustomersSetup(setupRegistry);
    }
  }

  /// Self-unregisters CustomersModule from the global ModuleRegistry.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleCustomers';

  @override
  IconData get icon => Icons.people_outline;

  @override
  String get rootRoute => CustomersRoutes.root;

  @override
  int get sortOrder => 20;

  @override
  bool get isEnabled => true;


  @override
  List<String> get requiredAnyPermissions => CustomersPermissions.view;

  @override
  List<RouteAccessRule> get routeAccessRules => [
        RouteAccessRule(
          pathEquals: CustomersRoutes.create,
          anyOf: CustomersPermissions.create,
        ),
        RouteAccessRule(
          pathEquals: CustomersRoutes.importPath,
          anyOf: CustomersPermissions.importOp,
        ),
        RouteAccessRule(
          pathEquals: CustomersRoutes.accounts,
          anyOf: CustomersPermissions.accountsView,
        ),
        RouteAccessRule(
          pathPrefix: CustomersRoutes.settings,
          anyOf: CustomersPermissions.settingsView,
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/customers/\d+/edit$'),
          anyOf: CustomersPermissions.update,
        ),
        RouteAccessRule(
          pathPrefix: CustomersRoutes.root,
          anyOf: CustomersPermissions.view,
        ),
      ];

  @override
  PermissionPackageDef? get permissionPackage => customersPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleCustomers;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleCustomersDescription;
  }

  @override
  List<QuickActionDefinition> get quickActions =>
      buildCustomersQuickActions(moduleId);

  @override
  List<ModuleSettingsCategoryDefinition> get settingsCategories =>
      buildCustomersSettingsCategories(moduleId);

  @override
  bool get hasSettings => true;

  @override
  List<Widget> buildSettingsSections(BuildContext context) {
    return const [CustomersSettingsPanel()];
  }

  @override
  void onSettingsReset(WidgetRef ref) {
    ref.invalidate(customersParentAccountProvider);
    ref.invalidate(customersAutoLinkAccountProvider);
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: CustomersRoutes.root,
      name: 'customers',
      builder: (context, state) => const CustomersHomePage(),
      routes: [
        GoRoute(
          path: 'list',
          name: 'customersList',
          builder: (context, state) => const CustomersListPage(),
        ),
        GoRoute(
          path: 'accounts',
          name: 'customersAccounts',
          builder: (context, state) => const CustomersAccountsPage(),
        ),
        GoRoute(
          path: 'import',
          name: 'customersImport',
          builder: (context, state) => const CustomersImportPage(),
        ),
        GoRoute(
          path: 'settings',
          name: 'customersSettings',
          builder: (context, state) => const CustomersSettingsPage(),
          routes: [
            GoRoute(
              path: 'parent-account',
              name: 'customersParentAccountSettings',
              builder: (context, state) =>
                  const CustomersParentAccountSettingsPage(),
            ),
          ],
        ),
        GoRoute(
          path: 'new',
          name: 'customersCreate',
          builder: (context, state) => const CustomerFormPage(),
        ),
        GoRoute(
          path: ':id',
          name: 'customersDetails',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return const CustomerDetailsPage(customerId: -1);
            }
            return CustomerDetailsPage(customerId: id);
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'customersEdit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) {
                  return const CustomerFormPage(customerId: -1);
                }
                return CustomerFormPage(customerId: id);
              },
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  List<Override> get providerOverrides => [
        saleCustomerLookupPortProvider.overrideWith((ref) {
          return CustomersSaleLookupAdapter(
            repository: ref.watch(customerRepositoryProvider),
            accountLinkPort: ref.watch(customerAccountLinkPortProvider),
            settings: ref.watch(settingsRepositoryProvider),
          );
        }),
        rpCustomerLookupPortProvider.overrideWith((ref) {
          return CustomersRpLookupAdapter(
            repository: ref.watch(customerRepositoryProvider),
            accountLinkPort: ref.watch(customerAccountLinkPortProvider),
            settings: ref.watch(settingsRepositoryProvider),
          );
        }),
      ];
}
