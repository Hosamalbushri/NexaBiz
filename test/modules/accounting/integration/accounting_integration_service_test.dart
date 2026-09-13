import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_journal_contracts.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_transaction_context.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_service.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_decision.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_port.dart';
import 'package:stock_count/modules/accounting/domain/posting/accounting_posting_authority_port.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_rules_engine_port.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_transaction_intent.dart';

class FakeAccountingPolicy implements AccountingPolicyPort {
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
  Future<bool> isValidCurrency({required String companyId, required String currencyCode, required String baseCurrencyCode}) async => true;

  @override
  Future<bool> isPeriodOpen({required String companyId, required DateTime transactionDate}) async => true;

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({required String companyId, required DateTime transactionDate, required String currencyCode, required String baseCurrencyCode}) async => AccountingPolicyDecision.allowed(lifecycleState: AccountingLifecycleState.active);
}

class FakeRulesEngine implements AccountingRulesEnginePort {
  bool shouldSucceed = true;

  @override
  Future<AccountingEffect?> deriveAccountingEffect(AccountingBusinessTransaction transaction) async {
    if (!shouldSucceed) {
      return null;
    }

    return AccountingEffect(
      context: AccountingTransactionContext(
        companyId: transaction.companyId,
        sourceReference: transaction.sourceReference,
        transactionDate: transaction.transactionDate,
        currencyCode: transaction.currencyCode,
        baseCurrencyCode: transaction.baseCurrencyCode,
      ),
      voucherNumber: 'VOUCHER-001',
      voucherType: transaction.transactionType.name,
      lines: [
        AccountingEffectLine(
          accountUuid: 'acc-debit-001',
          debit: transaction.amount,
          credit: 0.0,
          currencyCode: transaction.currencyCode,
        ),
        AccountingEffectLine(
          accountUuid: 'acc-credit-001',
          debit: 0.0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
        ),
      ],
    );
  }
}

class FakePostingAuthority implements AccountingPostingAuthorityPort {
  bool postCalled = false;

  @override
  Future<AccountingPostingResult> postEffect(AccountingEffect effect) async {
    postCalled = true;
    final journal = AccountingJournal(
      uuid: 'journal-uuid-100',
      context: effect.context,
      voucherNumber: effect.voucherNumber,
      voucherType: effect.voucherType,
      isPosted: true,
      lines: [],
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    return AccountingPostingResult(
      isSuccess: true,
      journal: journal,
    );
  }

  @override
  Future<AccountingPostingResult> reverseJournal({
    required String journalUuid,
    required String reason,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  late FakeAccountingPolicy fakePolicy;
  late FakeRulesEngine fakeRulesEngine;
  late FakePostingAuthority fakePostingAuthority;
  late AccountingIntegrationService service;

  final companyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);

  setUp(() {
    fakePolicy = FakeAccountingPolicy();
    fakeRulesEngine = FakeRulesEngine();
    fakePostingAuthority = FakePostingAuthority();

    service = AccountingIntegrationService(
      policyPort: fakePolicy,
      rulesEngine: fakeRulesEngine,
      postingAuthority: fakePostingAuthority,
    );
  });

  group('AccountingIntegrationService Operational Domain Integration Tests', () {
    test('1. Optional Accounting Disabled: Sale transaction succeeds with 0 journals', () async {
      fakePolicy.active = false;

      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'sale',
        sourceId: 'sale-doc-001',
        transactionType: AccountingTransactionType.saleCash,
        transactionDate: validDate,
        amount: 150.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await service.processOperationalTransaction(req);

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNull);
      expect(fakePostingAuthority.postCalled, isFalse);
    });

    test('2. Sale -> Accounting Integration (Enabled)', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'sale',
        sourceId: 'sale-doc-002',
        transactionType: AccountingTransactionType.saleCredit,
        transactionDate: validDate,
        amount: 250.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
        customerId: 'cust-uuid-001',
      );

      final result = await service.processOperationalTransaction(req);

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNotNull);
      expect(fakePostingAuthority.postCalled, isTrue);
    });

    test('3. Inventory -> Accounting Integration (Enabled)', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'stock_transfer',
        sourceId: 'transfer-doc-001',
        transactionType: AccountingTransactionType.stockTransfer,
        transactionDate: validDate,
        amount: 500.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final result = await service.processOperationalTransaction(req);

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNotNull);
      expect(fakePostingAuthority.postCalled, isTrue);
    });

    test('4. Treasury -> Accounting Integration (Enabled)', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'customer_receipt',
        sourceId: 'receipt-doc-001',
        transactionType: AccountingTransactionType.customerReceipt,
        transactionDate: validDate,
        amount: 100.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
        customerId: 'cust-uuid-001',
      );

      final result = await service.processOperationalTransaction(req);

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNotNull);
      expect(fakePostingAuthority.postCalled, isTrue);
    });

    test('5. Purchase -> Accounting Integration (Enabled)', () async {
      final req = OperationalAccountingRequest(
        companyId: companyId,
        sourceType: 'purchase',
        sourceId: 'purch-doc-001',
        transactionType: AccountingTransactionType.purchaseCredit,
        transactionDate: validDate,
        amount: 400.0,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
        vendorId: 'vendor-uuid-001',
      );

      final result = await service.processOperationalTransaction(req);

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNotNull);
      expect(fakePostingAuthority.postCalled, isTrue);
    });
  });
}

