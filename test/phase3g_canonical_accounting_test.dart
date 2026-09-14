import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  late NexabizDatabase db;

  setUp(() {
    db = NexabizDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3G — Canonical Financial Vouchers & GL Baseline Tests', () {
    test('NexabizDatabase schemaVersion is 7 or higher and accounting tables exist', () async {
      expect(db.schemaVersion, greaterThanOrEqualTo(7));

      final entriesCount = await db.select(db.journalEntries).get();
      final linesCount = await db.select(db.journalLines).get();
      final fiscalCount = await db.select(db.fiscalYears).get();
      final periodsCount = await db.select(db.accountingPeriods).get();

      expect(entriesCount, isEmpty);
      expect(linesCount, isEmpty);
      expect(fiscalCount, isEmpty);
      expect(periodsCount, isEmpty);
    });

    test('Canonical UUID identity and tenant isolation on journal entries', () async {
      final companyA = 'comp-gl-aaa-3g';
      final companyB = 'comp-gl-bbb-3g';

      final uuidA = generateUuidV4();
      final uuidB = generateUuidV4();

      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert Journal Entry for Company A
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              id: Value(uuidA),
              entryDate: now,
              voucherNumber: 'JV-A-001',
              voucherType: 'manual',
              currencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyA),
            ),
          );

      // Insert Journal Entry for Company B
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              id: Value(uuidB),
              entryDate: now,
              voucherNumber: 'JV-B-001',
              voucherType: 'manual',
              currencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyB),
            ),
          );

      // Query Company A GL entries
      final queryA = await (db.select(db.journalEntries)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();

      expect(queryA.length, equals(1));
      expect(queryA.first.id, equals(uuidA));
      expect(queryA.first.voucherNumber, equals('JV-A-001'));
      expect(queryA.first.companyId, equals(companyA));

      // Query Company B GL entries
      final queryB = await (db.select(db.journalEntries)
            ..where((tbl) => tbl.companyId.equals(companyB)))
          .get();

      expect(queryB.length, equals(1));
      expect(queryB.first.id, equals(uuidB));
      expect(queryB.first.voucherNumber, equals('JV-B-001'));
      expect(queryB.first.companyId, equals(companyB));
    });

    test('Journal entry debit/credit balancing verification', () async {
      final companyId = 'comp-gl-bal-3g';
      final entryId = generateUuidV4();
      final cashAccountUuid = generateUuidV4();
      final revenueAccountUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Create Header
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              id: Value(entryId),
              entryDate: now,
              voucherNumber: 'JV-2026-100',
              voucherType: 'sales_posting',
              currencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      // Insert Debit Line
      final debitLineUuid = generateUuidV4();
      await db.into(db.journalLines).insert(
            JournalLinesCompanion.insert(
              id: Value(debitLineUuid),
              entryId: entryId,
              accountId: cashAccountUuid,
              debit: const Value(150.0),
              credit: const Value(0.0),
              baseDebit: const Value(150.0),
              baseCredit: const Value(0.0),
              currencyCode: 'USD',
            ),
          );

      // Insert Credit Line
      final creditLineUuid = generateUuidV4();
      await db.into(db.journalLines).insert(
            JournalLinesCompanion.insert(
              id: Value(creditLineUuid),
              entryId: entryId,
              accountId: revenueAccountUuid,
              debit: const Value(0.0),
              credit: const Value(150.0),
              baseDebit: const Value(0.0),
              baseCredit: const Value(150.0),
              currencyCode: 'USD',
            ),
          );

      // Fetch Lines
      final lines = await (db.select(db.journalLines)
            ..where((tbl) => tbl.entryId.equals(entryId)))
          .get();

      final totalDebit = lines.fold<double>(0.0, (sum, line) => sum + line.debit);
      final totalCredit = lines.fold<double>(0.0, (sum, line) => sum + line.credit);

      expect(lines.length, equals(2));
      expect(totalDebit, equals(150.0));
      expect(totalCredit, equals(150.0));
      expect(totalDebit == totalCredit, isTrue);
    });

    test('Fiscal Year & Accounting Period canonical references in GL', () async {
      final companyId = 'comp-gl-period-3g';
      final fyUuid = generateUuidV4();
      final periodUuid = generateUuidV4();
      final entryId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert Fiscal Year
      await db.into(db.fiscalYears).insert(
            FiscalYearsCompanion.insert(
              id: Value(fyUuid),
              code: 'FY2026',
              name: 'Fiscal Year 2026',
              startDate: 1767225600000, // Jan 1 2026
              endDate: 1798761600000,   // Dec 31 2026
              status: 'open',
              baseCurrencyCode: 'USD',
              periodCount: 12,
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      // 2. Insert Accounting Period
      await db.into(db.accountingPeriods).insert(
            AccountingPeriodsCompanion.insert(
              id: Value(periodUuid),
              fiscalYearId: fyUuid,
              periodNumber: 1,
              name: 'Period 01 - Jan 2026',
              startDate: 1767225600000,
              endDate: 1769817600000,
              status: 'open',
            ),
          );

      // 3. Insert Journal Entry
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              id: Value(entryId),
              entryDate: now,
              voucherNumber: 'JV-FY2026-P01',
              voucherType: 'manual',
              currencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      final fetchedFY = await (db.select(db.fiscalYears)
            ..where((tbl) => tbl.id.equals(fyUuid)))
          .getSingle();

      final fetchedPeriod = await (db.select(db.accountingPeriods)
            ..where((tbl) => tbl.id.equals(periodUuid)))
          .getSingle();

      expect(fetchedFY.id, equals(fyUuid));
      expect(fetchedFY.companyId, equals(companyId));
      expect(fetchedPeriod.fiscalYearId, equals(fyUuid));
    });

    test('Transactional rollback on failed GL posting', () async {
      final companyId = 'comp-rollback-gl-3g';
      final entryId = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      try {
        await db.transaction(() async {
          await db.into(db.journalEntries).insert(
                JournalEntriesCompanion.insert(
                  id: Value(entryId),
                  entryDate: now,
                  voucherNumber: 'JV-FAIL-01',
                  voucherType: 'manual',
                  currencyCode: 'USD',
                  createdAt: now,
                  updatedAt: now,
                  companyId: Value(companyId),
                ),
              );

          await db.into(db.journalLines).insert(
                JournalLinesCompanion.insert(
                  id: Value(generateUuidV4()),
                  entryId: entryId,
                  accountId: generateUuidV4(),
                  debit: const Value(500.0),
                  credit: const Value(0.0),
                  currencyCode: 'USD',
                ),
              );

          throw Exception('Forced GL posting failure');
        });
      } catch (_) {}

      final entries = await (db.select(db.journalEntries)
            ..where((tbl) => tbl.id.equals(entryId)))
          .get();

      final lines = await (db.select(db.journalLines)
            ..where((tbl) => tbl.entryId.equals(entryId)))
          .get();

      expect(entries, isEmpty);
      expect(lines, isEmpty);
    });
  });
}
