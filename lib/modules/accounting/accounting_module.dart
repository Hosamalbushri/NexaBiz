import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/customers/accounting_customer_account_link_adapter.dart';
import '../../app/localization/app_localizations.dart';
import '../../app/presentation/providers/dashboard_services_provider.dart';
import '../../app/receipts_payments/accounting_rp_currency_adapter.dart';
import '../../app/receipts_payments/accounting_rp_ledger_adapter.dart';
import '../../app/receipts_payments/accounting_rp_treasury_adapter.dart';
import '../../app/receipts_payments/accounting_rp_voucher_book_adapter.dart';
import '../../app/sales/accounting_sale_bridge_adapter.dart';
import '../../app/sales/accounting_sale_cogs_adapter.dart';
import '../../app/sales/accounting_sale_currency_adapter.dart';
import '../../app/sales/accounting_sale_ledger_adapter.dart';
import '../../app/sales/accounting_sale_treasury_adapter.dart';
import '../../app/sales/accounting_sale_voucher_book_adapter.dart';
import '../../app/settings/settings_repository.dart';
import '../../app/sync/app_sync_adapters.dart';
import '../../app/system_setup/accounting_system_setup_seed_adapter.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/module_settings_definition.dart';
import '../../core/modules/quick_action_definition.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import '../customers/directory/presentation/providers/customer_providers.dart';
import '../receipts_payments/transactions/presentation/providers/rp_providers.dart';
import '../sales/invoices/presentation/providers/sale_providers.dart';
import '../sync/sync.dart';
import '../system_setup/presentation/providers/system_setup_providers.dart';
import 'accounting_module_quick_actions.dart';
import 'accounting_module_settings.dart';
import 'chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'chart_of_accounts/presentation/pages/account_details_page.dart';
import 'chart_of_accounts/presentation/pages/account_form_page.dart';
import 'chart_of_accounts/presentation/pages/accounts_opening_setup_page.dart';
import 'chart_of_accounts/presentation/pages/chart_of_accounts_page.dart';
import 'chart_of_accounts/presentation/providers/account_providers.dart';
import 'fiscal_years/presentation/pages/fiscal_year_create_page.dart';
import 'fiscal_years/presentation/pages/fiscal_year_details_page.dart';
import 'fiscal_years/presentation/pages/fiscal_years_page.dart';
import 'journals/presentation/pages/journal_entries_page.dart';
import 'journals/presentation/pages/journal_entry_details_page.dart';
import 'journals/presentation/pages/journal_entry_form_page.dart';
import 'journals/presentation/providers/journal_providers.dart';
import 'permissions/accounting_permission_package.dart';
import 'shared/presentation/pages/accounting_home_page.dart';
import 'shared/presentation/pages/accounting_reports_page.dart';
import 'shared/presentation/pages/accounting_routes.dart';
import 'shared/presentation/pages/currency_rates_page.dart';
import 'shared/presentation/providers/accounting_mode_providers.dart';
import 'shared/presentation/providers/currency_rate_providers.dart';
import 'shared/presentation/widgets/accounting_settings_panel.dart';
import 'voucher_books/domain/entities/voucher_book_type.dart';
import 'voucher_books/presentation/pages/voucher_book_form_page.dart';
import 'voucher_books/presentation/pages/voucher_book_section_page.dart';
import 'voucher_books/presentation/pages/voucher_books_page.dart';
import 'voucher_books/presentation/providers/voucher_book_providers.dart';

/// Accounting business module — COA, journals, rates, voucher books.
class AccountingModule extends AppModule {
  const AccountingModule();

  static const String moduleId = 'accounting';

  /// Self-registers AccountingModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const AccountingModule());
  }

  /// Self-unregisters AccountingModule from the global ModuleRegistry.
  static void unregister() {
    ModuleRegistry.unregister(moduleId);
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleAccounting';

  @override
  IconData get icon => Icons.account_balance_outlined;

  @override
  String get rootRoute => AccountingRoutes.root;

  @override
  int get sortOrder => 10;

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
  List<QuickActionDefinition> get quickActions =>
      buildAccountingQuickActions(moduleId);

  @override
  List<ModuleSettingsCategoryDefinition> get settingsCategories =>
      buildAccountingSettingsCategories(moduleId);

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

  @override
  List<Override> get providerOverrides => [
        systemSetupSeedPortProvider.overrideWith((ref) {
          return AccountingSystemSetupSeedAdapter(
            accounts: ref.watch(accountRepositoryProvider),
            voucherBooks: ref.watch(voucherBookRepositoryProvider),
            syncManager: ref.watch(syncManagerProvider),
            settings: ref.watch(settingsRepositoryProvider),
          );
        }),
        accountRepositoryImplProvider.overrideWith((ref) {
          return AccountRepositoryImpl(
            ref.watch(accountingDatabaseProvider),
            syncQueue: ref.watch(syncQueueProvider),
            shouldSuppressLocalChartSeed: () => ref
                .read(settingsRepositoryProvider)
                .loadChartBootstrapPreferRemote(),
            onUuidRemapped: (oldUuid, newUuid) async {
              await ref
                  .read(customerRepositoryImplProvider)
                  .remapAccountId(fromUuid: oldUuid, toUuid: newUuid);
              await ref
                  .read(journalRepositoryImplProvider)
                  .remapAccountUuid(fromUuid: oldUuid, toUuid: newUuid);
            },
          );
        }),
        customerAccountLinkPortProvider.overrideWith((ref) {
          return AccountingCustomerAccountLinkAdapter(
            ref.watch(accountRepositoryProvider),
          );
        }),
        saleAccountingBridgePortProvider.overrideWith((ref) {
          return AccountingSaleBridgeAdapter(
            integration: ref.watch(accountingIntegrationPortProvider),
          );
        }),
        saleLedgerPostingPortProvider.overrideWith((ref) {
          return AccountingSaleLedgerAdapter(
            posting: ref.watch(journalPostingServiceProvider),
            accounts: ref.watch(accountRepositoryProvider),
          );
        }),
        saleVoucherBookPortProvider.overrideWith((ref) {
          return AccountingSaleVoucherBookAdapter(
            ref.watch(voucherBookRepositoryProvider),
            deviceId: ref.watch(syncApiConfigProvider).deviceId,
          );
        }),
        saleCurrencyPortProvider.overrideWith((ref) {
          return AccountingSaleCurrencyAdapter(
            baseCurrencyReader: () async {
              final profile = await ref
                  .read(settingsRepositoryProvider)
                  .loadCompanyProfile();
              return profile.defaultCurrencyCode;
            },
            rates: ref.watch(currencyRateRepositoryProvider),
          );
        }),
        saleTreasuryAccountPortProvider.overrideWith((ref) {
          return AccountingSaleTreasuryAdapter(
            ref.watch(accountRepositoryProvider),
          );
        }),
        rpLedgerPostingPortProvider.overrideWith((ref) {
          return AccountingRpLedgerAdapter(
            posting: ref.watch(journalPostingServiceProvider),
            accounts: ref.watch(accountRepositoryProvider),
            fiscalYears: ref.watch(fiscalYearRepositoryProvider),
          );
        }),
        rpVoucherBookPortProvider.overrideWith((ref) {
          return AccountingRpVoucherBookAdapter(
            ref.watch(voucherBookRepositoryProvider),
            deviceId: ref.watch(syncApiConfigProvider).deviceId,
          );
        }),
        rpTreasuryAccountPortProvider.overrideWith((ref) {
          return AccountingRpTreasuryAdapter(
            ref.watch(accountRepositoryProvider),
          );
        }),
        rpCurrencyPortProvider.overrideWith((ref) {
          return AccountingRpCurrencyAdapter(
            baseCurrencyReader: () async {
              final profile = await ref
                  .read(settingsRepositoryProvider)
                  .loadCompanyProfile();
              return profile.defaultCurrencyCode;
            },
            rates: ref.watch(currencyRateRepositoryProvider),
          );
        }),
      ];
}
