import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reporting/report_file_actions.dart';
import '../../domain/entities/report_descriptor.dart';
import '../../domain/services/account_statement_report_data_port.dart';
import '../../domain/services/account_statement_report_definition.dart';
import '../../domain/services/report_runner.dart';
import '../../domain/services/sales_period_report_data_port.dart';
import '../../domain/services/sales_period_report_definition.dart';
import '../pages/reports_routes.dart';

final reportFileActionsProvider = Provider<ReportFileActions>((ref) {
  return const ReportFileActions();
});

final reportRunnerProvider = Provider<ReportRunner>((ref) {
  return const ReportRunner();
});

final salesPeriodReportDefinitionProvider =
    Provider<SalesPeriodReportDefinition>((ref) {
      return const SalesPeriodReportDefinition();
    });

final accountStatementReportDefinitionProvider =
    Provider<AccountStatementReportDefinition>((ref) {
      return const AccountStatementReportDefinition();
    });

/// Override in App with Sales-backed adapter.
final salesPeriodReportDataPortProvider = Provider<SalesPeriodReportDataPort>((
  ref,
) {
  return const NoOpSalesPeriodReportDataPort();
});

/// Override in App with Accounting-backed adapter.
final accountStatementReportDataPortProvider =
    Provider<AccountStatementReportDataPort>((ref) {
      return const NoOpAccountStatementReportDataPort();
    });

final reportCatalogProvider = Provider<List<ReportDescriptor>>((ref) {
  return const [
    ReportDescriptor(
      id: 'sales_period',
      titleKey: 'reportsSalesPeriodTitle',
      subtitleKey: 'reportsSalesPeriodSubtitle',
      routePath: ReportsRoutes.salesPeriod,
    ),
    ReportDescriptor(
      id: 'account_statement',
      titleKey: 'reportsAccountStatementTitle',
      subtitleKey: 'reportsAccountStatementSubtitle',
      routePath: ReportsRoutes.accountStatement,
    ),
  ];
});
