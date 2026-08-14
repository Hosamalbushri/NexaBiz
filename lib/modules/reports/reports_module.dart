import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_localizations.dart';
import '../../core/modules/app_module.dart';
import 'presentation/pages/account_statement_report_page.dart';
import 'presentation/pages/report_pdf_preview_page.dart';
import 'presentation/pages/reports_home_page.dart';
import 'presentation/pages/reports_routes.dart';
import 'presentation/pages/sales_period_report_page.dart';

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
  bool get isEnabled => true;

  @override
  String label(BuildContext context) {
    return AppLocalizations.of(context).moduleReports;
  }

  @override
  String? description(BuildContext context) {
    return AppLocalizations.of(context).moduleReportsDescription;
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
          path: 'preview',
          name: 'reportsPdfPreview',
          builder: (context, state) => const ReportPdfPreviewPage(),
        ),
      ],
    ),
  ];
}
