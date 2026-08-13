import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/modules/module_providers.dart';
import '../../core/modules/module_registry.dart';
import '../../modules/accounting/accounting_module.dart';
import '../../modules/accounting/domain/entities/accounting_mode.dart';
import '../../modules/accounting/presentation/providers/account_providers.dart';
import '../../modules/accounting/presentation/providers/accounting_mode_providers.dart';
import '../../modules/accounting/presentation/providers/currency_rate_providers.dart';
import '../../modules/accounting/presentation/providers/voucher_book_providers.dart';
import '../../modules/customers/customers_module.dart';
import '../../modules/customers/presentation/providers/customer_providers.dart';
import '../../modules/inventory/inventory_module.dart';
import '../../modules/inventory/presentation/pages/product_barcode_scanner_page.dart';
import '../../modules/inventory/presentation/providers/product_providers.dart';
import '../../modules/sales/presentation/providers/sale_barcode_capture_provider.dart';
import '../../modules/sales/presentation/providers/sale_providers.dart';
import '../../modules/sales/sales_module.dart';
import '../customers/accounting_customer_account_link_adapter.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../sales/accounting_sale_bridge_adapter.dart';
import '../sales/accounting_sale_currency_adapter.dart';
import '../sales/accounting_sale_treasury_adapter.dart';
import '../sales/accounting_sale_voucher_book_adapter.dart';
import '../sales/customers_sale_lookup_adapter.dart';
import '../sales/inventory_sale_product_catalog_adapter.dart';

/// App composition root: registers enabled business modules.
///
/// Add future modules here (Purchases, …) without changing Core
/// or the Dashboard.
List<Override> moduleRegistryOverrides() {
  return [
    moduleRegistryProvider.overrideWithValue(
      ModuleRegistry(const [
        InventoryModule(),
        AccountingModule(),
        CustomersModule(),
        SalesModule(),
      ]),
    ),
    // Modules must not import each other — App wires cross-module ports.
    customerAccountLinkPortProvider.overrideWith((ref) {
      return AccountingCustomerAccountLinkAdapter(
        ref.watch(accountRepositoryProvider),
      );
    }),
    saleCustomerLookupPortProvider.overrideWith((ref) {
      return CustomersSaleLookupAdapter(ref.watch(customerRepositoryProvider));
    }),
    saleProductCatalogPortProvider.overrideWith((ref) {
      return InventorySaleProductCatalogAdapter(
        repository: ref.watch(productRepositoryProvider),
        scanResolver: ref.watch(productScanResolverProvider),
      );
    }),
    saleAccountingBridgePortProvider.overrideWith((ref) {
      return AccountingSaleBridgeAdapter(
        modeReader: () =>
            ref.read(accountingModeProvider).valueOrNull ??
            AccountingMode.standalone,
        integration: ref.watch(accountingIntegrationPortProvider),
      );
    }),
    saleVoucherBookPortProvider.overrideWith((ref) {
      return AccountingSaleVoucherBookAdapter(
        ref.watch(voucherBookRepositoryProvider),
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
  ];
}
