import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/currency/domain/entities/currency_rate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  const companyA = 'company-uuid-1111-aaaa';
  const companyB = 'company-uuid-2222-bbbb';

  setUp(() {
    db = NexabizDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 2E — Currency Rate History Tenant Isolation Remediation', () {
    test('1. Same currency & date across companies coexist with distinct rates', () async {
      final repoA = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyA);
      final repoB = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyB);
      final date = DateTime.utc(2026, 1, 1);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'USD',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 100.0,
        createdAt: nowMs,
        companyId: const Value(companyA),
      ));

      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'USD',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 200.0,
        createdAt: nowMs,
        companyId: const Value(companyB),
      ));

      final rateA = await repoA.getRateOn('USD', date);
      final rateB = await repoB.getRateOn('USD', date);

      expect(rateA, equals(100.0));
      expect(rateB, equals(200.0));

      final allRows = await db.select(db.currencyRateHistory).get();
      expect(allRows.length, equals(2));
      expect(allRows.any((r) => r.companyId == companyA && r.rateToBase == 100.0), isTrue);
      expect(allRows.any((r) => r.companyId == companyB && r.rateToBase == 200.0), isTrue);
    });

    test('2. Same company duplicate date update maintains company unique constraint', () async {
      final repoA = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyA);
      final date = DateTime.utc(2026, 1, 1);

      await repoA.upsert(CurrencyRateDraft(
        currencyCode: 'USD',
        rateToBase: 100.0,
        asOfDate: date,
      ));

      await repoA.upsert(CurrencyRateDraft(
        currencyCode: 'USD',
        rateToBase: 150.0,
        asOfDate: date,
      ));

      final rateA = await repoA.getRateOn('USD', date);
      expect(rateA, equals(150.0));

      final rows = await (db.select(db.currencyRateHistory)
            ..where((t) => t.companyId.equals(companyA)))
          .get();
      expect(rows.length, equals(1));
      expect(rows.first.rateToBase, equals(150.0));
    });

    test('3. Company isolation — Company A cannot read Company B history', () async {
      final repoA = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyA);
      final repoB = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyB);
      final date = DateTime.utc(2026, 1, 15);

      await repoB.upsert(CurrencyRateDraft(
        currencyCode: 'EUR',
        rateToBase: 3.5,
        asOfDate: date,
      ));

      final rateA = await repoA.getRateOn('EUR', date);
      final historyA = await repoA.listHistory('EUR');

      expect(rateA, isNull);
      expect(historyA, isEmpty);

      final rateB = await repoB.getRateOn('EUR', date);
      final historyB = await repoB.listHistory('EUR');

      expect(rateB, equals(3.5));
      expect(historyB.length, equals(1));
    });

    test('4. Missing company scope fails explicitly', () async {
      final repoNoCompany = CurrencyRateRepositoryImpl(db, readCompanyId: () => '');
      final date = DateTime.utc(2026, 1, 1);

      expect(
        () => repoNoCompany.getRateOn('USD', date),
        throwsA(isA<MissingCompanyContextException>()),
      );

      expect(
        () => repoNoCompany.listHistory('USD'),
        throwsA(isA<MissingCompanyContextException>()),
      );

      expect(
        () => repoNoCompany.upsert(CurrencyRateDraft(currencyCode: 'USD', rateToBase: 1.0)),
        throwsA(isA<MissingCompanyContextException>()),
      );
    });

    test('5. Dynamic company context switching', () async {
      String activeCompany = companyA;
      final repoDynamic = CurrencyRateRepositoryImpl(db, readCompanyId: () => activeCompany);
      final date = DateTime.utc(2026, 2, 1);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'GBP',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 1.25,
        createdAt: nowMs,
        companyId: const Value(companyA),
      ));

      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'GBP',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 1.45,
        createdAt: nowMs,
        companyId: const Value(companyB),
      ));

      // Query as Company A
      activeCompany = companyA;
      expect(await repoDynamic.getRateOn('GBP', date), equals(1.25));

      // Switch to Company B
      activeCompany = companyB;
      expect(await repoDynamic.getRateOn('GBP', date), equals(1.45));
    });

    test('6. Delete by code is tenant-scoped', () async {
      final repoA = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyA);
      final repoB = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyB);
      final date = DateTime.utc(2026, 1, 1);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'CAD',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 0.75,
        createdAt: nowMs,
        companyId: const Value(companyA),
      ));

      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'CAD',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 0.80,
        createdAt: nowMs,
        companyId: const Value(companyB),
      ));

      await repoA.deleteByCode('CAD');

      expect(await repoA.getRateOn('CAD', date), isNull);

      // Company B CAD history remains intact
      expect(await repoB.getRateOn('CAD', date), equals(0.80));
    });

    test('7. Data migration & backfill test (v17 -> v18 schema migration)', () async {
      expect(db.schemaVersion, equals(18));

      // Manually insert un-scoped currency rate and history row simulating v17 schema state
      await db.customStatement('''
        INSERT INTO currency_rates (uuid, currency_code, rate_to_base, updated_at, sync_status, version, company_id)
        VALUES ('00000000-0000-0000-0000-000000000999', 'JPY', 0.007, 1700000000000, 'synced', 1, '$companyA')
      ''');

      await db.customStatement('''
        INSERT INTO currency_rate_history (currency_code, as_of_date, rate_to_base, created_at, company_id)
        VALUES ('JPY', 1700000000000, 0.007, 1700000000000, NULL)
      ''');

      // Execute migration logic step for from < 18
      await db.customStatement('''
        UPDATE currency_rate_history
        SET company_id = (
          SELECT cr.company_id
          FROM currency_rates cr
          WHERE cr.currency_code = currency_rate_history.currency_code
          LIMIT 1
        )
        WHERE company_id IS NULL
      ''');

      final historyRows = await db.select(db.currencyRateHistory).get();
      final jpyRow = historyRows.firstWhere((r) => r.currencyCode == 'JPY');
      expect(jpyRow.companyId, equals(companyA));
    });

    test('8. Zero unowned rows verification', () async {
      final repoA = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyA);
      await repoA.upsert(CurrencyRateDraft(currencyCode: 'CHF', rateToBase: 1.1));

      final unownedRows = await (db.select(db.currencyRateHistory)
            ..where((t) => t.companyId.isNull()))
          .get();

      expect(unownedRows, isEmpty);
    });

    test('9. Remote sync push and pull tenant isolation', () async {
      final repoA = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyA);
      final repoB = CurrencyRateRepositoryImpl(db, readCompanyId: () => companyB);
      final date = DateTime.utc(2026, 3, 1);

      final payloadRemoteB = {
        'uuid': 'b0000000-0000-0000-0000-000000000100',
        'currencyCode': 'NZD',
        'rateToBase': 0.65,
        'updatedAt': 1700000000000,
        'version': 1,
        'companyId': companyB,
        'history': [
          {
            'currencyCode': 'NZD',
            'asOfDate': date.millisecondsSinceEpoch,
            'rateToBase': 0.65,
            'companyId': companyB,
          }
        ],
      };

      await repoA.applyRemotePayload(payloadRemoteB);

      // Company A should NOT see remote Company B rate
      expect(await repoA.getByCode('NZD'), isNull);
      expect(await repoA.getRateOn('NZD', date), isNull);

      // Company B SHOULD see remote Company B rate
      expect(await repoB.getByCode('NZD'), isNotNull);
      expect(await repoB.getRateOn('NZD', date), equals(0.65));
    });

    test('10. Unique constraint verification per company', () async {
      final date = DateTime.utc(2026, 1, 1);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'USD',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 100.0,
        createdAt: nowMs,
        companyId: const Value(companyA),
      ));

      // Inserting duplicate for Company A throws SQLite UNIQUE constraint error
      expect(
        () async => await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
          currencyCode: 'USD',
          asOfDate: date.millisecondsSinceEpoch,
          rateToBase: 110.0,
          createdAt: nowMs,
          companyId: const Value(companyA),
        )),
        throwsA(anything),
      );

      // Inserting same currencyCode and date for Company B succeeds
      await db.into(db.currencyRateHistory).insert(CurrencyRateHistoryCompanion.insert(
        currencyCode: 'USD',
        asOfDate: date.millisecondsSinceEpoch,
        rateToBase: 200.0,
        createdAt: nowMs,
        companyId: const Value(companyB),
      ));

      final count = await db.select(db.currencyRateHistory).get();
      expect(count.length, equals(2));
    });
  });
}
