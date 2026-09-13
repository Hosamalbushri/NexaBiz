import 'package:stock_count/core/utils/id_generator.dart';
import 'accounting_domain_authority_port.dart';
import 'accounting_effect.dart';
import 'accounting_failure.dart';
import 'accounting_journal_contracts.dart';
import 'accounting_posting_result.dart';
import 'accounting_transaction_context.dart';
import 'accounting_validation_result.dart';

/// Concrete implementation of [AccountingDomainAuthorityPort] enforcing the protected accounting domain authority pipeline.
class AccountingDomainAuthority implements AccountingDomainAuthorityPort {
  AccountingDomainAuthority();

  @override
  AccountingValidationResult validateContext(AccountingTransactionContext context) {
    try {
      if (context.companyId.trim().isEmpty) {
        return AccountingValidationResult.singleFailure(
          const MissingCompanyScopeFailure('Missing required company scope.'),
        );
      }
      return AccountingValidationResult.success();
    } on AccountingFailure catch (f) {
      return AccountingValidationResult.singleFailure(f);
    } catch (e) {
      return AccountingValidationResult.singleFailure(
        InvalidTransactionDateFailure(e.toString()),
      );
    }
  }

  @override
  AccountingValidationResult validateEffect(AccountingEffect effect) {
    final contextVal = validateContext(effect.context);
    if (!contextVal.isValid) {
      return contextVal;
    }

    final failures = <AccountingFailure>[];
    if (effect.lines.isEmpty) {
      failures.add(
        const InvalidAccountingEffectFailure('Effect must contain at least 1 line.'),
      );
    }

    for (final line in effect.lines) {
      if (line.accountUuid.trim().isEmpty) {
        failures.add(
          const InvalidAccountingEffectFailure('Line accountUuid cannot be empty.'),
        );
      }
      if (line.debit < 0 || line.credit < 0) {
        failures.add(
          InvalidAccountingEffectFailure(
            'Line debit/credit cannot be negative (${line.debit}, ${line.credit}).',
          ),
        );
      }
      if (line.debit == 0 && line.credit == 0) {
        failures.add(
          const InvalidAccountingEffectFailure(
            'Line must have non-zero debit or credit amount.',
          ),
        );
      }
    }

    if (!effect.isBalanced) {
      failures.add(
        UnbalancedJournalFailure(
          'Effect is unbalanced: debit total (${effect.totalDebit}) != credit total (${effect.totalCredit}).',
        ),
      );
    }

    if (failures.isNotEmpty) {
      return AccountingValidationResult.failure(failures);
    }
    return AccountingValidationResult.success();
  }

  @override
  AccountingJournal constructJournal(AccountingEffect effect) {
    final validation = validateEffect(effect);
    if (!validation.isValid) {
      throw validation.failures.first;
    }

    final entryUuid = generateUuidV4();
    final now = DateTime.now().toUtc();
    final rate = effect.context.exchangeRate ?? 1.0;

    final journalLines = <AccountingJournalLine>[];
    for (var i = 0; i < effect.lines.length; i++) {
      final line = effect.lines[i];
      final lineRate = line.exchangeRateToBase ?? rate;
      final baseDebit = line.baseDebit ?? (line.debit * lineRate);
      final baseCredit = line.baseCredit ?? (line.credit * lineRate);

      journalLines.add(
        AccountingJournalLine(
          uuid: generateUuidV4(),
          entryUuid: entryUuid,
          accountUuid: line.accountUuid,
          debit: line.debit,
          credit: line.credit,
          currencyCode: line.currencyCode,
          exchangeRateToBase: lineRate,
          baseDebit: baseDebit,
          baseCredit: baseCredit,
          lineDescription: line.lineDescription ?? effect.description,
          sortOrder: line.sortOrder != 0 ? line.sortOrder : i,
        ),
      );
    }

    return AccountingJournal(
      uuid: entryUuid,
      context: effect.context,
      voucherNumber: effect.voucherNumber,
      voucherType: effect.voucherType,
      description: effect.description,
      lines: journalLines,
      isPosted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  AccountingValidationResult validateJournalIntegrity(AccountingJournal journal) {
    if (!journal.isIntegrityValid) {
      return AccountingValidationResult.singleFailure(
        UnbalancedJournalFailure(
          'Journal integrity validation failed: base debit total (${journal.totalBaseDebit}) != base credit total (${journal.totalBaseCredit}).',
        ),
      );
    }
    return AccountingValidationResult.success();
  }

  @override
  Future<AccountingPostingResult> post(AccountingEffect effect) async {
    final effectValidation = validateEffect(effect);
    if (!effectValidation.isValid) {
      return AccountingPostingResult.failure(effectValidation.failures.first);
    }

    final journal = constructJournal(effect);
    final integrityValidation = validateJournalIntegrity(journal);
    if (!integrityValidation.isValid) {
      return AccountingPostingResult.failure(integrityValidation.failures.first);
    }

    final postedJournal = AccountingJournal(
      uuid: journal.uuid,
      context: journal.context,
      voucherNumber: journal.voucherNumber,
      voucherType: journal.voucherType,
      description: journal.description,
      lines: journal.lines,
      isPosted: true,
      createdAt: journal.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    return AccountingPostingResult.success(postedJournal);
  }
}
