import '../entities/sale.dart';

/// Optional inventory side-effects when sales change status.
///
/// Default provider is no-op — App wires [PerpetualSaleInventoryEffectAdapter]
/// via bootstrap. Sale posting (ترحيل) stays blocked while
/// [NoOpSaleInventoryEffectPort] is registered.
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
