import 'package:drift/drift.dart';

import '../../../../core/utils/business_date.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/models/journal_exception.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/journal_repository.dart';
import '../database/accounting_database.dart';

class JournalRepositoryImpl implements JournalRepository {
  JournalRepositoryImpl(this._db, {required AccountRepository accounts})
    : _accounts = accounts;

  final AccountingDatabase _db;
  final AccountRepository _accounts;

  static const sourceSale = 'sale';

  @override
  Future<JournalEntry> post(JournalEntryDraft draft) async {
    if (draft.lines.isEmpty) {
      throw const JournalException(JournalException.emptyLines);
    }

    var totalDebit = 0.0;
    var totalCredit = 0.0;
    for (final line in draft.lines) {
      if (line.debit < 0 || line.credit < 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      if (line.debit > 0 && line.credit > 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      if (line.debit == 0 && line.credit == 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      totalDebit += line.debit;
      totalCredit += line.credit;

      final account = await _accounts.getByUuid(line.accountUuid);
      if (account == null || account.isDeleted) {
        throw const JournalException(JournalException.accountNotFound);
      }
      if (!account.isPostingAccount) {
        throw const JournalException(JournalException.accountNotPosting);
      }
      if (!account.isActive) {
        throw const JournalException(JournalException.accountInactive);
      }
    }

    if ((totalDebit - totalCredit).abs() > 0.0001) {
      throw JournalException(
        JournalException.unbalanced,
        'debit=$totalDebit credit=$totalCredit',
      );
    }

    final sourceType = draft.sourceType?.trim();
    final sourceId = draft.sourceId?.trim();
    JournalEntry? existing;
    if (sourceType != null &&
        sourceType.isNotEmpty &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      existing = await findBySource(
        sourceType: sourceType,
        sourceId: sourceId,
      );
    }

    final now = DateTime.now().toUtc();
    final entryUuid = existing?.uuid ?? generateUuidV4();
    final entryDateMs = BusinessDate.utcDayMs(draft.entryDate);
    final createdAtMs =
        existing?.createdAt.toUtc().millisecondsSinceEpoch ??
        now.millisecondsSinceEpoch;

    await _db.transaction(() async {
      if (existing != null) {
        await (_db.update(_db.journalEntries)
              ..where((t) => t.uuid.equals(entryUuid)))
            .write(
              JournalEntriesCompanion(
                entryDate: Value(entryDateMs),
                voucherNumber: Value(draft.voucherNumber.trim()),
                voucherType: Value(draft.voucherType.trim()),
                description: Value(draft.description?.trim()),
                currencyCode: Value(draft.currencyCode.trim().toUpperCase()),
                isPosted: Value(draft.isPosted),
                sourceType: Value(sourceType),
                sourceId: Value(sourceId),
                updatedAt: Value(now.millisecondsSinceEpoch),
              ),
            );
        await (_db.delete(_db.journalLines)
              ..where((t) => t.entryUuid.equals(entryUuid)))
            .go();
      } else {
        await _db
            .into(_db.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                uuid: entryUuid,
                entryDate: entryDateMs,
                voucherNumber: draft.voucherNumber.trim(),
                voucherType: draft.voucherType.trim(),
                description: Value(draft.description?.trim()),
                currencyCode: draft.currencyCode.trim().toUpperCase(),
                isPosted: Value(draft.isPosted),
                sourceType: Value(sourceType),
                sourceId: Value(sourceId),
                createdAt: createdAtMs,
                updatedAt: now.millisecondsSinceEpoch,
              ),
            );
      }

      var order = 0;
      for (final line in draft.lines) {
        await _db
            .into(_db.journalLines)
            .insert(
              JournalLinesCompanion.insert(
                uuid: generateUuidV4(),
                entryUuid: entryUuid,
                accountUuid: line.accountUuid,
                debit: Value(line.debit),
                credit: Value(line.credit),
                lineDescription: Value(line.lineDescription?.trim()),
                currencyCode: line.currencyCode.trim().toUpperCase(),
                sortOrder: Value(line.sortOrder != 0 ? line.sortOrder : order),
              ),
            );
        order++;
      }
    });

    final posted = await findBySource(
      sourceType: sourceType ?? '',
      sourceId: sourceId ?? '',
    );
    if (posted != null) {
      return posted;
    }
    // Fallback when no source (shouldn't happen for sales).
    final rows =
        await (_db.select(_db.journalEntries)
              ..where((t) => t.uuid.equals(entryUuid)))
            .get();
    return _mapEntry(rows.single, await _linesFor(entryUuid));
  }

  @override
  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    if (sourceType.trim().isEmpty || sourceId.trim().isEmpty) {
      return null;
    }
    final rows =
        await (_db.select(_db.journalEntries)..where(
              (t) =>
                  t.sourceType.equals(sourceType.trim()) &
                  t.sourceId.equals(sourceId.trim()) &
                  t.deletedAt.isNull(),
            ))
            .get();
    if (rows.isEmpty) {
      return null;
    }
    final entry = rows.first;
    return _mapEntry(entry, await _linesFor(entry.uuid));
  }

  @override
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.journalEntries)..where(
          (t) =>
              t.sourceType.equals(sourceType.trim()) &
              t.sourceId.equals(sourceId.trim()) &
              t.deletedAt.isNull(),
        ))
        .write(
          JournalEntriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
  }) async {
    final fromMs =
        fromDate == null ? null : BusinessDate.utcDayMs(fromDate);
    // Entry dates are stored as UTC midnight of the local calendar day, so
    // inclusive toDate is the same day epoch (no 23:59 pad on a shifted day).
    final toMs = toDate == null ? null : BusinessDate.utcDayMs(toDate);

    final query = _db.select(_db.journalLines).join([
      innerJoin(
        _db.journalEntries,
        _db.journalEntries.uuid.equalsExp(_db.journalLines.entryUuid),
      ),
    ])..where(
      _db.journalLines.accountUuid.equals(accountUuid) &
          _db.journalEntries.deletedAt.isNull(),
    );

    if (fromMs != null) {
      query.where(_db.journalEntries.entryDate.isBiggerOrEqualValue(fromMs));
    }
    if (toMs != null) {
      query.where(_db.journalEntries.entryDate.isSmallerOrEqualValue(toMs));
    }
    if (currencyCode != null && currencyCode.trim().isNotEmpty) {
      query.where(
        _db.journalLines.currencyCode.equals(
          currencyCode.trim().toUpperCase(),
        ),
      );
    }
    if (isPosted != null) {
      query.where(_db.journalEntries.isPosted.equals(isPosted));
    }

    query.orderBy([
      OrderingTerm.asc(_db.journalEntries.entryDate),
      OrderingTerm.asc(_db.journalLines.sortOrder),
      OrderingTerm.asc(_db.journalLines.id),
    ]);

    final rows = await query.get();
    return [
      for (final row in rows)
        AccountLedgerMovement(
          entryDate: DateTime.fromMillisecondsSinceEpoch(
            row.readTable(_db.journalEntries).entryDate,
            isUtc: true,
          ),
          voucherNumber: row.readTable(_db.journalEntries).voucherNumber,
          voucherType: row.readTable(_db.journalEntries).voucherType,
          description:
              row.readTable(_db.journalLines).lineDescription?.trim().isNotEmpty ==
                  true
              ? row.readTable(_db.journalLines).lineDescription!.trim()
              : (row.readTable(_db.journalEntries).description?.trim() ??
                    row.readTable(_db.journalEntries).voucherType),
          debit: row.readTable(_db.journalLines).debit,
          credit: row.readTable(_db.journalLines).credit,
          currencyCode: row.readTable(_db.journalLines).currencyCode,
          isPosted: row.readTable(_db.journalEntries).isPosted,
          accountUuid: row.readTable(_db.journalLines).accountUuid,
          entryUuid: row.readTable(_db.journalEntries).uuid,
          lineUuid: row.readTable(_db.journalLines).uuid,
        ),
    ];
  }

  @override
  Future<double> sumNetBefore({
    required String accountUuid,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  }) async {
    final beforeMs = BusinessDate.utcDayMs(beforeDate);

    final query = _db.select(_db.journalLines).join([
      innerJoin(
        _db.journalEntries,
        _db.journalEntries.uuid.equalsExp(_db.journalLines.entryUuid),
      ),
    ])..where(
      _db.journalLines.accountUuid.equals(accountUuid) &
          _db.journalEntries.deletedAt.isNull() &
          _db.journalEntries.entryDate.isSmallerThanValue(beforeMs),
    );

    if (currencyCode != null && currencyCode.trim().isNotEmpty) {
      query.where(
        _db.journalLines.currencyCode.equals(
          currencyCode.trim().toUpperCase(),
        ),
      );
    }
    if (isPosted != null) {
      query.where(_db.journalEntries.isPosted.equals(isPosted));
    }

    final rows = await query.get();
    var net = 0.0;
    for (final row in rows) {
      final line = row.readTable(_db.journalLines);
      net += line.debit - line.credit;
    }
    return net;
  }

  Future<List<JournalLine>> _linesFor(String entryUuid) async {
    final rows =
        await (_db.select(_db.journalLines)
              ..where((t) => t.entryUuid.equals(entryUuid))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return [
      for (final row in rows)
        JournalLine(
          id: row.id,
          uuid: row.uuid,
          entryUuid: row.entryUuid,
          accountUuid: row.accountUuid,
          debit: row.debit,
          credit: row.credit,
          currencyCode: row.currencyCode,
          sortOrder: row.sortOrder,
          lineDescription: row.lineDescription,
        ),
    ];
  }

  JournalEntry _mapEntry(JournalEntryRow row, List<JournalLine> lines) {
    return JournalEntry(
      id: row.id,
      uuid: row.uuid,
      entryDate: DateTime.fromMillisecondsSinceEpoch(row.entryDate, isUtc: true),
      voucherNumber: row.voucherNumber,
      voucherType: row.voucherType,
      currencyCode: row.currencyCode,
      isPosted: row.isPosted,
      lines: lines,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      description: row.description,
      sourceType: row.sourceType,
      sourceId: row.sourceId,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }
}
