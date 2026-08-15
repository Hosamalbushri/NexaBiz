import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import 'presentation/pages/customer_details_page.dart';
import 'presentation/pages/customer_form_page.dart';
import 'presentation/pages/customers_accounts_page.dart';
import 'presentation/pages/customers_home_page.dart';
import 'presentation/pages/customers_import_page.dart';
import 'presentation/pages/customers_list_page.dart';
import 'presentation/pages/customers_routes.dart';
import 'presentation/pages/customers_settings_page.dart';
import 'presentation/providers/customer_providers.dart';
import 'presentation/widgets/customers_settings_panel.dart';

/// Customers business module — master data for business partners.
///
/// Links to Chart of Accounts via opaque [Customer.accountId] (Account.uuid);
/// App wires [CustomerAccountLinkPort] to Accounting without module imports.
class CustomersModule extends AppModule {
  const CustomersModule();

  static const String moduleId = 'customers';

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleCustomers';

  @override
  IconData get icon => Icons.people_outline;

  @override
  String get rootRoute => CustomersRoutes.root;

  @override
  bool get isEnabled => true;

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleCustomers;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleCustomersDescription;
  }

  @override
  List<Override> get providerOverrides => const [];

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
}
