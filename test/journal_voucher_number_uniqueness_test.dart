import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;

  late String companyId;
  late String acc1Uuid;
  late String acc2Uuid;

  setUp(() async {
    db = AccountingDatabase(executor: NativeDatabase.memory());
    companyId = 'company_alpha';

    accountRepo = AccountRepositoryImpl(db, readCompanyId: () => companyId);

    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => companyId,
    );

    postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: legacyPeriodValidator(),
    );

    acc1Uuid = generateUuidV4();
    acc2Uuid = generateUuidV4();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            uuid: acc1Uuid,
            companyId: Value(companyId),
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

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            uuid: acc2Uuid,
            companyId: Value(companyId),
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
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'Different voucher_type documents (Receipt vs Issue) CAN share the SAME voucher_number',
    () async {
      // 1. Post Stock Receipt (أمر توريد) with voucherNumber = 7275000001
      final receiptDraft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: '7275000001',
        voucherType: 'أمر توريد',
        currencyCode: 'SAR',
        sourceType: 'stock_receipt',
        sourceId: 'rec-doc-001',
        lines: [
          JournalLineDraft(
            accountUuid: acc1Uuid,
            debit: 1000.0,
            credit: 0.0,
            currencyCode: 'SAR',
          ),
          JournalLineDraft(
            accountUuid: acc2Uuid,
            debit: 0.0,
            credit: 1000.0,
            currencyCode: 'SAR',
          ),
        ],
      );

      final postedReceipt = await postingService.post(receiptDraft);
      expect(postedReceipt.voucherNumber, equals('7275000001'));
      expect(postedReceipt.voucherType, equals('أمر توريد'));

      // 2. Post Stock Issue (أمر صرف) with the EXACT SAME voucherNumber = 7275000001
      final issueDraft = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: '7275000001',
        voucherType: 'أمر صرف',
        currencyCode: 'SAR',
        sourceType: 'stock_issue',
        sourceId: 'iss-doc-001',
        lines: [
          JournalLineDraft(
            accountUuid: acc2Uuid,
            debit: 600.0,
            credit: 0.0,
            currencyCode: 'SAR',
          ),
          JournalLineDraft(
            accountUuid: acc1Uuid,
            debit: 0.0,
            credit: 600.0,
            currencyCode: 'SAR',
          ),
        ],
      );

      // This must succeed without SqliteException(2067)
      final postedIssue = await postingService.post(issueDraft);
      expect(postedIssue.voucherNumber, equals('7275000001'));
      expect(postedIssue.voucherType, equals('أمر صرف'));
    },
  );

  test(
    'Same voucher_type documents with same voucher_number in same company are rejected by unique constraint',
    () async {
      final draft1 = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: '7275000002',
        voucherType: 'أمر توريد',
        currencyCode: 'SAR',
        sourceType: 'stock_receipt',
        sourceId: 'rec-doc-002',
        lines: [
          JournalLineDraft(
            accountUuid: acc1Uuid,
            debit: 500.0,
            credit: 0.0,
            currencyCode: 'SAR',
          ),
          JournalLineDraft(
            accountUuid: acc2Uuid,
            debit: 0.0,
            credit: 500.0,
            currencyCode: 'SAR',
          ),
        ],
      );

      await postingService.post(draft1);

      final draft2 = JournalEntryDraft(
        entryDate: DateTime.now(),
        voucherNumber: '7275000002',
        voucherType: 'أمر توريد',
        currencyCode: 'SAR',
        sourceType: 'stock_receipt',
        sourceId:
            'rec-doc-003', // Different document ID, same voucher type and number
        lines: [
          JournalLineDraft(
            accountUuid: acc1Uuid,
            debit: 500.0,
            credit: 0.0,
            currencyCode: 'SAR',
          ),
          JournalLineDraft(
            accountUuid: acc2Uuid,
            debit: 0.0,
            credit: 500.0,
            currencyCode: 'SAR',
          ),
        ],
      );

      expect(() => postingService.post(draft2), throwsA(anything));
    },
  );
}
