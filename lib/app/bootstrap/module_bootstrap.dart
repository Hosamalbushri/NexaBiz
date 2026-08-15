import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/modules/module_providers.dart';
import '../../core/modules/module_registry.dart';
import '../../core/sync/sync_providers.dart';
import '../../modules/accounting/accounting_module.dart';
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
import '../../modules/sales/sales_module.dart';
import '../../modules/system_setup/system_setup_module.dart';
import '../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../customers/accounting_customer_account_link_adapter.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../reports/account_statement_report_data_adapter.dart';
import '../reports/sales_period_report_data_adapter.dart';
import '../sales/accounting_sale_bridge_adapter.dart';
import '../sales/accounting_sale_currency_adapter.dart';
import '../sales/accounting_sale_ledger_adapter.dart';
import '../sales/accounting_sale_treasury_adapter.dart';
import '../sales/accounting_sale_voucher_book_adapter.dart';
import '../sales/customers_sale_lookup_adapter.dart';
import '../sales/inventory_sale_product_catalog_adapter.dart';
import '../system_setup/accounting_system_setup_seed_adapter.dart';

/// App composition root: registers enabled business modules.
///
/// Add future modules here (Purchases, …) without changing Core
/// or the Dashboard.
List<Override> moduleRegistryOverrides() {
  return [
    moduleRegistryProvider.overrideWithValue(
      ModuleRegistry(const [
        SystemSetupModule(),
        InventoryModule(),
        AccountingModule(),
        CustomersModule(),
        SalesModule(),
        ReportsModule(),
      ]),
    ),
    systemSetupSeedPortProvider.overrideWith((ref) {
      return AccountingSystemSetupSeedAdapter(
        accounts: ref.watch(accountRepositoryProvider),
        voucherBooks: ref.watch(voucherBookRepositoryProvider),
      );
    }),
    // Modules must not import each other — App wires cross-module ports.
    accountRepositoryImplProvider.overrideWith((ref) {
      return AccountRepositoryImpl(
        ref.watch(accountingDatabaseProvider),
        syncQueue: ref.watch(syncQueueProvider),
        onUuidRemapped: (oldUuid, newUuid) {
          return ref
              .read(customerRepositoryImplProvider)
              .remapAccountId(fromUuid: oldUuid, toUuid: newUuid);
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
  ];
}
