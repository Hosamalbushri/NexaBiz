import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_failure.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_journal_contracts.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_transaction_context.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_transaction_intent.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_port.dart';
import 'package:stock_count/modules/accounting/domain/integration/accounting_integration_service.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_lifecycle_state.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_decision.dart';
import 'package:stock_count/modules/accounting/domain/policy/accounting_policy_port.dart';
import 'package:stock_count/modules/accounting/domain/posting/accounting_posting_authority_port.dart';
import 'package:stock_count/modules/accounting/domain/rules/accounting_rules_engine_port.dart';

class MockPolicyPort implements AccountingPolicyPort {
  MockPolicyPort({required this.active, required this.configured});

  final bool active;
  final bool configured;

  @override
  Future<AccountingLifecycleState> getLifecycleState(String companyId) async =>
      active ? AccountingLifecycleState.active : AccountingLifecycleState.notConfigured;

  @override
  Future<bool> isActive(String companyId) async => active;

  @override
  Future<bool> isConfigured(String companyId) async => configured;

  @override
  Future<AccountingPolicyDecision> evaluatePostingPermission({
    required String companyId,
    required DateTime transactionDate,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async {
    if (!active) return AccountingPolicyDecision.disabledSkipped();
    if (!configured) {
      return AccountingPolicyDecision.denied(
        lifecycleState: AccountingLifecycleState.notConfigured,
        failure: const InvalidAccountingEffectFailure('Misconfigured'),
      );
    }
    return AccountingPolicyDecision.allowed(
      lifecycleState: AccountingLifecycleState.active,
    );
  }

  @override
  Future<bool> isPeriodOpen({required String companyId, required DateTime transactionDate}) async => true;

  @override
  bool isValidTransactionDate(DateTime date) => true;

  @override
  Future<bool> isValidCurrency({
    required String companyId,
    required String currencyCode,
    required String baseCurrencyCode,
  }) async => true;

  @override
  Future<bool> areAccountMappingsConfigured(String companyId) async => configured;
}

class MockRulesEngine implements AccountingRulesEnginePort {
  @override
  Future<AccountingEffect?> deriveAccountingEffect(
    AccountingBusinessTransaction transaction,
  ) async {
    return AccountingEffect(
      context: AccountingTransactionContext(
        companyId: transaction.companyId,
        sourceReference: transaction.sourceReference,
        transactionDate: transaction.transactionDate,
        currencyCode: transaction.currencyCode,
        baseCurrencyCode: transaction.baseCurrencyCode,
        exchangeRate: transaction.exchangeRate,
      ),
      voucherNumber: 'V-101',
      voucherType: 'Sale',
      lines: [
        AccountingEffectLine(
          accountUuid: 'acc_cash',
          debit: transaction.amount,
          credit: 0,
          currencyCode: transaction.currencyCode,
        ),
        AccountingEffectLine(
          accountUuid: 'acc_revenue',
          debit: 0,
          credit: transaction.amount,
          currencyCode: transaction.currencyCode,
        ),
      ],
    );
  }
}

class MockPostingAuthority implements AccountingPostingAuthorityPort {
  @override
  Future<AccountingPostingResult> postEffect(AccountingEffect effect) async {
    final now = DateTime.now();
    return AccountingPostingResult(
      isSuccess: true,
      journal: AccountingJournal(
        uuid: 'j_123',
        context: AccountingTransactionContext(
          companyId: 'company_001',
          sourceReference: AccountingSourceReference(
            sourceType: 'sale',
            sourceId: 's_01',
          ),
          transactionDate: now,
          currencyCode: 'YER',
          baseCurrencyCode: 'YER',
          exchangeRate: 1.0,
        ),
        voucherNumber: 'V-101',
        voucherType: 'Sale',
        isPosted: true,
        lines: const [],
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<AccountingPostingResult> reverseJournal({
    required String journalUuid,
    required String reason,
  }) async {
    return const AccountingPostingResult(isSuccess: true, journal: null);
  }
}

void main() {
  group('Accounting Integration State Tests (R2.6)', () {
    test('DISABLED state returns isSuccess: true with null journal', () async {
      final service = AccountingIntegrationService(
        policyPort: MockPolicyPort(active: false, configured: false),
        rulesEngine: MockRulesEngine(),
        postingAuthority: MockPostingAuthority(),
      );

      final result = await service.processOperationalTransaction(
        OperationalAccountingRequest(
          companyId: 'company_001',
          transactionType: AccountingTransactionType.saleCash,
          sourceType: 'sale',
          sourceId: 's_01',
          transactionDate: DateTime.now(),
          amount: 100.0,
          currencyCode: 'YER',
          baseCurrencyCode: 'YER',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNull);
    });

    test('MISCONFIGURED state returns isSuccess: false with failure reason', () async {
      final service = AccountingIntegrationService(
        policyPort: MockPolicyPort(active: true, configured: false),
        rulesEngine: MockRulesEngine(),
        postingAuthority: MockPostingAuthority(),
      );

      final result = await service.processOperationalTransaction(
        OperationalAccountingRequest(
          companyId: 'company_001',
          transactionType: AccountingTransactionType.saleCash,
          sourceType: 'sale',
          sourceId: 's_01',
          transactionDate: DateTime.now(),
          amount: 100.0,
          currencyCode: 'YER',
          baseCurrencyCode: 'YER',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.journal, isNull);
      expect(result.failureReason, contains('misconfigured'));
    });

    test('ENABLED state posts effect authoritatively', () async {
      final service = AccountingIntegrationService(
        policyPort: MockPolicyPort(active: true, configured: true),
        rulesEngine: MockRulesEngine(),
        postingAuthority: MockPostingAuthority(),
      );

      final result = await service.processOperationalTransaction(
        OperationalAccountingRequest(
          companyId: 'company_001',
          transactionType: AccountingTransactionType.saleCash,
          sourceType: 'sale',
          sourceId: 's_01',
          transactionDate: DateTime.now(),
          amount: 100.0,
          currencyCode: 'YER',
          baseCurrencyCode: 'YER',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.journal, isNotNull);
      expect(result.journal!.uuid, equals('j_123'));
    });
  });
}
