import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Financial Account Balance Projection Reconstruction Tests', () {
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

    test('Reconstructs account balance debit/credit/net totals strictly from POSTED journal lines', () async {
      final rate = DecimalRate.identity('YER');

      // Entry 1: Debit Acc1 1000 YER, Credit Acc2 1000 YER (POSTED)
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: account1,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: account2,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry1 = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyId,
        entryNumber: 'JE-BAL-01',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      ).post(timestamp: DateTime.now());

      await journalRepo.saveEntry(entry1);

      // Entry 2: Debit Acc1 500 YER, Credit Acc2 500 YER (DRAFT - must be excluded from balance!)
      final line3 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 1,
        accountId: account1,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('500.00', 'YER'),
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line4 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000404',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 2,
        accountId: account2,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('500.00', 'YER'),
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final draftEntry2 = JournalEntry(
        id: '00000000-0000-0000-0000-000000000502',
        companyId: companyId,
        entryNumber: 'JE-BAL-DRAFT',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line3, line4],
      ); // Unposted!

      await journalRepo.saveEntry(draftEntry2);

      // Reconstruct account balances
      final reconAcc1 = await projectionService.reconstructAccountBalance(
        companyId: companyId,
        accountId: account1,
        baseCurrencyCode: 'YER',
      );

      final reconAcc2 = await projectionService.reconstructAccountBalance(
        companyId: companyId,
        accountId: account2,
        baseCurrencyCode: 'YER',
      );

      // Acc1: Debit 1000 YER, Credit 0 YER, Net +1000 YER (draft 500 YER excluded)
      expect(reconAcc1.totalDebitBase.toFormattedString(2), equals('1000.00'));
      expect(reconAcc1.totalCreditBase.toFormattedString(2), equals('0.00'));
      expect(reconAcc1.netBalanceBase.toFormattedString(2), equals('1000.00'));

      // Acc2: Debit 0 YER, Credit 1000 YER, Net -1000 YER
      expect(reconAcc2.totalDebitBase.toFormattedString(2), equals('0.00'));
      expect(reconAcc2.totalCreditBase.toFormattedString(2), equals('1000.00'));
      expect(reconAcc2.netBalanceBase.toFormattedString(2), equals('-1000.00'));
    });
  });
}
