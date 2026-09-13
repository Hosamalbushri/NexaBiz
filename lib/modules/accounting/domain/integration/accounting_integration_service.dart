import '../foundation/accounting_effect.dart';
import '../foundation/accounting_source_reference.dart';
import '../foundation/accounting_transaction_context.dart';
import '../foundation/posting_intent.dart';
import '../policy/accounting_policy_port.dart';
import '../posting/accounting_posting_authority_port.dart';
import '../rules/accounting_rules_engine_port.dart';
import '../rules/accounting_transaction_intent.dart';
import '../validation/canonical_accounting_validation_boundary.dart';
import 'accounting_integration_port.dart';

/// Concrete implementation of [AccountingIntegrationPort].
class AccountingIntegrationService implements AccountingIntegrationPort {
  AccountingIntegrationService({
    required AccountingPolicyPort policyPort,
    required AccountingRulesEnginePort rulesEngine,
    required AccountingPostingAuthorityPort postingAuthority,
    CanonicalAccountingValidationBoundary? validationBoundary,
  })  : _policyPort = policyPort,
        _rulesEngine = rulesEngine,
        _postingAuthority = postingAuthority,
        _validationBoundary = validationBoundary;

  final AccountingPolicyPort _policyPort;
  final AccountingRulesEnginePort _rulesEngine;
  final AccountingPostingAuthorityPort _postingAuthority;
  final CanonicalAccountingValidationBoundary? _validationBoundary;

  @override
  Future<AccountingPostingResult> processOperationalTransaction(
    OperationalAccountingRequest request,
  ) async {
    // 1. Evaluate Accounting Integration State
    final isActive = await _policyPort.isActive(request.companyId);
    if (!isActive) {
      // DISABLED State: Accounting lifecycle is intentionally disabled for this company.
      return const AccountingPostingResult(
        isSuccess: true,
        journal: null, // Skipped because accounting is disabled
      );
    }

    final isConfigured = await _policyPort.isConfigured(request.companyId);
    if (!isConfigured) {
      // MISCONFIGURED State: Accounting is active but required configuration/mappings are missing.
      // Must FAIL and cause transaction ROLLBACK. Never return silent success with null journal.
      return AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason:
            'Accounting Configuration Error: Company "${request.companyId}" has active accounting '
            'but accounting rules or account mappings are misconfigured.',
      );
    }

    // 2. Resolve AccountingEffect via AccountingRulesEngine (Accounting owns GL account resolution)
    try {
      final effect = await _rulesEngine.deriveAccountingEffect(
        AccountingBusinessTransaction(
          companyId: request.companyId,
          transactionType: request.transactionType,
          sourceReference: AccountingSourceReference(
            sourceType: request.sourceType,
            sourceId: request.sourceId,
          ),
          transactionDate: request.transactionDate,
          amount: request.amount,
          currencyCode: request.currencyCode,
          baseCurrencyCode: request.baseCurrencyCode,
          exchangeRate: request.exchangeRate,
          warehouseId: request.warehouseId,
          description: request.description,
        ),
      );

      if (effect == null) {
        return AccountingPostingResult(
          isSuccess: false,
          journal: null,
          failureReason:
              'Accounting Rules Engine failed to derive accounting effect for transaction type "${request.transactionType}".',
        );
      }

      // 3. Post Effect authoritatively via AccountingPostingAuthority
      return await _postingAuthority.postEffect(effect);
    } catch (e) {
      return AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'Accounting posting failed: $e',
      );
    }
  }

  @override
  Future<AccountingPostingResult> processPostingIntent(
    PostingIntent intent,
  ) async {
    // 1. Evaluate Accounting Integration State
    final isActive = await _policyPort.isActive(intent.companyId);
    if (!isActive) {
      return const AccountingPostingResult(
        isSuccess: true,
        journal: null, // Skipped
      );
    }

    final isConfigured = await _policyPort.isConfigured(intent.companyId);
    if (!isConfigured) {
      return AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason:
            'Accounting Configuration Error: Company "${intent.companyId}" has active accounting '
            'but accounting rules or account mappings are misconfigured.',
      );
    }

    try {
      if (intent is ExplicitAccountPostingIntent) {
        // Validate explicit intent via CanonicalAccountingValidationBoundary
        if (_validationBoundary != null) {
          await _validationBoundary!.validateExplicitPosting(intent: intent);
        }

        final context = AccountingTransactionContext(
          companyId: intent.companyId,
          sourceReference: AccountingSourceReference(
            sourceType: intent.sourceType,
            sourceId: intent.sourceId,
          ),
          transactionDate: intent.transactionDate,
          currencyCode: intent.currencyCode,
          baseCurrencyCode: intent.baseCurrencyCode ?? intent.currencyCode,
          exchangeRate: intent.exchangeRate ?? 1.0,
        );

        final effectLines = intent.lines.map((line) => AccountingEffectLine(
          accountUuid: line.accountUuid,
          debit: line.debit,
          credit: line.credit,
          currencyCode: intent.currencyCode,
          lineDescription: line.lineDescription ?? intent.description,
          sortOrder: line.sortOrder,
        )).toList();

        final effect = AccountingEffect(
          context: context,
          voucherNumber: intent.voucherNumber,
          voucherType: intent.voucherType,
          description: intent.description ?? intent.voucherType,
          lines: effectLines,
        );

        return await _postingAuthority.postEffect(effect);
      } else if (intent is DeterminedAccountPostingIntent) {
        // Build operational request from determined intent
        final request = OperationalAccountingRequest(
          companyId: intent.companyId,
          sourceType: intent.sourceType,
          sourceId: intent.sourceId,
          transactionType: AccountingTransactionType.saleCredit, // default mapped type
          transactionDate: intent.transactionDate,
          amount: intent.amountsByRoleKey.values.fold(0.0, (a, b) => a + b),
          currencyCode: intent.currencyCode,
          baseCurrencyCode: intent.baseCurrencyCode ?? intent.currencyCode,
          exchangeRate: intent.exchangeRate ?? 1.0,
          description: intent.description,
        );
        return await processOperationalTransaction(request);
      }

      return const AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'Unsupported PostingIntent type',
      );
    } catch (e) {
      return AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'PostingIntent processing failed: $e',
      );
    }
  }
}

