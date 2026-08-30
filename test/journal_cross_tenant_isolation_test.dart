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
import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  late String compAAcc1;
  late String compAAcc2;
  late String compBAcc1;
  late String compBAcc2;

  setUp(() async {
    db = AccountingDatabase(executor: NativeDatabase.memory());
    companyA = 'company_alpha';
    companyB = 'company_beta';
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

    compAAcc1 = generateUuidV4();
    compAAcc2 = generateUuidV4();
    compBAcc1 = generateUuidV4();
    compBAcc2 = generateUuidV4();

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Seed Accounts for Company A
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compAAcc1,
            companyId: Value(companyA),
            accountCode: '1010-A',
            name: 'Cash Alpha',
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
            uuid: compAAcc2,
            companyId: Value(companyA),
            accountCode: '4010-A',
            name: 'Sales Alpha',
            accountType: 'revenue',
            normalBalance: 'credit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    // Seed Accounts for Company B
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compBAcc1,
            companyId: Value(companyB),
            accountCode: '1010-B',
            name: 'Cash Beta',
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
            uuid: compBAcc2,
            companyId: Value(companyB),
            accountCode: '4010-B',
            name: 'Sales Beta',
            accountType: 'revenue',
            normalBalance: 'credit',
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

  group('Journal Entry Cross-Tenant Isolation Security Suite', () {
    test('Test 1: Cross-Tenant Read Protection - Company B cannot read Company A entry or lines', () async {
      // Switch context to Company A and create entry X
      activeCompanyId = companyA;
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-A-001',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Secret financial record Company A',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compAAcc1, debit: 5000, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compAAcc2, debit: 0, credit: 5000, currencyCode: 'SAR'),
        ],
      );

      final posted = await postingService.post(draft);
      expect(posted.uuid, equals(entryUuid));

      // Switch context to Company B
      activeCompanyId = companyB;

      // 1a. getByUuid must return null
      final crossRead = await journalRepo.getByUuid(entryUuid);
      expect(crossRead, isNull);

      // 1b. listHeaders must not include entry X
      final headers = await journalRepo.listHeaders();
      expect(headers.any((h) => h.uuid == entryUuid), isFalse);

      // 1c. listJournalBookLines must not include entry X
      final bookLines = await journalRepo.listJournalBookLines();
      expect(bookLines.any((l) => l.voucherNumber == 'JE-A-001'), isFalse);

      // 1d. listTrialBalance for Company B must not include Company A's accounts or figures
      final tb = await journalRepo.listTrialBalance();
      expect(tb.any((row) => row.accountUuid == compAAcc1), isFalse);
    });

    test('Test 2: Cross-Tenant Update Protection - Company B cannot update or overwrite Company A entry', () async {
      // Switch to Company A and create entry X
      activeCompanyId = companyA;
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-A-002',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Company A entry for update test',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compAAcc1, debit: 1200, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compAAcc2, debit: 0, credit: 1200, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Switch to Company B
      activeCompanyId = companyB;

      // Company B attempts to overwrite entry X by providing same UUID
      final hackDraft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'HACKED-BY-B',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Malicious overwrite',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compBAcc1, debit: 9999, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compBAcc2, debit: 0, credit: 9999, currencyCode: 'SAR'),
        ],
      );

      await expectLater(
        () async => postingService.post(hackDraft),
        throwsA(isA<JournalException>().having((e) => e.code, 'message', JournalException.notFound)),
      );

      // Switch back to Company A context and verify entry X is unchanged
      activeCompanyId = companyA;
      final original = await journalRepo.getByUuid(entryUuid);
      expect(original, isNotNull);
      expect(original!.voucherNumber, equals('JE-A-002'));
      expect(original.description, equals('Company A entry for update test'));
      expect(original.lines.first.debit, equals(1200.0));
    });

    test('Test 3: Cross-Tenant Delete Protection - Company B cannot delete Company A draft entry', () async {
      // Switch to Company A and create draft entry X
      activeCompanyId = companyA;
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'DRAFT-A-003',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Company A draft entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compAAcc1, debit: 300, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compAAcc2, debit: 0, credit: 300, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Switch to Company B
      activeCompanyId = companyB;

      // Company B attempts softDeleteByUuid
      await journalRepo.softDeleteByUuid(entryUuid);

      // Switch back to Company A context and verify draft entry is intact
      activeCompanyId = companyA;
      final original = await journalRepo.getByUuid(entryUuid);
      expect(original, isNotNull);
      expect(original!.deletedAt, isNull);
    });

    test('Test 4: Cross-Tenant Reversal Protection - Company B cannot reverse Company A posted entry', () async {
      // Switch to Company A and post entry X
      activeCompanyId = companyA;
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-A-004',
        voucherType: 'sale',
        currencyCode: 'SAR',
        description: 'Company A posted sale',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compAAcc1, debit: 4500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compAAcc2, debit: 0, credit: 4500, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Switch to Company B
      activeCompanyId = companyB;

      // Company B attempts to reverse entry X
      await expectLater(
        () async => postingService.reverseByUuid(entryUuid),
        throwsA(isA<JournalException>().having((e) => e.code, 'message', JournalException.notFound)),
      );

      // Switch back to Company A context - original entry remains intact & no reversal created
      activeCompanyId = companyA;
      final original = await journalRepo.getByUuid(entryUuid);
      expect(original, isNotNull);
      expect(original!.isPosted, isTrue);

      final reversal = await journalRepo.findBySource(
        sourceType: JournalPostingService.reverseSourceType,
        sourceId: entryUuid,
      );
      expect(reversal, isNull);
    });

    test('Test 5: Identical sourceId Across Tenants - Company A & B manage same sourceId independently', () async {
      const commonSourceType = 'sale_invoice';
      const commonSourceId = 'INV-100999';

      // Switch to Company A and post entry with common sourceId
      activeCompanyId = companyA;
      final draftA = JournalEntryDraft(
        voucherNumber: 'INV-A-100',
        voucherType: 'sale',
        currencyCode: 'SAR',
        description: 'Invoice 100999 Company A',
        isPosted: true,
        sourceType: commonSourceType,
        sourceId: commonSourceId,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compAAcc1, debit: 750, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compAAcc2, debit: 0, credit: 750, currencyCode: 'SAR'),
        ],
      );
      final entryA = await postingService.post(draftA);

      // Switch to Company B and post entry with same sourceId
      activeCompanyId = companyB;
      final draftB = JournalEntryDraft(
        voucherNumber: 'INV-B-100',
        voucherType: 'sale',
        currencyCode: 'SAR',
        description: 'Invoice 100999 Company B',
        isPosted: true,
        sourceType: commonSourceType,
        sourceId: commonSourceId,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compBAcc1, debit: 990, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compBAcc2, debit: 0, credit: 990, currencyCode: 'SAR'),
        ],
      );
      final entryB = await postingService.post(draftB);

      // Verify UUIDs are distinct
      expect(entryA.uuid, isNot(equals(entryB.uuid)));

      // In Company B context, findBySource returns Company B's entry
      final fetchedB = await journalRepo.findBySource(
        sourceType: commonSourceType,
        sourceId: commonSourceId,
      );
      expect(fetchedB, isNotNull);
      expect(fetchedB!.uuid, equals(entryB.uuid));
      expect(fetchedB.voucherNumber, equals('INV-B-100'));

      // Switch context to Company A, findBySource returns Company A's entry
      activeCompanyId = companyA;
      final fetchedA = await journalRepo.findBySource(
        sourceType: commonSourceType,
        sourceId: commonSourceId,
      );
      expect(fetchedA, isNotNull);
      expect(fetchedA!.uuid, equals(entryA.uuid));
      expect(fetchedA.voucherNumber, equals('INV-A-100'));
    });

    test('Test 6: Direct Line Mutation Protection Across Tenants - Account remap is company-scoped', () async {
      // Company A posts entry with compAAcc1
      activeCompanyId = companyA;
      final entryUuid = generateUuidV4();
      final draft = JournalEntryDraft(
        uuid: entryUuid,
        voucherNumber: 'JE-A-006',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Remap scope test',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: compAAcc1, debit: 2000, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: compAAcc2, debit: 0, credit: 2000, currencyCode: 'SAR'),
        ],
      );

      await postingService.post(draft);

      // Switch to Company B and run remapAccountUuid from compAAcc1 to compBAcc1
      activeCompanyId = companyB;
      await journalRepo.remapAccountUuid(fromUuid: compAAcc1, toUuid: compBAcc1);

      // Switch back to Company A context - lines MUST still reference compAAcc1
      activeCompanyId = companyA;
      final entryA = await journalRepo.getByUuid(entryUuid);
      expect(entryA, isNotNull);
      expect(entryA!.lines.first.accountUuid, equals(compAAcc1));
    });
  });
}
