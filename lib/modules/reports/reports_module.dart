import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import '../../core/modules/route_access_rule.dart';
import '../../core/permissions/permission_defs.dart';
import 'permissions/reports_permission_package.dart';
import 'presentation/pages/account_statement_report_page.dart';
import 'presentation/pages/report_pdf_preview_page.dart';
import 'presentation/pages/reports_home_page.dart';
import 'presentation/pages/reports_routes.dart';
import 'presentation/pages/rp_transaction_report_page.dart';
import 'presentation/pages/sales_period_report_page.dart';
import 'presentation/pages/trial_balance_report_page.dart';
import 'presentation/pages/journal_book_report_page.dart';
import 'domain/services/rp_report_data_port.dart';

import '../../core/modules/report_category_definition.dart';

/// Platform reports module — generic PDF catalog, preview, print/share.
///
/// Data for concrete reports arrives via App-wired ports (modules ↛ modules).
class ReportsModule extends AppModule {
  const ReportsModule();

  static const String moduleId = 'reports';

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
  List<ReportCategoryDefinition> get reportCategories => [
        ReportCategoryDefinition(
          id: 'platform_reports_catalog',
          moduleId: moduleId,
          icon: Icons.assessment_outlined,
          titleBuilder: (l10n) => l10n.platformReportsBusiness,
          subtitleBuilder: (l10n) => l10n.platformReportsBusinessSubtitle,
          reports: [
            ReportItemDefinition(
              id: 'reports_sales_period',
              moduleId: moduleId,
              icon: Icons.receipt_long_outlined,
              path: ReportsRoutes.salesPeriod,
              titleBuilder: (l10n) => l10n.reportsSalesPeriodTitle,
              subtitleBuilder: (l10n) => l10n.reportsSalesPeriodSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_account_statement',
              moduleId: moduleId,
              icon: Icons.menu_book_outlined,
              path: ReportsRoutes.accountStatement,
              titleBuilder: (l10n) => l10n.reportsAccountStatementTitle,
              subtitleBuilder: (l10n) => l10n.reportsAccountStatementSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_trial_balance',
              moduleId: moduleId,
              icon: Icons.balance_outlined,
              path: ReportsRoutes.trialBalance,
              titleBuilder: (l10n) => l10n.reportsTrialBalanceTitle,
              subtitleBuilder: (l10n) => l10n.reportsTrialBalanceSubtitle,
            ),
            ReportItemDefinition(
              id: 'reports_journal_book',
              moduleId: moduleId,
              icon: Icons.auto_stories_outlined,
              path: ReportsRoutes.journalBook,
              titleBuilder: (l10n) => l10n.reportsJournalBookTitle,
              subtitleBuilder: (l10n) => l10n.reportsJournalBookSubtitle,
            ),
          ],
        ),
      ];

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
