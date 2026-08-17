import 'package:drift/drift.dart';

import '../../../../core/utils/business_date.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/accounting_period_status.dart';
import '../../domain/entities/fiscal_year.dart';
import '../../domain/models/fiscal_year_exception.dart';
import '../../domain/repositories/fiscal_year_repository.dart';
import '../database/accounting_database.dart';

class FiscalYearRepositoryImpl implements FiscalYearRepository {
  FiscalYearRepositoryImpl(this._db);

  final AccountingDatabase _db;

  DateTime _dayFromMs(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  int _dayMs(DateTime value) => BusinessDate.utcDayMs(value);

  FiscalYear _mapYear(FiscalYearRow row) {
    return FiscalYear(
      id: row.id,
      uuid: row.uuid,
      code: row.code,
      name: row.name,
      startDate: _dayFromMs(row.startDate),
      endDate: _dayFromMs(row.endDate),
      status: FiscalYearStatus.fromStorage(row.status),
      baseCurrencyCode: row.baseCurrencyCode,
      periodCount: row.periodCount,
      periodFrequency: PeriodFrequency.fromStorage(row.periodFrequency),
      fxRevaluationEnabled: row.fxRevaluationEnabled,
      fxGainAccountUuid: row.fxGainAccountUuid,
      fxLossAccountUuid: row.fxLossAccountUuid,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      closedAt: row.closedAt == null ? null : _dayFromMs(row.closedAt!),
      createdBy: row.createdBy,
      closedBy: row.closedBy,
    );
  }

  AccountingPeriod _mapPeriod(AccountingPeriodRow row) {
    return AccountingPeriod(
      id: row.id,
      uuid: row.uuid,
      fiscalYearUuid: row.fiscalYearUuid,
      periodNumber: row.periodNumber,
      name: row.name,
      startDate: _dayFromMs(row.startDate),
      endDate: _dayFromMs(row.endDate),
      status: AccountingPeriodStatus.fromStorage(row.status),
      openedAt: row.openedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.openedAt!, isUtc: true),
      openedBy: row.openedBy,
      closedAt: row.closedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.closedAt!, isUtc: true),
      closedBy: row.closedBy,
      reopenedAt: row.reopenedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.reopenedAt!, isUtc: true),
      reopenedBy: row.reopenedBy,
      reopenReason: row.reopenReason,
    );
  }

  PeriodClosingRecord _mapClosing(PeriodClosingRecordRow row) {
    return PeriodClosingRecord(
      id: row.id,
      uuid: row.uuid,
      fiscalYearUuid: row.fiscalYearUuid,
      periodUuid: row.periodUuid,
      closingDate: _dayFromMs(row.closingDate),
      status: PeriodClosingStatus.fromStorage(row.status),
      fxRevaluationEnabled: row.fxRevaluationEnabled,
      fxRevaluationExecuted: row.fxRevaluationExecuted,
      fxSkipReason: row.fxSkipReason,
      fxGain: row.fxGain,
      fxLoss: row.fxLoss,
      netFxDifference: row.netFxDifference,
      journalEntryUuid: row.journalEntryUuid,
      createdBy: row.createdBy,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  @override
  Stream<List<FiscalYear>> watchAll() {
    final query = _db.select(_db.fiscalYears)
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
    return query.watch().map((rows) => rows.map(_mapYear).toList(growable: false));
  }

  @override
  Future<List<FiscalYear>> listAll() async {
    final rows = await (_db.select(_db.fiscalYears)
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
    return rows.map(_mapYear).toList(growable: false);
  }

  @override
  Future<bool> hasAnyFiscalYear() async {
    final row = await (_db.select(_db.fiscalYears)..limit(1)).getSingleOrNull();
    return row != null;
  }

  @override
  Future<FiscalYear?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    return row == null ? null : _mapYear(row);
  }

  Future<FiscalYearSummary> _summaryFor(FiscalYear year) async {
    final periods = await listPeriods(year.uuid);
    var open = 0;
    var closed = 0;
    for (final p in periods) {
      if (p.allowsPosting) {
        open++;
      } else if (p.status == AccountingPeriodStatus.closed ||
          p.status == AccountingPeriodStatus.closing) {
        closed++;
      } else {
        closed++;
      }
    }
    return FiscalYearSummary(
      fiscalYear: year,
      openPeriodCount: open,
      closedPeriodCount: closed,
      totalPeriods: periods.length,
    );
  }

  @override
  Future<FiscalYearSummary?> getSummary(String uuid) async {
    final year = await getByUuid(uuid);
    if (year == null) {
      return null;
    }
    return _summaryFor(year);
  }

  @override
  Future<List<FiscalYearSummary>> listSummaries() async {
    final years = await listAll();
    final out = <FiscalYearSummary>[];
    for (final y in years) {
      out.add(await _summaryFor(y));
    }
    return out;
  }

  @override
  Future<AccountingPeriod?> findPeriodContaining(DateTime date) async {
    final dayMs = _dayMs(date);
    final row = await (_db.select(_db.accountingPeriods)..where(
          (t) =>
              t.startDate.isSmallerOrEqualValue(dayMs) &
              t.endDate.isBiggerOrEqualValue(dayMs),
        ))
        .getSingleOrNull();
    return row == null ? null : _mapPeriod(row);
  }

  @override
  Future<List<AccountingPeriod>> listPeriods(String fiscalYearUuid) async {
    final rows = await (_db.select(_db.accountingPeriods)
          ..where((t) => t.fiscalYearUuid.equals(fiscalYearUuid))
          ..orderBy([(t) => OrderingTerm.asc(t.periodNumber)]))
        .get();
    return rows.map(_mapPeriod).toList(growable: false);
  }

  @override
  Future<AccountingPeriod?> getPeriodByUuid(String uuid) async {
    final row = await (_db.select(
      _db.accountingPeriods,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    return row == null ? null : _mapPeriod(row);
  }

  @override
  Future<PeriodClosingRecord?> getCompletedClosing(String periodUuid) async {
    final row = await (_db.select(_db.periodClosingRecords)..where(
          (t) =>
              t.periodUuid.equals(periodUuid) &
              t.status.equals(PeriodClosingStatus.completed.storageValue),
        ))
        .getSingleOrNull();
    return row == null ? null : _mapClosing(row);
  }

  @override
  Future<List<PeriodClosingRecord>> listClosingsForFiscalYear(
    String fiscalYearUuid,
  ) async {
    final rows = await (_db.select(_db.periodClosingRecords)
          ..where((t) => t.fiscalYearUuid.equals(fiscalYearUuid))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_mapClosing).toList(growable: false);
  }

  @override
  Future<int> countUnpostedJournals({
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async {
    final startMs = _dayMs(startInclusive);
    final endMs = _dayMs(endInclusive);
    final count = _db.journalEntries.id.count();
    final query = _db.selectOnly(_db.journalEntries)
      ..addColumns([count])
      ..where(
        _db.journalEntries.isPosted.equals(false) &
            _db.journalEntries.deletedAt.isNull() &
            _db.journalEntries.entryDate.isBiggerOrEqualValue(startMs) &
            _db.journalEntries.entryDate.isSmallerOrEqualValue(endMs),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  @override
  Future<List<String>> listForeignCurrenciesInRange({
    required DateTime startInclusive,
    required DateTime endInclusive,
    required String baseCurrencyCode,
  }) async {
    final startMs = _dayMs(startInclusive);
    final endMs = _dayMs(endInclusive);
    final base = baseCurrencyCode.trim().toUpperCase();
    final rows = await _db
        .customSelect(
          '''
SELECT DISTINCT jl.currency_code AS code
FROM journal_lines jl
INNER JOIN journal_entries je ON je.uuid = jl.entry_uuid
WHERE je.deleted_at IS NULL
  AND je.entry_date >= ?
  AND je.entry_date <= ?
  AND UPPER(jl.currency_code) != ?
''',
          variables: [
            Variable<int>(startMs),
            Variable<int>(endMs),
            Variable<String>(base),
          ],
          readsFrom: {_db.journalLines, _db.journalEntries},
        )
        .get();
    return [
      for (final row in rows) row.read<String>('code').trim().toUpperCase(),
    ];
  }

  @override
  Future<FiscalYear> createFiscalYear({
    required FiscalYearDraft draft,
    required List<GeneratedPeriodSpec> periods,
  }) async {
    final startMs = _dayMs(draft.startDate);
    final endMs = _dayMs(draft.endDate);
    final code = draft.code.trim();
    if (code.isEmpty) {
      throw const FiscalYearException(FiscalYearException.invalidDateRange);
    }

    final duplicate = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.code.equals(code))).getSingleOrNull();
    if (duplicate != null) {
      throw const FiscalYearException(FiscalYearException.duplicateCode);
    }

    final overlap = await (_db.select(_db.fiscalYears)..where(
          (t) =>
              t.startDate.isSmallerOrEqualValue(endMs) &
              t.endDate.isBiggerOrEqualValue(startMs),
        ))
        .get();
    if (overlap.isNotEmpty) {
      throw const FiscalYearException(FiscalYearException.overlapExisting);
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final fyUuid = generateUuidV4();

    return _db.transaction(() async {
      await _db
          .into(_db.fiscalYears)
          .insert(
            FiscalYearsCompanion.insert(
              uuid: fyUuid,
              code: code,
              name: draft.name.trim(),
              startDate: startMs,
              endDate: endMs,
              status: FiscalYearStatus.open.storageValue,
              baseCurrencyCode: draft.baseCurrencyCode.trim().toUpperCase(),
              periodCount: draft.periodCount,
              periodFrequency: Value(draft.periodFrequency.storageValue),
              fxRevaluationEnabled: Value(draft.fxRevaluationEnabled),
              fxGainAccountUuid: Value(draft.fxGainAccountUuid),
              fxLossAccountUuid: Value(draft.fxLossAccountUuid),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: Value(draft.createdBy),
            ),
          );

      for (final spec in periods) {
        await _db
            .into(_db.accountingPeriods)
            .insert(
              AccountingPeriodsCompanion.insert(
                uuid: generateUuidV4(),
                fiscalYearUuid: fyUuid,
                periodNumber: spec.periodNumber,
                name: spec.name,
                startDate: _dayMs(spec.startDate),
                endDate: _dayMs(spec.endDate),
                status: AccountingPeriodStatus.closed.storageValue,
              ),
            );
      }

      final created = await getByUuid(fyUuid);
      if (created == null) {
        throw const FiscalYearException(FiscalYearException.notFound);
      }
      return created;
    });
  }

  @override
  Future<AccountingPeriod> openPeriod({
    required String periodUuid,
    required String openedBy,
  }) async {
    final period = await getPeriodByUuid(periodUuid);
    if (period == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    if (period.status != AccountingPeriodStatus.closed &&
        period.status != AccountingPeriodStatus.reopened) {
      // Allow re-open attempt only from closed; already open is fine idempotent.
      if (period.allowsPosting) {
        return period;
      }
      throw const FiscalYearException(FiscalYearException.periodNotOpenable);
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.accountingPeriods,
    )..where((t) => t.uuid.equals(periodUuid))).write(
      AccountingPeriodsCompanion(
        status: Value(AccountingPeriodStatus.open.storageValue),
        openedAt: Value(nowMs),
        openedBy: Value(openedBy),
      ),
    );
    final updated = await getPeriodByUuid(periodUuid);
    if (updated == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    return updated;
  }

  @override
  Future<AccountingPeriod> markPeriodClosing(String periodUuid) async {
    final period = await getPeriodByUuid(periodUuid);
    if (period == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    if (!period.allowsPosting) {
      throw const FiscalYearException(FiscalYearException.periodNotCloseable);
    }
    await (_db.update(
      _db.accountingPeriods,
    )..where((t) => t.uuid.equals(periodUuid))).write(
      const AccountingPeriodsCompanion(
        status: Value('closing'),
      ),
    );
    final updated = await getPeriodByUuid(periodUuid);
    if (updated == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    return updated;
  }

  @override
  Future<PeriodClosingRecord> closePeriodAtomically({
    required String periodUuid,
    required String closedBy,
    required bool fxRevaluationEnabled,
    required bool fxRevaluationExecuted,
    String? fxSkipReason,
    double fxGain = 0,
    double fxLoss = 0,
    double netFxDifference = 0,
    String? journalEntryUuid,
  }) async {
    return _db.transaction(() async {
      final period = await getPeriodByUuid(periodUuid);
      if (period == null) {
        throw const FiscalYearException(FiscalYearException.periodNotFound);
      }
      if (!period.allowsPosting &&
          period.status != AccountingPeriodStatus.closing) {
        throw const FiscalYearException(FiscalYearException.periodNotCloseable);
      }
      final fy = await getByUuid(period.fiscalYearUuid);
      if (fy == null) {
        throw const FiscalYearException(FiscalYearException.notFound);
      }

      final now = DateTime.now().toUtc();
      final nowMs = now.millisecondsSinceEpoch;
      final recordUuid = generateUuidV4();

      await (_db.update(
        _db.accountingPeriods,
      )..where((t) => t.uuid.equals(periodUuid))).write(
        AccountingPeriodsCompanion(
          status: Value(AccountingPeriodStatus.closed.storageValue),
          closedAt: Value(nowMs),
          closedBy: Value(closedBy),
        ),
      );

      await _db
          .into(_db.periodClosingRecords)
          .insert(
            PeriodClosingRecordsCompanion.insert(
              uuid: recordUuid,
              fiscalYearUuid: fy.uuid,
              periodUuid: period.uuid,
              closingDate: _dayMs(now),
              status: PeriodClosingStatus.completed.storageValue,
              fxRevaluationEnabled: Value(fxRevaluationEnabled),
              fxRevaluationExecuted: Value(fxRevaluationExecuted),
              fxSkipReason: Value(fxSkipReason),
              fxGain: Value(fxGain),
              fxLoss: Value(fxLoss),
              netFxDifference: Value(netFxDifference),
              journalEntryUuid: Value(journalEntryUuid),
              createdBy: Value(closedBy),
              createdAt: nowMs,
            ),
          );

      final record = await getCompletedClosing(period.uuid);
      if (record == null) {
        throw const FiscalYearException(FiscalYearException.periodNotFound);
      }
      return record;
    });
  }

  @override
  Future<PeriodClosingRecord> completePeriodClose({
    required AccountingPeriod period,
    required FiscalYear fiscalYear,
    required String closedBy,
    required bool fxRevaluationEnabled,
    required bool fxRevaluationExecuted,
    String? fxSkipReason,
    double fxGain = 0,
    double fxLoss = 0,
    double netFxDifference = 0,
    String? journalEntryUuid,
  }) {
    return closePeriodAtomically(
      periodUuid: period.uuid,
      closedBy: closedBy,
      fxRevaluationEnabled: fxRevaluationEnabled,
      fxRevaluationExecuted: fxRevaluationExecuted,
      fxSkipReason: fxSkipReason,
      fxGain: fxGain,
      fxLoss: fxLoss,
      netFxDifference: netFxDifference,
      journalEntryUuid: journalEntryUuid,
    );
  }

  @override
  Future<AccountingPeriod> reopenPeriod({
    required String periodUuid,
    required String reopenedBy,
    required String reason,
  }) async {
    final period = await getPeriodByUuid(periodUuid);
    if (period == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    if (period.status != AccountingPeriodStatus.closed) {
      throw const FiscalYearException(FiscalYearException.periodNotReopenable);
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.accountingPeriods,
    )..where((t) => t.uuid.equals(periodUuid))).write(
      AccountingPeriodsCompanion(
        status: Value(AccountingPeriodStatus.reopened.storageValue),
        reopenedAt: Value(nowMs),
        reopenedBy: Value(reopenedBy),
        reopenReason: Value(reason),
      ),
    );
    final updated = await getPeriodByUuid(periodUuid);
    if (updated == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    return updated;
  }
}
