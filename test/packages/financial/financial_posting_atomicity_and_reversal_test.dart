import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Transaction Atomicity & Reversal Isolation Tests', () {
    late NexabizDatabase db;
    late DriftFinancialJournalRepository journalRepo;
    late FinancialProjectionReconstructionService projectionService;

    const companyId = '00000000-0000-0000-0000-000000000001';
    const account1 = '00000000-0000-0000-0000-000000000101';
    const account2 = '00000000-0000-0000-0000-000000000102';

    setUp(() {
      db = NexabizDatabase.memory();
      journalRepo = DriftFinancialJournalRepository(db);
      projectionService = FinancialProjectionReconstructionService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Transaction Atomicity: Mid-transaction failure rolls back entire entry & lines', () async {
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: account1,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      // Line 2 has Int64 overflow on transaction amount => throws boundary exception
      final invalidAmount = DecimalMoney.fromScaled(
        FinancialInt64Boundary.int64Max + BigInt.one,
        'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: account2,
        side: FinancialSide.credit,
        transactionAmount: invalidAmount,
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyId,
        entryNumber: 'JE-ATOMIC-FAIL',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      // Save attempt throws
      expect(
        () => journalRepo.saveEntry(entry),
        throwsA(isA<FinancialInt64BoundaryException>()),
      );

      // Verify ZERO records persisted (atomicity guaranteed)
      final fetchedEntry = await journalRepo.findById(companyId, entry.id);
      expect(fetchedEntry, isNull);

      final fetchedRecon = await projectionService.reconstructAccountBalance(
        companyId: companyId,
        accountId: account1,
        baseCurrencyCode: 'YER',
      );
      expect(fetchedRecon.netBalanceBase.toFormattedString(2), equals('0.00'));
    });

    test('2. Reversal Isolation: Reversal creates inverted entry; original posted entry is untouched', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('1500.00', 'YER');

      // Original Entry
      final origLine1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 1,
        accountId: account1,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final origLine2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000404',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 2,
        accountId: account2,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final origEntry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000502',
        companyId: companyId,
        entryNumber: 'JE-ORIGINAL-01',
        baseCurrencyCode: 'YER',
        postingDate: DateTime(2026, 3, 1),
        lines: [origLine1, origLine2],
      ).post(timestamp: DateTime(2026, 3, 1));

      await journalRepo.saveEntry(origEntry);

      // Reversal Entry (Inverted sides)
      final revLine1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000405',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000503',
        lineNumber: 1,
        accountId: account1,
        side: FinancialSide.credit, // Inverted: Credit 1500
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final revLine2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000406',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000503',
        lineNumber: 2,
        accountId: account2,
        side: FinancialSide.debit, // Inverted: Debit 1500
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final revEntry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000503',
        companyId: companyId,
        entryNumber: 'JE-REVERSAL-01',
        baseCurrencyCode: 'YER',
        postingDate: DateTime(2026, 3, 2),
        description: 'Reversal of JE-ORIGINAL-01',
        lines: [revLine1, revLine2],
      ).post(timestamp: DateTime(2026, 3, 2));

      await journalRepo.saveEntry(revEntry);

      // Verify original entry remains in DB and POSTED
      final fetchedOrig = await journalRepo.findById(companyId, origEntry.id);
      expect(fetchedOrig, isNotNull);
      expect(fetchedOrig?.status, equals(JournalStatus.posted));
      expect(fetchedOrig?.lines[0].side, equals(FinancialSide.debit));

      // Verify reversal entry in DB and POSTED
      final fetchedRev = await journalRepo.findById(companyId, revEntry.id);
      expect(fetchedRev, isNotNull);
      expect(fetchedRev?.status, equals(JournalStatus.posted));
      expect(fetchedRev?.lines[0].side, equals(FinancialSide.credit));

      // Reconstructed net balance across orig + rev is exactly 0.00
      final reconAcc1 = await projectionService.reconstructAccountBalance(
        companyId: companyId,
        accountId: account1,
        baseCurrencyCode: 'YER',
      );
      expect(reconAcc1.netBalanceBase.toFormattedString(2), equals('0.00'));
    });
  });
}
