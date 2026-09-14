import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/reports/journal_book_report_data_adapter.dart';
import 'package:stock_count/app/reports/trial_balance_report_data_adapter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/reports/shared/domain/services/journal_book_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/trial_balance_report_data_port.dart';
import 'package:stock_count/modules/sync/sync.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase db;
  late AccountRepositoryImpl accounts;
  late JournalRepositoryImpl journals;
  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fin_posting_scope_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    db = NexabizDatabase.memory();
    accounts = AccountRepositoryImpl(
      db,
      syncQueue: queue,
      readCompanyId: () => 'test-company',
    );
    journals = JournalRepositoryImpl(
      db,
      accounts: accounts,
      periodValidator: legacyPeriodValidator(),
      syncQueue: queue,
      readCompanyId: () => 'test-company',
    );
    await accounts.seedDefaultChart();
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('ReportQueryFilter defaults to PostingScope.postedOnly', () {
    const filter = ReportQueryFilter(companyId: 'test-company');
    expect(filter.postingScope, PostingScope.postedOnly);
  });

  test(
    'Journal book excludes unposted entries when postedOnly is true',
    () async {
      final cash = await accounts.getByAccountCode('1211');
      final revenue = await accounts.getByAccountCode('4100');
      expect(cash, isNotNull);
      expect(revenue, isNotNull);

      // 1. Post a valid posted journal entry (100 YER)
      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 1),
          voucherNumber: 'JV-POSTED-1',
          voucherType: 'manual',
          currencyCode: 'YER',
          isPosted: true,
          lines: [
            JournalLineDraft(
              accountUuid: cash!.uuid,
              debit: 100,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue!.uuid,
              debit: 0,
              credit: 100,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      // 2. Post an unposted / draft journal entry (500 YER)
      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 2),
          voucherNumber: 'JV-DRAFT-2',
          voucherType: 'manual',
          currencyCode: 'YER',
          isPosted: false,
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 500,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 500,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      final adapter = JournalBookReportDataAdapter(
        journals: journals,
        loadCompanyProfile: () async =>
            const CompanyProfile(defaultCurrencyCode: 'YER'),
      );

      const labels = JournalBookReportLabels(
        companyName: 'Demo',
        reportTitle: 'Journal book',
        generatedAtLabel: 'Generated',
        periodLabel: 'Period',
        periodAll: 'All dates',
        columnDate: 'Date',
        columnVoucher: 'Voucher',
        columnType: 'Type',
        columnDescription: 'Description',
        columnAccount: 'Account',
        columnDebit: 'Debit',
        columnCredit: 'Credit',
        totalsLabel: 'Totals',
        emptyMessage: 'Empty',
      );

      // Default posted-only query via ReportQueryFilter
      const filterPosted = ReportQueryFilter(
        companyId: 'test-company',
        postingScope: PostingScope.postedOnly,
      );
      final payloadPosted = await adapter.loadFromFilter(
        filter: filterPosted,
        labels: labels,
      );
      expect(payloadPosted.rows, hasLength(2));
      expect(payloadPosted.totalsDebit, 100);

      // Unposted included query via ReportQueryFilter
      const filterAll = ReportQueryFilter(
        companyId: 'test-company',
        postingScope: PostingScope.all,
      );
      final payloadAll = await adapter.loadFromFilter(
        filter: filterAll,
        labels: labels,
      );
      expect(payloadAll.rows, hasLength(4));
      expect(payloadAll.totalsDebit, 600);
    },
  );

  test('Trial Balance excludes unposted entries by default', () async {
    final cash = await accounts.getByAccountCode('1211');
    final revenue = await accounts.getByAccountCode('4100');

    await journals.post(
      JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 1),
        voucherNumber: 'JV-TB-POSTED',
        voucherType: 'manual',
        currencyCode: 'YER',
        isPosted: true,
        lines: [
          JournalLineDraft(
            accountUuid: cash!.uuid,
            debit: 250,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: revenue!.uuid,
            debit: 0,
            credit: 250,
            currencyCode: 'YER',
          ),
        ],
      ),
    );

    await journals.post(
      JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 2),
        voucherNumber: 'JV-TB-UNPOSTED',
        voucherType: 'manual',
        currencyCode: 'YER',
        isPosted: false,
        lines: [
          JournalLineDraft(
            accountUuid: cash.uuid,
            debit: 1000,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: revenue.uuid,
            debit: 0,
            credit: 1000,
            currencyCode: 'YER',
          ),
        ],
      ),
    );

    final adapter = TrialBalanceReportDataAdapter(
      journals: journals,
      loadCompanyProfile: () async =>
          const CompanyProfile(defaultCurrencyCode: 'YER'),
    );

    const labels = TrialBalanceReportLabels(
      companyName: 'Demo',
      reportTitle: 'Trial Balance',
      generatedAtLabel: 'Generated',
      periodLabel: 'Period',
      periodAll: 'All dates',
      columnCode: 'Code',
      columnName: 'Name',
      columnDebit: 'Debit',
      columnCredit: 'Credit',
      totalsLabel: 'Totals',
      balancedLabel: 'Balanced',
      unbalancedLabel: 'Unbalanced',
      emptyMessage: 'Empty',
    );

    const filterPosted = ReportQueryFilter(
      companyId: 'test-company',
      postingScope: PostingScope.postedOnly,
    );
    final payloadPosted = await adapter.loadFromFilter(
      filter: filterPosted,
      labels: labels,
    );
    expect(payloadPosted.totalsDebit, 250);
    expect(payloadPosted.isBalanced, isTrue);

    const filterAll = ReportQueryFilter(
      companyId: 'test-company',
      postingScope: PostingScope.all,
    );
    final payloadAll = await adapter.loadFromFilter(
      filter: filterAll,
      labels: labels,
    );
    expect(payloadAll.totalsDebit, 1250);
    expect(payloadAll.isBalanced, isTrue);
  });
}
