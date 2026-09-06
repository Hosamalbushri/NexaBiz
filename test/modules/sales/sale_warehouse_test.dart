import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/presentation/providers/sale_composer_provider.dart';

void main() {
  group('Sales Warehouse Selection Tests', () {
    test('SaleComposerState default warehouseId is null and canSave returns false', () {
      final state = SaleComposerState(
        saleDate: DateTime.now(),
      );

      expect(state.warehouseId, isNull);
      expect(state.canSave, isFalse);
    });

    test('SaleComposerState copyWith and setWarehouse updates warehouseId', () {
      final state = SaleComposerState(
        saleDate: DateTime.now(),
        warehouseId: 'wh_main_01',
      );

      expect(state.warehouseId, equals('wh_main_01'));

      final updated = state.copyWith(warehouseId: 'wh_secondary_02');
      expect(updated.warehouseId, equals('wh_secondary_02'));

      final cleared = updated.copyWith(clearWarehouseId: true);
      expect(cleared.warehouseId, isNull);
    });

    test('toDraft includes warehouseId', () {
      final state = SaleComposerState(
        saleDate: DateTime(2026, 9, 6),
        settlementType: SaleSettlementType.cash,
        warehouseId: 'wh_main_01',
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        discountType: DiscountType.fixed,
        discountValue: 0,
        taxRate: 0,
        paidAmount: 100,
        paymentMethod: PaymentMethod.cash,
      );

      final draft = state.toDraft();
      expect(draft.warehouseId, equals('wh_main_01'));
    });
  });
}
