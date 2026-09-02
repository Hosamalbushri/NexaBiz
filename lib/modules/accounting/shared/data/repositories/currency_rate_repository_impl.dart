import 'package:drift/drift.dart';

import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/utils/business_date.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/currency_rate.dart';
import '../../domain/repositories/currency_rate_repository.dart';
import '../database/accounting_database.dart';

import 'package:stock_count/core/tenancy/company_context_resolver.dart';

class CurrencyRateRepositoryImpl implements CurrencyRateRepository {
  CurrencyRateRepositoryImpl(
    this._db, {
    this._syncQueue,
    this._readCompanyId,
  });

  final AccountingDatabase _db;
  final SyncQueue? _syncQueue;
  final String Function()? _readCompanyId;

  static const entityType = 'currency_rate';

  String get _currentCompanyId {
    final id = _readCompanyId?.call().trim();
    if (id == null || id.isEmpty) {
      throw MissingCompanyContextException(
        'CurrencyRateRepository operation failed: missing company context.',
      );
    }
    return id;
  }

  Expression<bool> _tenantScoped($CurrencyRatesTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($CurrencyRatesTable t) => _tenantScoped(t);

  CurrencyRate _map(CurrencyRateRow row) {
    return CurrencyRate(
      id: row.id,
      uuid: row.uuid,
      currencyCode: row.currencyCode,
      rateToBase: row.rateToBase,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      notes: row.notes,
      syncStatus: SyncStatusX.fromStorage(row.syncStatus),
      version: row.version,
    );
  }

  String _normalizeCode(String code) => code.trim().toUpperCase();

  int _dayMs(DateTime date) => BusinessDate.utcDay(date).millisecondsSinceEpoch;

  @override
  Future<List<CurrencyRate>> getAll() async {
    final rows = await (_db.select(
      _db.currencyRates,
    )..where(_scoped)..orderBy([(t) => OrderingTerm.asc(t.currencyCode)])).get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<CurrencyRate>> watchAll() {
    final query = _db.select(_db.currencyRates)
      ..where(_scoped)
      ..orderBy([(t) => OrderingTerm.asc(t.currencyCode)]);
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<CurrencyRate?> getByCode(String currencyCode) async {
    final code = _normalizeCode(currencyCode);
    if (code.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.currencyRates,
    )..where((t) => t.currencyCode.equals(code) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<CurrencyRate?> getByUuid(String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final row = await (_db.select(
      _db.currencyRates,
    )..where((t) => t.uuid.equals(trimmed) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<double?> getRateOn(String currencyCode, DateTime asOf) async {
    final code = _normalizeCode(currencyCode);
    if (code.isEmpty) {
      return null;
    }
    final dayMs = _dayMs(asOf);
    final history =
        await (_db.select(_db.currencyRateHistory)
              ..where(
                (t) =>
                    t.currencyCode.equals(code) &
                    t.asOfDate.isSmallerOrEqualValue(dayMs),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.asOfDate)])
              ..limit(1))
            .getSingleOrNull();
    if (history != null && history.rateToBase > 0) {
      return history.rateToBase;
    }
    final current = await getByCode(code);
    if (current != null && current.rateToBase > 0) {
      return current.rateToBase;
    }
    return null;
  }

  @override
  Future<List<CurrencyRateHistoryEntry>> listHistory(
    String currencyCode, {
    int limit = 30,
  }) async {
    final code = _normalizeCode(currencyCode);
    if (code.isEmpty) {
      return const [];
    }
    final rows =
        await (_db.select(_db.currencyRateHistory)
              ..where((t) => t.currencyCode.equals(code))
              ..orderBy([(t) => OrderingTerm.desc(t.asOfDate)])
              ..limit(limit))
            .get();
    return [
      for (final row in rows)
        CurrencyRateHistoryEntry(
          currencyCode: row.currencyCode,
          asOfDate: DateTime.fromMillisecondsSinceEpoch(
            row.asOfDate,
            isUtc: true,
          ),
          rateToBase: row.rateToBase,
          notes: row.notes,
        ),
    ];
  }

  Future<void> _upsertHistory({
    required String code,
    required double rateToBase,
    required DateTime asOf,
    String? notes,
  }) async {
    final dayMs = _dayMs(asOf);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final existing =
        await (_db.select(_db.currencyRateHistory)..where(
              (t) => t.currencyCode.equals(code) & t.asOfDate.equals(dayMs),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.currencyRateHistory)
          .insert(
            CurrencyRateHistoryCompanion.insert(
              currencyCode: code,
              asOfDate: dayMs,
              rateToBase: rateToBase,
              createdAt: nowMs,
              notes: Value(notes == null || notes.isEmpty ? null : notes),
            ),
          );
      return;
    }
    await (_db.update(
      _db.currencyRateHistory,
    )..where((t) => t.id.equals(existing.id))).write(
      CurrencyRateHistoryCompanion(
        rateToBase: Value(rateToBase),
        notes: Value(notes == null || notes.isEmpty ? null : notes),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _historyPayload(String code) async {
    final history = await listHistory(code, limit: 90);
    return [
      for (final entry in history)
        {
          'currencyCode': entry.currencyCode,
          'asOfDate': entry.asOfDate.toUtc().millisecondsSinceEpoch,
          'rateToBase': entry.rateToBase,
          'notes': entry.notes,
        },
    ];
  }

  Future<void> _enqueue(CurrencyRate rate, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: rate.uuid,
        type: type,
        baseVersion: rate.version,
        payload: {
          'uuid': rate.uuid,
          'currencyCode': rate.currencyCode,
          'rateToBase': rate.rateToBase,
          'notes': rate.notes,
          'history': await _historyPayload(rate.currencyCode),
          'version': rate.version,
          'updatedAt': rate.updatedAt.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  @override
  Future<CurrencyRate> upsert(CurrencyRateDraft draft) async {
    final code = _normalizeCode(draft.currencyCode);
    if (code.isEmpty) {
      throw ArgumentError('currencyCode is required');
    }
    if (draft.rateToBase <= 0 ||
        draft.rateToBase.isNaN ||
        draft.rateToBase.isInfinite) {
      throw ArgumentError('rateToBase must be a positive number');
    }

    final notes = draft.notes?.trim();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final asOf = draft.asOfDate ?? DateTime.now().toUtc();
    final existing = await getByCode(code);

    if (existing == null) {
      final uuid = generateUuidV4();
      final id = await _db
          .into(_db.currencyRates)
          .insert(
            CurrencyRatesCompanion.insert(
              uuid: uuid,
              currencyCode: code,
              rateToBase: draft.rateToBase,
              updatedAt: nowMs,
              notes: Value(notes == null || notes.isEmpty ? null : notes),
              syncStatus: const Value('pending'),
              version: const Value(1),
              companyId: Value(_currentCompanyId),
            ),
          );
      await _upsertHistory(
        code: code,
        rateToBase: draft.rateToBase,
        asOf: asOf,
        notes: notes,
      );
      final created = await (_db.select(
        _db.currencyRates,
      )..where((t) => t.id.equals(id) & _scoped(t))).getSingle();
      final mapped = _map(created);
      await _enqueue(mapped, SyncOperationType.create);
      return mapped;
    }

    final nextVersion = existing.version + 1;
    await (_db.update(
      _db.currencyRates,
    )..where((t) => t.id.equals(existing.id) & _scoped(t))).write(
      CurrencyRatesCompanion(
        rateToBase: Value(draft.rateToBase),
        updatedAt: Value(nowMs),
        notes: Value(notes == null || notes.isEmpty ? null : notes),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
        companyId: Value(_currentCompanyId),
      ),
    );
    await _upsertHistory(
      code: code,
      rateToBase: draft.rateToBase,
      asOf: asOf,
      notes: notes,
    );
    final updated = await getByCode(code);
    await _enqueue(updated!, SyncOperationType.update);
    return updated;
  }

  @override
  Future<void> deleteByCode(String currencyCode) async {
    final code = _normalizeCode(currencyCode);
    final existing = await getByCode(code);
    if (existing != null) {
      await _enqueue(existing, SyncOperationType.delete);
    }
    await (_db.delete(
      _db.currencyRates,
    )..where((t) => t.currencyCode.equals(code) & _scoped(t))).go();
    await (_db.delete(
      _db.currencyRateHistory,
    )..where((t) => t.currencyCode.equals(code))).go();
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final stamp = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await (_db.update(_db.currencyRates)..where((t) => t.uuid.equals(uuid)))
        .write(
          CurrencyRatesCompanion(
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(stamp),
            version: Value(remoteVersion),
          ),
        );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.currencyRates)..where((t) => t.uuid.equals(uuid)))
        .write(
          const CurrencyRatesCompanion(syncStatus: Value('conflict')),
        );
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) {
      return;
    }

    final deleted = payload['deletedAt'] != null || payload['deleted'] == true;
    final existingByUuid = await getByUuid(uuid);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updatedAt = (payload['updatedAt'] as num?)?.toInt() ?? nowMs;
    final version = (payload['version'] as num?)?.toInt() ?? 1;
    final code = _normalizeCode(
      payload['currencyCode']?.toString() ?? '',
    );
    if (code.isEmpty) {
      return;
    }

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

    if (deleted) {
      await (_db.delete(
        _db.currencyRates,
      )..where((t) => t.uuid.equals(uuid))).go();
      await (_db.delete(
        _db.currencyRateHistory,
      )..where((t) => t.currencyCode.equals(code))).go();
      await _syncQueue?.removeForEntity(entityType: entityType, entityId: uuid);
      return;
    }

    final rateToBase = (payload['rateToBase'] as num?)?.toDouble() ?? 0;
    final notes = payload['notes']?.toString();

    // Same currencyCode, different UUID → adopt remote identity.
    if (existingByUuid == null) {
      final byCode = await getByCode(code);
      if (byCode != null && byCode.uuid != uuid) {
        final oldUuid = byCode.uuid;
        await (_db.update(_db.currencyRates)
              ..where((t) => t.id.equals(byCode.id)))
            .write(
              CurrencyRatesCompanion(
                uuid: Value(uuid),
                rateToBase: Value(rateToBase > 0 ? rateToBase : byCode.rateToBase),
                updatedAt: Value(updatedAt),
                notes: Value(
                  notes == null || notes.isEmpty ? byCode.notes : notes,
                ),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
              ),
            );
        await _applyHistoryPayload(code, payload['history']);
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

    if (existingByUuid == null) {
      await _db
          .into(_db.currencyRates)
          .insert(
            CurrencyRatesCompanion.insert(
              uuid: uuid,
              currencyCode: code,
              rateToBase: rateToBase > 0 ? rateToBase : 1,
              updatedAt: updatedAt,
              notes: Value(notes == null || notes.isEmpty ? null : notes),
              syncStatus: const Value('synced'),
              lastSyncedAt: Value(nowMs),
              version: Value(version),
              companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
            ),
          );
      await _applyHistoryPayload(code, payload['history']);
      return;
    }

    await (_db.update(_db.currencyRates)..where((t) => t.uuid.equals(uuid) & _scoped(t)))
        .write(
          CurrencyRatesCompanion(
            currencyCode: Value(code),
            rateToBase: Value(
              rateToBase > 0 ? rateToBase : existingByUuid.rateToBase,
            ),
            updatedAt: Value(updatedAt),
            notes: Value(notes == null || notes.isEmpty ? null : notes),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(nowMs),
            version: Value(version),
            companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
          ),
        );
    await _applyHistoryPayload(code, payload['history']);
  }

  Future<void> _applyHistoryPayload(String code, Object? rawHistory) async {
    if (rawHistory is! List) {
      return;
    }
    for (final item in rawHistory) {
      if (item is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(item);
      final asOfMs = (map['asOfDate'] as num?)?.toInt();
      final rate = (map['rateToBase'] as num?)?.toDouble();
      if (asOfMs == null || rate == null || rate <= 0) {
        continue;
      }
      await _upsertHistory(
        code: code,
        rateToBase: rate,
        asOf: DateTime.fromMillisecondsSinceEpoch(asOfMs, isUtc: true),
        notes: map['notes']?.toString(),
      );
    }
  }
}
