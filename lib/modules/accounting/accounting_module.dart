import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import 'permissions/accounting_permission_package.dart';
import 'domain/entities/voucher_book_type.dart';
import 'presentation/pages/account_details_page.dart';
import 'presentation/pages/account_form_page.dart';
import 'presentation/pages/accounts_opening_setup_page.dart';
import 'presentation/pages/accounting_home_page.dart';
import 'presentation/pages/accounting_reports_page.dart';
import 'presentation/pages/accounting_routes.dart';
import 'presentation/pages/chart_of_accounts_page.dart';
import 'presentation/pages/currency_rates_page.dart';
import 'presentation/pages/fiscal_year_create_page.dart';
import 'presentation/pages/fiscal_year_details_page.dart';
import 'presentation/pages/fiscal_years_page.dart';
import 'presentation/pages/journal_entries_page.dart';
import 'presentation/pages/journal_entry_details_page.dart';
import 'presentation/pages/journal_entry_form_page.dart';
import 'presentation/pages/voucher_book_form_page.dart';
import 'presentation/pages/voucher_book_section_page.dart';
import 'presentation/pages/voucher_books_page.dart';
import 'presentation/providers/journal_providers.dart';
import 'presentation/widgets/accounting_settings_panel.dart';

/// Accounting business module — COA, journals, rates, voucher books.
class AccountingModule extends AppModule {
  const AccountingModule();

  static const String moduleId = 'accounting';

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleAccounting';

  @override
  IconData get icon => Icons.account_balance_outlined;

  @override
  String get rootRoute => AccountingRoutes.root;

  @override
  bool get isEnabled => true;

  @override
  List<String> get requiredAnyPermissions => const [
        'accounting.view',
        'accounting.accounts.view',
        'accounting.journals.view',
      ];

  @override
  List<RouteAccessRule> get routeAccessRules => [
        RouteAccessRule(
          pathEquals: AccountingRoutes.accountsCreate,
          anyOf: const ['accounting.accounts.create'],
        ),
        RouteAccessRule(
          pathEquals: AccountingRoutes.accountsImport,
          anyOf: const ['accounting.accounts.create'],
        ),
        RouteAccessRule(
          pathEquals: AccountingRoutes.openingSetup,
          anyOf: const [
            'accounting.accounts.create',
            'accounting.journals.create',
          ],
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/accounting/accounts/\d+/edit$'),
          anyOf: const ['accounting.accounts.update'],
        ),
        RouteAccessRule(
          pathEquals: AccountingRoutes.journalsCreate,
          anyOf: const ['accounting.journals.create'],
        ),
        RouteAccessRule(
          pathEquals: AccountingRoutes.fiscalYearsCreate,
          anyOf: const ['accounting.fiscal_years.create'],
        ),
        RouteAccessRule(
          pathPrefix: AccountingRoutes.fiscalYears,
          anyOf: const [
            'accounting.fiscal_years.view',
            'accounting.fiscal_years.create',
            'accounting.fiscal_years.update',
          ],
        ),
        RouteAccessRule(
          pathRegex: RegExp(r'^/accounting/journals/[^/]+/edit$'),
          anyOf: const ['accounting.journals.update'],
        ),
        RouteAccessRule(
          pathPrefix: AccountingRoutes.root,
          anyOf: requiredAnyPermissions,
        ),
      ];

  @override
  PermissionPackageDef? get permissionPackage => accountingPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleAccounting;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleAccountingDescription;
  }

  @override
  List<Override> get providerOverrides => const [];

  @override
  bool get hasSettings => true;

  @override
  List<Widget> buildSettingsSections(BuildContext context) {
    return const [AccountingSettingsPanel()];
  }

  @override
  void onSettingsReset(WidgetRef ref) {
    ref.invalidate(accountingFiscalClosedThroughProvider);
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: AccountingRoutes.root,
      name: 'accounting',
      builder: (context, state) => const AccountingHomePage(),
      routes: [
        GoRoute(
          path: 'opening-setup',
          name: 'accountingOpeningSetup',
          builder: (context, state) => const AccountsOpeningSetupPage(),
        ),
        GoRoute(
          path: 'currency-rates',
          name: 'accountingCurrencyRates',
          builder: (context, state) => const CurrencyRatesPage(),
        ),
        GoRoute(
          path: 'fiscal-years',
          name: 'accountingFiscalYears',
          builder: (context, state) => const FiscalYearsPage(),
          routes: [
            GoRoute(
              path: 'new',
              name: 'accountingFiscalYearsCreate',
              builder: (context, state) => const FiscalYearCreatePage(),
            ),
            GoRoute(
              path: ':uuid',
              name: 'accountingFiscalYearDetails',
              builder: (context, state) {
                final uuid = state.pathParameters['uuid'] ?? '';
                return FiscalYearDetailsPage(fiscalYearUuid: uuid);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'reports',
          name: 'accountingReports',
          builder: (context, state) => const AccountingReportsPage(),
        ),
        GoRoute(
          path: 'journals',
          name: 'accountingJournals',
          builder: (context, state) => const JournalEntriesPage(),
          routes: [
            GoRoute(
              path: 'new',
              name: 'accountingJournalsCreate',
              builder: (context, state) => const JournalEntryFormPage(),
            ),
            GoRoute(
              path: ':uuid',
              name: 'accountingJournalDetails',
              builder: (context, state) {
                final uuid = state.pathParameters['uuid'] ?? '';
                return JournalEntryDetailsPage(entryUuid: uuid);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'accountingJournalEdit',
                  builder: (context, state) {
                    final uuid = state.pathParameters['uuid'] ?? '';
                    return JournalEntryFormPage(entryUuid: uuid);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'voucher-books',
          name: 'accountingVoucherBooks',
          builder: (context, state) => const VoucherBooksPage(),
          routes: [
            GoRoute(
              path: 'new',
              name: 'accountingVoucherBooksCreate',
              builder: (context, state) {
                final parentId = state.uri.queryParameters['parentId'];
                final bookTypeRaw = state.uri.queryParameters['bookType'];
                VoucherBookType? bookType;
                if (bookTypeRaw != null && bookTypeRaw.isNotEmpty) {
                  try {
                    bookType = VoucherBookType.fromStorage(bookTypeRaw);
                  } catch (_) {
                    bookType = null;
                  }
                }
                return VoucherBookFormPage(
                  initialParentId: parentId,
                  initialBookType: bookType,
                );
              },
            ),
            GoRoute(
              path: 'section/:sectionType',
              name: 'accountingVoucherBookSection',
              builder: (context, state) {
                final raw = state.pathParameters['sectionType'] ?? 'sales';
                late final VoucherBookType section;
                try {
                  section = VoucherBookType.fromStorage(raw).section;
                } catch (_) {
                  section = VoucherBookType.sales;
                }
                return VoucherBookSectionPage(section: section);
              },
              routes: [
                GoRoute(
                  path: 'kind/:kindType',
                  name: 'accountingVoucherBookKind',
                  builder: (context, state) {
                    final sectionRaw =
                        state.pathParameters['sectionType'] ?? 'sales';
                    final kindRaw = state.pathParameters['kindType'] ?? 'sales';
                    late final VoucherBookType section;
                    late final VoucherBookType kind;
                    try {
                      section = VoucherBookType.fromStorage(sectionRaw).section;
                    } catch (_) {
                      section = VoucherBookType.sales;
                    }
                    try {
                      kind = VoucherBookType.fromStorage(kindRaw);
                    } catch (_) {
                      kind = VoucherBookType.leafKindsFor(section).first;
                    }
                    return VoucherBookKindPage(section: section, kind: kind);
                  },
                ),
              ],
            ),
            GoRoute(
              path: ':id/edit',
              name: 'accountingVoucherBooksEdit',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) {
                  return const VoucherBookFormPage(bookId: -1);
                }
                return VoucherBookFormPage(bookId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'accounts',
          name: 'accountingAccounts',
          builder: (context, state) => const ChartOfAccountsPage(),
          routes: [
            GoRoute(
              path: 'create',
              name: 'accountingAccountsCreate',
              builder: (context, state) {
                final parentId = state.uri.queryParameters['parentId'];
                return AccountFormPage(initialParentId: parentId);
              },
            ),
            GoRoute(
              path: 'import',
              name: 'accountingAccountsImport',
              redirect: (context, state) => AccountingRoutes.openingSetup,
            ),
            GoRoute(
              path: ':id',
              name: 'accountingAccountDetails',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                if (id == null) {
                  return const AccountDetailsPage(accountId: -1);
                }
                return AccountDetailsPage(accountId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  name: 'accountingAccountEdit',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    if (id == null) {
                      return const AccountFormPage(accountId: -1);
                    }
                    return AccountFormPage(accountId: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}
