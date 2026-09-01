import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/document_posting_providers.dart';
import 'package:stock_count/modules/customers/directory/presentation/providers/customer_providers.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/providers/stock_movements_providers.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_customer_lookup_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_ledger_posting_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_product_catalog_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_treasury_account_port.dart';

import 'accounting_sale_ledger_adapter.dart';
import 'accounting_sale_treasury_adapter.dart';
import 'customers_sale_lookup_adapter.dart';
import 'inventory_sale_product_catalog_adapter.dart';
import 'perpetual_sale_inventory_effect_adapter.dart';

/// App-level customer lookup port for Sales.
final appSaleCustomerLookupPortProvider = Provider<SaleCustomerLookupPort>((ref) {
  return CustomersSaleLookupAdapter(
    repository: ref.watch(customerRepositoryProvider),
    accountLinkPort: ref.watch(customerAccountLinkPortProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

/// App-level product catalog port for Sales.
final appSaleProductCatalogPortProvider = Provider<SaleProductCatalogPort>((ref) {
  return InventorySaleProductCatalogAdapter(
    repository: ref.watch(productRepositoryProvider),
    scanResolver: ref.watch(productScanResolverProvider),
  );
});

/// App-level inventory effect port for Sales.
final appSaleInventoryEffectPortProvider = Provider<SaleInventoryEffectPort>((ref) {
  return PerpetualSaleInventoryEffectAdapter(
    orchestrator: ref.watch(documentPostingOrchestratorProvider),
    stockMovementsRepository: ref.watch(stockMovementsRepositoryProvider),
  );
});

/// App-level ledger posting port for Sales.
final appSaleLedgerPostingPortProvider = Provider<SaleLedgerPostingPort>((ref) {
  return AccountingSaleLedgerAdapter(
    posting: ref.watch(journalPostingServiceProvider),
    accounts: ref.watch(accountRepositoryProvider),
  );
});

/// App-level treasury account port for Sales.
final appSaleTreasuryAccountPortProvider = Provider<SaleTreasuryAccountPort>((ref) {
  return AccountingSaleTreasuryAdapter(
    ref.watch(accountRepositoryProvider),
  );
});
