import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import 'domain/entities/voucher_book_type.dart';
import 'presentation/pages/account_details_page.dart';
import 'presentation/pages/account_form_page.dart';
import 'presentation/pages/accounting_home_page.dart';
import 'presentation/pages/accounting_reports_page.dart';
import 'presentation/pages/accounting_routes.dart';
import 'presentation/pages/chart_of_accounts_page.dart';
import 'presentation/pages/currency_rates_page.dart';
import 'presentation/pages/voucher_book_form_page.dart';
import 'presentation/pages/voucher_book_section_page.dart';
import 'presentation/pages/voucher_books_page.dart';
import 'presentation/providers/accounting_mode_providers.dart';
import 'presentation/widgets/accounting_settings_panel.dart';

/// Accounting business module — Chart of Accounts foundation.
///
/// Future: Journal Entries, Ledger, Suppliers, Reports.
/// Customers live in the dedicated Customers module.
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
    ref.invalidate(accountingModeProvider);
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: AccountingRoutes.root,
      name: 'accounting',
      builder: (context, state) => const AccountingHomePage(),
      routes: [
        GoRoute(
          path: 'currency-rates',
          name: 'accountingCurrencyRates',
          builder: (context, state) => const CurrencyRatesPage(),
        ),
        GoRoute(
          path: 'reports',
          name: 'accountingReports',
          builder: (context, state) => const AccountingReportsPage(),
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
