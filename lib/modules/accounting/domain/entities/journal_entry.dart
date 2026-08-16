import '../../../../core/sync/sync_status.dart';

/// One side of a journal entry.
class JournalLine {
  const JournalLine({
    required this.id,
    required this.uuid,
    required this.entryUuid,
    required this.accountUuid,
    required this.debit,
    required this.credit,
    required this.currencyCode,
    required this.sortOrder,
    this.lineDescription,
  });

  final int id;
  final String uuid;
  final String entryUuid;
  final String accountUuid;
  final double debit;
  final double credit;
  final String currencyCode;
  final int sortOrder;
  final String? lineDescription;
}

/// Draft line before persistence.
class JournalLineDraft {
  const JournalLineDraft({
    required this.accountUuid,
    required this.debit,
    required this.credit,
    required this.currencyCode,
    this.lineDescription,
    this.sortOrder = 0,
    this.uuid,
  });

  final String accountUuid;
  final double debit;
  final double credit;
  final String currencyCode;
  final String? lineDescription;
  final int sortOrder;

  /// When set (e.g. remote apply), preserves line identity across devices.
  final String? uuid;
}

/// Posted (or draft) journal entry with lines.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.uuid,
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    required this.currencyCode,
    required this.isPosted,
    required this.lines,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.sourceType,
    this.sourceId,
    this.syncStatus = SyncStatus.synced,
    this.lastSyncedAt,
    this.version = 1,
    this.deletedAt,
  });

  final int id;
  final String uuid;
  final DateTime entryDate;
  final String voucherNumber;
  final String voucherType;
  final String currencyCode;
  final bool isPosted;
  final List<JournalLine> lines;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? sourceType;
  final String? sourceId;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final int version;
  final DateTime? deletedAt;
}

/// Draft entry for [JournalRepository.post].
class JournalEntryDraft {
  const JournalEntryDraft({
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    required this.currencyCode,
    required this.lines,
    this.description,
    this.isPosted = true,
    this.sourceType,
    this.sourceId,
    this.uuid,
    this.allowUnbalancedMultiCurrency = false,
  });

  final DateTime entryDate;
  final String voucherNumber;
  final String voucherType;
  final String currencyCode;
  final List<JournalLineDraft> lines;
  final String? description;
  final bool isPosted;
  final String? sourceType;
  final String? sourceId;

  /// When set, replaces that existing non-deleted entry in place.
  final String? uuid;

  /// When true and lines use more than one currency, skip numeric debit=credit
  /// checks so cash/party legs can keep native amounts (e.g. SAR vs YER).
  final bool allowUnbalancedMultiCurrency;
}

/// Lightweight journal list row (no lines loaded).
class JournalEntryHeader {
  const JournalEntryHeader({
    required this.id,
    required this.uuid,
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    required this.currencyCode,
    required this.isPosted,
    required this.totalDebit,
    required this.totalCredit,
    this.description,
    this.sourceType,
    this.sourceId,
  });

  final int id;
  final String uuid;
  final DateTime entryDate;
  final String voucherNumber;
  final String voucherType;
  final String currencyCode;
  final bool isPosted;
  final double totalDebit;
  final double totalCredit;
  final String? description;
  final String? sourceType;
  final String? sourceId;
}

/// Movement row for account statements (one journal line + header fields).
class AccountLedgerMovement {
  const AccountLedgerMovement({
    required this.entryDate,
    required this.voucherNumber,
    required this.voucherType,
    required this.description,
    required this.debit,
    required this.credit,
    required this.currencyCode,
    required this.isPosted,
    required this.accountUuid,
    required this.entryUuid,
    required this.lineUuid,
    required this.lineId,
    required this.sortOrder,
  });

  final DateTime entryDate;
  final String voucherNumber;
  final String voucherType;
  final String description;
  final double debit;
  final double credit;
  final String currencyCode;
  final bool isPosted;
  final String accountUuid;
  final String entryUuid;
  final String lineUuid;

  /// Stable keyset fields for paginated ledger reads.
  final int lineId;
  final int sortOrder;
}
