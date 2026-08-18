import '../../modules/inventory/domain/models/product_exception.dart';
import '../../modules/inventory/domain/models/stock_quantity_line.dart';
import '../../modules/inventory/domain/services/product_stock_service.dart';
import '../../modules/sales/domain/entities/sale.dart';
import '../../modules/sales/domain/models/sale_exception.dart';
import '../../modules/sales/domain/services/sale_inventory_effect_port.dart';

/// COGS side-effect for posted sales (App-layer journal adapter).
abstract class SaleCogsEffectPort {
  Future<void> syncSale(Sale sale);

  Future<void> voidSale(Sale sale);
}

/// Perpetual inventory: issue stock on post, receive on cancel, with COGS journal.
class PerpetualSaleInventoryEffectAdapter implements SaleInventoryEffectPort {
  PerpetualSaleInventoryEffectAdapter({
    required ProductStockService stock,
    required SaleCogsEffectPort cogs,
  }) : _stock = stock,
       _cogs = cogs;

  final ProductStockService _stock;
  final SaleCogsEffectPort _cogs;

  @override
  Future<void> onConfirmed(Sale sale) async {
    final lines = _linesFor(sale);
    try {
      await _stock.issueLines(lines);
    } on ProductException catch (e) {
      if (e.code == ProductException.insufficientStock) {
        throw const SaleException(SaleException.insufficientStock);
      }
      rethrow;
    }

    try {
      await _cogs.syncSale(sale);
    } catch (e) {
      try {
        await _stock.receiveLines(lines);
      } catch (_) {
        // Best-effort stock rollback; surface COGS failure to caller.
      }
      rethrow;
    }
  }

  @override
  Future<void> onCancelled(Sale sale) async {
    await _cogs.voidSale(sale);
    await _stock.receiveLines(_linesFor(sale));
  }

  List<StockQuantityLine> _linesFor(Sale sale) {
    return [
      for (final item in sale.items)
        if (item.quantity > 0 && item.productId.trim().isNotEmpty)
          StockQuantityLine(
            productUuid: item.productId,
            quantity: item.quantity,
          ),
    ];
  }
}
