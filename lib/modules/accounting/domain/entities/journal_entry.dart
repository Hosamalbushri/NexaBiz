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
  });

  final String accountUuid;
  final double debit;
  final double credit;
  final String currencyCode;
  final String? lineDescription;
  final int sortOrder;
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
}
