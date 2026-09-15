import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Posted Journal Persistence Immutability Tests', () {
    late NexabizDatabase db;
    late DriftFinancialJournalRepository journalRepo;

    const companyId = '00000000-0000-0000-0000-000000000001';

    setUp(() {
      db = NexabizDatabase.memory();
      journalRepo = DriftFinancialJournalRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Draft entry can be updated, but once posted, persistence rejects mutation', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('1000.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final draftEntry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyId,
        entryNumber: 'JE-IMMUTABLE-01',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        description: 'Original Draft',
        lines: [line1, line2],
      );

      // Save initial draft
      await journalRepo.saveEntry(draftEntry);

      // Verify draft saved
      final savedDraft = await journalRepo.findById(companyId, draftEntry.id);
      expect(savedDraft?.status, equals(JournalStatus.draft));
      expect(savedDraft?.description, equals('Original Draft'));

      // Post the entry and save to DB
      final postedEntry = draftEntry.post(timestamp: DateTime.now());
      await journalRepo.saveEntry(postedEntry);

      final savedPosted = await journalRepo.findById(companyId, draftEntry.id);
      expect(savedPosted?.status, equals(JournalStatus.posted));

      // Attempting to modify description of posted entry via saveEntry must throw PostedJournalImmutableException
      final mutatedEntry = JournalEntry(
        id: draftEntry.id,
        companyId: companyId,
        entryNumber: draftEntry.entryNumber,
        baseCurrencyCode: draftEntry.baseCurrencyCode,
        postingDate: draftEntry.postingDate,
        status: JournalStatus.posted,
        description: 'ILLEGAL MUTATION ATTEMPT',
        lines: [line1, line2],
      );

      expect(
        () => journalRepo.saveEntry(mutatedEntry),
        throwsA(isA<PostedJournalImmutableException>()),
      );
    });

    test('2. Cannot modify amounts or lines on posted entry in persistence', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('500.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000404',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 2,
        accountId: '00000000-0000-0000-0000-000000000102',
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000502',
        companyId: companyId,
        entryNumber: 'JE-IMMUTABLE-02',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      ).post(timestamp: DateTime.now());

      await journalRepo.saveEntry(entry);

      // Attempting to overwrite posted entry with modified lines throws
      final lineModified = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyId,
        journalEntryId: entry.id,
        lineNumber: 1,
        accountId: '00000000-0000-0000-0000-000000000101',
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('99999.00', 'YER'),
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entryMutated = JournalEntry(
        id: entry.id,
        companyId: companyId,
        entryNumber: entry.entryNumber,
        baseCurrencyCode: entry.baseCurrencyCode,
        postingDate: entry.postingDate,
        status: JournalStatus.posted,
        lines: [lineModified, line2],
      );

      expect(
        () => journalRepo.saveEntry(entryMutated),
        throwsA(isA<PostedJournalImmutableException>()),
      );
    });
  });
}
