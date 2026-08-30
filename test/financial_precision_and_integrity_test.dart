import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_money.dart';

void main() {
  group('Financial Precision & 3-Decimal Currency Tests', () {
    test('JournalMoney handles 3-decimal currencies (KWD / OMR / BHD) without fils loss', () {
      const kwdAmount = 12.345; // 12 KWD 345 Fils
      final fils = JournalMoney.toCents(kwdAmount, decimalPlaces: 3);
      expect(fils, 12345);

      final reconstructed = JournalMoney.fromCents(fils, decimalPlaces: 3);
      expect(reconstructed, 12.345);
    });

    test('JournalMoney debit and credit sum to exact zero without floating point delta leak', () {
      final line1Debit = JournalMoney.round(100.125, decimalPlaces: 3); // 100.125
      final line2Debit = JournalMoney.round(50.375, decimalPlaces: 3);  // 50.375
      final line3Credit = JournalMoney.round(150.500, decimalPlaces: 3); // 150.500

      final totalDebitFils = JournalMoney.toCents(line1Debit, decimalPlaces: 3) + JournalMoney.toCents(line2Debit, decimalPlaces: 3);
      final totalCreditFils = JournalMoney.toCents(line3Credit, decimalPlaces: 3);

      expect(totalDebitFils, totalCreditFils);
      expect(totalDebitFils, 150500);
    });

    test('SaleMoney applies percentage and fixed discounts across 3 decimals', () {
      const basePrice = 100.000;
      final discountAmount = SaleMoney.applyDiscount(
        base: basePrice,
        isPercentage: true,
        discountValue: 15.5, // 15.5%
        decimalPlaces: 3,
      );

      expect(discountAmount, 15.500);
      expect(basePrice - discountAmount, 84.500);
    });

    test('SaleCalculationService calculates multi-item totals accurately', () {
      const service = SaleCalculationService();

      final items = [
        const SaleItemDraft(
          productId: 'P1',
          productName: 'Product A',
          productCode: 'PA',
          mainQuantity: 3,
          subQuantity: 0,
          packSize: 1,
          unitPrice: 10.250,
          baseUnitPrice: 10.250,
          discountType: DiscountType.fixed,
          discountValue: 0,
        ),
        const SaleItemDraft(
          productId: 'P2',
          productName: 'Product B',
          productCode: 'PB',
          mainQuantity: 2,
          subQuantity: 0,
          packSize: 1,
          unitPrice: 5.125,
          baseUnitPrice: 5.125,
          discountType: DiscountType.fixed,
          discountValue: 0,
        ),
      ];

      final summary = service.calculate(
        items: items,
        saleDiscountType: DiscountType.fixed,
        saleDiscountValue: 0,
        taxRatePercent: 10.0, // 10% VAT
        paidAmount: 45.000,
      );

      // (3 * 10.250) + (2 * 5.125) = 30.750 + 10.250 = 41.000
      expect(summary.subtotal, 41.000);
      // Tax: 41.000 * 10% = 4.100
      expect(summary.tax, 4.100);
      // Total: 45.100
      expect(summary.total, 45.100);
      // Remaining: 45.100 - 45.000 = 0.100
      expect(summary.remainingAmount, closeTo(0.100, 0.0001));
    });
  });
}
