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

String makeUuid(int id) =>
    '00000000-0000-0000-0000-${id.toString().padLeft(12, '0')}';

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
  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    return AccountMapping({
      AccountRole.cash: const AccountRoleRef(
        role: AccountRole.cash,
        accountUuid: 'acc_cash_reg_101',
        accountCode: '1010',
        accountName: 'Main Cash Register Account',
      ),
      AccountRole.receivable: const AccountRoleRef(
        role: AccountRole.receivable,
        accountUuid: 'acc_rec_cust_201',
        accountCode: '1100',
        accountName: 'Customer Receivables',
      ),
      AccountRole.revenue: const AccountRoleRef(
        role: AccountRole.revenue,
        accountUuid: 'acc_rev_401',
        accountCode: '4010',
        accountName: 'Sales Revenue',
      ),
      AccountRole.cogs: const AccountRoleRef(
        role: AccountRole.cogs,
        accountUuid: 'acc_cogs_501',
        accountCode: '5010',
        accountName: 'COGS',
      ),
      AccountRole.inventory: const AccountRoleRef(
        role: AccountRole.inventory,
        accountUuid: 'acc_inv_120',
        accountCode: '1200',
        accountName: 'Inventory Asset',
      ),
    });
  }
}

class FakeInvalidCashAccountMappingResolver implements AccountMappingResolver {
  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    return AccountMapping({
      AccountRole.cash: const AccountRoleRef(
        role: AccountRole.cash,
        accountUuid: 'invalid_cash_account',
        accountCode: '9999',
        accountName: 'Invalid Cash Account',
      ),
      AccountRole.revenue: const AccountRoleRef(
        role: AccountRole.revenue,
        accountUuid: 'acc_rev_401',
        accountCode: '4010',
        accountName: 'Sales Revenue',
      ),
    });
  }
}

void main() {
  group('SA-07 — Sales Payments & Cash Register Integration Tests', () {
    late AccountingEntryBuilder entryBuilder;
    const validator = SaleValidator();

    setUp(() {
      entryBuilder = AccountingEntryBuilder(
        mappingResolver: FakeAccountMappingResolver(),
        validationService: const FakeAccountValidationService(),
      );
    });

    test(
      '1. Cash sale integration generates DEBIT to Cash Register Account and CREDIT to Sales Revenue',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: makeUuid(1),
          saleNumber: 'INV-PAY-001',
          saleDate: DateTime.now(),
          total: 150.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'acc_cash_reg_101',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 80.0,
        );

        expect(drafts.length, equals(2)); // 1 Revenue entry + 1 COGS entry

        final revenueEntry = drafts.firstWhere((d) => d.sourceType == 'sale');
        expect(revenueEntry.voucherType, equals('بيع نقدي'));

        final cashDebitLine = revenueEntry.lines.firstWhere((l) => l.debit > 0);
        expect(cashDebitLine.accountUuid, equals('acc_cash_reg_101'));
        expect(cashDebitLine.debit, equals(150.0));

        final revenueCreditLine = revenueEntry.lines.firstWhere(
          (l) => l.credit > 0,
        );
        expect(revenueCreditLine.accountUuid, equals('acc_rev_401'));
        expect(revenueCreditLine.credit, equals(150.0));

        final cogsEntry = drafts.firstWhere((d) => d.sourceType == 'sale_cogs');
        expect(
          cogsEntry.lines.firstWhere((l) => l.debit > 0).debit,
          equals(80.0),
        );
      },
    );

    test(
      '2. Credit sale integration generates DEBIT to Customer Receivable without touching Cash Register Account',
      () async {
        final sale = SaleInvoicePostingData(
          uuid: makeUuid(2),
          saleNumber: 'INV-PAY-002',
          saleDate: DateTime.now(),
          total: 300.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.credit,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          customerAccountId: 'acc_rec_cust_201',
        );

        final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
          sale: sale,
          calculatedCogsCost: 120.0,
        );

        final revenueEntry = drafts.firstWhere((d) => d.sourceType == 'sale');
        expect(revenueEntry.voucherType, equals('بيع آجل'));

        final recDebitLine = revenueEntry.lines.firstWhere((l) => l.debit > 0);
        expect(recDebitLine.accountUuid, equals('acc_rec_cust_201'));
        expect(recDebitLine.debit, equals(300.0));

        // Cash account is NOT present in credit sale lines
        expect(
          revenueEntry.lines.any((l) => l.accountUuid == 'acc_cash_reg_101'),
          isFalse,
        );
      },
    );

    test('3. Credit sale validation requires customerAccountId', () {
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

    test(
      '4. Payment validation rejects invalid/inactive accounting account',
      () async {
        final invalidEntryBuilder = AccountingEntryBuilder(
          mappingResolver: FakeInvalidCashAccountMappingResolver(),
          validationService: const FakeAccountValidationService(),
        );

        final sale = SaleInvoicePostingData(
          uuid: makeUuid(4),
          saleNumber: 'INV-PAY-004',
          saleDate: DateTime.now(),
          total: 100.0,
          itemDiscountTotal: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          settlementType: PostingSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          cashAccountId: 'invalid_cash_account',
        );

        expect(
          invalidEntryBuilder.buildDraftsFromSaleInvoice(
            sale: sale,
            calculatedCogsCost: 0.0,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
