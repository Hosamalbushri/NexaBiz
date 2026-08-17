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

  /// Soft-deletes a **draft** (unposted) entry for a source document.
  ///
  /// Throws [JournalException.postedImmutable] when the active entry is posted.
  /// Use [JournalPostingService.voidBySource] to reverse posted entries.
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  });

  /// Soft-deletes a **draft** entry by UUID.
  ///
  /// Throws [JournalException.postedImmutable] when posted.
  Future<void> softDeleteByUuid(String uuid);

  /// Tombstones a posted entry after an operational reverse (source reuse).
  ///
  /// Only [JournalPostingService.voidBySource] should call this, and only after
  /// a reversing entry exists so active ledgers stay balanced (both removed).
  Future<void> softDeletePostedAfterReverse(String uuid);

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

  /// Trial balance rows: SUM(base_debit) / SUM(base_credit) per posting account.
  Future<List<TrialBalanceRow>> listTrialBalance({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  });

  /// Journal book (دفتر اليومية) lines in entry order, base currency amounts.
  Future<List<JournalBookLineRow>> listJournalBookLines({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
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

/// One trial-balance account aggregate in company base currency.
class TrialBalanceRow {
  const TrialBalanceRow({
    required this.accountUuid,
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  final String accountUuid;
  final String accountCode;
  final String accountName;

  /// SUM(base_debit)
  final double debit;

  /// SUM(base_credit)
  final double credit;
}

/// One journal-book line in company base currency.
class JournalBookLineRow {
  const JournalBookLineRow({
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    required this.description,
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  final DateTime entryDate;
  final String voucherNumber;
  final String voucherType;
  final String description;
  final String accountCode;
  final String accountName;

  /// base_debit
  final double debit;

  /// base_credit
  final double credit;
}
