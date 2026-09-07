import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class FakeAccountMappingResolver implements AccountMappingResolver {
  @override
  Future<AccountMapping> resolveForDocument({
    required String documentType,
    Map<AccountRole, String>? overrides,
  }) async {
    return const AccountMapping({
      AccountRole.inventory: AccountRoleRef(
        role: AccountRole.inventory,
        accountUuid: 'acc-inventory-uuid',
        accountCode: '1200',
        accountName: 'المخزون',
      ),
      AccountRole.payable: AccountRoleRef(
        role: AccountRole.payable,
        accountUuid: 'acc-payable-uuid',
        accountCode: '2100',
        accountName: 'الموردين',
      ),
      AccountRole.cogs: AccountRoleRef(
        role: AccountRole.cogs,
        accountUuid: 'acc-cogs-uuid',
        accountCode: '5100',
        accountName: 'تكلفة المبيعات',
      ),
    });
  }
}

class FakeAccountValidationService implements AccountValidationService {
  @override
  Future<void> assertCanPost(String accountUuid) async {}

  @override
  Future<bool> canPost(String accountUuid) async => true;

  @override
  Future<AccountValidationResult> validateAccountUuid(
    String accountUuid,
  ) async {
    return AccountValidationResult.valid;
  }
}

class FakeCompanyInitRepo implements CompanyInitializationRepository {
  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async {
    return const CompanyInventoryConfig(
      companyId: 'comp_1',
      inventoryBaseCurrencyId: 'YER',
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Multi-Currency Inventory Journal Entry Tests', () {
    late AccountingEntryBuilder builder;

    setUp(() {
      builder = AccountingEntryBuilder(
        mappingResolver: FakeAccountMappingResolver(),
        validationService: FakeAccountValidationService(),
        initRepository: FakeCompanyInitRepo(),
      );
    });

    test(
      'Stock Receipt in USD creates Inventory line in YER and Payable line in USD',
      () async {
        final docRef = InventoryDocumentRef(
          documentId: 'receipt-101',
          documentNumber: 'REC-001',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.utc(2026, 9, 6),
          currencyCode: 'USD',
          exchangeRate: 145.0,
        );

        final draft = await builder.buildDraftFromInventoryDocument(
          document: docRef,
          totalAmount: 100.0, // $100 USD
        );

        expect(draft.currencyCode, equals('USD'));
        expect(draft.baseCurrencyCode, equals('YER'));
        expect(draft.lines.length, equals(2));

        // 1. Inventory Line (Debit): YER 14,500 with rate 1.0
        final inventoryLine = draft.lines.firstWhere(
          (l) => l.accountUuid == 'acc-inventory-uuid',
        );
        expect(inventoryLine.currencyCode, equals('YER'));
        expect(inventoryLine.debit, equals(14500.0)); // 100 * 145
        expect(inventoryLine.credit, equals(0.0));
        expect(inventoryLine.exchangeRateToBase, equals(1.0));

        // 2. Payable / Vendor Line (Credit): USD 100 with rate 145.0
        final payableLine = draft.lines.firstWhere(
          (l) => l.accountUuid == 'acc-payable-uuid',
        );
        expect(payableLine.currencyCode, equals('USD'));
        expect(payableLine.debit, equals(0.0));
        expect(payableLine.credit, equals(100.0));
        expect(payableLine.exchangeRateToBase, equals(145.0));
      },
    );
  });
}
