import '../entities/sale.dart';

/// Optional inventory side-effects when sales change status.
///
/// Default is no-op — there is no stock ledger yet. App may wire a future
/// Inventory adapter without Sales importing Inventory types.
///
/// Sale posting (ترحيل) stays blocked while [NoOpSaleInventoryEffectPort]
/// is registered; wiring a real adapter unlocks posting.
abstract class SaleInventoryEffectPort {
  Future<void> onConfirmed(Sale sale);

  Future<void> onCancelled(Sale sale);
}

class NoOpSaleInventoryEffectPort implements SaleInventoryEffectPort {
  const NoOpSaleInventoryEffectPort();

  @override
  Future<void> onConfirmed(Sale sale) async {}

  @override
  Future<void> onCancelled(Sale sale) async {}
}

/// True once inventory stock tracking is wired for sales.
bool isSalePostingEnabled(SaleInventoryEffectPort effect) =>
    effect is! NoOpSaleInventoryEffectPort;
