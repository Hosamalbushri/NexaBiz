import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/native.dart';

import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_base_amount_resolver.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency_rate.dart';

import 'package:stock_count/modules/sales/invoices/domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_money.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';

import 'package:stock_count/modules/receipts_payments/transactions/domain/services/rp_money.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ROOT FIX 14 — Financial Precision and Rounding Test Suite', () {
    test('1. Floating-point accumulation safety (0.1 + 0.2 == 0.3)', () {
      final double rawSum = 0.1 + 0.2;
      expect(rawSum == 0.3, isFalse); // Standard IEEE 754 float drift gives 0.30000000000000004

      final double safeSum = JournalMoney.add(0.1, 0.2);
      expect(safeSum, 0.3);
      expect(JournalMoney.toCents(safeSum), 30);
    });

    test('2. 3-decimal currencies (KWD / OMR / BHD) fils precision', () {
      const kwdAmount = 125.375; // 125 KWD 375 Fils
      final fils = JournalMoney.toCents(kwdAmount, decimalPlaces: 3);
      expect(fils, 125375);

      final reconstructed = JournalMoney.fromCents(fils, decimalPlaces: 3);
      expect(reconstructed, 125.375);

      final rounded = JournalMoney.round(125.3756, decimalPlaces: 3);
      expect(rounded, 125.376);
    });

    test('3. High quantity * small unit price scaling precision without loss', () {
      const quantity = 100000.0;
      const unitPrice = 0.0034; // $0.0034 per piece

      final roundedUnitCost = JournalMoney.roundUnitCost(unitPrice);
      expect(roundedUnitCost, 0.0034);

      final totalUnrounded = quantity * unitPrice; // 340.0
      final totalRounded = JournalMoney.round(totalUnrounded);
      expect(totalRounded, 340.0);
    });

    test('4. Very large quantities and fractional quantities', () {
      const largeQty = 1000000.5000;
      const unitPrice = 12.34;

      final roundedQty = JournalMoney.roundQuantity(largeQty);
      expect(roundedQty, 1000000.5);

      final lineTotal = JournalMoney.round(roundedQty * unitPrice);
      expect(lineTotal, 12340006.17);
    });

    test('5. Multi-line FX conversion penny-balancing guarantees SUM(debit) == SUM(credit)', () async {
      late AccountingDatabase db;
      late CurrencyRateRepositoryImpl rateRepo;

      db = AccountingDatabase(executor: NativeDatabase.memory());
      rateRepo = CurrencyRateRepositoryImpl(db, readCompanyId: () => 'test_company');

      await rateRepo.upsert(
        const CurrencyRateDraft(
          currencyCode: 'USD',
          rateToBase: 3.75,
        ),
      );

      final resolver = JournalBaseAmountResolver(rateRepo);

      // Create a foreign currency draft with line-by-line rounding disparity:
      // Line 1 Debit: 10.005 USD @ 3.75 -> 37.51875 -> rounded 37.52
      // Line 2 Debit: 10.005 USD @ 3.75 -> 37.51875 -> rounded 37.52 (Total base debit: 75.04)
      // Line 3 Credit: 20.009 USD @ 3.75 -> 75.03375 -> rounded 75.03 (Total base credit: 75.03)
      final lines = [
        const JournalLineDraft(
          accountUuid: 'acc1',
          debit: 10.005,
          credit: 0,
          currencyCode: 'USD',
        ),
        const JournalLineDraft(
          accountUuid: 'acc2',
          debit: 10.005,
          credit: 0,
          currencyCode: 'USD',
        ),
        const JournalLineDraft(
          accountUuid: 'acc3',
          debit: 0,
          credit: 20.009,
          currencyCode: 'USD',
        ),
      ];

      final resolved = await resolver.resolve(
        entryDate: DateTime.now(),
        baseCurrencyCode: 'SAR',
        lines: lines,
      );

      final sumBaseDebit = resolved.fold<double>(0, (s, l) => s + (l.baseDebit ?? 0));
      final sumBaseCredit = resolved.fold<double>(0, (s, l) => s + (l.baseCredit ?? 0));

      final int baseDebitCents = JournalMoney.toCents(sumBaseDebit);
      final int baseCreditCents = JournalMoney.toCents(sumBaseCredit);

      // Verify that penny-balancing adjusted the credit line so base debits and credits balance perfectly!
      expect(baseDebitCents, baseCreditCents);

      await db.close();
    });

    test('6. Tax and discount distribution without cent leakage', () {
      const calcService = SaleCalculationService();

      final items = [
        const SaleItemDraft(
          productId: 'P1',
          productName: 'Item 1',
          productCode: 'I1',
          mainQuantity: 3,
          subQuantity: 0,
          packSize: 1,
          unitPrice: 33.33,
          baseUnitPrice: 33.33,
          discountType: DiscountType.percentage,
          discountValue: 10.0, // 10% line discount
        ),
        const SaleItemDraft(
          productId: 'P2',
          productName: 'Item 2',
          productCode: 'I2',
          mainQuantity: 1,
          subQuantity: 0,
          packSize: 1,
          unitPrice: 99.99,
          baseUnitPrice: 99.99,
          discountType: DiscountType.percentage,
          discountValue: 15.0, // 15% line discount
        ),
      ];

      final summary = calcService.calculate(
        items: items,
        saleDiscountType: DiscountType.fixed,
        saleDiscountValue: 5.0,
        taxRatePercent: 15.0, // 15% VAT
        paidAmount: 180.0,
      );

      // Subtotal: (3 * 33.33) + 99.99 = 99.99 + 99.99 = 199.98
      expect(summary.subtotal, 199.98);

      // Item discounts: 10% of 99.99 = 10.00, 15% of 99.99 = 15.00 -> 25.00 total item discount
      expect(summary.itemDiscountTotal, 25.00);

      // After item discount = 174.98
      // Sale discount = 5.00 -> Net = 169.98
      // Tax = 15% of 169.98 = 25.497 -> rounded to 25.50
      expect(summary.tax, 25.50);

      // Total = 169.98 + 25.50 = 195.48
      expect(summary.total, 195.48);

      // Remaining = 195.48 - 180.00 = 15.48
      expect(summary.remainingAmount, 15.48);
    });

    test('7. RpMoney delegates to JournalMoney scale and preserves 3-decimal currencies', () {
      const omrAmount = 45.678;
      final rounded = RpMoney.round(omrAmount, decimalPlaces: 3);
      expect(rounded, 45.678);

      final fils = RpMoney.toCents(omrAmount, decimalPlaces: 3);
      expect(fils, 45678);

      final back = RpMoney.fromCents(fils, decimalPlaces: 3);
      expect(back, 45.678);
    });

    test('8. Repeated calculations produce identical results (Idempotency)', () {
      const calcService = SaleCalculationService();
      final items = [
        const SaleItemDraft(
          productId: 'P1',
          productName: 'Item 1',
          productCode: 'I1',
          mainQuantity: 7,
          subQuantity: 0,
          packSize: 1,
          unitPrice: 14.285,
          baseUnitPrice: 14.285,
          discountType: DiscountType.percentage,
          discountValue: 5.5,
        ),
      ];

      final run1 = calcService.calculate(items: items, taxRatePercent: 14.0);
      final run2 = calcService.calculate(items: items, taxRatePercent: 14.0);
      final run3 = calcService.calculate(items: items, taxRatePercent: 14.0);

      expect(run1.subtotal, run2.subtotal);
      expect(run2.subtotal, run3.subtotal);
      expect(run1.tax, run2.tax);
      expect(run2.tax, run3.tax);
      expect(run1.total, run2.total);
      expect(run2.total, run3.total);
    });
  });
}
