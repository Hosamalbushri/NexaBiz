import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/sales/soft_sale_inventory_effect_adapter.dart';
import 'package:stock_count/modules/sales/domain/services/sale_inventory_effect_port.dart';

void main() {
  test('SoftSaleInventoryEffectAdapter unlocks sale posting gate', () {
    const soft = SoftSaleInventoryEffectAdapter();
    expect(isSalePostingEnabled(soft), isTrue);
    expect(isSalePostingEnabled(const NoOpSaleInventoryEffectPort()), isFalse);
  });
}
