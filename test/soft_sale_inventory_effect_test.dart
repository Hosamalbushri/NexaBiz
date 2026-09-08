import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/sales/perpetual_sale_inventory_effect_adapter.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/domain/services/product_stock_service.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PerpetualSaleInventoryEffectAdapter unlocks sale posting gate', () {
    final db = InventoryDatabase.memory();
    addTearDown(db.close);

    final perpetual = PerpetualSaleInventoryEffectAdapter(
      stock: ProductStockService(ProductRepositoryImpl(db, null, () => 'COMP-TEST')),
      cogs: _NoOpCogs(),
    );
    expect(isSalePostingEnabled(perpetual), isTrue);
    expect(isSalePostingEnabled(const NoOpSaleInventoryEffectPort()), isFalse);
  });
}

class _NoOpCogs implements SaleCogsEffectPort {
  @override
  Future<void> syncSale(sale) async {}

  @override
  Future<void> voidSale(sale) async {}
}
