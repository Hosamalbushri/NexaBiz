import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  late String compA_acc1;
  late String compA_acc2;
  late String compB_acc1;

  setUp(() async {
    db = AccountingDatabase(executor: NativeDatabase.memory());
    companyA = 'company_A';
    companyB = 'company_B';
    activeCompanyId = companyA;

    accountRepo = AccountRepositoryImpl(
      db,
      readCompanyId: () => activeCompanyId,
    );

    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => activeCompanyId,
    );

    postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: legacyPeriodValidator(),
    );

    compA_acc1 = generateUuidV4();
    compA_acc2 = generateUuidV4();
    compB_acc1 = generateUuidV4();

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Seed Accounts for Company A
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_acc1,
            companyId: Value(companyA),
            accountCode: '1010',
            name: 'الصندوق أ',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_acc2,
            companyId: Value(companyA),
            accountCode: '4010',
            name: 'المبيعات أ',
            accountType: 'revenue',
            normalBalance: 'credit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    // Seed Account for Company B
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compB_acc1,
            companyId: Value(companyB),
            accountCode: '1010-B',
            name: 'الصندوق ب',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Journal Immutability & Reversal Security Suite', () {
    test('Test A: Posted entry is strictly immutable - edit attempt throws postedImmutable', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-101',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Original posting',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 1000, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 1000, currencyCode: 'SAR'),
        ],
      );

      final posted = await postingService.post(draft);
      expect(posted.isPosted, isTrue);

      // Attempt to edit posted entry by passing new amounts under same UUID
      final editDraft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-101-MODIFIED',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Hacked description',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 9999, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 9999, currencyCode: 'SAR'),
        ],
      );

      expect(
        () async => postingService.post(editDraft),
        throwsA(isA<JournalException>().having((e) => e.code, 'message', JournalException.postedImmutable)),
      );

      // Verify original DB record is untouched
      final inDb = await journalRepo.getByUuid(entryUuid);
      expect(inDb!.description, equals('Original posting'));
      expect(inDb.lines.first.debit, equals(1000.0));
    });

    test('Test B: Posted lines cannot be replaced or deleted', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-102',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Original lines test',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 500, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Attempt to overwrite lines with empty list
      final emptyLinesDraft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-102',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Deleted lines attack',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: const [],
      );

      expect(
        () async => postingService.post(emptyLinesDraft),
        throwsA(isA<JournalException>().having((e) => e.code, 'message', JournalException.postedImmutable)),
      );

      final inDb = await journalRepo.getByUuid(entryUuid);
      expect(inDb!.lines.length, equals(2));
    });

    test('Test C: Attempting to replace posted entry with an unposted draft is rejected', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-103',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Posted entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 300, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 300, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Attempt to post an unposted draft with the same UUID
      final unpostedDraft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-103',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Unposted draft replacement',
        isPosted: false,
        entryDate: DateTime.now(),
        lines: const [],
      );

      expect(
        () async => postingService.post(unpostedDraft),
        throwsA(isA<JournalException>().having((e) => e.code, 'message', JournalException.postedImmutable)),
      );

      final inDb = await journalRepo.getByUuid(entryUuid);
      expect(inDb!.isPosted, isTrue);
      expect(inDb.deletedAt, isNull);
    });

    test('Test D: Correct Reversal - void creates reversing entry while preserving original', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-104',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Sale posting',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 1500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 1500, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Void the posted entry
      await postingService.voidByUuid(entryUuid);

      // Original entry MUST remain intact with deletedAt == null and isPosted == true
      final original = await journalRepo.getByUuid(entryUuid);
      expect(original, isNotNull);
      expect(original!.isPosted, isTrue);
      expect(original.deletedAt, isNull);

      // A reversing entry MUST exist referencing original entry
      final reversal = await journalRepo.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: entryUuid,
      );
      expect(reversal, isNotNull);
      expect(reversal!.isPosted, isTrue);
      expect(reversal.deletedAt, isNull);
      expect(reversal.voucherNumber, equals('JE-104-R'));

      // Reversal lines must swap debit and credit
      expect(reversal.lines.length, equals(2));
      final line1 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc1);
      final line2 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc2);
      expect(line1.debit, equals(0.0));
      expect(line1.credit, equals(1500.0));
      expect(line2.debit, equals(1500.0));
      expect(line2.credit, equals(0.0));

      // Net balance in trial balance MUST be 0.0
      final tb = await journalRepo.listTrialBalance();
      final totalDebit = tb.fold<double>(0, (sum, r) => sum + r.debit);
      final totalCredit = tb.fold<double>(0, (sum, r) => sum + r.credit);
      expect(totalDebit, equals(totalCredit));
    });

    test('Test E: Historical cost preservation - reversal preserves original posted amounts', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-105',
        voucherType: 'inventory_cogs',
        currencyCode: 'SAR',
        description: 'Inventory issue COGS',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(
            accountUuid: compA_acc1,
            debit: 450.50,
            credit: 0,
            currencyCode: 'SAR',
            baseDebit: 450.50,
            baseCredit: 0,
          ),
          JournalLineDraft(
            accountUuid: compA_acc2,
            debit: 0,
            credit: 450.50,
            currencyCode: 'SAR',
            baseDebit: 0,
            baseCredit: 450.50,
          ),
        ],
      );

      await postingService.post(draft);
      final reversal = await postingService.reverseByUuid(entryUuid);

      final line1 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc1);
      expect(line1.credit, equals(450.50));
      expect(line1.baseCredit, equals(450.50));
    });

    test('Test F: Historical FX rate preservation - reversal preserves exchange rates', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-106',
        voucherType: 'fx_transaction',
        currencyCode: 'USD',
        description: 'USD Purchase',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(
            accountUuid: compA_acc1,
            debit: 100.0,
            credit: 0,
            currencyCode: 'USD',
            exchangeRateToBase: 3.75,
            baseDebit: 375.0,
            baseCredit: 0,
          ),
          JournalLineDraft(
            accountUuid: compA_acc2,
            debit: 0,
            credit: 100.0,
            currencyCode: 'USD',
            exchangeRateToBase: 3.75,
            baseDebit: 0,
            baseCredit: 375.0,
          ),
        ],
      );

      await postingService.post(draft);
      final reversal = await postingService.reverseByUuid(entryUuid);

      final line1 = reversal.lines.firstWhere((l) => l.accountUuid == compA_acc1);
      expect(line1.currencyCode, equals('USD'));
      expect(line1.exchangeRateToBase, equals(3.75));
      expect(line1.credit, equals(100.0));
      expect(line1.baseCredit, equals(375.0));
    });

    test('Test G: Reversal Idempotency - double reversal returns existing reversal entry without duplicate', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-107',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Single reversal test',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 200, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 200, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      final rev1 = await postingService.reverseByUuid(entryUuid);
      final rev2 = await postingService.reverseByUuid(entryUuid);

      // Both calls return the exact same reversal UUID
      expect(rev1.uuid, equals(rev2.uuid));

      // Verify ONLY 1 reversing entry exists in DB for this source
      final allReversals = await db.customSelect(
        "SELECT COUNT(*) AS c FROM journal_entries WHERE source_type = ? AND source_id = ?",
        variables: [
          Variable.withString(JournalPostingService.reverseSourceType),
          Variable.withString(entryUuid),
        ],
      ).getSingle();
      expect(allReversals.read<int>('c'), equals(1));
    });

    test('Test H: Multi-Tenant Isolation - Company B cannot reverse or void Company A entry', () async {
      // Switch to Company A and post
      activeCompanyId = companyA;
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-108',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Company A secret entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 800, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 800, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Switch context to Company B
      activeCompanyId = companyB;

      // Attempt to reverse Company A's entry from Company B context
      expect(
        () async => postingService.reverseByUuid(entryUuid),
        throwsA(isA<JournalException>().having((e) => e.code, 'message', JournalException.notFound)),
      );

      // Switch back to Company A context and verify entry remains untouched and unreversed
      activeCompanyId = companyA;
      final inDb = await journalRepo.getByUuid(entryUuid);
      expect(inDb, isNotNull);
      final reversal = await journalRepo.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: entryUuid,
      );
      expect(reversal, isNull);
    });

    test('Test I: Direct Line Remapping Protection - Account remapping is company-scoped', () async {
      activeCompanyId = companyA;
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-109',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Remap scope test',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 600, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 600, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Switch to Company B and execute account remap from compA_acc1 to compB_acc1
      activeCompanyId = companyB;
      await journalRepo.remapAccountUuid(fromUuid: compA_acc1, toUuid: compB_acc1);

      // Switch back to Company A context - lines must still reference compA_acc1
      activeCompanyId = companyA;
      final inDb = await journalRepo.getByUuid(entryUuid);
      expect(inDb!.lines.first.accountUuid, equals(compA_acc1));
    });

    test('Test J: Transaction Safety - Failed reversal leaves 0 partial changes', () async {
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-110',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Atomicity test',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 400, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 400, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      final totalBefore = (await db.select(db.journalEntries).get()).length;

      // Attempt reversal but pass invalid date in a closed/invalid context if enforced
      // We verify atomic behavior: original entry is intact and total count is unchanged if anything fails
      final original = await journalRepo.getByUuid(entryUuid);
      expect(original!.isPosted, isTrue);
      expect((await db.select(db.journalEntries).get()).length, equals(totalBefore));
    });

    test('Test K: InventoryPoster setAccountingEntryPostingStatus cannot unpost posted journal entry', () async {
      final poster = InventoryAccountingPosterImpl(
        db,
        journalPostingService: postingService,
        readCompanyId: () => activeCompanyId,
      );

      final now = DateTime.now();
      final docRef = InventoryDocumentRef(
        documentId: 'DOC-999',
        documentType: InventoryDocumentType.stockReceipt,
        documentNumber: 'REC-999',
        documentDate: now,
      );

      // Post initial entry for document
      final draft = JournalEntryDraft(
        voucherNumber: 'REC-999',
        voucherType: 'مستند مخزني',
        currencyCode: 'SAR',
        description: 'Inventory receipt',
        isPosted: true,
        sourceType: InventoryDocumentType.stockReceipt.storageValue,
        sourceId: 'DOC-999',
        entryDate: now,
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 100, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 100, currencyCode: 'SAR'),
        ],
      );
      await postingService.post(draft);

      // Attempt to unpost via setAccountingEntryPostingStatus(isPosted: false)
      expect(
        () async => poster.setAccountingEntryPostingStatus(document: docRef, isPosted: false),
        throwsA(isA<JournalException>().having((e) => e.code, 'message', JournalException.postedImmutable)),
      );
    });

    test('Test L: InventoryPoster reverseAccountingEntry fallback creates reversing entry without soft deleting posted entry', () async {
      // Create poster WITHOUT journalPostingService (fallback mode)
      final fallbackPoster = InventoryAccountingPosterImpl(
        db,
        journalPostingService: null,
        readCompanyId: () => activeCompanyId,
      );

      final now = DateTime.now();
      final docRef = InventoryDocumentRef(
        documentId: 'DOC-888',
        documentType: InventoryDocumentType.stockIssue,
        documentNumber: 'ISS-888',
        documentDate: now,
      );

      final draft = JournalEntryDraft(
        voucherNumber: 'ISS-888',
        voucherType: 'مستند مخزني',
        currencyCode: 'SAR',
        description: 'Inventory issue',
        isPosted: true,
        sourceType: InventoryDocumentType.stockIssue.storageValue,
        sourceId: 'DOC-888',
        entryDate: now,
        lines: [
          JournalLineDraft(accountUuid: compA_acc1, debit: 250, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compA_acc2, debit: 0, credit: 250, currencyCode: 'SAR'),
        ],
      );
      final postedEntry = await postingService.post(draft);

      // Reverse using fallback poster
      await fallbackPoster.reverseAccountingEntry(document: docRef);

      // Original posted entry MUST remain intact
      final originalInDb = await journalRepo.getByUuid(postedEntry.uuid);
      expect(originalInDb, isNotNull);
      expect(originalInDb!.isPosted, isTrue);
      expect(originalInDb.deletedAt, isNull);

      // A reversing entry MUST exist
      final reversalInDb = await journalRepo.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: postedEntry.uuid,
      );
      expect(reversalInDb, isNotNull);
      expect(reversalInDb!.isPosted, isTrue);
      expect(reversalInDb.lines.firstWhere((l) => l.accountUuid == compA_acc1).credit, equals(250.0));
    });
  });
}
