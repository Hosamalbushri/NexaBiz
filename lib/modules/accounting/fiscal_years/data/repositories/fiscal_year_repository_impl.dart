import 'package:drift/drift.dart';

import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/utils/business_date.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/accounting_period_status.dart';
import '../../domain/entities/fiscal_year.dart';
import '../../domain/models/fiscal_year_exception.dart';
import '../../domain/repositories/fiscal_year_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';

import 'package:stock_count/modules/authentication/data/local_auth_store.dart';

class FiscalYearRepositoryImpl implements FiscalYearRepository {
  FiscalYearRepositoryImpl(
    this._db, {
    SyncQueue? syncQueue,
    String Function()? readCompanyId,
  }) : _syncQueue = syncQueue,
       _readCompanyId = readCompanyId;

  final AccountingDatabase _db;
  final SyncQueue? _syncQueue;
  final String Function()? _readCompanyId;

  static const entityType = 'fiscal_year';

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Expression<bool> _tenantScoped($FiscalYearsTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($FiscalYearsTable t) => _tenantScoped(t);

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

  Future<String?> _accountCodeByUuid(String? uuid) async {
    final trimmed = uuid?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.uuid.equals(trimmed))).getSingleOrNull();
    return row?.accountCode;
  }

  Future<String?> _accountUuidByCode(String? code) async {
    final normalized = code?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.accountCode.equals(normalized) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row?.uuid;
  }

  Future<String?> _resolveFxAccountUuid({
    required String? accountUuid,
    required String? accountCode,
  }) async {
    final byCode = await _accountUuidByCode(accountCode);
    if (byCode != null) {
      return byCode;
    }
    final uuid = accountUuid?.trim();
    if (uuid == null || uuid.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.uuid.equals(uuid) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row?.uuid ?? uuid;
  }

  Future<Map<String, dynamic>> _buildPayload(FiscalYearRow row) async {
    final periods = await listPeriods(row.uuid);
    final closings = await listClosingsForFiscalYear(row.uuid);
    final fxGainCode = await _accountCodeByUuid(row.fxGainAccountUuid);
    final fxLossCode = await _accountCodeByUuid(row.fxLossAccountUuid);
    return {
      'uuid': row.uuid,
      'code': row.code,
      'name': row.name,
      'startDate': row.startDate,
      'endDate': row.endDate,
      'status': row.status,
      'baseCurrencyCode': row.baseCurrencyCode,
      'periodCount': row.periodCount,
      'periodFrequency': row.periodFrequency,
      'fxRevaluationEnabled': row.fxRevaluationEnabled,
      'fxGainAccountUuid': row.fxGainAccountUuid,
      'fxGainAccountCode': fxGainCode,
      'fxLossAccountUuid': row.fxLossAccountUuid,
      'fxLossAccountCode': fxLossCode,
      'periods': [
        for (final p in periods)
          {
            'uuid': p.uuid,
            'periodNumber': p.periodNumber,
            'name': p.name,
            'startDate': p.startDate.toUtc().millisecondsSinceEpoch,
            'endDate': p.endDate.toUtc().millisecondsSinceEpoch,
            'status': p.status.storageValue,
            'openedAt': p.openedAt?.toUtc().millisecondsSinceEpoch,
            'openedBy': p.openedBy,
            'closedAt': p.closedAt?.toUtc().millisecondsSinceEpoch,
            'closedBy': p.closedBy,
            'reopenedAt': p.reopenedAt?.toUtc().millisecondsSinceEpoch,
            'reopenedBy': p.reopenedBy,
            'reopenReason': p.reopenReason,
          },
      ],
      'closings': [
        for (final c in closings)
          {
            'uuid': c.uuid,
            'periodUuid': c.periodUuid,
            'closingDate': c.closingDate.toUtc().millisecondsSinceEpoch,
            'status': c.status.storageValue,
            'fxRevaluationEnabled': c.fxRevaluationEnabled,
            'fxRevaluationExecuted': c.fxRevaluationExecuted,
            'fxSkipReason': c.fxSkipReason,
            'fxGain': c.fxGain,
            'fxLoss': c.fxLoss,
            'netFxDifference': c.netFxDifference,
            'journalEntryUuid': c.journalEntryUuid,
            'createdBy': c.createdBy,
            'createdAt': c.createdAt.toUtc().millisecondsSinceEpoch,
          },
      ],
      'version': row.version,
      'updatedAt': row.updatedAt,
      'createdAt': row.createdAt,
      'closedAt': row.closedAt,
      'createdBy': row.createdBy,
      'closedBy': row.closedBy,
    };
  }

  Future<void> _enqueue(
    String fiscalYearUuid,
    SyncOperationType type,
  ) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.uuid.equals(fiscalYearUuid))).getSingleOrNull();
    if (row == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: row.uuid,
        type: type,
        baseVersion: row.version,
        payload: await _buildPayload(row),
      ),
    );
  }

  /// Bump FY version, mark pending, enqueue update (period lifecycle changes).
  Future<void> _touchAndEnqueueUpdate(String fiscalYearUuid) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.uuid.equals(fiscalYearUuid))).getSingleOrNull();
    if (row == null) {
      return;
    }
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.fiscalYears)
          ..where((t) => t.uuid.equals(fiscalYearUuid)))
        .write(
          FiscalYearsCompanion(
            updatedAt: Value(nowMs),
            version: Value(row.version + 1),
            syncStatus: const Value('pending'),
          ),
        );
    await _enqueue(fiscalYearUuid, SyncOperationType.update);
  }

  @override
  Stream<List<FiscalYear>> watchAll() {
    final query = _db.select(_db.fiscalYears)
      ..where(_scoped)
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
    return query.watch().map((rows) => rows.map(_mapYear).toList(growable: false));
  }

  @override
  Future<List<FiscalYear>> listAll() async {
    final rows = await (_db.select(_db.fiscalYears)
          ..where(_scoped)
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
    return rows.map(_mapYear).toList(growable: false);
  }

  @override
  Future<bool> hasAnyFiscalYear() async {
    final row = await (_db.select(_db.fiscalYears)..where(_scoped)..limit(1)).getSingleOrNull();
    return row != null;
  }

  @override
  Future<FiscalYear?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.uuid.equals(uuid) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _mapYear(row);
  }

  Future<FiscalYear?> getByCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.code.equals(trimmed) & _scoped(t))).getSingleOrNull();
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
            _db.journalEntries.companyId.equals(_currentCompanyId) &
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
  AND je.company_id = ?
  AND je.entry_date >= ?
  AND je.entry_date <= ?
  AND UPPER(jl.currency_code) != ?
''',
          variables: [
            Variable<String>(_currentCompanyId),
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

    final created = await _db.transaction(() async {
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
              syncStatus: const Value('pending'),
              version: const Value(1),
              companyId: Value(_currentCompanyId),
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

      final row = await getByUuid(fyUuid);
      if (row == null) {
        throw const FiscalYearException(FiscalYearException.notFound);
      }
      return row;
    });

    await _enqueue(fyUuid, SyncOperationType.create);
    return created;
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
    await _touchAndEnqueueUpdate(updated.fiscalYearUuid);
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
    await _touchAndEnqueueUpdate(updated.fiscalYearUuid);
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
    final record = await _db.transaction(() async {
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

      final completed = await getCompletedClosing(period.uuid);
      if (completed == null) {
        throw const FiscalYearException(FiscalYearException.periodNotFound);
      }
      return completed;
    });

    await _touchAndEnqueueUpdate(record.fiscalYearUuid);
    return record;
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
    await _touchAndEnqueueUpdate(updated.fiscalYearUuid);
    return updated;
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final stamp = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await (_db.update(_db.fiscalYears)..where((t) => t.uuid.equals(uuid)))
        .write(
          FiscalYearsCompanion(
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(stamp),
            version: Value(remoteVersion),
          ),
        );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.fiscalYears)..where((t) => t.uuid.equals(uuid)))
        .write(
          const FiscalYearsCompanion(syncStatus: Value('conflict')),
        );
  }

  Future<SyncStatus> _syncStatusForUuid(String uuid) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    return SyncStatusX.fromStorage(row?.syncStatus);
  }

  Future<int> _versionForUuid(String uuid) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    return row?.version ?? 1;
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) {
      return;
    }

    final existingByUuid = await getByUuid(uuid);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updatedAt = (payload['updatedAt'] as num?)?.toInt() ?? nowMs;
    final version = (payload['version'] as num?)?.toInt() ?? 1;
    final code = payload['code']?.toString().trim() ?? '';
    if (code.isEmpty) {
      return;
    }

    if (existingByUuid != null) {
      final status = await _syncStatusForUuid(uuid);
      final localVersion = await _versionForUuid(uuid);
      if (status.needsUpload ||
          status == SyncStatus.conflict ||
          status == SyncStatus.syncing) {
        if (version > localVersion) {
          await markConflict(uuid);
        }
        return;
      }
      // Stale remote: incoming version <= local version → skip (idempotent pull).
      if (version <= localVersion) {
        return;
      }
    }

    final fxGainUuid = await _resolveFxAccountUuid(
      accountUuid: payload['fxGainAccountUuid']?.toString(),
      accountCode: payload['fxGainAccountCode']?.toString(),
    );
    final fxLossUuid = await _resolveFxAccountUuid(
      accountUuid: payload['fxLossAccountUuid']?.toString(),
      accountCode: payload['fxLossAccountCode']?.toString(),
    );

    final startDate =
        (payload['startDate'] as num?)?.toInt() ??
        existingByUuid?.startDate.toUtc().millisecondsSinceEpoch ??
        nowMs;
    final endDate =
        (payload['endDate'] as num?)?.toInt() ??
        existingByUuid?.endDate.toUtc().millisecondsSinceEpoch ??
        nowMs;
    final createdAt =
        (payload['createdAt'] as num?)?.toInt() ??
        existingByUuid?.createdAt.toUtc().millisecondsSinceEpoch ??
        updatedAt;
    final name = payload['name']?.toString() ?? existingByUuid?.name ?? code;
    final status =
        payload['status']?.toString() ??
        existingByUuid?.status.storageValue ??
        FiscalYearStatus.open.storageValue;
    final baseCurrency =
        (payload['baseCurrencyCode']?.toString() ??
                existingByUuid?.baseCurrencyCode ??
                'SAR')
            .trim()
            .toUpperCase();
    final periodCount =
        (payload['periodCount'] as num?)?.toInt() ??
        existingByUuid?.periodCount ??
        12;
    final periodFrequency =
        payload['periodFrequency']?.toString() ??
        existingByUuid?.periodFrequency.storageValue ??
        PeriodFrequency.monthly.storageValue;
    final fxEnabled =
        payload['fxRevaluationEnabled'] as bool? ??
        existingByUuid?.fxRevaluationEnabled ??
        false;
    final closedAt = (payload['closedAt'] as num?)?.toInt();
    final createdBy = payload['createdBy']?.toString();
    final closedBy = payload['closedBy']?.toString();

    // Same code, different UUID → adopt remote identity.
    if (existingByUuid == null) {
      final byCode = await getByCode(code);
      if (byCode != null && byCode.uuid != uuid) {
        final oldUuid = byCode.uuid;
        await (_db.update(_db.fiscalYears)
              ..where((t) => t.id.equals(byCode.id)))
            .write(
              FiscalYearsCompanion(
                uuid: Value(uuid),
                name: Value(name),
                startDate: Value(startDate),
                endDate: Value(endDate),
                status: Value(status),
                baseCurrencyCode: Value(baseCurrency),
                periodCount: Value(periodCount),
                periodFrequency: Value(periodFrequency),
                fxRevaluationEnabled: Value(fxEnabled),
                fxGainAccountUuid: Value(fxGainUuid),
                fxLossAccountUuid: Value(fxLossUuid),
                updatedAt: Value(updatedAt),
                closedAt: Value(closedAt),
                createdBy: Value(createdBy ?? byCode.createdBy),
                closedBy: Value(closedBy),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
              ),
            );
        await (_db.update(_db.accountingPeriods)
              ..where((t) => t.fiscalYearUuid.equals(oldUuid)))
            .write(AccountingPeriodsCompanion(fiscalYearUuid: Value(uuid)));
        await (_db.update(_db.periodClosingRecords)
              ..where((t) => t.fiscalYearUuid.equals(oldUuid)))
            .write(PeriodClosingRecordsCompanion(fiscalYearUuid: Value(uuid)));
        await _replacePeriodsAndClosings(
          fiscalYearUuid: uuid,
          periodsRaw: payload['periods'],
          closingsRaw: payload['closings'],
        );
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: oldUuid,
        );
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: uuid,
        );
        return;
      }
    }

    await _db.transaction(() async {
      final current = await getByUuid(uuid);
      if (current == null) {
        await _db
            .into(_db.fiscalYears)
            .insert(
              FiscalYearsCompanion.insert(
                uuid: uuid,
                code: code,
                name: name,
                startDate: startDate,
                endDate: endDate,
                status: status,
                baseCurrencyCode: baseCurrency,
                periodCount: periodCount,
                periodFrequency: Value(periodFrequency),
                fxRevaluationEnabled: Value(fxEnabled),
                fxGainAccountUuid: Value(fxGainUuid),
                fxLossAccountUuid: Value(fxLossUuid),
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: Value(closedAt),
                createdBy: Value(createdBy),
                closedBy: Value(closedBy),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
              ),
            );
      } else {
        await (_db.update(_db.fiscalYears)..where((t) => t.uuid.equals(uuid) & _scoped(t)))
            .write(
              FiscalYearsCompanion(
                code: Value(code),
                name: Value(name),
                startDate: Value(startDate),
                endDate: Value(endDate),
                status: Value(status),
                baseCurrencyCode: Value(baseCurrency),
                periodCount: Value(periodCount),
                periodFrequency: Value(periodFrequency),
                fxRevaluationEnabled: Value(fxEnabled),
                fxGainAccountUuid: Value(fxGainUuid),
                fxLossAccountUuid: Value(fxLossUuid),
                updatedAt: Value(updatedAt),
                closedAt: Value(closedAt),
                createdBy: Value(createdBy ?? current.createdBy),
                closedBy: Value(closedBy),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
              ),
            );
      }

      await _replacePeriodsAndClosings(
        fiscalYearUuid: uuid,
        periodsRaw: payload['periods'],
        closingsRaw: payload['closings'],
      );
    });
  }

  Future<void> _replacePeriodsAndClosings({
    required String fiscalYearUuid,
    required Object? periodsRaw,
    required Object? closingsRaw,
  }) async {
    await (_db.delete(_db.periodClosingRecords)
          ..where((t) => t.fiscalYearUuid.equals(fiscalYearUuid)))
        .go();
    await (_db.delete(_db.accountingPeriods)
          ..where((t) => t.fiscalYearUuid.equals(fiscalYearUuid)))
        .go();

    if (periodsRaw is List) {
      for (final item in periodsRaw) {
        if (item is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        final periodUuid = map['uuid']?.toString().trim();
        final periodNumber = (map['periodNumber'] as num?)?.toInt();
        final periodName = map['name']?.toString();
        final startDate = (map['startDate'] as num?)?.toInt();
        final endDate = (map['endDate'] as num?)?.toInt();
        if (periodUuid == null ||
            periodUuid.isEmpty ||
            periodNumber == null ||
            periodName == null ||
            startDate == null ||
            endDate == null) {
          continue;
        }
        await _db
            .into(_db.accountingPeriods)
            .insert(
              AccountingPeriodsCompanion.insert(
                uuid: periodUuid,
                fiscalYearUuid: fiscalYearUuid,
                periodNumber: periodNumber,
                name: periodName,
                startDate: startDate,
                endDate: endDate,
                status: map['status']?.toString() ??
                    AccountingPeriodStatus.closed.storageValue,
                openedAt: Value((map['openedAt'] as num?)?.toInt()),
                openedBy: Value(map['openedBy']?.toString()),
                closedAt: Value((map['closedAt'] as num?)?.toInt()),
                closedBy: Value(map['closedBy']?.toString()),
                reopenedAt: Value((map['reopenedAt'] as num?)?.toInt()),
                reopenedBy: Value(map['reopenedBy']?.toString()),
                reopenReason: Value(map['reopenReason']?.toString()),
              ),
            );
      }
    }

    if (closingsRaw is List) {
      for (final item in closingsRaw) {
        if (item is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        final closingUuid = map['uuid']?.toString().trim();
        final periodUuid = map['periodUuid']?.toString().trim();
        final closingDate = (map['closingDate'] as num?)?.toInt();
        if (closingUuid == null ||
            closingUuid.isEmpty ||
            periodUuid == null ||
            periodUuid.isEmpty ||
            closingDate == null) {
          continue;
        }
        await _db
            .into(_db.periodClosingRecords)
            .insert(
              PeriodClosingRecordsCompanion.insert(
                uuid: closingUuid,
                fiscalYearUuid: fiscalYearUuid,
                periodUuid: periodUuid,
                closingDate: closingDate,
                status: map['status']?.toString() ??
                    PeriodClosingStatus.completed.storageValue,
                fxRevaluationEnabled: Value(
                  map['fxRevaluationEnabled'] as bool? ?? false,
                ),
                fxRevaluationExecuted: Value(
                  map['fxRevaluationExecuted'] as bool? ?? false,
                ),
                fxSkipReason: Value(map['fxSkipReason']?.toString()),
                fxGain: Value((map['fxGain'] as num?)?.toDouble() ?? 0),
                fxLoss: Value((map['fxLoss'] as num?)?.toDouble() ?? 0),
                netFxDifference: Value(
                  (map['netFxDifference'] as num?)?.toDouble() ?? 0,
                ),
                journalEntryUuid: Value(map['journalEntryUuid']?.toString()),
                createdBy: Value(map['createdBy']?.toString()),
                createdAt: (map['createdAt'] as num?)?.toInt() ??
                    DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            );
      }
    }
  }
}
