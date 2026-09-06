import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';

import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_money.dart';

String makeUuid(int id) =>
    '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}';

class FakeAccountValidationService implements AccountValidationService {
  const FakeAccountValidationService();

  @override
  Future<AccountValidationResult> validateAccountUuid(
    String accountUuid,
  ) async {
    return AccountValidationResult.valid;
  }

  @override
  Future<void> assertCanPost(String accountUuid) async {}
}

class FakeAccountMappingResolver implements AccountMappingResolver {
  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    return AccountMapping({
      AccountRole.cash: const AccountRoleRef(
        role: AccountRole.cash,
        accountUuid: 'acc_cash_101',
        accountCode: '1010',
        accountName: 'Cash',
      ),
      AccountRole.revenue: const AccountRoleRef(
        role: AccountRole.revenue,
        accountUuid: 'acc_rev_401',
        accountCode: '4010',
        accountName: 'Sales Revenue',
      ),
      AccountRole.discount: const AccountRoleRef(
        role: AccountRole.discount,
        accountUuid: 'acc_disc_502',
        accountCode: '5020',
        accountName: 'Sales Discount',
      ),
      AccountRole.tax: const AccountRoleRef(
        role: AccountRole.tax,
        accountUuid: 'acc_tax_202',
        accountCode: '2020',
        accountName: 'Tax Payable',
      ),
    });
  }
}

void main() {
  group('SA-09 — Sales Financial Calculation Integrity Tests', () {
    const calcService = SaleCalculationService();
    late AccountingEntryBuilder entryBuilder;

    setUp(() {
      entryBuilder = AccountingEntryBuilder(
        mappingResolver: FakeAccountMappingResolver(),
        validationService: const FakeAccountValidationService(),
      );
    });

    test('1. Subtotal invariant: subtotal equals sum of line subtotals', () {
      final items = [
        const SaleItemDraft(
          productId: 'p1',
          productName: 'Item 1',
          productCode: 'P1',
          mainQuantity: 3,
          unitPrice: 25.50,
          baseUnitPrice: 25.50,
        ),
        const SaleItemDraft(
          productId: 'p2',
          productName: 'Item 2',
          productCode: 'P2',
          mainQuantity: 2,
          unitPrice: 40.25,
          baseUnitPrice: 40.25,
        ),
      ];

      final lines = calcService.calculateLines(items);
      final expectedSubtotal = lines.fold<double>(
        0.0,
        (sum, l) => sum + l.subtotal,
      ); // 76.50 + 80.50 = 157.00

      final summary = calcService.calculate(items: items);
      expect(summary.subtotal, equals(157.00));
      expect(summary.subtotal, equals(expectedSubtotal));
    });

    test(
      '2. Multi-tier discount invariant: Item discount + Header discount prevents double discounting',
      () {
        final items = [
          const SaleItemDraft(
            productId: 'p1',
            productName: 'Item 1',
            productCode: 'P1',
            mainQuantity: 2,
            unitPrice: 100.0, // Subtotal 200
            baseUnitPrice: 100.0,
            discountType: DiscountType.percentage,
            discountValue: 10.0, // 10% line discount = 20.0, net = 180.0
          ),
        ];

        final summary = calcService.calculate(
          items: items,
          saleDiscountType: DiscountType.percentage,
          saleDiscountValue: 10.0, // 10% header discount on 180.0 net = 18.0
        );

        expect(summary.subtotal, equals(200.0));
        expect(summary.itemDiscountTotal, equals(20.0));
        expect(summary.saleDiscount, equals(18.0));
        expect(summary.total, equals(162.0)); // 200 - 20 - 18 = 162.0
      },
    );

    test(
      '3. Tax invariant: Tax calculated strictly on post-discount net amount',
      () {
        final items = [
          const SaleItemDraft(
            productId: 'p1',
            productName: 'Item 1',
            productCode: 'P1',
            mainQuantity: 1,
            unitPrice: 100.0,
            baseUnitPrice: 100.0,
            discountType: DiscountType.fixed,
            discountValue: 20.0, // Net 80.0
          ),
        ];

        final summary = calcService.calculate(
          items: items,
          taxRatePercent: 15.0, // 15% tax on 80.0 = 12.0
        );

        expect(summary.subtotal, equals(100.0));
        expect(summary.itemDiscountTotal, equals(20.0));
        expect(summary.tax, equals(12.0));
        expect(summary.total, equals(92.0)); // 80.0 + 12.0 = 92.0
      },
    );

    test(
      '4. Grand total invariant: grandTotal equals subtotal - discounts + tax',
      () {
        final items = [
          const SaleItemDraft(
            productId: 'p1',
            productName: 'Item 1',
            productCode: 'P1',
            mainQuantity: 5,
            unitPrice: 33.33,
            baseUnitPrice: 33.33,
            discountType: DiscountType.fixed,
            discountValue: 6.65,
          ),
        ];

        final summary = calcService.calculate(
          items: items,
          saleDiscountType: DiscountType.fixed,
          saleDiscountValue: 10.0,
          taxRatePercent: 10.0,
        );

        final expectedGrandTotal = SaleMoney.round(
          summary.subtotal -
              (summary.itemDiscountTotal + summary.saleDiscount) +
              summary.tax,
        );
        expect(summary.total, equals(expectedGrandTotal));
      },
    );

    test(
      '5. Settlement invariant: paidAmount + remainingAmount equals grandTotal',
      () {
        final items = [
          const SaleItemDraft(
            productId: 'p1',
            productName: 'Item 1',
            productCode: 'P1',
            mainQuantity: 1,
            unitPrice: 250.0,
            baseUnitPrice: 250.0,
          ),
        ];

        final summary = calcService.calculate(items: items, paidAmount: 100.0);

        expect(summary.total, equals(250.0));
        expect(summary.paidAmount, equals(100.0));
        expect(summary.remainingAmount, equals(150.0));
        expect(
          summary.paidAmount + summary.remainingAmount,
          equals(summary.total),
        );
      },
    );

    test('6. Cents-based rounding drift immunity via SaleMoney', () {
      // 0.1 + 0.2 floating point anomaly testing
      final items = [
        const SaleItemDraft(
          productId: 'p1',
          productName: 'Item 1',
          productCode: 'P1',
          mainQuantity: 1,
          unitPrice: 0.10,
          baseUnitPrice: 0.10,
        ),
        const SaleItemDraft(
          productId: 'p2',
          productName: 'Item 2',
          productCode: 'P2',
          mainQuantity: 1,
          unitPrice: 0.20,
          baseUnitPrice: 0.20,
        ),
      ];

      final summary = calcService.calculate(items: items);
      expect(summary.subtotal, equals(0.30));
    });

    test(
      '7. Accounting entry line draft totals correspond exactly to finalized sale summary',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: makeUuid(70),
          saleNumber: 'INV-FIN-070',
          saleDate: DateTime.now(),
          total: 115.0, // 100 net + 15 tax
          itemDiscountTotal: 10.0,
          discountAmount: 10.0,
          taxAmount: 15.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_101',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 0.0,
        );

        final entry = drafts.first;
        final totalDebit = entry.lines.fold<double>(
          0.0,
          (sum, l) => sum + l.debit,
        );
        final totalCredit = entry.lines.fold<double>(
          0.0,
          (sum, l) => sum + l.credit,
        );

        expect(
          totalDebit,
          equals(totalCredit),
        ); // Journal entry is perfectly balanced
        expect(
          totalDebit,
          equals(135.0),
        ); // 115 cash + 20 discounts = 135 debit; 120 gross revenue + 15 tax = 135 credit
      },
    );
  });
}
