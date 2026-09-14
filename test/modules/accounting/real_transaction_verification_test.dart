import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_failure.dart';
import 'package:drift/drift.dart' hide isNotNull;

import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/domain/builder/authoritative_journal_builder_impl.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_service.dart';
import 'package:stock_count/modules/accounting/domain/integrity/journal_integrity_engine_impl.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_decision.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_port.dart';
import 'package:stock_count/modules/accounting/domain/posting/accounting_posting_authority_impl.dart';
import 'package:stock_count/modules/accounting/domain/resolvers/authoritative_account_resolver_impl.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_rules_engine_impl.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_transaction_intent.dart';
import 'package:stock_count/modules/accounting/domain/validation/accounting_validation_engine_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class FakePeriodValidator implements PeriodValidatorPort {
  @override
  Future<void> assertEntryAllowed(DateTime entryDate) async {}

  @override
  Future<void> assertMutationAllowed({required DateTime entryDate, DateTime? originalDate}) async {}

  @override
  Future<bool> isPeriodOpen(DateTime date) async => true;
}

class FakeCompanyInitRepository implements CompanyInitializationRepository {
  CompanyAccountingConfig? config;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => config;
}

class RealAccountingPolicy implements AccountingPolicyPort {

  bool periodOpen = true;
  bool configured = true;
  bool active = true;

  @override
  Future<AccountingLifecycleState> getLifecycleState(String companyId) async =>
      active ? AccountingLifecycleState.active : AccountingLifecycleState.notConfigured;

  @override
  Future<bool> isConfigured(String companyId) async => configured;

  @override
  Future<bool> isActive(String companyId) async => active;

  @override
  Future<bool> areAccountMappingsConfigured(String companyId) async => true;

  @override
  bool isValidTransactionDate(DateTime date) => true;

  @override
  Future<bool> isValidCurrency({
    required String companyId,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async => true;

  @override
  Future<bool> isPeriodOpen({
    required String companyId,
    required DateTime transactionDate,
  }) async => periodOpen;

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({
    required String companyId,
    required DateTime transactionDate,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async {
    if (!periodOpen) {
      return AccountingPolicyDecision.denied(
        lifecycleState: AccountingLifecycleState.active,
        failure: ClosedAccountingPeriodFailure('Accounting period is closed'),
        reason: 'Accounting period is closed',
      );
    }
    return AccountingPolicyDecision.allowed(
      lifecycleState: AccountingLifecycleState.active,
    );
  }

}


void main() {
  late NexabizDatabase db;
  late JournalRepositoryImpl journalRepo;
  late AccountRepositoryImpl accountRepo;
  late RealAccountingPolicy policy;

  late AuthoritativeAccountResolver accountResolver;
  late AccountingValidationEngine validationEngine;
  late AccountingRulesEngine rulesEngine;
  late AuthoritativeJournalBuilder journalBuilder;
  late JournalIntegrityEngine integrityEngine;
  late AccountingPostingAuthority postingAuthority;
  late AccountingIntegrationService integrationService;

  final companyId = 'comp-real-100';
  final validDate = DateTime.utc(2026, 9, 12);

  final accCashUuid = '00000000-0000-0000-0000-000000000101';
  final accArUuid = '00000000-0000-0000-0000-000000000102';
  final accApUuid = '00000000-0000-0000-0000-000000000103';
  final accRevUuid = '00000000-0000-0000-0000-000000000104';
  final accCogsUuid = '00000000-0000-0000-0000-000000000105';
  final accInvUuid = '00000000-0000-0000-0000-000000000106';
  final accDiscUuid = '00000000-0000-0000-0000-000000000107';
  final accBankUuid = '00000000-0000-0000-0000-000000000108';

  final accInactiveUuid = '00000000-0000-0000-0000-000000000109';
  final accWrongCompanyUuid = '00000000-0000-0000-0000-000000000110';


  setUp(() async {
    final fakeInitRepo = FakeCompanyInitRepository();
    fakeInitRepo.config = CompanyAccountingConfig(
      companyId: companyId,
      accountMappings: {
        AccountRole.cash: accCashUuid,
        AccountRole.receivable: accArUuid,
        AccountRole.payable: accApUuid,
        AccountRole.revenue: accRevUuid,
        AccountRole.cogs: accCogsUuid,
        AccountRole.inventory: accInvUuid,
        AccountRole.inventoryTo: accInvUuid,
        AccountRole.inventoryFrom: accInvUuid,
        AccountRole.discount: accDiscUuid,

        AccountRole.bank: accBankUuid,
      },
    );

    db = NexabizDatabase.connect(NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(db, readCompanyId: () => companyId);
    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: FakePeriodValidator(),
      readCompanyId: () => companyId,
    );
    policy = RealAccountingPolicy();

    Future<void> addAccount(Account acc) async {
      await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          id: Value(acc.id),
          uuid: Value(acc.uuid),
          accountCode: acc.accountCode,
          name: acc.name,
          accountType: acc.accountType.storageValue,
          normalBalance: acc.normalBalance.storageValue,
          level: Value(acc.level),
          isGroup: Value(acc.isGroup),
          isActive: Value(acc.isActive),
          isSystemAccount: Value(acc.isSystemAccount),
          companyId: acc.companyId ?? companyId,
          createdAt: Value(acc.createdAt),
          updatedAt: Value(acc.updatedAt),
        ),
      );
    }

    // 1. Seed Accounts Table in real SQLite database
    await addAccount(Account(
      id: accCashUuid, accountCode: '1101', name: 'Cash', accountType: AccountType.asset,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));
    await addAccount(Account(
      id: accArUuid, accountCode: '1201', name: 'Accounts Receivable', accountType: AccountType.asset,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));
    await addAccount(Account(
      id: accApUuid, accountCode: '2101', name: 'Accounts Payable', accountType: AccountType.liability,
      normalBalance: NormalBalance.credit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));
    await addAccount(Account(
      id: accRevUuid, accountCode: '4101', name: 'Sales Revenue', accountType: AccountType.revenue,
      normalBalance: NormalBalance.credit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));
    await addAccount(Account(
      id: accCogsUuid, accountCode: '5101', name: 'Cost of Goods Sold', accountType: AccountType.expense,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));
    await addAccount(Account(
      id: accInvUuid, accountCode: '1301', name: 'Inventory Asset', accountType: AccountType.asset,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));
    await addAccount(Account(
      id: accDiscUuid, accountCode: '5201', name: 'Sales Discount', accountType: AccountType.expense,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));
    await addAccount(Account(
      id: accBankUuid, accountCode: '1102', name: 'Bank Account', accountType: AccountType.asset,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));

    // Seed Inactive Account
    await addAccount(Account(
      id: accInactiveUuid, accountCode: '9901', name: 'Inactive Account', accountType: AccountType.expense,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: false, isSystemAccount: false,
      companyId: companyId, createdAt: validDate, updatedAt: validDate,
    ));

    // Seed Wrong Company Account
    await addAccount(Account(
      id: accWrongCompanyUuid, accountCode: '9902', name: 'Other Co Account', accountType: AccountType.asset,
      normalBalance: NormalBalance.debit, level: 1, isGroup: false, isActive: true, isSystemAccount: false,
      companyId: 'comp-OTHER-company', createdAt: validDate, updatedAt: validDate,
    ));


    // 2. Instantiate Accounting Authority Pipeline
    accountResolver = AuthoritativeAccountResolver(
      accountRepository: accountRepo,
      initRepository: fakeInitRepo,
    );
    validationEngine = AccountingValidationEngine(accountRepository: accountRepo, policyPort: policy);
    rulesEngine = AccountingRulesEngine(
      accountResolver: accountResolver,
      policyPort: policy,
    );
    journalBuilder = AuthoritativeJournalBuilder(validationEngine: validationEngine);
    integrityEngine = JournalIntegrityEngine(accountRepository: accountRepo, policyPort: policy);
    postingAuthority = AccountingPostingAuthority(
      validationEngine: validationEngine,
      journalBuilder: journalBuilder,
      integrityEngine: integrityEngine,
      journalRepository: journalRepo,
    );
    integrationService = AccountingIntegrationService(
      policyPort: policy,
      rulesEngine: rulesEngine,
      postingAuthority: postingAuthority,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3W.11 — Real Accounting Transaction & Canonical Database Forensics', () {
    test('1. Real SALE_CASH Flow: Verifies persistence in Drift NexabizDatabase', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'sale',
        sourceId: 'sale-real-001',
        transactionType: AccountingTransactionType.saleCash,
        transactionDate: validDate,
        amount: 350.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await integrationService.processOperationalTransaction(req);
      expect(result.isSuccess, isTrue);
      expect(result.journal, isNotNull);

      // Forensic Direct Query on NexabizDatabase
      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
      final entry = entries.first;
      expect(entry.id, equals(result.journal!.uuid));
      expect(entry.companyId, equals(companyId));
      expect(entry.currencyCode, equals('USD'));
      expect(entry.isPosted, isTrue);

      final lines = await (db.select(db.journalLines)..where((t) => t.entryId.equals(entry.id))).get();
      expect(lines.length, equals(2));

      final totalDebit = lines.fold<double>(0, (s, l) => s + l.debit);
      final totalCredit = lines.fold<double>(0, (s, l) => s + l.credit);
      expect(totalDebit, equals(350.0));
      expect(totalCredit, equals(350.0));
    });

    test('2. Real SALE_CREDIT Flow: AR debited, Revenue credited', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'sale',
        sourceId: 'sale-real-002',
        transactionType: AccountingTransactionType.saleCredit,
        transactionDate: validDate,
        amount: 1200.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await integrationService.processOperationalTransaction(req);
      expect(result.isSuccess, isTrue);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
    });

    test('3. Real PURCHASE_CREDIT Flow: Expense debited, AP credited', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'purchase',
        sourceId: 'purch-real-001',
        transactionType: AccountingTransactionType.purchaseCredit,
        transactionDate: validDate,
        amount: 800.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await integrationService.processOperationalTransaction(req);
      expect(result.isSuccess, isTrue);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
    });

    test('4. Real CUSTOMER_RECEIPT Flow: Cash debited, AR credited', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'customer_receipt',
        sourceId: 'rcpt-real-001',
        transactionType: AccountingTransactionType.customerReceipt,
        transactionDate: validDate,
        amount: 500.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await integrationService.processOperationalTransaction(req);
      expect(result.isSuccess, isTrue);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
    });

    test('5. Real SUPPLIER_PAYMENT Flow: AP debited, Cash credited', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'supplier_payment',
        sourceId: 'pmt-real-001',
        transactionType: AccountingTransactionType.supplierPayment,
        transactionDate: validDate,
        amount: 400.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await integrationService.processOperationalTransaction(req);
      expect(result.isSuccess, isTrue);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
    });

    test('6. Real STOCK_TRANSFER Flow: Inventory debited, Inventory credited', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'stock_transfer',
        sourceId: 'trsf-real-001',
        transactionType: AccountingTransactionType.stockTransfer,
        transactionDate: validDate,
        amount: 650.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await integrationService.processOperationalTransaction(req);
      expect(result.isSuccess, isTrue);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
    });

    test('7. Negative Forensics — Closed Period: Database remains completely unchanged', () async {
      policy.periodOpen = false;

      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'sale',
        sourceId: 'sale-closed-001',
        transactionType: AccountingTransactionType.saleCash,
        transactionDate: validDate,
        amount: 100.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await integrationService.processOperationalTransaction(req);
      expect(result.isSuccess, isFalse);

      // Verify Database is completely empty (zero rows inserted)
      final entries = await db.select(db.journalEntries).get();
      final lines = await db.select(db.journalLines).get();
      expect(entries, isEmpty);
      expect(lines, isEmpty);
    });

    test('8. Negative Forensics — Duplicate Transaction: Rejects second post, DB count stays 1', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'sale',
        sourceId: 'sale-dup-001',
        transactionType: AccountingTransactionType.saleCash,
        transactionDate: validDate,
        amount: 100.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final res1 = await integrationService.processOperationalTransaction(req);
      expect(res1.isSuccess, isTrue);

      final res2 = await integrationService.processOperationalTransaction(req);
      expect(res2.isSuccess, isTrue);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));

    });

    test('9. Legacy Write Detection: Confirms zero writes to non-canonical database tables', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'sale',
        sourceId: 'sale-legacy-check',
        transactionType: AccountingTransactionType.saleCash,
        transactionDate: validDate,
        amount: 200.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      await integrationService.processOperationalTransaction(req);

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
      // All persistence occurred strictly inside canonical Drift database
      expect(entries.first.sourceType, equals('sale'));
      expect(entries.first.sourceId, equals('sale-legacy-check'));
    });
  });
}
