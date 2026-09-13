import '../../chart_of_accounts/domain/repositories/account_repository.dart';
import '../foundation/accounting_journal_contracts.dart';
import '../policy/accounting_policy_port.dart';
import 'journal_integrity_engine_port.dart';
import 'journal_integrity_report.dart';

/// Concrete implementation of [JournalIntegrityEnginePort].
class JournalIntegrityEngine implements JournalIntegrityEnginePort {
  JournalIntegrityEngine({
    required AccountRepository accountRepository,
    required AccountingPolicyPort policyPort,
    Set<String>? postedTracker,
  })  : _accountRepository = accountRepository,
        _policyPort = policyPort,
        _postedTracker = postedTracker ?? {};

  final AccountRepository _accountRepository;
  final AccountingPolicyPort _policyPort;
  final Set<String> _postedTracker;

  @override
  Future<JournalIntegrityReport> evaluateIntegrity(AccountingJournal journal) async {
    final report = JournalIntegrityReport();

    // 1. Company Valid
    final companyId = journal.context.companyId.trim();
    if (companyId.isEmpty) {
      report.addError(rule: 'COMPANY_INVALID', message: 'Journal context companyId is missing or empty.');
    }

    // 2. Period Valid
    final isPeriodOpen = await _policyPort.isPeriodOpen(
      companyId: companyId,
      transactionDate: journal.context.transactionDate,
    );
    if (!isPeriodOpen) {
      report.addError(
        rule: 'CLOSED_PERIOD',
        message: 'Journal transaction date ${journal.context.transactionDate} falls in a closed accounting period.',
      );
    }

    // 3. Source Reference Exists
    final source = journal.context.sourceReference;
    if (source.sourceType.trim().isEmpty || source.sourceId.trim().isEmpty) {
      report.addError(
        rule: 'SOURCE_REFERENCE_MISSING',
        message: 'Journal source reference (sourceType/sourceId) is invalid.',
      );
    }

    // 4. Line Count Valid (Minimum 2 lines)
    if (journal.lines.length < 2) {
      report.addError(
        rule: 'LINE_COUNT_INVALID',
        message: 'Journal must contain at least 2 lines (debit & credit). Found ${journal.lines.length}.',
      );
    }

    // 5 & 6. Account Existence & Company Match
    double totalBaseDebitInCents = 0;
    double totalBaseCreditInCents = 0;

    for (var i = 0; i < journal.lines.length; i++) {
      final line = journal.lines[i];

      // 7. Amount Validation (no NaN, Infinity, negative)
      if (line.debit.isNaN || line.debit.isInfinite || line.debit < 0) {
        report.addError(
          rule: 'INVALID_AMOUNT',
          message: 'Line $i has invalid debit amount ${line.debit}.',
          field: 'lines[$i].debit',
        );
      }
      if (line.credit.isNaN || line.credit.isInfinite || line.credit < 0) {
        report.addError(
          rule: 'INVALID_AMOUNT',
          message: 'Line $i has invalid credit amount ${line.credit}.',
          field: 'lines[$i].credit',
        );
      }

      // 8. Debit/Credit Direction
      if ((line.debit > 0 && line.credit > 0) || (line.debit == 0 && line.credit == 0)) {
        report.addError(
          rule: 'INVALID_DIRECTION',
          message: 'Line $i must have strictly positive debit OR credit, not both or neither.',
          field: 'lines[$i]',
        );
      }

      // 11. Exchange Rate Validation
      if (line.exchangeRateToBase.isNaN || line.exchangeRateToBase.isInfinite || line.exchangeRateToBase <= 0) {
        report.addError(
          rule: 'INVALID_EXCHANGE_RATE',
          message: 'Line $i exchange rate ${line.exchangeRateToBase} is invalid.',
          field: 'lines[$i].exchangeRateToBase',
        );
      }

      // Account Existence & Company Scope check
      if (line.accountUuid.trim().isEmpty) {
        report.addError(rule: 'ACCOUNT_MISSING', message: 'Line $i missing account UUID.', field: 'lines[$i]');
      } else {
        final acc = await _accountRepository.getByUuid(line.accountUuid);
        if (acc == null) {
          report.addError(
            rule: 'ACCOUNT_NOT_FOUND',
            message: 'Line $i account UUID ${line.accountUuid} not found.',
            field: 'lines[$i].accountUuid',
          );
        } else {
          if (acc.companyId != companyId) {
            report.addError(
              rule: 'ACCOUNT_COMPANY_MISMATCH',
              message: 'Line $i account ${acc.id} belongs to company ${acc.companyId}, not $companyId.',
              field: 'lines[$i].accountUuid',
            );
          }
          if (acc.isGroup || !acc.isActive || acc.isDeleted) {
            report.addError(
              rule: 'ACCOUNT_NOT_POSTABLE',
              message: 'Line $i account ${acc.id} is not a postable active account.',
              field: 'lines[$i].accountUuid',
            );
          }
        }
      }

      totalBaseDebitInCents += (line.baseDebit * 10000).roundToDouble();
      totalBaseCreditInCents += (line.baseCredit * 10000).roundToDouble();
    }

    // 9. Total Debits == Total Credits (Exact Arithmetic)
    final diff = (totalBaseDebitInCents - totalBaseCreditInCents).abs();
    if (diff > 1.0) { // 1.0 in 10,000ths = 0.0001
      report.addError(
        rule: 'UNBALANCED_JOURNAL',
        message: 'Journal is unbalanced: Base Debit (${journal.totalBaseDebit}) != Base Credit (${journal.totalBaseCredit}).',
      );
    }

    // 10. Currency Context
    if (journal.context.currencyCode.trim().isEmpty || journal.context.baseCurrencyCode.trim().isEmpty) {
      report.addError(rule: 'CURRENCY_INVALID', message: 'Journal context contains empty ISO currency codes.');
    }

    // 12. Duplicate Check
    final sourceKey = '$companyId:${source.canonicalKey}';
    final entryKey = '$companyId:${journal.uuid}';
    if (_postedTracker.contains(sourceKey) || _postedTracker.contains(entryKey)) {
      report.addError(
        rule: 'DUPLICATE_JOURNAL',
        message: 'Journal entry ${journal.uuid} or source reference ${source.canonicalKey} has already been posted.',
      );
    }

    // 13. Journal State Valid
    if (journal.uuid.trim().isEmpty) {
      report.addError(rule: 'JOURNAL_STATE_INVALID', message: 'Journal UUID is empty.');
    }

    // 14. Inventory Currency Restrictions
    if (source.sourceType.startsWith('stock') || source.sourceType.startsWith('inventory')) {
      for (final line in journal.lines) {
        if (line.currencyCode.trim().isEmpty) {
          report.addError(rule: 'INVENTORY_CURRENCY_VIOLATION', message: 'Inventory line missing currency code.');
        }
      }
    }

    return report;
  }
}
