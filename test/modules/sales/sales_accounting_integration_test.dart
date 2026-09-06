import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_validator.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_accounting_bridge_port.dart';

class FakeAccountValidationService implements AccountValidationService {
  const FakeAccountValidationService();

  @override
  Future<AccountValidationResult> validateAccountUuid(
    String accountUuid,
  ) async {
    if (accountUuid.startsWith('invalid_') ||
        accountUuid.startsWith('inactive_')) {
      return AccountValidationResult(
        isValid: false,
        errorMessage: 'الحساب غير صالح: $accountUuid',
      );
    }
    return AccountValidationResult.valid;
  }

  @override
  Future<void> assertCanPost(String accountUuid) async {
    if (accountUuid.startsWith('invalid_') ||
        accountUuid.startsWith('inactive_')) {
      throw StateError('الحساب غير صالح للترحيل: $accountUuid');
    }
  }
}

class FakeAccountMappingResolver implements AccountMappingResolver {
  FakeAccountMappingResolver({
    this.cashAccountId = 'acc_cash_main',
    this.receivableAccountId = 'acc_rec_main',
    this.revenueAccountId = 'acc_rev_main',
    this.discountAccountId = 'acc_disc_main',
    this.taxAccountId = 'acc_tax_main',
    this.cogsAccountId = 'acc_cogs_main',
    this.inventoryAccountId = 'acc_inv_main',
  });

  final String cashAccountId;
  final String receivableAccountId;
  final String revenueAccountId;
  final String discountAccountId;
  final String taxAccountId;
  final String cogsAccountId;
  final String inventoryAccountId;

  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    final Map<AccountRole, AccountRoleRef> roles = {
      AccountRole.cash: AccountRoleRef(
        role: AccountRole.cash,
        accountUuid: overrides?[AccountRole.cash] ?? cashAccountId,
        accountCode: '1010',
        accountName: 'Cash',
      ),
      AccountRole.receivable: AccountRoleRef(
        role: AccountRole.receivable,
        accountUuid: overrides?[AccountRole.receivable] ?? receivableAccountId,
        accountCode: '1100',
        accountName: 'Receivables',
      ),
      AccountRole.revenue: AccountRoleRef(
        role: AccountRole.revenue,
        accountUuid: overrides?[AccountRole.revenue] ?? revenueAccountId,
        accountCode: '4010',
        accountName: 'Sales Revenue',
      ),
      AccountRole.discount: AccountRoleRef(
        role: AccountRole.discount,
        accountUuid: overrides?[AccountRole.discount] ?? discountAccountId,
        accountCode: '4020',
        accountName: 'Sales Discount',
      ),
      AccountRole.tax: AccountRoleRef(
        role: AccountRole.tax,
        accountUuid: overrides?[AccountRole.tax] ?? taxAccountId,
        accountCode: '2150',
        accountName: 'Output VAT',
      ),
      AccountRole.cogs: AccountRoleRef(
        role: AccountRole.cogs,
        accountUuid: overrides?[AccountRole.cogs] ?? cogsAccountId,
        accountCode: '5010',
        accountName: 'COGS',
      ),
      AccountRole.inventory: AccountRoleRef(
        role: AccountRole.inventory,
        accountUuid: overrides?[AccountRole.inventory] ?? inventoryAccountId,
        accountCode: '1200',
        accountName: 'Inventory Asset',
      ),
    };
    return AccountMapping(roles);
  }
}

void main() {
  group('SA-04 — Customer Receivables & Accounting Integration Tests', () {
    late AccountingEntryBuilder entryBuilder;
    const validator = SaleValidator();

    setUp(() {
      entryBuilder = AccountingEntryBuilder(
        mappingResolver: FakeAccountMappingResolver(),
        validationService: const FakeAccountValidationService(),
      );
    });

    test(
      '1. Cash sale journal entry generation (DEBIT Cash, CREDIT Revenue)',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: 'sale_cash_01',
          saleNumber: 'INV-1001',
          saleDate: DateTime.now(),
          total: 100.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_01',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 0.0,
        );

        expect(drafts.length, equals(1));
        final entry = drafts.first;
        expect(entry.voucherType, equals('بيع نقدي'));
        expect(entry.lines.length, equals(2));

        // Debit line: Cash account
        final debitLine = entry.lines.firstWhere((l) => l.debit > 0);
        expect(debitLine.accountUuid, equals('acc_cash_01'));
        expect(debitLine.debit, equals(100.0));

        // Credit line: Revenue account
        final creditLine = entry.lines.firstWhere((l) => l.credit > 0);
        expect(creditLine.accountUuid, equals('acc_rev_main'));
        expect(creditLine.credit, equals(100.0));
      },
    );

    test(
      '2. Credit sale journal entry generation (DEBIT Customer Receivable, CREDIT Revenue)',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: 'sale_credit_01',
          saleNumber: 'INV-1002',
          saleDate: DateTime.now(),
          total: 250.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.credit,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          customerAccountId: 'acc_cust_rec_101',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 0.0,
        );

        expect(drafts.length, equals(1));
        final entry = drafts.first;
        expect(entry.voucherType, equals('بيع آجل'));

        final debitLine = entry.lines.firstWhere((l) => l.debit > 0);
        expect(debitLine.accountUuid, equals('acc_cust_rec_101'));
        expect(debitLine.debit, equals(250.0));

        final creditLine = entry.lines.firstWhere((l) => l.credit > 0);
        expect(creditLine.accountUuid, equals('acc_rev_main'));
        expect(creditLine.credit, equals(250.0));
      },
    );

    test(
      '3. Sales discount accounting treatment (DEBIT Sales Discount)',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: 'sale_disc_01',
          saleNumber: 'INV-1003',
          saleDate: DateTime.now(),
          total: 180.0,
          itemDiscountTotal: 20.0, // Total discount = 20
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_01',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 0.0,
        );

        final entry = drafts.first;
        expect(entry.lines.length, equals(3));

        final cashLine = entry.lines.firstWhere(
          (l) => l.accountUuid == 'acc_cash_01',
        );
        expect(cashLine.debit, equals(180.0));

        final discLine = entry.lines.firstWhere(
          (l) => l.accountUuid == 'acc_disc_main',
        );
        expect(discLine.debit, equals(20.0));

        final revLine = entry.lines.firstWhere(
          (l) => l.accountUuid == 'acc_rev_main',
        );
        expect(revLine.credit, equals(200.0)); // Gross revenue = 180 + 20 = 200
      },
    );

    test(
      '4. Tax accounting treatment (CREDIT Tax Payable separated from Revenue)',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: 'sale_tax_01',
          saleNumber: 'INV-1004',
          saleDate: DateTime.now(),
          total: 115.0, // 100 subtotal + 15 tax
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 15.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_01',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 0.0,
        );

        final entry = drafts.first;
        expect(entry.lines.length, equals(3));

        final cashLine = entry.lines.firstWhere(
          (l) => l.accountUuid == 'acc_cash_01',
        );
        expect(cashLine.debit, equals(115.0));

        final taxLine = entry.lines.firstWhere(
          (l) => l.accountUuid == 'acc_tax_main',
        );
        expect(taxLine.credit, equals(15.0));

        final revLine = entry.lines.firstWhere(
          (l) => l.accountUuid == 'acc_rev_main',
        );
        expect(
          revLine.credit,
          equals(100.0),
        ); // Net gross revenue = 115 - 15 = 100
      },
    );

    test(
      '5. COGS journal entry generation (DEBIT COGS, CREDIT Inventory Asset from cost layer)',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: 'sale_cogs_01',
          saleNumber: 'INV-1005',
          saleDate: DateTime.now(),
          total: 300.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_01',
        );

        // Inventory engine resolved COGS cost = 160.0 (based on FIFO cost layer, not selling price 300)
        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 160.0,
        );

        expect(drafts.length, equals(2)); // 1 revenue entry + 1 COGS entry

        final cogsEntry = drafts.firstWhere((d) => d.sourceType == 'sale_cogs');
        expect(cogsEntry.voucherType, equals('تكلفة مبيعات'));

        final cogsLine = cogsEntry.lines.firstWhere((l) => l.debit > 0);
        expect(cogsLine.accountUuid, equals('acc_cogs_main'));
        expect(cogsLine.debit, equals(160.0));

        final invLine = cogsEntry.lines.firstWhere((l) => l.credit > 0);
        expect(invLine.accountUuid, equals('acc_inv_main'));
        expect(invLine.credit, equals(160.0));
      },
    );

    test('6. Credit sale validation requires customerAccountId', () {
      final creditDraftWithoutCustomer = SaleDraft(
        companyId: 'comp_01',
        warehouseId: 'wh_01',
        voucherBookId: 'vb_01',
        saleDate: DateTime.now(),
        settlementType: SaleSettlementType.credit,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        items: const [
          SaleItemDraft(
            productId: 'prod_01',
            productName: 'Product 1',
            productCode: 'P01',
            mainQuantity: 1,
            unitPrice: 100,
            baseUnitPrice: 100,
          ),
        ],
      );

      expect(
        () => validator.validate(creditDraftWithoutCustomer),
        throwsA(
          isA<SaleException>().having(
            (e) => e.code,
            'code',
            SaleException.customerRequired,
          ),
        ),
      );
    });

    test('7. No-op accounting bridge returns non-integrated mode', () async {
      const bridge = NoOpSaleAccountingBridgePort();
      final isIntegrated = await bridge.isIntegratedMode;
      expect(isIntegrated, isFalse);
    });
  });
}
