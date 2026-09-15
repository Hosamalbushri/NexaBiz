import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('Financial Subject Bucket Projection Reconstruction Tests', () {
    late NexabizDatabase db;
    late DriftFinancialJournalRepository journalRepo;
    late FinancialProjectionReconstructionService projectionService;

    const companyId = '00000000-0000-0000-0000-000000000001';
    const customerId = '00000000-0000-0000-0000-000000000201';
    const arAccountId = '00000000-0000-0000-0000-000000000105';
    const salesAccountId = '00000000-0000-0000-0000-000000000106';

    setUp(() {
      db = NexabizDatabase.memory();
      journalRepo = DriftFinancialJournalRepository(db);
      projectionService = FinancialProjectionReconstructionService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Reconstructs subject buckets per currency independently from POSTED journal lines', () async {
      // 1. Transaction in USD: Debit AR (Customer) $100, Credit Sales $100
      final rateUsd = DecimalRate.identity('USD');
      final usdAmount = DecimalMoney.fromString('100.00', 'USD');

      final lineUsd1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000401',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 1,
        accountId: arAccountId,
        subjectId: customerId,
        side: FinancialSide.debit,
        transactionAmount: usdAmount,
        exchangeRate: rateUsd,
        baseCurrencyCode: 'USD',
      );

      final lineUsd2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000402',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000501',
        lineNumber: 2,
        accountId: salesAccountId,
        side: FinancialSide.credit,
        transactionAmount: usdAmount,
        exchangeRate: rateUsd,
        baseCurrencyCode: 'USD',
      );

      final entryUsd = JournalEntry(
        id: '00000000-0000-0000-0000-000000000501',
        companyId: companyId,
        entryNumber: 'JE-CUST-USD',
        baseCurrencyCode: 'USD',
        postingDate: DateTime.now(),
        lines: [lineUsd1, lineUsd2],
      ).post(timestamp: DateTime.now());

      await journalRepo.saveEntry(entryUsd);

      // 2. Transaction in YER: Debit AR (Customer) 5000 YER, Credit Sales 5000 YER
      final rateYer = DecimalRate.identity('YER');
      final yerAmount = DecimalMoney.fromString('5000.00', 'YER');

      final lineYer1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000403',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 1,
        accountId: arAccountId,
        subjectId: customerId,
        side: FinancialSide.debit,
        transactionAmount: yerAmount,
        exchangeRate: rateYer,
        baseCurrencyCode: 'YER',
      );

      final lineYer2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000404',
        companyId: companyId,
        journalEntryId: '00000000-0000-0000-0000-000000000502',
        lineNumber: 2,
        accountId: salesAccountId,
        side: FinancialSide.credit,
        transactionAmount: yerAmount,
        exchangeRate: rateYer,
        baseCurrencyCode: 'YER',
      );

      final entryYer = JournalEntry(
        id: '00000000-0000-0000-0000-000000000502',
        companyId: companyId,
        entryNumber: 'JE-CUST-YER',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [lineYer1, lineYer2],
      ).post(timestamp: DateTime.now());

      await journalRepo.saveEntry(entryYer);

      // 3. Reconstruct USD and YER buckets independently
      final reconUsd = await projectionService.reconstructSubjectBucketBalance(
        companyId: companyId,
        subjectId: customerId,
        accountId: arAccountId,
        currencyCode: 'USD',
      );

      final reconYer = await projectionService.reconstructSubjectBucketBalance(
        companyId: companyId,
        subjectId: customerId,
        accountId: arAccountId,
        currencyCode: 'YER',
      );

      final reconSar = await projectionService.reconstructSubjectBucketBalance(
        companyId: companyId,
        subjectId: customerId,
        accountId: arAccountId,
        currencyCode: 'SAR',
      );

      expect(reconUsd.netBalance.toFormattedString(2), equals('100.00'));
      expect(reconYer.netBalance.toFormattedString(2), equals('5000.00'));
      expect(reconSar.netBalance.toFormattedString(2), equals('0.00'));
    });
  });
}
