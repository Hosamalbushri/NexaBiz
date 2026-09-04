import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';

import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';


class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accountsByUuid = {};

  void add(Account account) {
    _accountsByUuid[account.uuid] = account;
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      _accountsByUuid.values.where((a) => includeInactive || a.isActive).toList();

  @override
  Future<Account?> getByUuid(String uuid) async => _accountsByUuid[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async {
    for (final acc in _accountsByUuid.values) {
      if (acc.accountCode == code) return acc;
    }
    return null;
  }

  @override
  Future<Account?> getById(int id) async => null;

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCompanyInitRepo implements CompanyInitializationRepository {
  CompanyAccountingConfig? _config;

  void setConfig(CompanyAccountingConfig config) {
    _config = config;
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => _config;

  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


Account createTestAccount({
  required int id,
  required String uuid,
  required String code,
  required String name,
  required AccountType accountType,
  required String companyId,
}) {
  return Account(
    id: id,
    uuid: uuid,
    accountCode: code,
    name: name,
    accountType: accountType,
    normalBalance: accountType.normalBalance,
    level: 3,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

void main() {
  group('Hardcoded Chart of Accounts Dependency Elimination Tests', () {
    late FakeAccountRepository accountRepo;
    late FakeCompanyInitRepo initRepo;
    late AccountValidationServiceImpl validationService;
    late AccountMappingResolverImpl mappingResolver;
    late AccountingEntryBuilder entryBuilder;

    const companyId = 'tenant_company_99';

    setUp(() {
      accountRepo = FakeAccountRepository();
      initRepo = FakeCompanyInitRepo();
      validationService = AccountValidationServiceImpl(accountRepo);
      mappingResolver = AccountMappingResolverImpl(
        accountRepository: accountRepo,
        validationService: validationService,
        initRepository: initRepo,
      );
      entryBuilder = AccountingEntryBuilder(
        mappingResolver: mappingResolver,
        validationService: validationService,
        initRepository: initRepo,
      );
    });

    test('1. Cash Sale Posting — Resolves cash and revenue dynamically via UUID without hardcoded codes', () async {
      accountRepo.add(createTestAccount(
        id: 1,
        uuid: 'custom_uuid_cash_box',
        code: '9901',
        name: 'صندوق الرئيسي المخصص',
        accountType: AccountType.asset,
        companyId: companyId,
      ));

      accountRepo.add(createTestAccount(
        id: 2,
        uuid: 'custom_uuid_sales_rev',
        code: '9902',
        name: 'إيراد المبيعات المخصص',
        accountType: AccountType.revenue,
        companyId: companyId,
      ));

      initRepo.setConfig(const CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {
          AccountRole.cash: 'custom_uuid_cash_box',
          AccountRole.revenue: 'custom_uuid_sales_rev',
        },
      ));

      final saleData = SaleInvoicePostingData(
        uuid: 'sale_inv_1001',
        saleNumber: 'INV-1001',
        saleDate: DateTime.now().toUtc(),
        total: 500.0,
        discountAmount: 0.0,
        itemDiscountTotal: 0.0,
        cashAccountId: 'custom_uuid_cash_box',
        settlementType: PostingSettlementType.cash,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
      );


      final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
        sale: saleData,
        calculatedCogsCost: 0.0,
      );

      expect(drafts, hasLength(1));
      final revDraft = drafts.first;

      expect(revDraft.lines, hasLength(2));
      expect(revDraft.lines[0].accountUuid, equals('custom_uuid_cash_box'));
      expect(revDraft.lines[0].debit, equals(500.0));
      expect(revDraft.lines[1].accountUuid, equals('custom_uuid_sales_rev'));
      expect(revDraft.lines[1].credit, equals(500.0));
    });

    test('2. Credit Sale Posting — Resolves receivable and revenue dynamically via UUID without hardcoded codes', () async {
      accountRepo.add(createTestAccount(
        id: 3,
        uuid: 'custom_uuid_customer_rec',
        code: '9903',
        name: 'حساب الذمم المدينة المخصص',
        accountType: AccountType.asset,
        companyId: companyId,
      ));

      accountRepo.add(createTestAccount(
        id: 2,
        uuid: 'custom_uuid_sales_rev',
        code: '9902',
        name: 'إيراد المبيعات المخصص',
        accountType: AccountType.revenue,
        companyId: companyId,
      ));

      initRepo.setConfig(const CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {
          AccountRole.receivable: 'custom_uuid_customer_rec',
          AccountRole.revenue: 'custom_uuid_sales_rev',
        },
      ));

      final saleData = SaleInvoicePostingData(
        uuid: 'sale_inv_1002',
        saleNumber: 'INV-1002',
        saleDate: DateTime.now().toUtc(),
        total: 1200.0,
        discountAmount: 0.0,
        itemDiscountTotal: 0.0,
        customerAccountId: 'custom_uuid_customer_rec',
        settlementType: PostingSettlementType.credit,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
      );


      final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
        sale: saleData,
        calculatedCogsCost: 0.0,
      );

      expect(drafts, hasLength(1));
      final revDraft = drafts.first;

      expect(revDraft.lines[0].accountUuid, equals('custom_uuid_customer_rec'));
      expect(revDraft.lines[0].debit, equals(1200.0));
      expect(revDraft.lines[1].accountUuid, equals('custom_uuid_sales_rev'));
      expect(revDraft.lines[1].credit, equals(1200.0));
    });

    test('3. Sales Discount Posting — Uses AccountRole.discount instead of AccountRole.cogs', () async {
      accountRepo.add(createTestAccount(
        id: 1,
        uuid: 'custom_uuid_cash_box',
        code: '9901',
        name: 'صندوق الرئيسي المخصص',
        accountType: AccountType.asset,
        companyId: companyId,
      ));

      accountRepo.add(createTestAccount(
        id: 2,
        uuid: 'custom_uuid_sales_rev',
        code: '9902',
        name: 'إيراد المبيعات المخصص',
        accountType: AccountType.revenue,
        companyId: companyId,
      ));

      accountRepo.add(createTestAccount(
        id: 4,
        uuid: 'custom_uuid_sales_discount',
        code: '9904',
        name: 'حساب خصم المبيعات المخصص',
        accountType: AccountType.revenue,
        companyId: companyId,
      ));

      initRepo.setConfig(const CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {
          AccountRole.cash: 'custom_uuid_cash_box',
          AccountRole.revenue: 'custom_uuid_sales_rev',
          AccountRole.discount: 'custom_uuid_sales_discount',
        },
      ));

      final saleData = SaleInvoicePostingData(
        uuid: 'sale_inv_1003',
        saleNumber: 'INV-1003',
        saleDate: DateTime.now().toUtc(),
        total: 900.0,
        discountAmount: 100.0,
        itemDiscountTotal: 0.0,
        cashAccountId: 'custom_uuid_cash_box',
        settlementType: PostingSettlementType.cash,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
      );

      final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
        sale: saleData,
        calculatedCogsCost: 0.0,
      );

      expect(drafts, hasLength(1));
      final revDraft = drafts.first;

      expect(revDraft.lines, hasLength(3));
      expect(revDraft.lines[0].accountUuid, equals('custom_uuid_cash_box'));
      expect(revDraft.lines[0].debit, equals(900.0));
      expect(revDraft.lines[1].accountUuid, equals('custom_uuid_sales_discount'));
      expect(revDraft.lines[1].debit, equals(100.0));
      expect(revDraft.lines[2].accountUuid, equals('custom_uuid_sales_rev'));
      expect(revDraft.lines[2].credit, equals(1000.0));
    });

    test('4. Inventory Receipt Posting — Resolves inventory and supplier payable accounts dynamically', () async {
      accountRepo.add(createTestAccount(
        id: 5,
        uuid: 'custom_uuid_inventory_asset',
        code: '9905',
        name: 'مخزون الأصول المخصص',
        accountType: AccountType.asset,
        companyId: companyId,
      ));

      accountRepo.add(createTestAccount(
        id: 6,
        uuid: 'custom_uuid_supplier_payable',
        code: '9906',
        name: 'حساب الموردين المخصص',
        accountType: AccountType.liability,
        companyId: companyId,
      ));

      initRepo.setConfig(const CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {
          AccountRole.inventory: 'custom_uuid_inventory_asset',
          AccountRole.payable: 'custom_uuid_supplier_payable',
        },
      ));

      final docRef = InventoryDocumentRef(
        documentId: 'receipt_5001',
        documentNumber: 'REC-5001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        currencyCode: 'YER',
        exchangeRate: 1.0,
      );

      final draft = await entryBuilder.buildDraftFromInventoryDocument(
        document: docRef,
        totalAmount: 3500.0,
      );

      expect(draft.lines, hasLength(2));
      expect(draft.lines[0].accountUuid, equals('custom_uuid_inventory_asset'));
      expect(draft.lines[0].debit, equals(3500.0));
      expect(draft.lines[1].accountUuid, equals('custom_uuid_supplier_payable'));
      expect(draft.lines[1].credit, equals(3500.0));
    });

    test('5. Missing Account Override — Throws controlled MissingAccountException when specified account does not exist', () async {
      accountRepo.add(createTestAccount(
        id: 1,
        uuid: 'custom_uuid_cash_box',
        code: '9901',
        name: 'صندوق الرئيسي المخصص',
        accountType: AccountType.asset,
        companyId: companyId,
      ));

      expect(
        () => mappingResolver.resolveForDocument(
          documentType: 'sale',
          overrides: {
            AccountRole.revenue: 'non_existent_rev_uuid',
          },
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('غير موجود في الدليل المحاسبي'),
        )),
      );
    });
  });
}

