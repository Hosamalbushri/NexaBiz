import 'package:drift/drift.dart';

import 'package:stock_count/core/sync/sync_core.dart';
import 'package:stock_count/core/utils/business_date.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/accounting_period_status.dart';
import '../../domain/entities/fiscal_year.dart';
import '../../domain/models/fiscal_year_exception.dart';
import '../../domain/repositories/fiscal_year_repository.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

import 'package:stock_count/core/tenancy/company_context_resolver.dart';

class FiscalYearRepositoryImpl implements FiscalYearRepository {
  FiscalYearRepositoryImpl(this._db, {this._syncQueue, this._readCompanyId});

  final NexabizDatabase _db;
  final SyncQueue? _syncQueue;
  final String Function()? _readCompanyId;

  static const entityType = 'fiscal_year';

  String get _currentCompanyId {
    final id = _readCompanyId?.call().trim();
    if (id == null || id.isEmpty) {
      throw MissingCompanyContextException(
        'FiscalYearRepository operation failed: missing company context.',
      );
    }
    return id;
  }

  Expression<bool> _tenantScoped($FiscalYearsTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($FiscalYearsTable t) => _tenantScoped(t);

  DateTime _dayFromMs(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  int _dayMs(DateTime value) => BusinessDate.utcDayMs(value);

  FiscalYear _mapYear(FiscalYearRow row) {
    return FiscalYear(
      id: row.id,
      code: row.code,
      name: row.name,
      startDate: _dayFromMs(row.startDate),
      endDate: _dayFromMs(row.endDate),
      status: FiscalYearStatus.fromStorage(row.status),
      baseCurrencyCode: row.baseCurrencyCode,
      periodCount: row.periodCount,
      periodFrequency: PeriodFrequency.fromStorage(row.periodFrequency),
      fxRevaluationEnabled: row.fxRevaluationEnabled,
      fxGainAccountId: row.fxGainAccountId,
      fxLossAccountId: row.fxLossAccountId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      closedAt: row.closedAt == null ? null : _dayFromMs(row.closedAt!),
      createdBy: row.createdBy,
      closedBy: row.closedBy,
    );
  }

  AccountingPeriod _mapPeriod(AccountingPeriodRow row) {
    return AccountingPeriod(
      id: row.id,
      fiscalYearId: row.fiscalYearId,
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
      fiscalYearId: row.fiscalYearId,
      periodId: row.periodId,
      closingDate: _dayFromMs(row.closingDate),
      status: PeriodClosingStatus.fromStorage(row.status),
      fxRevaluationEnabled: row.fxRevaluationEnabled,
      fxRevaluationExecuted: row.fxRevaluationExecuted,
      fxSkipReason: row.fxSkipReason,
      fxGain: row.fxGain,
      fxLoss: row.fxLoss,
      netFxDifference: row.netFxDifference,
      journalEntryId: row.journalEntryId,
      createdBy: row.createdBy,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
    );
  }

  Future<String?> _accountCodeById(String? id) async {
    final trimmed = id?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.id.equals(trimmed))).getSingleOrNull();
    return row?.accountCode;
  }

  Future<String?> _accountIdByCode(String? code) async {
    final normalized = code?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.accounts)..where(
              (t) => t.accountCode.equals(normalized) & t.isActive.equals(true),
            ))
            .getSingleOrNull();
    return row?.id;
  }

  Future<String?> _resolveFxAccountId({
    required String? accountId,
    required String? accountCode,
  }) async {
    final byCode = await _accountIdByCode(accountCode);
    if (byCode != null) {
      return byCode;
    }
    final id = accountId?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.accounts)
              ..where((t) => t.id.equals(id) & t.isActive.equals(true)))
            .getSingleOrNull();
    return row?.id ?? id;
  }

  Future<Map<String, dynamic>> _buildPayload(FiscalYearRow row) async {
    final periods = await listPeriods(row.id);
    final closings = await listClosingsForFiscalYear(row.id);
    final fxGainCode = await _accountCodeById(row.fxGainAccountId);
    final fxLossCode = await _accountCodeById(row.fxLossAccountId);
    return {
      'id': row.id,
      'code': row.code,
      'name': row.name,
      'startDate': row.startDate,
      'endDate': row.endDate,
      'status': row.status,
      'baseCurrencyCode': row.baseCurrencyCode,
      'periodCount': row.periodCount,
      'periodFrequency': row.periodFrequency,
      'fxRevaluationEnabled': row.fxRevaluationEnabled,
      'fxGainAccountId': row.fxGainAccountId,
      'fxGainAccountCode': fxGainCode,
      'fxLossAccountId': row.fxLossAccountId,
      'fxLossAccountCode': fxLossCode,
      'periods': [
        for (final p in periods)
          {
            'id': p.id,
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
            'id': c.id,
            'periodId': c.periodId,
            'closingDate': c.closingDate.toUtc().millisecondsSinceEpoch,
            'status': c.status.storageValue,
            'fxRevaluationEnabled': c.fxRevaluationEnabled,
            'fxRevaluationExecuted': c.fxRevaluationExecuted,
            'fxSkipReason': c.fxSkipReason,
            'fxGain': c.fxGain,
            'fxLoss': c.fxLoss,
            'netFxDifference': c.netFxDifference,
            'journalEntryId': c.journalEntryId,
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

  Future<void> _enqueue(String fiscalYearId, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.id.equals(fiscalYearId))).getSingleOrNull();
    if (row == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: row.id,
        type: type,
        baseVersion: row.version,
        payload: await _buildPayload(row),
      ),
    );
  }

  /// Bump FY version, mark pending, enqueue update (period lifecycle changes).
  Future<void> _touchAndEnqueueUpdate(String fiscalYearId) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.id.equals(fiscalYearId))).getSingleOrNull();
    if (row == null) {
      return;
    }
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.fiscalYears,
    )..where((t) => t.id.equals(fiscalYearId))).write(
      FiscalYearsCompanion(
        updatedAt: Value(nowMs),
        version: Value(row.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
    await _enqueue(fiscalYearId, SyncOperationType.update);
  }

  @override
  Stream<List<FiscalYear>> watchAll() {
    final query = _db.select(_db.fiscalYears)
      ..where(_scoped)
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
    return query.watch().map(
      (rows) => rows.map(_mapYear).toList(growable: false),
    );
  }

  @override
  Future<List<FiscalYear>> listAll() async {
    final rows =
        await (_db.select(_db.fiscalYears)
              ..where(_scoped)
              ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
            .get();
    return rows.map(_mapYear).toList(growable: false);
  }

  @override
  Future<bool> hasAnyFiscalYear() async {
    final row =
        await (_db.select(_db.fiscalYears)
              ..where(_scoped)
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<FiscalYear?> getByUuid(String id) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.id.equals(id) & _scoped(t))).getSingleOrNull();
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
    final periods = await listPeriods(year.id);
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
  Future<FiscalYearSummary?> getSummary(String id) async {
    final year = await getByUuid(id);
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
    final row =
        await (_db.select(_db.accountingPeriods)..where(
              (t) =>
                  t.startDate.isSmallerOrEqualValue(dayMs) &
                  t.endDate.isBiggerOrEqualValue(dayMs),
            ))
            .getSingleOrNull();
    return row == null ? null : _mapPeriod(row);
  }

  @override
  Future<List<AccountingPeriod>> listPeriods(String fiscalYearId) async {
    final rows =
        await (_db.select(_db.accountingPeriods)
              ..where((t) => t.fiscalYearId.equals(fiscalYearId))
              ..orderBy([(t) => OrderingTerm.asc(t.periodNumber)]))
            .get();
    return rows.map(_mapPeriod).toList(growable: false);
  }

  @override
  Future<AccountingPeriod?> getPeriodByUuid(String id) async {
    final row = await (_db.select(
      _db.accountingPeriods,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapPeriod(row);
  }

  @override
  Future<PeriodClosingRecord?> getCompletedClosing(String periodId) async {
    final row =
        await (_db.select(_db.periodClosingRecords)..where(
              (t) =>
                  t.periodId.equals(periodId) &
                  t.status.equals(PeriodClosingStatus.completed.storageValue),
            ))
            .getSingleOrNull();
    return row == null ? null : _mapClosing(row);
  }

  @override
  Future<List<PeriodClosingRecord>> listClosingsForFiscalYear(
    String fiscalYearId,
  ) async {
    final rows =
        await (_db.select(_db.periodClosingRecords)
              ..where((t) => t.fiscalYearId.equals(fiscalYearId))
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
INNER JOIN journal_entries je ON je.id = jl.entry_id
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

    final overlap =
        await (_db.select(_db.fiscalYears)..where(
              (t) =>
                  t.startDate.isSmallerOrEqualValue(endMs) &
                  t.endDate.isBiggerOrEqualValue(startMs),
            ))
            .get();
    if (overlap.isNotEmpty) {
      throw const FiscalYearException(FiscalYearException.overlapExisting);
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final fyId = generateUuidV7();

    final created = await _db.transaction(() async {
      await _db
          .into(_db.fiscalYears)
          .insert(
            FiscalYearsCompanion.insert(
              id: Value(fyId),
              code: code,
              name: draft.name.trim(),
              startDate: startMs,
              endDate: endMs,
              status: FiscalYearStatus.open.storageValue,
              baseCurrencyCode: draft.baseCurrencyCode.trim().toUpperCase(),
              periodCount: draft.periodCount,
              periodFrequency: Value(draft.periodFrequency.storageValue),
              fxRevaluationEnabled: Value(draft.fxRevaluationEnabled),
              fxGainAccountId: Value(draft.fxGainAccountId),
              fxLossAccountId: Value(draft.fxLossAccountId),
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
                id: Value(generateUuidV7()),
                fiscalYearId: fyId,
                periodNumber: spec.periodNumber,
                name: spec.name,
                startDate: _dayMs(spec.startDate),
                endDate: _dayMs(spec.endDate),
                status: AccountingPeriodStatus.closed.storageValue,
              ),
            );
      }

      final row = await getByUuid(fyId);
      if (row == null) {
        throw const FiscalYearException(FiscalYearException.notFound);
      }
      return row;
    });

    await _enqueue(fyId, SyncOperationType.create);
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
      if (period.allowsPosting) {
        return period;
      }
      throw const FiscalYearException(FiscalYearException.periodNotOpenable);
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.accountingPeriods,
    )..where((t) => t.id.equals(periodUuid))).write(
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
    await _touchAndEnqueueUpdate(updated.fiscalYearId);
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
    await (_db.update(_db.accountingPeriods)
          ..where((t) => t.id.equals(periodUuid)))
        .write(const AccountingPeriodsCompanion(status: Value('closing')));
    final updated = await getPeriodByUuid(periodUuid);
    if (updated == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    await _touchAndEnqueueUpdate(updated.fiscalYearId);
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
      final fy = await getByUuid(period.fiscalYearId);
      if (fy == null) {
        throw const FiscalYearException(FiscalYearException.notFound);
      }

      final now = DateTime.now().toUtc();
      final nowMs = now.millisecondsSinceEpoch;
      final recordId = generateUuidV7();

      await (_db.update(
        _db.accountingPeriods,
      )..where((t) => t.id.equals(periodUuid))).write(
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
              id: Value(recordId),
              fiscalYearId: fy.id,
              periodId: period.id,
              closingDate: _dayMs(now),
              status: PeriodClosingStatus.completed.storageValue,
              fxRevaluationEnabled: Value(fxRevaluationEnabled),
              fxRevaluationExecuted: Value(fxRevaluationExecuted),
              fxSkipReason: Value(fxSkipReason),
              fxGain: Value(fxGain),
              fxLoss: Value(fxLoss),
              netFxDifference: Value(netFxDifference),
              journalEntryId: Value(journalEntryUuid),
              createdBy: Value(closedBy),
              createdAt: nowMs,
            ),
          );

      final completed = await getCompletedClosing(period.id);
      if (completed == null) {
        throw const FiscalYearException(FiscalYearException.periodNotFound);
      }
      return completed;
    });

    await _touchAndEnqueueUpdate(record.fiscalYearId);
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
      periodUuid: period.id,
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
    )..where((t) => t.id.equals(periodUuid))).write(
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
    await _touchAndEnqueueUpdate(updated.fiscalYearId);
    return updated;
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final stamp = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await (_db.update(
      _db.fiscalYears,
    )..where((t) => t.id.equals(uuid))).write(
      FiscalYearsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(stamp),
        version: Value(remoteVersion),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.fiscalYears)..where((t) => t.id.equals(uuid)))
        .write(const FiscalYearsCompanion(syncStatus: Value('conflict')));
  }

  Future<SyncStatus> _syncStatusForUuid(String uuid) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.id.equals(uuid))).getSingleOrNull();
    return SyncStatusX.fromStorage(row?.syncStatus);
  }

  Future<int> _versionForUuid(String uuid) async {
    final row = await (_db.select(
      _db.fiscalYears,
    )..where((t) => t.id.equals(uuid))).getSingleOrNull();
    return row?.version ?? 1;
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final id = payload['id']?.toString() ?? payload['uuid']?.toString();
    if (id == null || id.isEmpty) {
      return;
    }

    final existingByUuid = await getByUuid(id);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updatedAt = (payload['updatedAt'] as num?)?.toInt() ?? nowMs;
    final version = (payload['version'] as num?)?.toInt() ?? 1;
    final code = payload['code']?.toString().trim() ?? '';
    if (code.isEmpty) {
      return;
    }

    if (existingByUuid != null) {
      final status = await _syncStatusForUuid(id);
      final localVersion = await _versionForUuid(id);
      if (status.needsUpload ||
          status == SyncStatus.conflict ||
          status == SyncStatus.syncing) {
        if (version > localVersion) {
          await markConflict(id);
        }
        return;
      }
      if (version <= localVersion) {
        return;
      }
    }

    final fxGainId = await _resolveFxAccountId(
      accountId: payload['fxGainAccountId']?.toString() ?? payload['fxGainAccountUuid']?.toString(),
      accountCode: payload['fxGainAccountCode']?.toString(),
    );
    final fxLossId = await _resolveFxAccountId(
      accountId: payload['fxLossAccountId']?.toString() ?? payload['fxLossAccountUuid']?.toString(),
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

    if (existingByUuid == null) {
      final byCode = await getByCode(code);
      if (byCode != null && byCode.id != id) {
        final oldId = byCode.id;
        await (_db.update(
          _db.fiscalYears,
        )..where((t) => t.id.equals(byCode.id))).write(
          FiscalYearsCompanion(
            id: Value(id),
            name: Value(name),
            startDate: Value(startDate),
            endDate: Value(endDate),
            status: Value(status),
            baseCurrencyCode: Value(baseCurrency),
            periodCount: Value(periodCount),
            periodFrequency: Value(periodFrequency),
            fxRevaluationEnabled: Value(fxEnabled),
            fxGainAccountId: Value(fxGainId),
            fxLossAccountId: Value(fxLossId),
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
              ..where((t) => t.fiscalYearId.equals(oldId)))
            .write(AccountingPeriodsCompanion(fiscalYearId: Value(id)));
        await (_db.update(_db.periodClosingRecords)
              ..where((t) => t.fiscalYearId.equals(oldId)))
            .write(PeriodClosingRecordsCompanion(fiscalYearId: Value(id)));
        await _replacePeriodsAndClosings(
          fiscalYearId: id,
          periodsRaw: payload['periods'],
          closingsRaw: payload['closings'],
        );
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: oldId,
        );
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: id,
        );
        return;
      }
    }

    await _db.transaction(() async {
      final current = await getByUuid(id);
      if (current == null) {
        await _db
            .into(_db.fiscalYears)
            .insert(
              FiscalYearsCompanion.insert(
                id: Value(id),
                code: code,
                name: name,
                startDate: startDate,
                endDate: endDate,
                status: status,
                baseCurrencyCode: baseCurrency,
                periodCount: periodCount,
                periodFrequency: Value(periodFrequency),
                fxRevaluationEnabled: Value(fxEnabled),
                fxGainAccountId: Value(fxGainId),
                fxLossAccountId: Value(fxLossId),
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: Value(closedAt),
                createdBy: Value(createdBy),
                closedBy: Value(closedBy),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                companyId: Value(
                  payload['companyId']?.toString() ?? _currentCompanyId,
                ),
              ),
            );
      } else {
        await (_db.update(
          _db.fiscalYears,
        )..where((t) => t.id.equals(id) & _scoped(t))).write(
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
            fxGainAccountId: Value(fxGainId),
            fxLossAccountId: Value(fxLossId),
            updatedAt: Value(updatedAt),
            closedAt: Value(closedAt),
            createdBy: Value(createdBy ?? current.createdBy),
            closedBy: Value(closedBy),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(nowMs),
            version: Value(version),
            companyId: Value(
              payload['companyId']?.toString() ?? _currentCompanyId,
            ),
          ),
        );
      }

      await _replacePeriodsAndClosings(
        fiscalYearId: id,
        periodsRaw: payload['periods'],
        closingsRaw: payload['closings'],
      );
    });
  }

  Future<void> _replacePeriodsAndClosings({
    required String fiscalYearId,
    required Object? periodsRaw,
    required Object? closingsRaw,
  }) async {
    await (_db.delete(
      _db.periodClosingRecords,
    )..where((t) => t.fiscalYearId.equals(fiscalYearId))).go();
    await (_db.delete(
      _db.accountingPeriods,
    )..where((t) => t.fiscalYearId.equals(fiscalYearId))).go();

    if (periodsRaw is List) {
      for (final item in periodsRaw) {
        if (item is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        final periodId = map['id']?.toString().trim() ?? map['uuid']?.toString().trim();
        final periodNumber = (map['periodNumber'] as num?)?.toInt();
        final periodName = map['name']?.toString();
        final startDate = (map['startDate'] as num?)?.toInt();
        final endDate = (map['endDate'] as num?)?.toInt();
        if (periodId == null ||
            periodId.isEmpty ||
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
                id: Value(periodId),
                fiscalYearId: fiscalYearId,
                periodNumber: periodNumber,
                name: periodName,
                startDate: startDate,
                endDate: endDate,
                status:
                    map['status']?.toString() ??
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
        final closingId = map['id']?.toString().trim() ?? map['uuid']?.toString().trim();
        final periodId = map['periodId']?.toString().trim() ?? map['periodUuid']?.toString().trim();
        final closingDate = (map['closingDate'] as num?)?.toInt();
        if (closingId == null ||
            closingId.isEmpty ||
            periodId == null ||
            periodId.isEmpty ||
            closingDate == null) {
          continue;
        }
        await _db
            .into(_db.periodClosingRecords)
            .insert(
              PeriodClosingRecordsCompanion.insert(
                id: Value(closingId),
                fiscalYearId: fiscalYearId,
                periodId: periodId,
                closingDate: closingDate,
                status:
                    map['status']?.toString() ??
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
                journalEntryId: Value(map['journalEntryId']?.toString() ?? map['journalEntryUuid']?.toString()),
                createdBy: Value(map['createdBy']?.toString()),
                createdAt:
                    (map['createdAt'] as num?)?.toInt() ??
                    DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            );
      }
    }
  }
}
