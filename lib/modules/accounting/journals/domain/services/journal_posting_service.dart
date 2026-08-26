import '../entities/journal_entry.dart';
import '../models/journal_exception.dart';
import '../repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';

/// Application entry point for posting / voiding journals.
///
/// Period checks also run inside [JournalRepository.post]; this service adds
/// reverse-on-void for posted entries so product features never soft-delete
/// posted ledgers.
class JournalPostingService {
  const JournalPostingService({
    required JournalRepository journals,
    required AccountingPeriodValidator periodValidator,
  }) : _journals = journals,
       _periodValidator = periodValidator;

  /// Source type for reversing journals (`sourceId` = original entry UUID).
  static const reverseSourceType = 'journal_reverse';

  final JournalRepository _journals;
  final AccountingPeriodValidator _periodValidator;

  Future<JournalEntry> post(JournalEntryDraft draft) async {
    await _periodValidator.assertEntryAllowed(draft.entryDate);
    return _journals.post(draft);
  }

  /// Voids a journal: soft-delete drafts; reverse posted entries.
  Future<void> voidByUuid(String uuid) async {
    final existing = await _journals.getByUuid(uuid);
    if (existing == null) {
      throw const JournalException(JournalException.notFound);
    }
    if (!existing.isPosted) {
      await _periodValidator.assertEntryAllowed(existing.entryDate);
      await _journals.softDeleteByUuid(uuid);
      return;
    }
    await reverseByUuid(uuid);
  }

  /// Voids the active journal for a business document (sale, R&P, …).
  ///
  /// Posted → reverse JE, then tombstone original + reverse so the source id
  /// can be re-posted (pair leaves active ledgers at net zero via removal after
  /// reverse was recorded). Draft → soft-delete only.
  ///
  /// Manual UI void uses [voidByUuid] which keeps both original and reverse.
  Future<void> voidBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    final existing = await _journals.findBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    if (existing == null) {
      return;
    }
    if (!existing.isPosted) {
      await _periodValidator.assertEntryAllowed(existing.entryDate);
      await _journals.softDeleteBySource(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      return;
    }
    final reverse = await reverseByUuid(existing.uuid);
    await _journals.softDeletePostedAfterReverse(existing.uuid);
    await _journals.softDeletePostedAfterReverse(reverse.uuid);
  }

  /// Posts a reversing entry for a posted journal (swap debit/credit).
  Future<JournalEntry> reverseByUuid(
    String uuid, {
    DateTime? reverseDate,
  }) async {
    final existing = await _journals.getByUuid(uuid.trim());
    if (existing == null) {
      throw const JournalException(JournalException.notFound);
    }
    if (!existing.isPosted) {
      throw const JournalException(JournalException.notPosted);
    }

    final already = await _journals.findBySource(
      sourceType: reverseSourceType,
      sourceId: existing.uuid,
    );
    if (already != null) {
      throw const JournalException(JournalException.alreadyReversed);
    }

    final entryDate = reverseDate ?? existing.entryDate;
    await _periodValidator.assertEntryAllowed(entryDate);

    final description = existing.description?.trim();
    final reverseDescription = (description == null || description.isEmpty)
        ? 'عكس قيد ${existing.voucherNumber}'
        : 'عكس: $description';

    return _journals.post(
      JournalEntryDraft(
        entryDate: entryDate,
        voucherNumber: '${existing.voucherNumber}-R',
        voucherType: existing.voucherType,
        currencyCode: existing.currencyCode,
        baseCurrencyCode: existing.currencyCode,
        description: reverseDescription,
        isPosted: true,
        sourceType: reverseSourceType,
        sourceId: existing.uuid,
        lines: [
          for (final line in existing.lines)
            JournalLineDraft(
              accountUuid: line.accountUuid,
              debit: line.credit,
              credit: line.debit,
              currencyCode: line.currencyCode,
              exchangeRateToBase: line.exchangeRateToBase,
              baseDebit: line.baseCredit,
              baseCredit: line.baseDebit,
              lineDescription: line.lineDescription,
              sortOrder: line.sortOrder,
            ),
        ],
      ),
    );
  }

  @Deprecated('Use voidBySource — soft-delete of posted journals is blocked')
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) =>
      voidBySource(sourceType: sourceType, sourceId: sourceId);

  @Deprecated('Use voidByUuid — soft-delete of posted journals is blocked')
  Future<void> softDeleteByUuid(String uuid) => voidByUuid(uuid);
}
