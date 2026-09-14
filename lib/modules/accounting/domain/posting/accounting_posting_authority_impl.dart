import 'dart:async';
import '../../journals/data/repositories/journal_repository_impl.dart';
import '../../journals/domain/entities/journal_entry.dart';
import '../../journals/domain/repositories/journal_repository.dart';
import '../builder/authoritative_journal_builder_port.dart';
import '../foundation/accounting_effect.dart';
import '../foundation/accounting_journal_contracts.dart';
import '../integrity/journal_integrity_engine_port.dart';
import '../validation/accounting_validation_engine_port.dart';
import 'accounting_posting_authority_port.dart';

/// Concrete implementation of [AccountingPostingAuthorityPort].
class AccountingPostingAuthority implements AccountingPostingAuthorityPort {
  AccountingPostingAuthority({
    required this._validationEngine,
    required this._journalBuilder,
    required this._integrityEngine,
    required this._journalRepository,
  });

  final AccountingValidationEnginePort _validationEngine;
  final AuthoritativeJournalBuilderPort _journalBuilder;
  final JournalIntegrityEnginePort _integrityEngine;
  final JournalRepository _journalRepository;

  final Set<String> _inFlightLocks = {};

  @override
  Future<AccountingPostingResult> postEffect(AccountingEffect effect) async {
    final sourceKey = '${effect.context.companyId}:${effect.context.sourceReference.canonicalKey}';

    // Concurrent duplicate posting guard
    if (_inFlightLocks.contains(sourceKey)) {
      return AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'Concurrent duplicate posting detected for source reference: ${effect.context.sourceReference.canonicalKey}',
      );
    }

    _inFlightLocks.add(sourceKey);

    try {
      // 1. Validation Gatekeeper
      final valReport = await _validationEngine.validateEffect(effect);
      if (!valReport.isValid) {
        final err = valReport.errors.first.reason;
        return AccountingPostingResult(
          isSuccess: false,
          journal: null,
          failureReason: 'Accounting Validation Engine Rejected Effect: $err',
        );
      }

      // 2. Journal Builder
      final journal = await _journalBuilder.buildJournal(effect);

      // 3. Journal Integrity Engine
      final integrityReport = await _integrityEngine.evaluateIntegrity(journal);
      if (!integrityReport.isValid) {
        final err = integrityReport.errors.first.reason;
        return AccountingPostingResult(
          isSuccess: false,
          journal: null,
          failureReason: 'Journal Integrity Engine Rejected Journal: $err',
        );
      }

      // 4. Atomic DB Persistence & Immutability Guarantee
      final draft = JournalEntryDraft(
        uuid: journal.uuid,
        entryDate: journal.context.transactionDate,
        voucherNumber: journal.voucherNumber,
        voucherType: journal.voucherType,
        currencyCode: journal.context.currencyCode,
        baseCurrencyCode: journal.context.baseCurrencyCode,
        description: journal.description,
        isPosted: true,
        sourceType: journal.context.sourceReference.sourceType,
        sourceId: journal.context.sourceReference.sourceId,
        lines: journal.lines.map((line) => JournalLineDraft(
          uuid: line.uuid,
          accountUuid: line.accountUuid,
          debit: line.debit,
          credit: line.credit,
          currencyCode: line.currencyCode,
          exchangeRateToBase: line.exchangeRateToBase,
          baseDebit: line.baseDebit,
          baseCredit: line.baseCredit,
          lineDescription: line.lineDescription,
          sortOrder: line.sortOrder,
        )).toList(),
      );

      final postedEntry = await _journalRepository.post(draft);

      final postedJournal = AccountingJournal(
        uuid: postedEntry.uuid,
        context: journal.context,
        voucherNumber: postedEntry.voucherNumber,
        voucherType: postedEntry.voucherType,
        description: postedEntry.description,
        isPosted: postedEntry.isPosted,
        lines: journal.lines,
        createdAt: postedEntry.createdAt,
        updatedAt: postedEntry.updatedAt,
      );

      return AccountingPostingResult(
        isSuccess: true,
        journal: postedJournal,
      );
    } catch (e) {
      return AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'Posting Failed with exception: $e',
      );
    } finally {
      _inFlightLocks.remove(sourceKey);
    }
  }

  @override
  Future<AccountingPostingResult> reverseJournal({
    required String journalUuid,
    required String reason,
  }) async {
    final existing = await _journalRepository.getByUuid(journalUuid);
    if (existing == null) {
      return const AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'Target journal entry for reversal not found.',
      );
    }

    if (!existing.isPosted) {
      return const AccountingPostingResult(
        isSuccess: false,
        journal: null,
        failureReason: 'Cannot reverse an unposted journal entry.',
      );
    }

    // Create reversing draft with inverted debits and credits
    final reverseLines = existing.lines.map((line) => JournalLineDraft(
      accountUuid: line.accountUuid,
      debit: line.credit, // Invert
      credit: line.debit, // Invert
      currencyCode: line.currencyCode,
      exchangeRateToBase: line.exchangeRateToBase,
      baseDebit: line.baseCredit,
      baseCredit: line.baseDebit,
      lineDescription: 'Reversal of ${existing.voucherNumber}: $reason',
      sortOrder: line.sortOrder,
    )).toList();

    final reverseDraft = JournalEntryDraft(
      entryDate: DateTime.now().toUtc(),
      voucherNumber: 'REV-${existing.voucherNumber}',
      voucherType: 'Reversal',
      currencyCode: existing.currencyCode,
      description: 'Reversal of ${existing.voucherNumber}: $reason',
      isPosted: true,
      sourceType: kJournalReverseSourceType,
      sourceId: existing.uuid,
      lines: reverseLines,
    );

    await _journalRepository.post(reverseDraft);
    await _journalRepository.softDeletePostedAfterReverse(existing.uuid);

    return const AccountingPostingResult(
      isSuccess: true,
      journal: null, // Successfully reversed
    );
  }
}
