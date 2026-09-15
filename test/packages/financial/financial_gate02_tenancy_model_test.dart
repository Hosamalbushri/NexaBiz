import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('GATE-02 JournalLine Tenancy Model Canonical Test Suite', () {
    late NexabizDatabase db;
    late DriftFinancialAccountRepository accountRepo;
    late DriftFinancialJournalRepository journalRepo;
    late FinancialProjectionReconstructionService reconstructionService;

    const companyA = '11111111-1111-1111-1111-111111111111';
    const companyB = '22222222-2222-2222-2222-222222222222';

    late FinancialAccount accountA1;
    late FinancialAccount accountA2;
    late FinancialAccount accountB1;
    late FinancialAccount accountB2;

    setUp(() async {
      db = NexabizDatabase.memory();
      accountRepo = DriftFinancialAccountRepository(db);
      journalRepo = DriftFinancialJournalRepository(db);
      reconstructionService = FinancialProjectionReconstructionService(db);

      accountA1 = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000a01',
        companyId: companyA,
        code: '1001',
        nameAr: 'حساب النقدية A1',
        nameEn: 'Cash Account A1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountA2 = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000a02',
        companyId: companyA,
        code: '4001',
        nameAr: 'حساب المبيعات A2',
        nameEn: 'Sales Revenue A2',
        accountType: FinancialAccountType.revenue,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountB1 = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000b01',
        companyId: companyB,
        code: '1001',
        nameAr: 'حساب النقدية B1',
        nameEn: 'Cash Account B1',
        accountType: FinancialAccountType.asset,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountB2 = FinancialAccount(
        id: '00000000-0000-0000-0000-000000000b02',
        companyId: companyB,
        code: '4001',
        nameAr: 'حساب المبيعات B2',
        nameEn: 'Sales Revenue B2',
        accountType: FinancialAccountType.revenue,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      await accountRepo.saveAccount(accountA1);
      await accountRepo.saveAccount(accountA2);
      await accountRepo.saveAccount(accountB1);
      await accountRepo.saveAccount(accountB2);
    });

    tearDown(() async {
      await db.close();
    });

    test('TEST-15: Cross-company journal rejection (Company A Journal + Company B Account)', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('1000.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000015-1',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000015',
        lineNumber: 1,
        accountId: accountA1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      // Line 2 points to accountB1 (Company B) inside Company A Journal
      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000015-2',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000015',
        lineNumber: 2,
        accountId: accountB1.id, // FOREIGN TENANT ACCOUNT!
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000015',
        companyId: companyA,
        entryNumber: 'JE-T15',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      final accountMap = {
        accountA1.id: accountA1,
        accountB1.id: accountB1,
      };

      expect(
        () async => await PostingEngine.prepareAndValidateForPosting(
          entry: entry,
          accountsById: accountMap,
          postingTimestamp: DateTime.now(),
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'TENANCY_VIOLATION',
          ),
        ),
      );
    });

    test('TEST-16: Same-company journal acceptance (Company A Journal + Company A Accounts)', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('1000.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000016-1',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000016',
        lineNumber: 1,
        accountId: accountA1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000016-2',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000016',
        lineNumber: 2,
        accountId: accountA2.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000016',
        companyId: companyA,
        entryNumber: 'JE-T16',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2],
      );

      final accountMap = {
        accountA1.id: accountA1,
        accountA2.id: accountA2,
      };

      final result = await PostingEngine.prepareAndValidateForPosting(
        entry: entry,
        accountsById: accountMap,
        postingTimestamp: DateTime.now(),
      );

      expect(result.preparedEntry.status, JournalStatus.posted);
      expect(result.totalDebitBase.unitsScaled, BigInt.from(100000000000));
      expect(result.totalCreditBase.unitsScaled, BigInt.from(100000000000));
    });

    test('TEST-17: Cross-company persistence rejection (Line companyId mismatch rejected by Repo)', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('500.00', 'YER');

      final lineMismatch = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000017-1',
        companyId: companyB, // MISMATCHED LINE COMPANY
        journalEntryId: '00000000-0000-0000-0000-000000000017',
        lineNumber: 1,
        accountId: accountA1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final lineOk = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000017-2',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000017',
        lineNumber: 2,
        accountId: accountA2.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000017',
        companyId: companyA,
        entryNumber: 'JE-T17',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [lineMismatch, lineOk],
      );

      expect(
        () => journalRepo.saveEntry(entry),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'TENANCY_VIOLATION',
          ),
        ),
      );

      // Verify nothing was saved to DB
      final savedEntry = await journalRepo.findById(companyA, entry.id);
      expect(savedEntry, isNull);
    });

    test('TEST-18: Reconstruction isolation (Company A reconstruction never includes Company B)', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('2000.00', 'YER');

      // Save posted journal in Company A
      final lineA1 = JournalLine.create(
        id: '00000000-0000-0000-0000-00000018a001',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-0000000018a0',
        lineNumber: 1,
        accountId: accountA1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final lineA2 = JournalLine.create(
        id: '00000000-0000-0000-0000-00000018a002',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-0000000018a0',
        lineNumber: 2,
        accountId: accountA2.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entryA = JournalEntry(
        id: '00000000-0000-0000-0000-0000000018a0',
        companyId: companyA,
        entryNumber: 'JE-T18-A',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [lineA1, lineA2],
      );

      await journalRepo.saveEntry(entryA);

      // Save posted journal in Company B using accountB1 (same account code, different ID)
      final lineB1 = JournalLine.create(
        id: '00000000-0000-0000-0000-00000018b001',
        companyId: companyB,
        journalEntryId: '00000000-0000-0000-0000-0000000018b0',
        lineNumber: 1,
        accountId: accountB1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final lineB2 = JournalLine.create(
        id: '00000000-0000-0000-0000-00000018b002',
        companyId: companyB,
        journalEntryId: '00000000-0000-0000-0000-0000000018b0',
        lineNumber: 2,
        accountId: accountB2.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entryB = JournalEntry(
        id: '00000000-0000-0000-0000-0000000018b0',
        companyId: companyB,
        entryNumber: 'JE-T18-B',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [lineB1, lineB2],
      );

      await journalRepo.saveEntry(entryB);

      // Reconstruct account balance for Company A accountA1
      final reconA = await reconstructionService.reconstructAccountBalance(
        companyId: companyA,
        accountId: accountA1.id,
        baseCurrencyCode: 'YER',
      );

      // Reconstruct account balance for Company B accountA1 (using Company A accountId under Company B context)
      final reconB = await reconstructionService.reconstructAccountBalance(
        companyId: companyB,
        accountId: accountA1.id,
        baseCurrencyCode: 'YER',
      );

      expect(reconA.totalDebitBase.unitsScaled, BigInt.from(200000000000));
      expect(reconB.totalDebitBase.unitsScaled, BigInt.zero); // Strictly ZERO for Company B
    });

    test('TEST-19: Reversal isolation (Company A reversal cannot use Company B account)', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('1500.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000019001',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000019',
        lineNumber: 1,
        accountId: accountA1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000019002',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000019',
        lineNumber: 2,
        accountId: accountA2.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entryA = JournalEntry(
        id: '00000000-0000-0000-0000-000000000019',
        companyId: companyA,
        entryNumber: 'JE-T19',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [line1, line2],
      );

      final reversalDraft = entryA.createReversal(
        reversalId: '00000000-0000-0000-0000-000000019rev',
        reversalEntryNumber: 'REV-JE-T19',
        postingDate: DateTime.now(),
        reversalLineIdGenerator: (idx) => '00000000-0000-0000-0000-0000019rev00$idx',
      );

      expect(reversalDraft.companyId, companyA);
      expect(reversalDraft.lines.every((l) => l.companyId == companyA), isTrue);

      // Verify that if an attacker attempts to inject Company B account into reversal draft
      final corruptedLines = [
        reversalDraft.lines[0],
        JournalLine(
          id: reversalDraft.lines[1].id,
          companyId: companyA,
          journalEntryId: reversalDraft.id,
          lineNumber: 2,
          accountId: accountB1.id, // ATTACK: INJECT COMPANY B ACCOUNT!
          side: reversalDraft.lines[1].side,
          transactionAmount: reversalDraft.lines[1].transactionAmount,
          exchangeRate: reversalDraft.lines[1].exchangeRate,
          baseAmount: reversalDraft.lines[1].baseAmount,
        ),
      ];

      final corruptedReversal = JournalEntry(
        id: reversalDraft.id,
        companyId: companyA,
        entryNumber: reversalDraft.entryNumber,
        baseCurrencyCode: reversalDraft.baseCurrencyCode,
        postingDate: reversalDraft.postingDate,
        lines: corruptedLines,
      );

      final accountMap = {
        accountA1.id: accountA1,
        accountA2.id: accountA2,
        accountB1.id: accountB1,
      };

      expect(
        () async => await PostingEngine.prepareAndValidateForPosting(
          entry: corruptedReversal,
          accountsById: accountMap,
          postingTimestamp: DateTime.now(),
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'TENANCY_VIOLATION',
          ),
        ),
      );
    });

    test('TEST-20: Tenant-scoped account lookup (Company A cannot resolve Company B account)', () async {
      final lookupInA = await accountRepo.findById(companyA, accountB1.id);
      final lookupInB = await accountRepo.findById(companyB, accountB1.id);

      expect(lookupInA, isNull);
      expect(lookupInB, isNotNull);
      expect(lookupInB!.id, accountB1.id);

      final codeInA = await accountRepo.findByCode(companyA, '1001');
      expect(codeInA!.id, accountA1.id);
      expect(codeInA.id, isNot(accountB1.id));
    });

    test('TEST-21: Historical journal tenant stability (Historical journal remains attached to companyA)', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('3000.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000021001',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000021',
        lineNumber: 1,
        accountId: accountA1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000021002',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000021',
        lineNumber: 2,
        accountId: accountA2.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000021',
        companyId: companyA,
        entryNumber: 'HIST-001',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now().subtract(const Duration(days: 365)),
        status: JournalStatus.posted,
        lines: [line1, line2],
      );

      await journalRepo.saveEntry(entry);

      final queriedByA = await journalRepo.findById(companyA, entry.id);
      final queriedByB = await journalRepo.findById(companyB, entry.id);

      expect(queriedByA, isNotNull);
      expect(queriedByA!.companyId, companyA);
      expect(queriedByB, isNull);
    });

    test('TEST-22: Multi-line journal isolation (One foreign account among valid lines causes complete atomic rejection)', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('100.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000022-1',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000022',
        lineNumber: 1,
        accountId: accountA1.id, // Valid Company A account
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000022-2',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000022',
        lineNumber: 2,
        accountId: accountA2.id, // Valid Company A account
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line3 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000022-3',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000022',
        lineNumber: 3,
        accountId: accountB1.id, // ATTACK: FOREIGN ACCOUNT (Company B)!
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('200.00', 'YER'),
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000022',
        companyId: companyA,
        entryNumber: 'JE-MULTILINE-ATTACK',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2, line3],
      );

      final accountMap = {
        accountA1.id: accountA1,
        accountA2.id: accountA2,
        accountB1.id: accountB1,
      };

      expect(
        () async => await PostingEngine.prepareAndValidateForPosting(
          entry: entry,
          accountsById: accountMap,
          postingTimestamp: DateTime.now(),
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'TENANCY_VIOLATION',
          ),
        ),
      );
    });

    test('ATTACK SUITE: Mixed batch foreign line injection rejected by persistence transaction', () async {
      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('750.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000099-1',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000099',
        lineNumber: 1,
        accountId: accountA1.id,
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2Foreign = JournalLine.create(
        id: '00000000-0000-0000-0000-000000000099-2',
        companyId: companyB, // INJECTED FOREIGN COMPANY ID ON LINE 2
        journalEntryId: '00000000-0000-0000-0000-000000000099',
        lineNumber: 2,
        accountId: accountA2.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000099',
        companyId: companyA,
        entryNumber: 'JE-ATTACK-099',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        lines: [line1, line2Foreign],
      );

      expect(
        () => journalRepo.saveEntry(entry),
        throwsA(isA<FinancialValidationException>()),
      );

      // Verify header and line 1 were NOT inserted (Atomic rollback)
      final queriedEntry = await journalRepo.findById(companyA, entry.id);
      expect(queriedEntry, isNull);
    });
  });
}
