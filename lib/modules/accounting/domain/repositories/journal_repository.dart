import '../entities/journal_entry.dart';

/// Persistence for journal entries / ledger movements.
abstract class JournalRepository {
  /// Posts a balanced entry. Throws [JournalException] on validation failure.
  ///
  /// When [JournalEntryDraft.sourceType] + [JournalEntryDraft.sourceId] are set
  /// and a non-deleted entry already exists, replaces that entry in place
  /// (same uuid; header updated; lines deleted and reinserted).
  Future<JournalEntry> post(JournalEntryDraft draft);

  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  });

  /// Soft-deletes the entry for a source document (phase-1 void).
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  });

  /// Ledger movements for one account (not deleted), ordered by date then id.
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
  });

  /// Net signed amount (debit − credit) before [beforeDate] for opening balance.
  Future<double> sumNetBefore({
    required String accountUuid,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  });
}
