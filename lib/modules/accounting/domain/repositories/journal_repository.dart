import '../entities/journal_entry.dart';

/// Keyset cursor for paginating [JournalRepository.listMovementsForAccount].
class AccountLedgerCursor {
  const AccountLedgerCursor({
    required this.entryDateMs,
    required this.sortOrder,
    required this.lineId,
  });

  final int entryDateMs;
  final int sortOrder;
  final int lineId;

  factory AccountLedgerCursor.fromMovement(AccountLedgerMovement movement) {
    return AccountLedgerCursor(
      entryDateMs: movement.entryDate.toUtc().millisecondsSinceEpoch,
      sortOrder: movement.sortOrder,
      lineId: movement.lineId,
    );
  }
}

/// Persistence for journal entries / ledger movements.
abstract class JournalRepository {
  /// Posts a balanced entry. Throws [JournalException] on validation failure.
  ///
  /// Replacement order:
  /// 1. [JournalEntryDraft.uuid] when set and found (non-deleted)
  /// 2. else [sourceType]+[sourceId] when set and found
  /// 3. else insert a new entry
  Future<JournalEntry> post(JournalEntryDraft draft);

  Future<JournalEntry?> getByUuid(String uuid);

  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  });

  /// Soft-deletes the entry for a source document.
  ///
  /// Applies to both posted and unposted entries (phase-1 void). Header is
  /// tombstoned; lines remain for audit. Ledger queries ignore deleted headers.
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  });

  Future<void> softDeleteByUuid(String uuid);

  /// Lightweight journal headers with debit/credit totals (no lines).
  Future<List<JournalEntryHeader>> listHeaders({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
    String? query,
    int? limit,
    int? afterId,
  });

  /// Ledger movements for one account (not deleted), ordered by date then id.
  ///
  /// Pass [limit] + [after] for keyset pagination (General Ledger / large
  /// statements). Omit both to load the full filtered window (reports with
  /// an explicit date range).
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
    int? limit,
    AccountLedgerCursor? after,
  });

  /// Distinct currency codes with activity for an account (DB-level).
  Future<List<String>> listCurrencyCodesForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  });

  /// Net signed amount (debit − credit) before [beforeDate] for opening balance.
  /// Computed with SQL aggregation — does not load historical rows into Dart.
  Future<double> sumNetBefore({
    required String accountUuid,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  });

  /// Asset/liability foreign positions as of [asOfInclusive] (posted only).
  Future<List<MonetaryFxPositionRow>> listMonetaryFxPositions({
    required DateTime asOfInclusive,
    required String baseCurrencyCode,
  });
}

/// Aggregated foreign monetary position used for FX revaluation.
class MonetaryFxPositionRow {
  const MonetaryFxPositionRow({
    required this.accountUuid,
    required this.currencyCode,
    required this.foreignBalance,
    required this.bookedBase,
  });

  final String accountUuid;
  final String currencyCode;
  final double foreignBalance;
  final double bookedBase;
}
