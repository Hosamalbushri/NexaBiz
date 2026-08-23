import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/data/repositories/inventory_movement_ledger.dart';

void main() {
  group('InventoryMovementLedger Tests', () {
    late InventoryMovementLedger ledger;

    setUp(() {
      ledger = InventoryMovementLedger();
    });

    test('concurrent inventory movements both survive and calculate stock change', () async {
      final mov1 = InventoryMovementEvent(
        uuid: 'mov-1',
        itemCode: 'SKU-WIDGET',
        quantityChange: -10.0,
        movementType: 'sale',
        createdAt: DateTime.utc(2026, 8, 23, 10, 0),
      );

      final mov2 = InventoryMovementEvent(
        uuid: 'mov-2',
        itemCode: 'SKU-WIDGET',
        quantityChange: -20.0,
        movementType: 'sale',
        createdAt: DateTime.utc(2026, 8, 23, 10, 5),
      );

      await ledger.recordMovement(mov1);
      await ledger.recordMovement(mov2);

      final derivedStock = ledger.calculateDerivedStock(
        itemCode: 'SKU-WIDGET',
        openingBalance: 100.0,
      );

      expect(derivedStock, equals(70.0));
    });

    test('duplicate movement event is idempotent and ignored', () async {
      final mov1 = InventoryMovementEvent(
        uuid: 'mov-dup-1',
        itemCode: 'SKU-BOLT',
        quantityChange: 15.0,
        movementType: 'purchase',
        createdAt: DateTime.utc(2026, 8, 23, 11, 0),
      );

      await ledger.recordMovement(mov1);
      await ledger.applyRemoteMovement(mov1.toMap()); // Duplicate push/pull payload

      final stock = ledger.calculateDerivedStock(
        itemCode: 'SKU-BOLT',
        openingBalance: 0.0,
      );

      expect(stock, equals(15.0));
    });
  });
}
