import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/reporting/report_file_actions.dart';
import '../../domain/entities/report_descriptor.dart';
import '../../domain/services/account_statement_report_data_port.dart';
import '../../domain/services/account_statement_report_definition.dart';
import '../../domain/services/report_runner.dart';
import '../../domain/services/rp_report_data_port.dart';
import '../../domain/services/rp_transaction_report_definition.dart';
import '../../domain/services/sales_period_report_data_port.dart';
import '../../domain/services/sales_period_report_definition.dart';
import '../../domain/services/trial_balance_report_data_port.dart';
import '../../domain/services/trial_balance_report_definition.dart';
import '../../domain/services/journal_book_report_data_port.dart';
import '../../domain/services/journal_book_report_definition.dart';
import '../../domain/services/product_stock_movement_report_definition.dart';
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

final trialBalanceReportDefinitionProvider =
    Provider<TrialBalanceReportDefinition>((ref) {
  return const TrialBalanceReportDefinition();
});

final journalBookReportDefinitionProvider =
    Provider<JournalBookReportDefinition>((ref) {
  return const JournalBookReportDefinition();
});

final rpTransactionReportDefinitionProvider =
    Provider<RpTransactionReportDefinition>((ref) {
  return const RpTransactionReportDefinition();
});

final productStockMovementReportDefinitionProvider =
    Provider<ProductStockMovementReportDefinition>((ref) {
  return const ProductStockMovementReportDefinition();
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

/// Override in App with Accounting journal adapter.
final trialBalanceReportDataPortProvider =
    Provider<TrialBalanceReportDataPort>((ref) {
  return const NoOpTrialBalanceReportDataPort();
});

/// Override in App with Accounting journal-book adapter.
final journalBookReportDataPortProvider =
    Provider<JournalBookReportDataPort>((ref) {
  return const NoOpJournalBookReportDataPort();
});

/// Override in App with Receipts & Payments repository adapter.
final rpReportDataPortProvider = Provider<RpReportDataPort>((ref) {
  return const NoOpRpReportDataPort();
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
    ReportDescriptor(
      id: 'trial_balance',
      titleKey: 'reportsTrialBalanceTitle',
      subtitleKey: 'reportsTrialBalanceSubtitle',
      routePath: ReportsRoutes.trialBalance,
    ),
    ReportDescriptor(
      id: 'journal_book',
      titleKey: 'reportsJournalBookTitle',
      subtitleKey: 'reportsJournalBookSubtitle',
      routePath: ReportsRoutes.journalBook,
    ),
    ReportDescriptor(
      id: 'rp_receipts',
      titleKey: 'reportsRpReceiptsTitle',
      subtitleKey: 'reportsRpReceiptsSubtitle',
      routePath: ReportsRoutes.rpReceipts,
    ),
    ReportDescriptor(
      id: 'rp_payments',
      titleKey: 'reportsRpPaymentsTitle',
      subtitleKey: 'reportsRpPaymentsSubtitle',
      routePath: ReportsRoutes.rpPayments,
    ),
    ReportDescriptor(
      id: 'rp_cash_movement',
      titleKey: 'reportsRpCashMovementTitle',
      subtitleKey: 'reportsRpCashMovementSubtitle',
      routePath: ReportsRoutes.rpCashMovement,
    ),
    ReportDescriptor(
      id: 'rp_bank_movement',
      titleKey: 'reportsRpBankMovementTitle',
      subtitleKey: 'reportsRpBankMovementSubtitle',
      routePath: ReportsRoutes.rpBankMovement,
    ),
    ReportDescriptor(
      id: 'rp_customer_receipts',
      titleKey: 'reportsRpCustomerReceiptsTitle',
      subtitleKey: 'reportsRpCustomerReceiptsSubtitle',
      routePath: ReportsRoutes.rpCustomerReceipts,
    ),
    ReportDescriptor(
      id: 'rp_daily_summary',
      titleKey: 'reportsRpDailySummaryTitle',
      subtitleKey: 'reportsRpDailySummarySubtitle',
      routePath: ReportsRoutes.rpDailySummary,
    ),
    ReportDescriptor(
      id: 'rp_period_summary',
      titleKey: 'reportsRpPeriodSummaryTitle',
      subtitleKey: 'reportsRpPeriodSummarySubtitle',
      routePath: ReportsRoutes.rpPeriodSummary,
    ),
  ];
});
