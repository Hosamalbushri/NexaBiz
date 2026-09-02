import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/report_engine/report_engine.dart';
import '../settings/company/company_profile_providers.dart';
import '../../modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../modules/accounting/journals/presentation/providers/journal_providers.dart';
import '../../modules/accounting/shared/presentation/providers/currency_rate_providers.dart';
import '../../modules/inventory/products/presentation/providers/product_providers.dart';
import '../../modules/receipts_payments/transactions/presentation/providers/rp_providers.dart';
import '../../modules/reports/shared/domain/services/product_stock_movement_report_data_port.dart';
import '../../modules/reports/shared/presentation/providers/reports_providers.dart';
import '../../modules/sales/invoices/presentation/providers/sale_providers.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import 'account_statement_report_data_adapter.dart';
import 'journal_book_report_data_adapter.dart';
import 'product_stock_movement_report_data_adapter.dart';
import 'rp_report_data_adapter.dart';
import 'sales_period_report_data_adapter.dart';
import 'trial_balance_report_data_adapter.dart';

/// App-level bridge provider overrides for [ReportsModule].
///
/// Encapsulates concrete provider wiring from business modules (Accounting, Inventory,
/// Sales, Receipts & Payments) into Reports domain ports without [ReportsModule]
/// having direct cross-module imports.
List<Override> buildReportsAppProviderOverrides() {
  return [
    salesPeriodReportDataPortProvider.overrideWith((ref) {
      return SalesPeriodReportDataAdapter(
        ref.watch(saleRepositoryProvider),
      );
    }),
    salesPeriodReportEngineDataProvider.overrideWith((ref) {
      final companyName = ref.watch(companyProfileProvider).valueOrNull?.name ??
          'NexaBiz ERP';
      return SalesPeriodReportDataProvider(
        salesDb: ref.watch(salesDatabaseProvider),
        companyName: companyName,
      );
    }),
    stockMovementReportEngineDataProvider.overrideWith((ref) {
      final companyName = ref.watch(companyProfileProvider).valueOrNull?.name ??
          'NexaBiz ERP';
      return StockMovementReportDataProvider(
        inventoryDb: ref.watch(inventoryDatabaseProvider),
        salesDb: ref.watch(salesDatabaseProvider),
        companyName: companyName,
      );
    }),
    accountStatementReportDataPortProvider.overrideWith((ref) {
      return AccountStatementReportDataAdapter(
        accounts: ref.watch(accountRepositoryProvider),
        currencyRates: ref.watch(currencyRateRepositoryProvider),
        journals: ref.watch(journalRepositoryProvider),
        loadCompanyProfile: () =>
            ref.read(settingsRepositoryProvider).loadCompanyProfile(),
        loadSalesForAccount: (accountUuid) =>
            ref.read(saleRepositoryProvider).listByAccountLink(accountUuid),
        ledger: ref.watch(saleLedgerPostingPortProvider),
      );
    }),
    trialBalanceReportDataPortProvider.overrideWith((ref) {
      return TrialBalanceReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        loadCompanyProfile: () =>
            ref.read(settingsRepositoryProvider).loadCompanyProfile(),
      );
    }),
    journalBookReportDataPortProvider.overrideWith((ref) {
      return JournalBookReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        loadCompanyProfile: () =>
            ref.read(settingsRepositoryProvider).loadCompanyProfile(),
      );
    }),
    rpReportDataPortProvider.overrideWith((ref) {
      return RpReportDataAdapter(
        ref.watch(financialTransactionRepositoryProvider),
      );
    }),
    productStockMovementReportDataPortProvider.overrideWith((ref) {
      return ProductStockMovementReportDataAdapter(
        db: ref.watch(inventoryDatabaseProvider),
        salesDb: ref.watch(salesDatabaseProvider),
        loadCompanyProfile: () =>
            ref.read(settingsRepositoryProvider).loadCompanyProfile(),
      );
    }),
  ];
}
