import 'package:drift/drift.dart';

import '../../../../core/utils/business_date.dart';
import '../../domain/entities/currency_rate.dart';
import '../../domain/repositories/currency_rate_repository.dart';
import '../database/accounting_database.dart';

class CurrencyRateRepositoryImpl implements CurrencyRateRepository {
  CurrencyRateRepositoryImpl(this._db);

  final AccountingDatabase _db;

  CurrencyRate _map(CurrencyRateRow row) {
    return CurrencyRate(
      id: row.id,
      currencyCode: row.currencyCode,
      rateToBase: row.rateToBase,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      notes: row.notes,
    );
  }

  String _normalizeCode(String code) => code.trim().toUpperCase();

  int _dayMs(DateTime date) => BusinessDate.utcDay(date).millisecondsSinceEpoch;

  @override
  Future<List<CurrencyRate>> getAll() async {
    final rows = await (_db.select(
      _db.currencyRates,
    )..orderBy([(t) => OrderingTerm.asc(t.currencyCode)])).get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<CurrencyRate>> watchAll() {
    final query = _db.select(_db.currencyRates)
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
    )..where((t) => t.currencyCode.equals(code))).getSingleOrNull();
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
      final id = await _db
          .into(_db.currencyRates)
          .insert(
            CurrencyRatesCompanion.insert(
              currencyCode: code,
              rateToBase: draft.rateToBase,
              updatedAt: nowMs,
              notes: Value(notes == null || notes.isEmpty ? null : notes),
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
      )..where((t) => t.id.equals(id))).getSingle();
      return _map(created);
    }

    await (_db.update(
      _db.currencyRates,
    )..where((t) => t.id.equals(existing.id))).write(
      CurrencyRatesCompanion(
        rateToBase: Value(draft.rateToBase),
        updatedAt: Value(nowMs),
        notes: Value(notes == null || notes.isEmpty ? null : notes),
      ),
    );
    await _upsertHistory(
      code: code,
      rateToBase: draft.rateToBase,
      asOf: asOf,
      notes: notes,
    );
    final updated = await getByCode(code);
    return updated!;
  }

  @override
  Future<void> deleteByCode(String currencyCode) async {
    final code = _normalizeCode(currencyCode);
    await (_db.delete(
      _db.currencyRates,
    )..where((t) => t.currencyCode.equals(code))).go();
    await (_db.delete(
      _db.currencyRateHistory,
    )..where((t) => t.currencyCode.equals(code))).go();
  }
}
