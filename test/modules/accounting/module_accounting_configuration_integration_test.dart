import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/accounting_entry_builder.dart';
import 'package:stock_count/modules/customers/customers_module_setup.dart';
import 'package:stock_count/modules/inventory/inventory_module_setup.dart';
import 'package:stock_count/modules/purchases/purchases_module_setup.dart';
import 'package:stock_count/modules/receipts_payments/receipts_payments_module_setup.dart';
import 'package:stock_count/modules/sales/sales_module_setup.dart';
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
  bool isGroup = false,
  bool isActive = true,
}) {
  return Account(
    id: id,
    uuid: uuid,
    accountCode: code,
    name: name,
    accountType: accountType,
    normalBalance: accountType.normalBalance,
    level: 3,
    isGroup: isGroup,
    isActive: isActive,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}


void main() {
  group('Phase 5 — Module Accounting Configuration Integration Tests', () {
    late CentralSetupRegistry registry;
    late FakeAccountRepository accountRepo;
    late FakeCompanyInitRepo initRepo;
    late AccountValidationServiceImpl validationService;
    late AccountMappingResolverImpl mappingResolver;
    late AccountingEntryBuilder entryBuilder;

    const tenantCompanyId = 'tenant_co_700';

    setUp(() {
      registry = CentralSetupRegistry();
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

      // Register package setup definitions
      registerInventorySetup(registry);
      registerSalesSetup(registry);
      registerPurchasesSetup(registry);
      registerCustomersSetup(registry);
      registerReceiptsPaymentsSetup(registry);
    });

    test('1. Setup Registry Discovery — Discovers setup definitions for all 5 business packages', () {
      expect(registry.isRegistered('inventory'), isTrue);
      expect(registry.isRegistered('sales'), isTrue);
      expect(registry.isRegistered('purchases'), isTrue);
      expect(registry.isRegistered('customers'), isTrue);
      expect(registry.isRegistered('receipts_payments'), isTrue);

      final invSetup = registry.get('inventory')!;
      final salesSetup = registry.get('sales')!;
      final purSetup = registry.get('purchases')!;

      expect(invSetup.displayName('ar'), equals('إعدادات المخزون'));
      expect(salesSetup.displayName('ar'), equals('إعدادات المبيعات'));
      expect(purSetup.displayName('ar'), equals('إعدادات المشتريات'));
    });

    test('2. Inventory Module Integration — Resolves custom inventory asset and COGS account UUIDs', () async {
      accountRepo.add(createTestAccount(
        id: 10,
        uuid: 'inv_asset_uuid_901',
        code: '1210',
        name: 'حساب المخزون الرئيسي المخصص',
        accountType: AccountType.asset,
        companyId: tenantCompanyId,
      ));

      accountRepo.add(createTestAccount(
        id: 11,
        uuid: 'cogs_uuid_902',
        code: '5100',
        name: 'حساب تكلفة البضاعة المباعة المخصص',
        accountType: AccountType.expense,
        companyId: tenantCompanyId,
      ));

      accountRepo.add(createTestAccount(
        id: 12,
        uuid: 'supplier_payable_uuid_903',
        code: '2110',
        name: 'حساب الموردين المخصص',
        accountType: AccountType.liability,
        companyId: tenantCompanyId,
      ));

      initRepo.setConfig(const CompanyAccountingConfig(
        companyId: tenantCompanyId,
        accountMappings: {
          AccountRole.inventory: 'inv_asset_uuid_901',
          AccountRole.cogs: 'cogs_uuid_902',
          AccountRole.payable: 'supplier_payable_uuid_903',
        },
      ));

      final docRef = InventoryDocumentRef(
        documentId: 'receipt_7001',
        documentNumber: 'REC-7001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now().toUtc(),
        currencyCode: 'YER',
        exchangeRate: 1.0,
      );

      final draft = await entryBuilder.buildDraftFromInventoryDocument(
        document: docRef,
        totalAmount: 4500.0,
      );


      expect(draft.lines[0].accountUuid, equals('inv_asset_uuid_901'));
      expect(draft.lines[0].debit, equals(4500.0));
      expect(draft.lines[1].accountUuid, equals('supplier_payable_uuid_903'));
      expect(draft.lines[1].credit, equals(4500.0));
    });

    test('3. Sales Module Integration — Resolves custom revenue, cash, and discount account UUIDs', () async {
      accountRepo.add(createTestAccount(
        id: 20,
        uuid: 'cash_box_uuid_801',
        code: '1110',
        name: 'الصندوق المركزي للمبيعات',
        accountType: AccountType.asset,
        companyId: tenantCompanyId,
      ));

      accountRepo.add(createTestAccount(
        id: 21,
        uuid: 'sales_rev_uuid_802',
        code: '4100',
        name: 'إيراد مبيعات المنتجات',
        accountType: AccountType.revenue,
        companyId: tenantCompanyId,
      ));

      accountRepo.add(createTestAccount(
        id: 22,
        uuid: 'sales_disc_uuid_803',
        code: '4150',
        name: 'خصم المبيعات المسموح به',
        accountType: AccountType.revenue,
        companyId: tenantCompanyId,
      ));

      initRepo.setConfig(const CompanyAccountingConfig(
        companyId: tenantCompanyId,
        accountMappings: {
          AccountRole.cash: 'cash_box_uuid_801',
          AccountRole.revenue: 'sales_rev_uuid_802',
          AccountRole.discount: 'sales_disc_uuid_803',
        },
      ));

      final saleData = SaleInvoicePostingData(
        uuid: 'sale_7002',
        saleNumber: 'INV-7002',
        saleDate: DateTime.now().toUtc(),
        total: 1800.0,
        discountAmount: 200.0,
        itemDiscountTotal: 0.0,
        cashAccountId: 'cash_box_uuid_801',
        settlementType: PostingSettlementType.cash,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
      );

      final drafts = await entryBuilder.buildDraftsFromSaleInvoice(
        sale: saleData,
        calculatedCogsCost: 0.0,
      );

      final revDraft = drafts.first;
      expect(revDraft.lines[0].accountUuid, equals('cash_box_uuid_801'));
      expect(revDraft.lines[0].debit, equals(1800.0));
      expect(revDraft.lines[1].accountUuid, equals('sales_disc_uuid_803'));
      expect(revDraft.lines[1].debit, equals(200.0));
      expect(revDraft.lines[2].accountUuid, equals('sales_rev_uuid_802'));
      expect(revDraft.lines[2].credit, equals(2000.0));
    });

    test('4. Purchases Module Integration — Resolves supplier payable and inventory asset accounts', () async {
      accountRepo.add(createTestAccount(
        id: 30,
        uuid: 'pur_inv_asset_uuid_701',
        code: '1210',
        name: 'مخزون بضائع الشراء',
        accountType: AccountType.asset,
        companyId: tenantCompanyId,
      ));

      accountRepo.add(createTestAccount(
        id: 31,
        uuid: 'pur_supplier_uuid_702',
        code: '2110',
        name: 'ذمم الموردين التجارية',
        accountType: AccountType.liability,
        companyId: tenantCompanyId,
      ));

      initRepo.setConfig(const CompanyAccountingConfig(
        companyId: tenantCompanyId,
        accountMappings: {
          AccountRole.inventory: 'pur_inv_asset_uuid_701',
          AccountRole.payable: 'pur_supplier_uuid_702',
        },
      ));

      final mapping = await mappingResolver.resolveForDocument(
        documentType: 'purchase_receipt',
      );

      expect(mapping.getRole(AccountRole.inventory)?.accountUuid, equals('pur_inv_asset_uuid_701'));
      expect(mapping.getRole(AccountRole.payable)?.accountUuid, equals('pur_supplier_uuid_702'));

    });

    test('5. Validation Gate — Rejects invalid or deleted accounts in configuration binding', () async {
      accountRepo.add(createTestAccount(
        id: 40,
        uuid: 'inactive_acc_uuid_601',
        code: '9999',
        name: 'حساب غير نشط غير صالح',
        accountType: AccountType.expense,
        companyId: tenantCompanyId,
        isActive: false,
      ));

      expect(
        () async => validationService.assertCanPost('inactive_acc_uuid_601'),
        throwsA(isA<StateError>()),
      );

    });
  });
}
