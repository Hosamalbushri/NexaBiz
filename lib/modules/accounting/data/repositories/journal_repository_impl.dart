import 'package:drift/drift.dart';

import '../../../../core/sync/sync_operation.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/utils/business_date.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/models/journal_exception.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/currency_rate_repository.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../domain/services/accounting_period_validator.dart';
import '../../domain/services/journal_base_amount_resolver.dart';
import '../../domain/services/journal_money.dart';
import '../database/accounting_database.dart';

/// Source type used by reversing journals (`sourceId` = original entry UUID).
const kJournalReverseSourceType = 'journal_reverse';

class JournalRepositoryImpl implements JournalRepository {
  JournalRepositoryImpl(
    this._db, {
    required AccountRepository accounts,
    required AccountingPeriodValidator periodValidator,
    CurrencyRateRepository? rates,
    SyncQueue? syncQueue,
  }) : _accounts = accounts,
       _periodValidator = periodValidator,
       _rates = rates,
       _syncQueue = syncQueue;

  final AccountingDatabase _db;
  final AccountRepository _accounts;
  final AccountingPeriodValidator _periodValidator;
  final CurrencyRateRepository? _rates;
  final SyncQueue? _syncQueue;

  static const entityType = 'journal_entry';
  static const sourceSale = 'sale';
  static const reverseSourceType = kJournalReverseSourceType;

  @override
  Future<JournalEntry> post(JournalEntryDraft draft) async {
    await _periodValidator.assertEntryAllowed(draft.entryDate);

    if (draft.lines.isEmpty) {
      throw const JournalException(JournalException.emptyLines);
    }

    final baseCode = (draft.baseCurrencyCode ?? draft.currencyCode)
        .trim()
        .toUpperCase();
    final lines = _rates != null
        ? await JournalBaseAmountResolver(_rates!).resolve(
            entryDate: draft.entryDate,
            baseCurrencyCode: baseCode,
            lines: draft.lines,
          )
        : [
            for (final line in draft.lines)
              _resolveLineWithoutRates(line, baseCode),
          ];

    var totalDebitCents = 0;
    var totalCreditCents = 0;
    var totalBaseDebitCents = 0;
    var totalBaseCreditCents = 0;
    final currencies = <String>{};
    for (final line in lines) {
      if (line.debit > 0 && line.credit > 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      if (line.debit == 0 && line.credit == 0) {
        throw const JournalException(JournalException.invalidAmount);
      }
      currencies.add(line.currencyCode.trim().toUpperCase());
      totalDebitCents += JournalMoney.toCents(line.debit);
      totalCreditCents += JournalMoney.toCents(line.credit);
      totalBaseDebitCents += JournalMoney.toCents(line.baseDebit ?? 0);
      totalBaseCreditCents += JournalMoney.toCents(line.baseCredit ?? 0);
    }

    final skipForeignBalance =
        draft.allowUnbalancedMultiCurrency && currencies.length > 1;
    if (!skipForeignBalance && totalDebitCents != totalCreditCents) {
      throw JournalException(
        JournalException.unbalanced,
        'debit=${JournalMoney.fromCents(totalDebitCents)} '
        'credit=${JournalMoney.fromCents(totalCreditCents)}',
      );
    }
    if (totalBaseDebitCents != totalBaseCreditCents) {
      throw JournalException(
        JournalException.unbalanced,
        'baseDebit=${JournalMoney.fromCents(totalBaseDebitCents)} '
        'baseCredit=${JournalMoney.fromCents(totalBaseCreditCents)}',
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
    final nextVersion = (existing?.version ?? 0) + 1;
    final isCreate = existing == null;
    final opType = isCreate
        ? SyncOperationType.create
        : SyncOperationType.update;

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
                syncStatus: const Value('pending'),
                version: Value(nextVersion),
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
                syncStatus: const Value('pending'),
                version: Value(nextVersion),
              ),
            );
      }

      var order = 0;
      for (final line in lines) {
        final lineUuid = line.uuid?.trim();
        await _db
            .into(_db.journalLines)
            .insert(
              JournalLinesCompanion.insert(
                uuid: (lineUuid != null && lineUuid.isNotEmpty)
                    ? lineUuid
                    : generateUuidV4(),
                entryUuid: entryUuid,
                accountUuid: line.accountUuid,
                debit: Value(line.debit),
                credit: Value(line.credit),
                exchangeRateToBase: Value(line.exchangeRateToBase ?? 1),
                baseDebit: Value(line.baseDebit ?? 0),
                baseCredit: Value(line.baseCredit ?? 0),
                lineDescription: Value(line.lineDescription?.trim()),
                currencyCode: line.currencyCode.trim().toUpperCase(),
                sortOrder: Value(line.sortOrder != 0 ? line.sortOrder : order),
              ),
            );
        order++;
      }
    });

    final posted = await getByUuid(entryUuid);
    if (posted == null) {
      // Fallback when soft-deleted mid-flight (shouldn't happen).
      final rows =
          await (_db.select(_db.journalEntries)
                ..where((t) => t.uuid.equals(entryUuid)))
              .get();
      final fallback = _mapEntry(rows.single, await _linesFor(entryUuid));
      await _enqueue(fallback, opType);
      return fallback;
    }
    await _enqueue(posted, opType);
    return posted;
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
    for (final row in rows) {
      // Posted originals that already have an active reverse are not "active"
      // for source replacement (sale re-post after void).
      if (sourceType.trim() != reverseSourceType &&
          await _hasActiveReverse(row.uuid)) {
        continue;
      }
      return _mapEntry(row, await _linesFor(row.uuid));
    }
    return null;
  }

  Future<bool> _hasActiveReverse(String entryUuid) async {
    final rows =
        await (_db.select(_db.journalEntries)..where(
              (t) =>
                  t.sourceType.equals(reverseSourceType) &
                  t.sourceId.equals(entryUuid) &
                  t.deletedAt.isNull(),
            ))
            .get();
    return rows.isNotEmpty;
  }

  @override
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    final existing = await findBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    if (existing == null) {
      return;
    }
    if (existing.isPosted) {
      throw const JournalException(JournalException.postedImmutable);
    }
    await _tombstoneUuid(existing.uuid, existing.version);
  }

  @override
  Future<void> softDeleteByUuid(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final existing = await getByUuid(trimmed);
    if (existing == null) {
      return;
    }
    if (existing.isPosted) {
      throw const JournalException(JournalException.postedImmutable);
    }
    await _tombstoneUuid(trimmed, existing.version);
  }

  @override
  Future<void> softDeletePostedAfterReverse(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final existing = await getByUuid(trimmed);
    if (existing == null) {
      return;
    }
    await _tombstoneUuid(trimmed, existing.version);
  }

  Future<void> _tombstoneUuid(String uuid, int version) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final nextVersion = version + 1;
    await (_db.update(_db.journalEntries)..where(
          (t) => t.uuid.equals(uuid) & t.deletedAt.isNull(),
        ))
        .write(
          JournalEntriesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('pending'),
            version: Value(nextVersion),
          ),
        );
    final tombstone = await _getByUuidIncludingDeleted(uuid);
    if (tombstone != null) {
      await _enqueue(tombstone, SyncOperationType.delete);
    }
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
          exchangeRateToBase: row.exchangeRateToBase,
          baseDebit: row.baseDebit,
          baseCredit: row.baseCredit,
          lineDescription: row.lineDescription,
        ),
    ];
  }

  JournalLineDraft _resolveLineWithoutRates(
    JournalLineDraft line,
    String baseCode,
  ) {
    final code = line.currencyCode.trim().toUpperCase();
    final debit = JournalMoney.clampNonNegative(line.debit);
    final credit = JournalMoney.clampNonNegative(line.credit);
    final rate = (line.exchangeRateToBase != null &&
            line.exchangeRateToBase! > 0)
        ? line.exchangeRateToBase!
        : (code == baseCode || code.isEmpty ? 1.0 : 1.0);
    return JournalLineDraft(
      accountUuid: line.accountUuid,
      debit: debit,
      credit: credit,
      currencyCode: code,
      lineDescription: line.lineDescription,
      sortOrder: line.sortOrder,
      uuid: line.uuid,
      exchangeRateToBase: rate,
      baseDebit: line.baseDebit != null
          ? JournalMoney.clampNonNegative(line.baseDebit!)
          : JournalMoney.round(debit * rate),
      baseCredit: line.baseCredit != null
          ? JournalMoney.clampNonNegative(line.baseCredit!)
          : JournalMoney.round(credit * rate),
    );
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
      syncStatus: SyncStatusX.fromStorage(row.syncStatus),
      lastSyncedAt: row.lastSyncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
      version: row.version,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Future<JournalEntry?> _getByUuidIncludingDeleted(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.journalEntries)
              ..where((t) => t.uuid.equals(trimmed)))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _mapEntry(row, await _linesFor(row.uuid));
  }

  Future<void> _enqueue(JournalEntry entry, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    final linesPayload = <Map<String, dynamic>>[];
    for (final line in entry.lines) {
      final account = await _accounts.getByUuid(line.accountUuid);
      linesPayload.add({
        'uuid': line.uuid,
        'accountUuid': line.accountUuid,
        'accountCode': account?.accountCode,
        'debit': line.debit,
        'credit': line.credit,
        'exchangeRateToBase': line.exchangeRateToBase,
        'baseDebit': line.baseDebit,
        'baseCredit': line.baseCredit,
        'currencyCode': line.currencyCode,
        'lineDescription': line.lineDescription,
        'sortOrder': line.sortOrder,
      });
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: entry.uuid,
        type: type,
        baseVersion: entry.version,
        payload: {
          'uuid': entry.uuid,
          'entryDate': entry.entryDate.toUtc().millisecondsSinceEpoch,
          'voucherNumber': entry.voucherNumber,
          'voucherType': entry.voucherType,
          'description': entry.description,
          'currencyCode': entry.currencyCode,
          'isPosted': entry.isPosted,
          'sourceType': entry.sourceType,
          'sourceId': entry.sourceId,
          'lines': linesPayload,
          'version': entry.version,
          'updatedAt': entry.updatedAt.toUtc().millisecondsSinceEpoch,
          'createdAt': entry.createdAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': entry.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final stamp = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await (_db.update(_db.journalEntries)..where((t) => t.uuid.equals(uuid)))
        .write(
          JournalEntriesCompanion(
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(stamp),
            version: Value(remoteVersion),
          ),
        );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.journalEntries)..where((t) => t.uuid.equals(uuid)))
        .write(
          const JournalEntriesCompanion(syncStatus: Value('conflict')),
        );
  }

  /// Remap journal line FKs when a CoA UUID is adopted from another device.
  Future<void> remapAccountUuid({
    required String fromUuid,
    required String toUuid,
  }) async {
    if (fromUuid == toUuid || fromUuid.isEmpty || toUuid.isEmpty) {
      return;
    }
    await (_db.update(_db.journalLines)
          ..where((t) => t.accountUuid.equals(fromUuid)))
        .write(JournalLinesCompanion(accountUuid: Value(toUuid)));
  }

  Future<String> _resolveRemoteAccountUuid({
    required String? accountUuid,
    required String? accountCode,
  }) async {
    // Prefer business key: CoA UUIDs often differ per install until accounts sync.
    final code = accountCode?.trim();
    if (code != null && code.isNotEmpty) {
      final byCode = await _accounts.getByAccountCode(code);
      if (byCode != null && !byCode.isDeleted) {
        return byCode.uuid;
      }
    }
    final uuid = accountUuid?.trim();
    if (uuid != null && uuid.isNotEmpty) {
      final byUuid = await _accounts.getByUuid(uuid);
      if (byUuid != null && !byUuid.isDeleted) {
        return byUuid.uuid;
      }
      return uuid;
    }
    throw const JournalException(JournalException.accountNotFound);
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) {
      return;
    }

    final deletedAtMs = (payload['deletedAt'] as num?)?.toInt();
    final existingByUuid = await _getByUuidIncludingDeleted(uuid);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updatedAt = (payload['updatedAt'] as num?)?.toInt() ?? nowMs;
    final version = (payload['version'] as num?)?.toInt() ?? 1;
    final sourceType = payload['sourceType']?.toString();
    final sourceId = payload['sourceId']?.toString();

    if (existingByUuid != null &&
        (existingByUuid.syncStatus.needsUpload ||
            existingByUuid.syncStatus == SyncStatus.conflict ||
            existingByUuid.syncStatus == SyncStatus.syncing)) {
      if (version > existingByUuid.version) {
        await markConflict(uuid);
      }
      return;
    }

    // Stale remote: incoming version <= local version → skip (idempotent pull).
    if (existingByUuid != null && version <= existingByUuid.version) {
      return;
    }

    // Same source document, different journal UUID → adopt remote identity.
    if (deletedAtMs == null &&
        sourceType != null &&
        sourceType.isNotEmpty &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      final bySource = await findBySource(
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (bySource != null && bySource.uuid != uuid) {
        await (_db.update(_db.journalEntries)
              ..where((t) => t.uuid.equals(bySource.uuid)))
            .write(JournalEntriesCompanion(uuid: Value(uuid)));
        await (_db.update(_db.journalLines)
              ..where((t) => t.entryUuid.equals(bySource.uuid)))
            .write(JournalLinesCompanion(entryUuid: Value(uuid)));
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: bySource.uuid,
        );
      }
    }

    final rawLines = payload['lines'];
    final lineMaps = <Map<String, dynamic>>[];
    if (rawLines is List) {
      for (final item in rawLines) {
        if (item is Map) {
          lineMaps.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final resolvedLines = <({
      String uuid,
      String accountUuid,
      double debit,
      double credit,
      double exchangeRateToBase,
      double baseDebit,
      double baseCredit,
      String currencyCode,
      String? lineDescription,
      int sortOrder,
    })>[];
    for (var i = 0; i < lineMaps.length; i++) {
      final line = lineMaps[i];
      final accountUuid = await _resolveRemoteAccountUuid(
        accountUuid: line['accountUuid']?.toString(),
        accountCode: line['accountCode']?.toString(),
      );
      final lineUuidRaw = line['uuid']?.toString().trim();
      final debit = (line['debit'] as num?)?.toDouble() ?? 0;
      final credit = (line['credit'] as num?)?.toDouble() ?? 0;
      final rate = (line['exchangeRateToBase'] as num?)?.toDouble() ?? 1;
      final baseDebit =
          (line['baseDebit'] as num?)?.toDouble() ??
          JournalMoney.round(debit * rate);
      final baseCredit =
          (line['baseCredit'] as num?)?.toDouble() ??
          JournalMoney.round(credit * rate);
      resolvedLines.add((
        uuid: (lineUuidRaw != null && lineUuidRaw.isNotEmpty)
            ? lineUuidRaw
            : generateUuidV4(),
        accountUuid: accountUuid,
        debit: debit,
        credit: credit,
        exchangeRateToBase: rate,
        baseDebit: baseDebit,
        baseCredit: baseCredit,
        currencyCode:
            (line['currencyCode']?.toString() ?? 'SAR').trim().toUpperCase(),
        lineDescription: line['lineDescription']?.toString(),
        sortOrder: (line['sortOrder'] as num?)?.toInt() ?? i,
      ));
    }

    final entryDate =
        (payload['entryDate'] as num?)?.toInt() ??
        existingByUuid?.entryDate.toUtc().millisecondsSinceEpoch ??
        nowMs;
    final createdAt =
        (payload['createdAt'] as num?)?.toInt() ??
        existingByUuid?.createdAt.toUtc().millisecondsSinceEpoch ??
        updatedAt;

    await _db.transaction(() async {
      final current = await _getByUuidIncludingDeleted(uuid);
      if (current == null) {
        await _db
            .into(_db.journalEntries)
            .insert(
              JournalEntriesCompanion.insert(
                uuid: uuid,
                entryDate: entryDate,
                voucherNumber:
                    payload['voucherNumber']?.toString() ?? uuid,
                voucherType: payload['voucherType']?.toString() ?? 'journal',
                description: Value(payload['description']?.toString()),
                currencyCode:
                    (payload['currencyCode']?.toString() ?? 'SAR')
                        .trim()
                        .toUpperCase(),
                isPosted: Value(payload['isPosted'] as bool? ?? true),
                sourceType: Value(sourceType),
                sourceId: Value(sourceId),
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                deletedAt: Value(deletedAtMs),
              ),
            );
      } else {
        await (_db.update(_db.journalEntries)
              ..where((t) => t.uuid.equals(uuid)))
            .write(
              JournalEntriesCompanion(
                entryDate: Value(entryDate),
                voucherNumber: Value(
                  payload['voucherNumber']?.toString() ??
                      current.voucherNumber,
                ),
                voucherType: Value(
                  payload['voucherType']?.toString() ?? current.voucherType,
                ),
                description: Value(payload['description']?.toString()),
                currencyCode: Value(
                  (payload['currencyCode']?.toString() ?? current.currencyCode)
                      .trim()
                      .toUpperCase(),
                ),
                isPosted: Value(
                  payload['isPosted'] as bool? ?? current.isPosted,
                ),
                sourceType: Value(sourceType ?? current.sourceType),
                sourceId: Value(sourceId ?? current.sourceId),
                updatedAt: Value(updatedAt),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                deletedAt: Value(deletedAtMs),
              ),
            );
        await (_db.delete(_db.journalLines)
              ..where((t) => t.entryUuid.equals(uuid)))
            .go();
      }

      if (deletedAtMs == null) {
        for (final line in resolvedLines) {
          await _db
              .into(_db.journalLines)
              .insert(
                JournalLinesCompanion.insert(
                  uuid: line.uuid,
                  entryUuid: uuid,
                  accountUuid: line.accountUuid,
                  debit: Value(line.debit),
                  credit: Value(line.credit),
                  exchangeRateToBase: Value(line.exchangeRateToBase),
                  baseDebit: Value(line.baseDebit),
                  baseCredit: Value(line.baseCredit),
                  lineDescription: Value(line.lineDescription?.trim()),
                  currencyCode: line.currencyCode,
                  sortOrder: Value(line.sortOrder),
                ),
              );
        }
      }
    });

    await _syncQueue?.removeForEntity(entityType: entityType, entityId: uuid);
  }

  @override
  Future<List<MonetaryFxPositionRow>> listMonetaryFxPositions({
    required DateTime asOfInclusive,
    required String baseCurrencyCode,
  }) async {
    final asOfMs = BusinessDate.utcDayMs(asOfInclusive);
    final base = baseCurrencyCode.trim().toUpperCase();
    final rows = await _db
        .customSelect(
          '''
          SELECT jl.account_uuid AS account_uuid,
                 UPPER(jl.currency_code) AS currency_code,
                 SUM(jl.debit - jl.credit) AS foreign_balance,
                 SUM(jl.base_debit - jl.base_credit) AS booked_base
          FROM journal_lines jl
          INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
          INNER JOIN accounts a ON a.uuid = jl.account_uuid
          WHERE je.deleted_at IS NULL
            AND je.is_posted = 1
            AND je.entry_date <= ?
            AND UPPER(jl.currency_code) != ?
            AND a.account_type IN ('asset', 'liability')
            AND a.is_group = 0
            AND a.deleted_at IS NULL
          GROUP BY jl.account_uuid, UPPER(jl.currency_code)
          HAVING ABS(SUM(jl.debit - jl.credit)) > 0.0001
          ''',
          variables: [
            Variable.withInt(asOfMs),
            Variable.withString(base),
          ],
          readsFrom: {_db.journalLines, _db.journalEntries, _db.accounts},
        )
        .get();
    return [
      for (final row in rows)
        MonetaryFxPositionRow(
          accountUuid: row.read<String>('account_uuid'),
          currencyCode: row.read<String>('currency_code'),
          foreignBalance: row.read<double>('foreign_balance'),
          bookedBase: row.read<double>('booked_base'),
        ),
    ];
  }

  @override
  Future<List<TrialBalanceRow>> listTrialBalance({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async {
    final variables = <Variable<Object>>[];
    final sql = StringBuffer(
      '''
      SELECT a.uuid AS account_uuid,
             a.account_code AS account_code,
             a.name AS account_name,
             COALESCE(SUM(jl.base_debit), 0.0) AS debit,
             COALESCE(SUM(jl.base_credit), 0.0) AS credit
      FROM journal_lines jl
      INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
      INNER JOIN accounts a ON a.uuid = jl.account_uuid
      WHERE je.deleted_at IS NULL
        AND a.is_group = 0
        AND a.deleted_at IS NULL
      ''',
    );
    if (fromDate != null) {
      sql.write('AND je.entry_date >= ? ');
      variables.add(Variable.withInt(BusinessDate.utcDayMs(fromDate)));
    }
    if (toDate != null) {
      sql.write('AND je.entry_date <= ? ');
      variables.add(Variable.withInt(BusinessDate.utcDayMs(toDate)));
    }
    if (isPosted != null) {
      sql.write('AND je.is_posted = ? ');
      variables.add(Variable.withBool(isPosted));
    }
    sql.write(
      '''
      GROUP BY a.uuid, a.account_code, a.name
      HAVING ABS(SUM(jl.base_debit)) + ABS(SUM(jl.base_credit)) > 0.0001
      ORDER BY a.account_code
      ''',
    );

    final rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
          readsFrom: {_db.journalLines, _db.journalEntries, _db.accounts},
        )
        .get();
    return [
      for (final row in rows)
        TrialBalanceRow(
          accountUuid: row.read<String>('account_uuid'),
          accountCode: row.read<String>('account_code'),
          accountName: row.read<String>('account_name'),
          debit: JournalMoney.round(row.read<double>('debit')),
          credit: JournalMoney.round(row.read<double>('credit')),
        ),
    ];
  }

  @override
  Future<List<JournalBookLineRow>> listJournalBookLines({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async {
    final variables = <Variable<Object>>[];
    final sql = StringBuffer(
      '''
      SELECT je.entry_date AS entry_date,
             je.voucher_number AS voucher_number,
             je.voucher_type AS voucher_type,
             COALESCE(NULLIF(TRIM(je.description), ''), jl.line_description, '')
               AS description,
             a.account_code AS account_code,
             a.name AS account_name,
             jl.base_debit AS debit,
             jl.base_credit AS credit
      FROM journal_lines jl
      INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
      INNER JOIN accounts a ON a.uuid = jl.account_uuid
      WHERE je.deleted_at IS NULL
        AND a.deleted_at IS NULL
      ''',
    );
    if (fromDate != null) {
      sql.write('AND je.entry_date >= ? ');
      variables.add(Variable.withInt(BusinessDate.utcDayMs(fromDate)));
    }
    if (toDate != null) {
      sql.write('AND je.entry_date <= ? ');
      variables.add(Variable.withInt(BusinessDate.utcDayMs(toDate)));
    }
    if (isPosted != null) {
      sql.write('AND je.is_posted = ? ');
      variables.add(Variable.withBool(isPosted));
    }
    sql.write(
      '''
      ORDER BY je.entry_date ASC, je.id ASC, jl.sort_order ASC, jl.id ASC
      ''',
    );

    final rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
          readsFrom: {_db.journalLines, _db.journalEntries, _db.accounts},
        )
        .get();
    return [
      for (final row in rows)
        JournalBookLineRow(
          entryDate: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('entry_date'),
            isUtc: true,
          ),
          voucherNumber: row.read<String>('voucher_number'),
          voucherType: row.read<String>('voucher_type'),
          description: row.read<String>('description'),
          accountCode: row.read<String>('account_code'),
          accountName: row.read<String>('account_name'),
          debit: JournalMoney.round(row.read<double>('debit')),
          credit: JournalMoney.round(row.read<double>('credit')),
        ),
    ];
  }
}
