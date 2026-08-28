import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/tenancy/session_company.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';
import '../../data/datasources/sale_invoice_pdf_printer.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/entities/sale.dart';
import '../../domain/models/sale_list_filter.dart';
import '../../domain/repositories/sale_repository.dart';
import 'package:stock_count/app/sales/accounting_sale_ledger_adapter.dart';
import 'package:stock_count/app/sales/accounting_sale_treasury_adapter.dart';
import 'package:stock_count/app/sales/customers_sale_lookup_adapter.dart';
import 'package:stock_count/app/sales/inventory_sale_product_catalog_adapter.dart';
import 'package:stock_count/app/sales/perpetual_sale_inventory_effect_adapter.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/document_posting_providers.dart';
import 'package:stock_count/modules/customers/directory/presentation/providers/customer_providers.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/providers/stock_movements_providers.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_accounting_bridge_port.dart';
import '../../domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_currency_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_customer_lookup_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_ledger_posting_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_number_allocator_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_product_catalog_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_treasury_account_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_voucher_book_port.dart';
import '../../domain/services/device_sale_number.dart';
import '../../domain/usecases/sale_usecases.dart';

final salesDatabaseProvider = Provider<SalesDatabase>((ref) {
  final db = SalesDatabase(
    name: tenantScopedName('sales_master', ref.watch(sessionCompanyIdProvider)),
  );
  ref.onDispose(db.close);
  ref.keepAlive();
  return db;
});

final saleRepositoryImplProvider = Provider<SaleRepositoryImpl>((ref) {
  return SaleRepositoryImpl(
    ref.watch(salesDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return ref.watch(saleRepositoryImplProvider);
});

final saleCalculationServiceProvider = Provider<SaleCalculationService>((ref) {
  return const SaleCalculationService();
});

/// Override in App with Customers-backed adapter.
final saleCustomerLookupPortProvider = Provider<SaleCustomerLookupPort>((ref) {
  return CustomersSaleLookupAdapter(
    repository: ref.watch(customerRepositoryProvider),
    accountLinkPort: ref.watch(customerAccountLinkPortProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

/// Override in App with Inventory-backed adapter.
final saleProductCatalogPortProvider = Provider<SaleProductCatalogPort>((ref) {
  return InventorySaleProductCatalogAdapter(
    repository: ref.watch(productRepositoryProvider),
    scanResolver: ref.watch(productScanResolverProvider),
  );
});

final saleInventoryEffectPortProvider = Provider<SaleInventoryEffectPort>((
  ref,
) {
  return PerpetualSaleInventoryEffectAdapter(
    orchestrator: ref.watch(documentPostingOrchestratorProvider),
    stockMovementsRepository: ref.watch(stockMovementsRepositoryProvider),
  );
});

final salePostingEnabledProvider = Provider<bool>((ref) {
  return isSalePostingEnabled(ref.watch(saleInventoryEffectPortProvider));
});

final saleAccountingBridgePortProvider = Provider<SaleAccountingBridgePort>((
  ref,
) {
  return const NoOpSaleAccountingBridgePort();
});

/// Override in App with Accounting journal adapter (standalone credit sales).
final saleLedgerPostingPortProvider = Provider<SaleLedgerPostingPort>((ref) {
  return AccountingSaleLedgerAdapter(
    posting: ref.watch(journalPostingServiceProvider),
    accounts: ref.watch(accountRepositoryProvider),
  );
});

/// Override in App with Accounting voucher-book adapter.
final saleVoucherBookPortProvider = Provider<SaleVoucherBookPort>((ref) {
  return const NoOpSaleVoucherBookPort();
});

/// Override in App with company profile + currency rates adapter.
final saleCurrencyPortProvider = Provider<SaleCurrencyPort>((ref) {
  return const NoOpSaleCurrencyPort();
});

/// Override in App with Chart of Accounts cash/treasury adapter.
final saleTreasuryAccountPortProvider = Provider<SaleTreasuryAccountPort>((
  ref,
) {
  return AccountingSaleTreasuryAdapter(
    ref.watch(accountRepositoryProvider),
  );
});

/// Default: plain integer in this device's numeric lane (no device label).
final saleNumberAllocatorPortProvider = Provider<SaleNumberAllocatorPort>((
  ref,
) {
  final repo = ref.watch(saleRepositoryProvider);
  final base = deviceSaleNumberBase(ref.watch(syncApiConfigProvider).deviceId);
  return LocalSaleNumberAllocator(
    nextSequence: () => repo.nextLocalSequence(minExclusive: base),
  );
});

final watchSalesUseCaseProvider = Provider<WatchSales>((ref) {
  return WatchSales(ref.watch(saleRepositoryProvider));
});

final getSaleByIdUseCaseProvider = Provider<GetSaleById>((ref) {
  return GetSaleById(ref.watch(saleRepositoryProvider));
});

final createSaleUseCaseProvider = Provider<CreateSale>((ref) {
  return CreateSale(
    repository: ref.watch(saleRepositoryProvider),
    numberAllocator: ref.watch(saleNumberAllocatorPortProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
    voucherBookPort: ref.watch(saleVoucherBookPortProvider),
    ledgerPosting: ref.watch(saleLedgerPostingPortProvider),
    accountingBridge: ref.watch(saleAccountingBridgePortProvider),
  );
});

final updateSaleUseCaseProvider = Provider<UpdateSale>((ref) {
  return UpdateSale(
    repository: ref.watch(saleRepositoryProvider),
    ledgerPosting: ref.watch(saleLedgerPostingPortProvider),
    accountingBridge: ref.watch(saleAccountingBridgePortProvider),
  );
});

final confirmSaleUseCaseProvider = Provider<ConfirmSale>((ref) {
  return ConfirmSale(
    repository: ref.watch(saleRepositoryProvider),
    accountingBridge: ref.watch(saleAccountingBridgePortProvider),
    inventoryEffect: ref.watch(saleInventoryEffectPortProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
    ledgerPosting: ref.watch(saleLedgerPostingPortProvider),
  );
});

final cancelSaleUseCaseProvider = Provider<CancelSale>((ref) {
  return CancelSale(
    repository: ref.watch(saleRepositoryProvider),
    inventoryEffect: ref.watch(saleInventoryEffectPortProvider),
    permissionGuard: ref.watch(permissionGuardProvider),
    ledgerPosting: ref.watch(saleLedgerPostingPortProvider),
  );
});

final completeSaleUseCaseProvider = Provider<CompleteSale>((ref) {
  return CompleteSale(repository: ref.watch(saleRepositoryProvider));
});

final duplicateSaleUseCaseProvider = Provider<DuplicateSale>((ref) {
  return DuplicateSale(
    repository: ref.watch(saleRepositoryProvider),
    createSale: ref.watch(createSaleUseCaseProvider),
  );
});

final deleteSaleUseCaseProvider = Provider<DeleteSale>((ref) {
  return DeleteSale(ref.watch(saleRepositoryProvider));
});

final saleListFilterProvider = StateProvider<SaleListFilter>(
  (ref) => const SaleListFilter(),
);

/// Full-sale stream (details/workflows). Prefer [salesListProvider] for the list UI.
final salesProvider = StreamProvider.autoDispose<List<Sale>>((ref) {
  final filter = ref.watch(saleListFilterProvider);
  return ref.watch(watchSalesUseCaseProvider).call(filter);
});

final saleByIdProvider = FutureProvider.autoDispose.family<Sale?, int>((
  ref,
  id,
) async {
  return ref.watch(getSaleByIdUseCaseProvider).call(id);
});

/// Default tax rate (%) for new sales — configurable later via settings.
final salesDefaultTaxRateProvider = StateProvider<double>((ref) => 0);

final saleInvoicePdfPrinterProvider = Provider<SaleInvoicePdfPrinter>((ref) {
  return const SaleInvoicePdfPrinter();
});
