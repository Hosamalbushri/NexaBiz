import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_decision.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_port.dart';
import 'package:stock_count/modules/accounting/domain/resolvers/authoritative_account_resolver_port.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_rules_engine_impl.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_transaction_intent.dart';

class FakeAuthoritativeAccountResolver implements AuthoritativeAccountResolverPort {
  final Map<AccountRole, Account> roleAccounts = {};

  @override
  Future<Account> resolveAccount({
    required String companyId,
    required AccountRole role,
    String? currencyCode,
    String? overrideAccountUuid,
  }) async {
    if (overrideAccountUuid != null && overrideAccountUuid.isNotEmpty) {
      return Account(
        id: overrideAccountUuid,
        accountCode: '9999',
        name: 'Custom Account $overrideAccountUuid',
        accountType: AccountType.asset,

        normalBalance: NormalBalance.debit,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyId,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }
    final acc = roleAccounts[role];
    if (acc != null) return acc;
    return Account(
      id: role.index + 1,
      uuid: 'acc-uuid-${role.name}',
      accountCode: '${1000 + role.index}',
      name: 'Account ${role.name}',
      accountType: AccountType.asset,
      normalBalance: NormalBalance.debit,
      level: 1,
      isGroup: false,
      isActive: true,
      isSystemAccount: false,
      companyId: companyId,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }
}

class FakeAccountingPolicy implements AccountingPolicyPort {
  bool active = true;

  @override
  Future<AccountingLifecycleState> getLifecycleState(String companyId) async =>
      active ? AccountingLifecycleState.active : AccountingLifecycleState.notConfigured;

  @override
  Future<bool> isConfigured(String companyId) async => active;

  @override
  Future<bool> isActive(String companyId) async => active;

  @override
  Future<bool> areAccountMappingsConfigured(String companyId) async => active;

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
  }) async => true;

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({
    required String companyId,
    required DateTime transactionDate,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async {
    if (!active) {
      return AccountingPolicyDecision.disabledSkipped();
    }
    return AccountingPolicyDecision.allowed(
      lifecycleState: AccountingLifecycleState.active,
    );
  }
}

void main() {
  late FakeAuthoritativeAccountResolver fakeResolver;
  late FakeAccountingPolicy fakePolicy;
  late AccountingRulesEngine engine;

  final companyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);
  final sourceRef = AccountingSourceReference(
    sourceType: 'sale',
    sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
  );

  setUp(() {
    fakeResolver = FakeAuthoritativeAccountResolver();
    fakePolicy = FakeAccountingPolicy();
    engine = AccountingRulesEngine(
      accountResolver: fakeResolver,
      policyPort: fakePolicy,
    );
  });

  group('AccountingRulesEngine Tests', () {
    test('SALE_CASH derives Dr Cash, Cr Sales Revenue', () async {
      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.saleCash,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 150.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNotNull);
      expect(effect!.lines.length, 2);
      expect(effect.lines[0].accountId, 'acc-uuid-cash');
      expect(effect.lines[0].debit, 150.0);
      expect(effect.lines[0].credit, 0.0);
      expect(effect.lines[1].accountId, 'acc-uuid-revenue');
      expect(effect.lines[1].debit, 0.0);
      expect(effect.lines[1].credit, 150.0);
    });

    test('SALE_CREDIT derives Dr Accounts Receivable, Cr Sales Revenue', () async {
      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.saleCredit,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 250.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNotNull);
      expect(effect!.lines[0].accountId, 'acc-uuid-receivable');
      expect(effect.lines[0].debit, 250.0);
      expect(effect.lines[1].accountId, 'acc-uuid-revenue');
      expect(effect.lines[1].credit, 250.0);
    });

    test('PURCHASE_CREDIT derives Dr Inventory, Cr Accounts Payable', () async {
      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.purchaseCredit,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 500.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNotNull);
      expect(effect!.lines[0].accountId, 'acc-uuid-inventory');
      expect(effect.lines[0].debit, 500.0);
      expect(effect.lines[1].accountId, 'acc-uuid-payable');
      expect(effect.lines[1].credit, 500.0);
    });

    test('STOCK_ISSUE derives Dr COGS, Cr Inventory', () async {
      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.stockIssue,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 80.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNotNull);
      expect(effect!.lines[0].accountId, 'acc-uuid-cogs');
      expect(effect.lines[0].debit, 80.0);
      expect(effect.lines[1].accountId, 'acc-uuid-inventory');
      expect(effect.lines[1].credit, 80.0);
    });

    test('CUSTOMER_RECEIPT derives Dr Cash, Cr Accounts Receivable', () async {
      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.customerReceipt,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 100.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNotNull);
      expect(effect!.lines[0].accountId, 'acc-uuid-cash');
      expect(effect.lines[0].debit, 100.0);
      expect(effect.lines[1].accountId, 'acc-uuid-receivable');
      expect(effect.lines[1].credit, 100.0);
    });

    test('BANK_TRANSFER derives Dr Bank To, Cr Bank From', () async {
      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.bankTransfer,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 300.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNotNull);
      expect(effect!.lines[0].accountId, 'acc-uuid-bank');
      expect(effect.lines[0].debit, 300.0);
      expect(effect.lines[1].accountId, 'acc-uuid-bank');
      expect(effect.lines[1].credit, 300.0);
    });

    test('returns null (clean skip) when accounting policy is inactive', () async {
      fakePolicy.active = false;

      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.saleCash,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 150.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNull);
    });

    test('preserves multi-currency context and exchange rate', () async {
      final tx = AccountingBusinessTransaction(
        companyId: companyId,
        transactionType: AccountingTransactionType.saleCash,
        sourceReference: sourceRef,
        transactionDate: validDate,
        amount: 100.0,
        currencyCode: 'EUR',
        baseCurrencyCode: 'USD',
        exchangeRate: 1.08,
      );

      final effect = await engine.deriveAccountingEffect(tx);
      expect(effect, isNotNull);
      expect(effect!.context.currencyCode, 'EUR');
      expect(effect.context.baseCurrencyCode, 'USD');
      expect(effect.context.exchangeRate, 1.08);
      expect(effect.lines[0].currencyCode, 'EUR');
    });
  });
}
