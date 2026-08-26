import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';

/// Soft unlock for sale posting (ترحيل) until a perpetual stock ledger exists.
///
/// Inventory today is catalog + stock-count only — there is no on-hand balance
/// API to debit on confirm. Wiring this non-[NoOpSaleInventoryEffectPort]
/// adapter unblocks [ConfirmSale] while documenting that stock qty effects
/// remain deferred (COGS / movements are Phase 5+ follow-ups).
class SoftSaleInventoryEffectAdapter implements SaleInventoryEffectPort {
  const SoftSaleInventoryEffectAdapter();

  @override
  Future<void> onConfirmed(Sale sale) async {}

  @override
  Future<void> onCancelled(Sale sale) async {}
}
