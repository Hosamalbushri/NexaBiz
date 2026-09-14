import '../../chart_of_accounts/domain/repositories/account_repository.dart';
import '../foundation/accounting_effect.dart';
import '../policy/accounting_policy_port.dart';
import 'accounting_validation_engine_port.dart';
import 'accounting_validation_report.dart';

/// Central Implementation of [AccountingValidationEnginePort] validating all 15 accounting rule categories.
class AccountingValidationEngine implements AccountingValidationEnginePort {
  AccountingValidationEngine({
    required this._accountRepository,
    required this._policyPort,
    Set<String>? postedSourceTracker,
  })  : _postedSourceTracker = postedSourceTracker ?? {};

  final AccountRepository _accountRepository;
  final AccountingPolicyPort _policyPort;
  final Set<String> _postedSourceTracker;

  @override
  Future<AccountingValidationReport> validateEffect(AccountingEffect effect) async {
    final results = <AccountingValidationRuleResult>[];

    // Category A: Company Scope
    final companyId = effect.context.companyId.trim();
    if (companyId.isEmpty || _isIllegalCompanyId(companyId)) {
      results.add(
        const AccountingValidationRuleResult(
          rule: 'COMPANY_SCOPE',
          severity: AccountingRuleSeverity.error,
          affectedField: 'companyId',
          reason: 'Missing or illegal company scope.',
          actionableMessage: 'Specify a valid tenant companyId.',
        ),
      );
    }

    // Category B: Source Document
    final sourceRef = effect.context.sourceReference;
    if (sourceRef.sourceType.trim().isEmpty || sourceRef.sourceId.trim().isEmpty) {
      results.add(
        const AccountingValidationRuleResult(
          rule: 'SOURCE_DOCUMENT',
          severity: AccountingRuleSeverity.error,
          affectedField: 'sourceReference',
          reason: 'Source reference type or ID is empty.',
          actionableMessage: 'Provide explicit sourceType and sourceId.',
        ),
      );
    }

    // Category C: Accounting Period & Date Bounds
    final dateVal = _policyPort.isValidTransactionDate(effect.context.transactionDate);
    if (!dateVal) {
      results.add(
        AccountingValidationRuleResult(
          rule: 'ACCOUNTING_PERIOD',
          severity: AccountingRuleSeverity.error,
          affectedField: 'transactionDate',
          reason: 'Transaction date ${effect.context.transactionDate} is outside valid operational bounds.',
          actionableMessage: 'Provide a valid business date between 2000 and 2100.',
        ),
      );
    }

    if (companyId.isNotEmpty && !_isIllegalCompanyId(companyId)) {
      final periodOpen = await _policyPort.isPeriodOpen(
        companyId: companyId,
        transactionDate: effect.context.transactionDate,
      );
      if (!periodOpen) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'CLOSED_PERIOD',
            severity: AccountingRuleSeverity.error,
            affectedField: 'transactionDate',
            reason: 'Accounting period for date ${effect.context.transactionDate} is closed or outside fiscal year.',
            actionableMessage: 'Reopen fiscal period or choose a date in an open period.',
          ),
        );
      }
    }

    // Category F & G: Currency & Exchange Rate
    final curVal = await _policyPort.isValidCurrency(
      companyId: companyId,
      currencyCode: effect.context.currencyCode,
      baseCurrencyCode: effect.context.baseCurrencyCode,
    );
    if (!curVal) {
      results.add(
        const AccountingValidationRuleResult(
          rule: 'CURRENCY',
          severity: AccountingRuleSeverity.error,
          affectedField: 'currencyCode',
          reason: 'Invalid or fallback currency context.',
          actionableMessage: 'Configure an explicit ISO currency code.',
        ),
      );
    }

    final rate = effect.context.exchangeRate;
    if (rate != null && (rate.isNaN || rate.isInfinite || rate <= 0)) {
      results.add(
        AccountingValidationRuleResult(
          rule: 'EXCHANGE_RATE',
          severity: AccountingRuleSeverity.error,
          affectedField: 'exchangeRate',
          reason: 'Exchange rate must be positive and finite. Got $rate.',
          actionableMessage: 'Provide a positive exchange rate greater than 0.',
        ),
      );
    }

    // Category J: Duplicate Posting
    final sourceKey = '$companyId:${sourceRef.canonicalKey}';
    if (_postedSourceTracker.contains(sourceKey)) {
      results.add(
        AccountingValidationRuleResult(
          rule: 'DUPLICATE_POSTING',
          severity: AccountingRuleSeverity.error,
          affectedField: 'sourceReference',
          reason: 'Duplicate accounting effect detected for source reference $sourceKey.',
          actionableMessage: 'Do not re-post an already posted transaction effect.',
        ),
      );
    }

    // Category D, E, H, L, M, N: Account Line Validations & Money Precision
    double sumDebits = 0.0;
    double sumCredits = 0.0;

    for (var i = 0; i < effect.lines.length; i++) {
      final line = effect.lines[i];

      // Money Validation (NaN, Infinity, Negative)
      if (line.debit.isNaN || line.debit.isInfinite || line.credit.isNaN || line.credit.isInfinite) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'MONEY_NUMERIC',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i]',
            reason: 'Line debit/credit contains NaN or Infinity.',
            actionableMessage: 'Provide a valid numeric decimal amount.',
          ),
        );
      } else if (line.debit < 0 || line.credit < 0) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'MONEY_NEGATIVE',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i]',
            reason: 'Negative debit (${line.debit}) or credit (${line.credit}) is forbidden.',
            actionableMessage: 'Amounts must be non-negative.',
          ),
        );
      } else if (line.debit == 0 && line.credit == 0) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'MONEY_ZERO_LINE',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i]',
            reason: 'Line cannot have zero debit AND zero credit.',
            actionableMessage: 'Specify a non-zero debit or credit amount for the line.',
          ),
        );
      }

      sumDebits += line.debit;
      sumCredits += line.credit;

      // Account Existence, Activity, & Postability
      final accUuid = line.accountUuid.trim();
      if (accUuid.isEmpty) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'ACCOUNT_MISSING',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i].accountUuid',
            reason: 'Account UUID is empty.',
            actionableMessage: 'Assign a valid account to the line.',
          ),
        );
        continue;
      }

      final account = await _accountRepository.getByUuid(accUuid);
      if (account == null) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'ACCOUNT_NOT_FOUND',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i].accountUuid',
            reason: 'Account with UUID "$accUuid" not found in Chart of Accounts.',
            actionableMessage: 'Select an existing account from CoA.',
          ),
        );
        continue;
      }

      if (account.companyId != null && account.companyId!.trim().isNotEmpty) {
        if (account.companyId!.trim() != companyId) {
          results.add(
            AccountingValidationRuleResult(
              rule: 'CROSS_COMPANY_ACCOUNT',
              severity: AccountingRuleSeverity.error,
              affectedField: 'lines[$i].accountUuid',
              reason: 'Account "${account.name}" belongs to company "${account.companyId}", expected "$companyId".',
              actionableMessage: 'Use accounts belonging to the current tenant company.',
            ),
          );
        }
      }

      if (account.isDeleted) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'ACCOUNT_DELETED',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i].accountUuid',
            reason: 'Account "${account.name}" ($accUuid) is deleted.',
            actionableMessage: 'Restore account or assign an active account.',
          ),
        );
      }

      if (!account.isActive) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'ACCOUNT_INACTIVE',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i].accountUuid',
            reason: 'Account "${account.name}" ($accUuid) is inactive.',
            actionableMessage: 'Activate account or select an active account.',
          ),
        );
      }

      if (account.isGroup || !account.canPost) {
        results.add(
          AccountingValidationRuleResult(
            rule: 'ACCOUNT_NON_POSTABLE',
            severity: AccountingRuleSeverity.error,
            affectedField: 'lines[$i].accountUuid',
            reason: 'Account "${account.name}" ($accUuid) is a group header account.',
            actionableMessage: 'Select a leaf posting account.',
          ),
        );
      }
    }

    // Category I: Debit/Credit Balance (Exact Money Arithmetic)
    final debitCents = (sumDebits * 10000).round();
    final creditCents = (sumCredits * 10000).round();
    if ((debitCents - creditCents).abs() > 1) {
      results.add(
        AccountingValidationRuleResult(
          rule: 'UNBALANCED_JOURNAL',
          severity: AccountingRuleSeverity.error,
          affectedField: 'lines',
          reason: 'Accounting effect is unbalanced: total debits ($sumDebits) != total credits ($sumCredits).',
          actionableMessage: 'Ensure total debit equals total credit.',
        ),
      );
    }

    return AccountingValidationReport.evaluate(results);
  }

  bool _isIllegalCompanyId(String id) {
    final lower = id.toLowerCase();
    return lower == 'fallback' ||
        lower == 'default' ||
        lower == 'legacy_company' ||
        lower == 'global' ||
        lower == 'legacycompanyid';
  }
}
