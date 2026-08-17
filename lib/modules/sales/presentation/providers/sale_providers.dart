import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../../../modules/authentication/presentation/providers/auth_providers.dart';
import '../../data/database/sales_database.dart';
import '../../data/datasources/sale_invoice_pdf_printer.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/entities/sale.dart';
import '../../domain/models/sale_list_filter.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/services/sale_accounting_bridge_port.dart';
import '../../domain/services/sale_calculation_service.dart';
import '../../domain/services/sale_currency_port.dart';
import '../../domain/services/sale_customer_lookup_port.dart';
import '../../domain/services/sale_inventory_effect_port.dart';
import '../../domain/services/sale_ledger_posting_port.dart';
import '../../domain/services/sale_number_allocator_port.dart';
import '../../domain/services/sale_product_catalog_port.dart';
import '../../domain/services/sale_treasury_account_port.dart';
import '../../domain/services/sale_voucher_book_port.dart';
import '../../domain/services/device_sale_number.dart';
import '../../domain/usecases/sale_usecases.dart';

final salesDatabaseProvider = Provider<SalesDatabase>((ref) {
  final db = SalesDatabase();
  ref.onDispose(db.close);
  ref.keepAlive();
  return db;
});

final saleRepositoryImplProvider = Provider<SaleRepositoryImpl>((ref) {
  return SaleRepositoryImpl(
    ref.watch(salesDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
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
  return const NoOpSaleCustomerLookupPort();
});

/// Override in App with Inventory-backed adapter.
final saleProductCatalogPortProvider = Provider<SaleProductCatalogPort>((ref) {
  return const NoOpSaleProductCatalogPort();
});

final saleInventoryEffectPortProvider = Provider<SaleInventoryEffectPort>((
  ref,
) {
  // Replace with Inventory stock adapter to unlock sale posting (ترحيل).
  return const NoOpSaleInventoryEffectPort();
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
  return const NoOpSaleLedgerPostingPort();
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
  return const NoOpSaleTreasuryAccountPort();
});

/// Default: plain integer in this device's numeric lane (no device label).
final saleNumberAllocatorPortProvider = Provider<SaleNumberAllocatorPort>((
  ref,
) {
  final repo = ref.watch(saleRepositoryProvider);
  final base = deviceSaleNumberBase(
    ref.watch(syncApiConfigProvider).deviceId,
  );
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
