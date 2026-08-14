import 'package:drift/drift.dart';

import '../../../../core/utils/business_date.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/models/journal_exception.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../domain/services/journal_money.dart';
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

    // Round at the write boundary so debit/credit stay cent-stable in REAL.
    final lines = [
      for (final line in draft.lines)
        JournalLineDraft(
          accountUuid: line.accountUuid,
          debit: JournalMoney.clampNonNegative(line.debit),
          credit: JournalMoney.clampNonNegative(line.credit),
          currencyCode: line.currencyCode,
          lineDescription: line.lineDescription,
          sortOrder: line.sortOrder,
        ),
    ];

    var totalDebitCents = 0;
    var totalCreditCents = 0;
    for (final line in lines) {
      if (line.debit > 0 && line.credit > 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      if (line.debit == 0 && line.credit == 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      totalDebitCents += JournalMoney.toCents(line.debit);
      totalCreditCents += JournalMoney.toCents(line.credit);
    }

    if (totalDebitCents != totalCreditCents) {
      throw JournalException(
        JournalException.unbalanced,
        'debit=${JournalMoney.fromCents(totalDebitCents)} '
        'credit=${JournalMoney.fromCents(totalCreditCents)}',
      );
    }

    final byUuid = {
      for (final account in await _accounts.getByUuids(
        lines.map((line) => line.accountUuid),
      ))
        account.uuid: account,
    };
    for (final line in lines) {
      final account = byUuid[line.accountUuid];
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

    final sourceType = draft.sourceType?.trim();
    final sourceId = draft.sourceId?.trim();
    final replaceUuid = draft.uuid?.trim();
    JournalEntry? existing;
    if (replaceUuid != null && replaceUuid.isNotEmpty) {
      existing = await getByUuid(replaceUuid);
    } else if (sourceType != null &&
        sourceType.isNotEmpty &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      existing = await findBySource(
        sourceType: sourceType,
        sourceId: sourceId,
      );
    }

    final now = DateTime.now().toUtc();
    final entryUuid = existing?.uuid ?? replaceUuid ?? generateUuidV4();
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
      for (final line in lines) {
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
    final loaded = await getByUuid(entryUuid);
    if (loaded != null) {
      return loaded;
    }
    // Fallback when no source (shouldn't happen for sales).
    final rows =
        await (_db.select(_db.journalEntries)
              ..where((t) => t.uuid.equals(entryUuid)))
            .get();
    return _mapEntry(rows.single, await _linesFor(entryUuid));
  }

  @override
  Future<JournalEntry?> getByUuid(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.journalEntries)..where(
              (t) => t.uuid.equals(trimmed) & t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapEntry(row, await _linesFor(row.uuid));
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
    // Phase-1 void: tombstone the header for both posted and unposted entries.
    // Lines are retained for audit; all ledger reads filter deletedAt.isNull().
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
  Future<void> softDeleteByUuid(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.journalEntries)..where(
          (t) => t.uuid.equals(trimmed) & t.deletedAt.isNull(),
        ))
        .write(
          JournalEntriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<List<JournalEntryHeader>> listHeaders({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
    String? query,
    int? limit,
    int? afterId,
  }) async {
    final fromMs = fromDate == null ? null : BusinessDate.utcDayMs(fromDate);
    final toMs = toDate == null ? null : BusinessDate.utcDayMs(toDate);
    final normalizedQuery = query?.trim().toLowerCase() ?? '';

    final variables = <Variable<Object>>[];
    final sql = StringBuffer(
      'SELECT je.id AS id, '
      'je.uuid AS uuid, '
      'je.entry_date AS entry_date, '
      'je.voucher_number AS voucher_number, '
      'je.voucher_type AS voucher_type, '
      'je.description AS description, '
      'je.currency_code AS currency_code, '
      'je.is_posted AS is_posted, '
      'je.source_type AS source_type, '
      'je.source_id AS source_id, '
      'COALESCE(SUM(jl.debit), 0.0) AS total_debit, '
      'COALESCE(SUM(jl.credit), 0.0) AS total_credit '
      'FROM journal_entries je '
      'LEFT JOIN journal_lines jl ON jl.entry_uuid = je.uuid '
      'WHERE je.deleted_at IS NULL ',
    );

    if (fromMs != null) {
      sql.write('AND je.entry_date >= ? ');
      variables.add(Variable.withInt(fromMs));
    }
    if (toMs != null) {
      sql.write('AND je.entry_date <= ? ');
      variables.add(Variable.withInt(toMs));
    }
    if (isPosted != null) {
      sql.write('AND je.is_posted = ? ');
      variables.add(Variable.withBool(isPosted));
    }
    if (afterId != null) {
      sql.write('AND je.id < ? ');
      variables.add(Variable.withInt(afterId));
    }
    if (normalizedQuery.isNotEmpty) {
      sql.write(
        'AND (LOWER(je.voucher_number) LIKE ? '
        'OR LOWER(IFNULL(je.description, \'\')) LIKE ? '
        'OR LOWER(je.voucher_type) LIKE ?) ',
      );
      final like = '%$normalizedQuery%';
      variables
        ..add(Variable.withString(like))
        ..add(Variable.withString(like))
        ..add(Variable.withString(like));
    }

    sql.write(
      'GROUP BY je.id '
      'ORDER BY je.entry_date DESC, je.id DESC ',
    );
    if (limit != null && limit > 0) {
      sql.write('LIMIT ? ');
      variables.add(Variable.withInt(limit));
    }

    final rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
          readsFrom: {_db.journalEntries, _db.journalLines},
        )
        .get();

    return [
      for (final row in rows)
        JournalEntryHeader(
          id: row.read<int>('id'),
          uuid: row.read<String>('uuid'),
          entryDate: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('entry_date'),
            isUtc: true,
          ),
          voucherNumber: row.read<String>('voucher_number'),
          voucherType: row.read<String>('voucher_type'),
          description: row.readNullable<String>('description'),
          currencyCode: row.read<String>('currency_code'),
          isPosted: row.read<bool>('is_posted'),
          sourceType: row.readNullable<String>('source_type'),
          sourceId: row.readNullable<String>('source_id'),
          totalDebit: row.read<double>('total_debit'),
          totalCredit: row.read<double>('total_credit'),
        ),
    ];
  }

  @override
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
    int? limit,
    AccountLedgerCursor? after,
  }) async {
    final fromMs = fromDate == null ? null : BusinessDate.utcDayMs(fromDate);
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
    if (after != null) {
      // Keyset: (entry_date, sort_order, line.id) > cursor
      query.where(
        _db.journalEntries.entryDate.isBiggerThanValue(after.entryDateMs) |
            (_db.journalEntries.entryDate.equals(after.entryDateMs) &
                (_db.journalLines.sortOrder.isBiggerThanValue(after.sortOrder) |
                    (_db.journalLines.sortOrder.equals(after.sortOrder) &
                        _db.journalLines.id.isBiggerThanValue(after.lineId)))),
      );
    }

    query.orderBy([
      OrderingTerm.asc(_db.journalEntries.entryDate),
      OrderingTerm.asc(_db.journalLines.sortOrder),
      OrderingTerm.asc(_db.journalLines.id),
    ]);
    if (limit != null && limit > 0) {
      query.limit(limit);
    }

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
          lineId: row.readTable(_db.journalLines).id,
          sortOrder: row.readTable(_db.journalLines).sortOrder,
        ),
    ];
  }

  @override
  Future<List<String>> listCurrencyCodesForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async {
    final fromMs = fromDate == null ? null : BusinessDate.utcDayMs(fromDate);
    final toMs = toDate == null ? null : BusinessDate.utcDayMs(toDate);

    final variables = <Variable<Object>>[
      Variable.withString(accountUuid),
    ];
    final sql = StringBuffer(
      'SELECT DISTINCT jl.currency_code AS currency_code '
      'FROM journal_lines jl '
      'INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid '
      'WHERE jl.account_uuid = ? '
      'AND je.deleted_at IS NULL ',
    );
    if (fromMs != null) {
      sql.write('AND je.entry_date >= ? ');
      variables.add(Variable.withInt(fromMs));
    }
    if (toMs != null) {
      sql.write('AND je.entry_date <= ? ');
      variables.add(Variable.withInt(toMs));
    }
    if (isPosted != null) {
      sql.write('AND je.is_posted = ? ');
      variables.add(Variable.withBool(isPosted));
    }
    sql.write('ORDER BY jl.currency_code COLLATE NOCASE');

    final rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
          readsFrom: {_db.journalLines, _db.journalEntries},
        )
        .get();
    return [
      for (final row in rows)
        row.read<String>('currency_code').trim().toUpperCase(),
    ]..removeWhere((code) => code.isEmpty);
  }

  @override
  Future<double> sumNetBefore({
    required String accountUuid,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  }) async {
    final beforeMs = BusinessDate.utcDayMs(beforeDate);
    final variables = <Variable<Object>>[
      Variable.withString(accountUuid),
      Variable.withInt(beforeMs),
    ];
    final sql = StringBuffer(
      'SELECT COALESCE(SUM(jl.debit - jl.credit), 0.0) AS net '
      'FROM journal_lines jl '
      'INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid '
      'WHERE jl.account_uuid = ? '
      'AND je.deleted_at IS NULL '
      'AND je.entry_date < ? ',
    );
    final code = currencyCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      sql.write('AND jl.currency_code = ? ');
      variables.add(Variable.withString(code));
    }
    if (isPosted != null) {
      sql.write('AND je.is_posted = ? ');
      variables.add(Variable.withBool(isPosted));
    }

    final row = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
          readsFrom: {_db.journalLines, _db.journalEntries},
        )
        .getSingle();
    return row.read<double>('net');
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
