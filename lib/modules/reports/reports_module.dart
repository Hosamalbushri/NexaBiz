import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/module_registry.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import 'financial_reports/presentation/pages/account_statement_report_page.dart';
import 'financial_reports/presentation/pages/journal_book_report_page.dart';
import 'financial_reports/presentation/pages/trial_balance_report_page.dart';
import 'operational_reports/presentation/pages/rp_transaction_report_page.dart';
import 'operational_reports/presentation/pages/sales_period_report_page.dart';
import 'permissions/reports_permission_package.dart';
import 'shared/domain/services/rp_report_data_port.dart';
import 'shared/presentation/pages/report_pdf_preview_page.dart';
import 'shared/presentation/pages/reports_home_page.dart';
import 'shared/presentation/pages/reports_routes.dart';

import '../../core/modules/report_category_definition.dart';

/// Platform reports module — generic PDF catalog, preview, print/share.
///
/// Data for concrete reports arrives via App-wired ports (modules ↛ modules).
class ReportsModule extends AppModule {
  const ReportsModule();

  static const String moduleId = 'reports';

  /// Self-registers ReportsModule into the global ModuleRegistry via injection.
  static void register() {
    ModuleRegistry.register(const ReportsModule());
  }

  @override
  String get id => moduleId;

  @override
  String get nameKey => 'moduleReports';

  @override
  IconData get icon => Icons.assessment_outlined;

  @override
  String get rootRoute => ReportsRoutes.root;

  @override
  int get sortOrder => 60;

  @override
  bool get isEnabled => true;

  @override
  List<String> get requiredAnyPermissions => const [
        'reports.view',
        'reports.sales_period.view',
        'reports.account_statement.view',
        'reports.trial_balance.view',
        'reports.journal_book.view',
        'receipts_payments.reports.view',
      ];

  @override
  List<RouteAccessRule> get routeAccessRules => [
        RouteAccessRule(
          pathPrefix: ReportsRoutes.root,
          anyOf: requiredAnyPermissions,
        ),
      ];

  @override
  PermissionPackageDef? get permissionPackage => reportsPermissionPackage();

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleReports;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleReportsDescription;
  }

  @override
  List<ReportCategoryDefinition> get reportCategories {
    final categories = <ReportCategoryDefinition>[];

    // 1. Accounting Reports
    if (ModuleRegistry.isModuleRegistered('accounting')) {
      categories.add(
        ReportCategoryDefinition(
          id: 'accounting_reports',
          moduleId: 'accounting',
          icon: Icons.account_balance_outlined,
          titleBuilder: (l10n) => l10n.moduleAccounting,
          subtitleBuilder: (l10n) => l10n.moduleAccountingDescription,
          reports: [
            ReportItemDefinition(
              id: 'reports_account_statement',
              moduleId: 'accounting',
              icon: Icons.menu_book_outlined,
              path: ReportsRoutes.accountStatement,
              titleBuilder: (l10n) => l10n.reportsAccountStatementTitle,
              subtitleBuilder: (l10n) => l10n.reportsAccountStatementSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_trial_balance',
              moduleId: 'accounting',
              icon: Icons.balance_outlined,
              path: ReportsRoutes.trialBalance,
              titleBuilder: (l10n) => l10n.reportsTrialBalanceTitle,
              subtitleBuilder: (l10n) => l10n.reportsTrialBalanceSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_journal_book',
              moduleId: 'accounting',
              icon: Icons.auto_stories_outlined,
              path: ReportsRoutes.journalBook,
              titleBuilder: (l10n) => l10n.reportsJournalBookTitle,
              subtitleBuilder: (l10n) => l10n.reportsJournalBookSubtitle,
            ),
          ],
        ),
      );
    }

    // 2. Sales Reports
    if (ModuleRegistry.isModuleRegistered('sales')) {
      categories.add(
        ReportCategoryDefinition(
          id: 'sales_reports',
          moduleId: 'sales',
          icon: Icons.point_of_sale_outlined,
          titleBuilder: (l10n) => l10n.moduleSales,
          subtitleBuilder: (l10n) => l10n.moduleSalesDescription,
          reports: [
            ReportItemDefinition(
              id: 'reports_sales_period',
              moduleId: 'sales',
              icon: Icons.receipt_long_outlined,
              path: ReportsRoutes.salesPeriod,
              titleBuilder: (l10n) => l10n.reportsSalesPeriodTitle,
              subtitleBuilder: (l10n) => l10n.reportsSalesPeriodSubtitle,
            ),
          ],
        ),
      );
    }

    // 3. Receipts & Payments Reports
    if (ModuleRegistry.isModuleRegistered('receipts_payments')) {
      categories.add(
        ReportCategoryDefinition(
          id: 'rp_reports',
          moduleId: 'receipts_payments',
          icon: Icons.account_balance_wallet_outlined,
          titleBuilder: (l10n) => l10n.moduleReceiptsPayments,
          subtitleBuilder: (l10n) => l10n.moduleReceiptsPaymentsDescription,
          reports: [
            ReportItemDefinition(
              id: 'reports_rp_receipts',
              moduleId: 'receipts_payments',
              icon: Icons.payments_outlined,
              path: ReportsRoutes.rpReceipts,
              titleBuilder: (l10n) => l10n.rpServiceReceiptsTitle,
              subtitleBuilder: (l10n) => l10n.rpServiceReceiptsSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_rp_payments',
              moduleId: 'receipts_payments',
              icon: Icons.outbox_outlined,
              path: ReportsRoutes.rpPayments,
              titleBuilder: (l10n) => l10n.rpServicePaymentsTitle,
              subtitleBuilder: (l10n) => l10n.rpServicePaymentsSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_rp_transfers',
              moduleId: 'receipts_payments',
              icon: Icons.swap_horiz_outlined,
              path: ReportsRoutes.rpCashMovement,
              titleBuilder: (l10n) => l10n.rpServiceTransfersTitle,
              subtitleBuilder: (l10n) => l10n.rpServiceTransfersSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_rp_exchanges',
              moduleId: 'receipts_payments',
              icon: Icons.currency_exchange_outlined,
              path: ReportsRoutes.rpDailySummary,
              titleBuilder: (l10n) => l10n.rpServiceExchangesTitle,
              subtitleBuilder: (l10n) => l10n.rpServiceExchangesSubtitle,
            ),
          ],
        ),
      );
    }

    // 4. Inventory Reports
    if (ModuleRegistry.isModuleRegistered('inventory')) {
      categories.add(
        ReportCategoryDefinition(
          id: 'inventory_reports',
          moduleId: 'inventory',
          icon: Icons.inventory_2_outlined,
          titleBuilder: (l10n) => l10n.moduleInventory,
          subtitleBuilder: (l10n) => l10n.moduleInventoryDescription,
          reports: [
            ReportItemDefinition(
              id: 'reports_stock_balance',
              moduleId: 'inventory',
              icon: Icons.assessment_outlined,
              path: '/inventory/reports',
              titleBuilder: (l10n) => l10n.moduleInventory,
              subtitleBuilder: (l10n) => l10n.moduleInventoryDescription,
            ),
          ],
        ),
      );
    }

    // 5. Customers Reports
    if (ModuleRegistry.isModuleRegistered('customers')) {
      categories.add(
        ReportCategoryDefinition(
          id: 'customers_reports',
          moduleId: 'customers',
          icon: Icons.people_outline,
          titleBuilder: (l10n) => l10n.moduleCustomers,
          subtitleBuilder: (l10n) => l10n.moduleCustomersDescription,
          reports: [
            ReportItemDefinition(
              id: 'reports_customers_list',
              moduleId: 'customers',
              icon: Icons.group_outlined,
              path: '/customers',
              titleBuilder: (l10n) => l10n.moduleCustomers,
              subtitleBuilder: (l10n) => l10n.moduleCustomersDescription,
            ),
          ],
        ),
      );
    }

    categories.sort((a, b) {
      final moduleA = ModuleRegistry.registeredModules.firstWhere(
        (m) => m.id == a.moduleId,
        orElse: () => const ReportsModule(),
      );
      final moduleB = ModuleRegistry.registeredModules.firstWhere(
        (m) => m.id == b.moduleId,
        orElse: () => const ReportsModule(),
      );
      return moduleA.sortOrder.compareTo(moduleB.sortOrder);
    });

    return categories;
  }

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: ReportsRoutes.root,
      name: 'moduleReportsHome',
      builder: (context, state) => const ReportsHomePage(),
      routes: [
        GoRoute(
          path: 'sales-period',
          name: 'reportsSalesPeriod',
          builder: (context, state) => const SalesPeriodReportPage(),
        ),
        GoRoute(
          path: 'account-statement',
          name: 'reportsAccountStatement',
          builder: (context, state) => const AccountStatementReportPage(),
        ),
        GoRoute(
          path: 'trial-balance',
          name: 'reportsTrialBalance',
          builder: (context, state) => const TrialBalanceReportPage(),
        ),
        GoRoute(
          path: 'journal-book',
          name: 'reportsJournalBook',
          builder: (context, state) => const JournalBookReportPage(),
        ),
        GoRoute(
          path: 'rp-receipts',
          name: 'reportsRpReceipts',
          builder: (context, state) =>
              const RpTransactionReportPage(kind: RpReportKind.receipts),
        ),
        GoRoute(
          path: 'rp-payments',
          name: 'reportsRpPayments',
          builder: (context, state) =>
              const RpTransactionReportPage(kind: RpReportKind.payments),
        ),
        GoRoute(
          path: 'rp-cash-movement',
          name: 'reportsRpCash',
          builder: (context, state) =>
              const RpTransactionReportPage(kind: RpReportKind.cashMovement),
        ),
        GoRoute(
          path: 'rp-bank-movement',
          name: 'reportsRpBank',
          builder: (context, state) =>
              const RpTransactionReportPage(kind: RpReportKind.bankMovement),
        ),
        GoRoute(
          path: 'rp-customer-receipts',
          name: 'reportsRpCustomerReceipts',
          builder: (context, state) => const RpTransactionReportPage(
            kind: RpReportKind.customerReceipts,
          ),
        ),
        GoRoute(
          path: 'rp-daily-summary',
          name: 'reportsRpDaily',
          builder: (context, state) =>
              const RpTransactionReportPage(kind: RpReportKind.dailySummary),
        ),
        GoRoute(
          path: 'rp-period-summary',
          name: 'reportsRpPeriod',
          builder: (context, state) =>
              const RpTransactionReportPage(kind: RpReportKind.periodSummary),
        ),
        GoRoute(
          path: 'preview',
          name: 'reportsPdfPreview',
          builder: (context, state) => const ReportPdfPreviewPage(),
        ),
      ],
    ),
  ];
}
