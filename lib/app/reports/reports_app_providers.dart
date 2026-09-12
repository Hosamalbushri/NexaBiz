import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/database/canonical_database_provider.dart';
import 'package:stock_count/core/report_engine/report_engine.dart';
import 'package:stock_count/modules/reports/providers/sales_period_report_provider.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/currency_providers.dart';
import '../../modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../modules/accounting/journals/presentation/providers/journal_providers.dart';
import '../../modules/accounting/shared/presentation/providers/currency_rate_providers.dart';
import '../../modules/inventory/products/presentation/providers/product_providers.dart';
import '../../modules/receipts_payments/transactions/presentation/providers/rp_providers.dart';
import '../../modules/reports/shared/domain/services/product_stock_movement_report_data_port.dart';
import '../../modules/reports/shared/presentation/providers/reports_providers.dart';
import '../../modules/sales/invoices/presentation/providers/sale_providers.dart';
import 'account_statement_report_data_adapter.dart';
import 'balance_sheet_report_data_adapter.dart';
import 'cash_flow_report_data_adapter.dart';
import 'general_ledger_report_data_adapter.dart';
import 'income_statement_report_data_adapter.dart';
import 'journal_book_report_data_adapter.dart';
import 'product_stock_movement_report_data_adapter.dart';
import 'receivables_payables_report_data_adapter.dart';
import 'rp_report_data_adapter.dart';
import 'sales_period_report_data_adapter.dart';
import 'trial_balance_report_data_adapter.dart';
import '../../modules/reports/shared/domain/services/balance_sheet_report_data_port.dart';
import '../../modules/reports/shared/domain/services/cash_flow_report_data_port.dart';
import '../../modules/reports/shared/domain/services/general_ledger_report_data_port.dart';
import '../../modules/reports/shared/domain/services/income_statement_report_data_port.dart';
import '../../modules/reports/shared/domain/services/receivables_payables_report_data_port.dart';

/// App-level bridge provider overrides for [ReportsModule].
///
/// Encapsulates concrete provider wiring from business modules (Accounting, Inventory,
/// Sales, Receipts & Payments) into Reports domain ports without [ReportsModule]
/// having direct cross-module imports.
List<Override> buildReportsAppProviderOverrides() {
  return [
    salesPeriodReportDataPortProvider.overrideWith((ref) {
      return SalesPeriodReportDataAdapter(ref.watch(saleRepositoryProvider));
    }),
    salesPeriodReportEngineDataProvider.overrideWith((ref) {
      final companyName =
          ref.watch(companyProfileProvider).valueOrNull?.name ?? 'NexaBiz ERP';
      return SalesPeriodReportDataProvider(
        salesDb: ref.watch(nexabizDatabaseProvider),
        companyName: companyName,
      );
    }),
    stockMovementReportEngineDataProvider.overrideWith((ref) {
      final companyName =
          ref.watch(companyProfileProvider).valueOrNull?.name ?? 'NexaBiz ERP';
      return StockMovementReportDataProvider(
        db: ref.watch(nexabizDatabaseProvider),
        companyName: companyName,
      );
    }),
    accountStatementReportDataPortProvider.overrideWith((ref) {
      return AccountStatementReportDataAdapter(
        accounts: ref.watch(accountRepositoryProvider),
        currencyRates: ref.watch(currencyRateRepositoryProvider),
        journals: ref.watch(journalRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
        loadSalesForAccount: (accountUuid) =>
            ref.read(saleRepositoryProvider).listByAccountLink(accountUuid),
        ledger: ref.watch(saleLedgerPostingPortProvider),
      );
    }),
    trialBalanceReportDataPortProvider.overrideWith((ref) {
      return TrialBalanceReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
    journalBookReportDataPortProvider.overrideWith((ref) {
      return JournalBookReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
    rpReportDataPortProvider.overrideWith((ref) {
      return RpReportDataAdapter(
        ref.watch(financialTransactionRepositoryProvider),
      );
    }),
    productStockMovementReportDataPortProvider.overrideWith((ref) {
      return ProductStockMovementReportDataAdapter(
        db: ref.watch(nexabizDatabaseProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
    generalLedgerReportDataPortProvider.overrideWith((ref) {
      return GeneralLedgerReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
    incomeStatementReportDataPortProvider.overrideWith((ref) {
      return IncomeStatementReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        accounts: ref.watch(accountRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
    balanceSheetReportDataPortProvider.overrideWith((ref) {
      return BalanceSheetReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        accounts: ref.watch(accountRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
    receivablesPayablesReportDataPortProvider.overrideWith((ref) {
      return ReceivablesPayablesReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        accounts: ref.watch(accountRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
    cashFlowReportDataPortProvider.overrideWith((ref) {
      return CashFlowReportDataAdapter(
        journals: ref.watch(journalRepositoryProvider),
        accounts: ref.watch(accountRepositoryProvider),
        loadFunctionalCurrencyCode: () async {
          final c = await ref
              .read(currencyRepositoryProvider)
              .getDefaultCurrency();
          return c?.code ?? '';
        },
      );
    }),
  ];
}
