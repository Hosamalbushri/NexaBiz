import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/modules/module_providers.dart';
import '../../core/modules/module_registry.dart';
import '../../core/sync/sync_providers.dart';
import '../../modules/accounting/accounting_module.dart';
import '../../modules/administration/administration_module.dart';
import '../../modules/accounting/data/repositories/account_repository_impl.dart';
import '../../modules/accounting/presentation/providers/account_providers.dart';
import '../../modules/accounting/presentation/providers/accounting_mode_providers.dart';
import '../../modules/accounting/presentation/providers/currency_rate_providers.dart';
import '../../modules/accounting/presentation/providers/journal_providers.dart';
import '../../modules/accounting/presentation/providers/voucher_book_providers.dart';
import '../../modules/customers/customers_module.dart';
import '../../modules/customers/presentation/providers/customer_providers.dart';
import '../../modules/inventory/inventory_module.dart';
import '../../modules/inventory/presentation/pages/product_barcode_scanner_page.dart';
import '../../modules/inventory/presentation/providers/product_providers.dart';
import '../../modules/reports/presentation/providers/reports_providers.dart';
import '../../modules/reports/reports_module.dart';
import '../../modules/sales/presentation/providers/sale_barcode_capture_provider.dart';
import '../../modules/sales/presentation/providers/sale_providers.dart';
import '../../modules/receipts_payments/presentation/providers/rp_providers.dart';
import '../../modules/receipts_payments/receipts_payments_module.dart';
import '../../modules/sales/sales_module.dart';
import '../../modules/system_setup/system_setup_module.dart';
import '../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../customers/accounting_customer_account_link_adapter.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../receipts_payments/accounting_rp_currency_adapter.dart';
import '../receipts_payments/accounting_rp_ledger_adapter.dart';
import '../receipts_payments/accounting_rp_treasury_adapter.dart';
import '../receipts_payments/accounting_rp_voucher_book_adapter.dart';
import '../receipts_payments/customers_rp_lookup_adapter.dart';
import '../reports/account_statement_report_data_adapter.dart';
import '../reports/rp_report_data_adapter.dart';
import '../reports/sales_period_report_data_adapter.dart';
import '../reports/trial_balance_report_data_adapter.dart';
import '../reports/journal_book_report_data_adapter.dart';
import '../sales/accounting_sale_bridge_adapter.dart';
import '../sales/accounting_sale_currency_adapter.dart';
import '../sales/accounting_sale_ledger_adapter.dart';
import '../sales/accounting_sale_treasury_adapter.dart';
import '../sales/accounting_sale_voucher_book_adapter.dart';
import '../sales/customers_sale_lookup_adapter.dart';
import '../sales/inventory_sale_product_catalog_adapter.dart';
import '../sales/soft_sale_inventory_effect_adapter.dart';
import '../system_setup/accounting_system_setup_seed_adapter.dart';

/// App composition root: registers enabled business modules.
///
/// Add/remove modules here — launcher routes, settings, and Administration
/// permission packages (Package → Service → Operation) update automatically.
List<Override> moduleRegistryOverrides() {
  return [
    moduleRegistryProvider.overrideWithValue(
      ModuleRegistry(const [
        SystemSetupModule(),
        InventoryModule(),
        AccountingModule(),
        CustomersModule(),
        SalesModule(),
        ReceiptsPaymentsModule(),
        ReportsModule(),
        AdministrationModule(),
      ]),
    ),
    systemSetupSeedPortProvider.overrideWith((ref) {
      return AccountingSystemSetupSeedAdapter(
        accounts: ref.watch(accountRepositoryProvider),
        voucherBooks: ref.watch(voucherBookRepositoryProvider),
        syncManager: ref.watch(syncManagerProvider),
        settings: ref.watch(settingsRepositoryProvider),
      );
    }),
    // Modules must not import each other — App wires cross-module ports.
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
    saleCustomerLookupPortProvider.overrideWith((ref) {
      return CustomersSaleLookupAdapter(
        repository: ref.watch(customerRepositoryProvider),
        accountLinkPort: ref.watch(customerAccountLinkPortProvider),
        settings: ref.watch(settingsRepositoryProvider),
      );
    }),
    saleProductCatalogPortProvider.overrideWith((ref) {
      return InventorySaleProductCatalogAdapter(
        repository: ref.watch(productRepositoryProvider),
        scanResolver: ref.watch(productScanResolverProvider),
      );
    }),
    saleInventoryEffectPortProvider.overrideWith(
      (ref) => const SoftSaleInventoryEffectAdapter(),
    ),
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
    rpCustomerLookupPortProvider.overrideWith((ref) {
      return CustomersRpLookupAdapter(
        repository: ref.watch(customerRepositoryProvider),
        accountLinkPort: ref.watch(customerAccountLinkPortProvider),
        settings: ref.watch(settingsRepositoryProvider),
      );
    }),
    saleBarcodeCaptureProvider.overrideWithValue(
      (context) => ProductBarcodeScannerPage.open(context),
    ),
    salesPeriodReportDataPortProvider.overrideWith((ref) {
      return SalesPeriodReportDataAdapter(
        ref.watch(saleRepositoryProvider),
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
  ];
}
