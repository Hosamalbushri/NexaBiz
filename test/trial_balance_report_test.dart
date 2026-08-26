import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/reports/trial_balance_report_data_adapter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/reports/domain/services/trial_balance_report_data_port.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  late AccountingDatabase db;
  late AccountRepositoryImpl accounts;
  late JournalRepositoryImpl journals;
  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('trial_balance_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    db = AccountingDatabase.memory();
    accounts = AccountRepositoryImpl(db, syncQueue: queue);
    journals = JournalRepositoryImpl(
      db,
      accounts: accounts,
      periodValidator: legacyPeriodValidator(),
      syncQueue: queue,
    );
    await accounts.ensureDefaultChartSeeded();
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('listTrialBalance returns balanced posted aggregates', () async {
    final cash = await accounts.getByAccountCode('1211');
    final revenue = await accounts.getByAccountCode('4100');
    expect(cash, isNotNull);
    expect(revenue, isNotNull);

    await journals.post(
      JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 1),
        voucherNumber: 'JV-TB-1',
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

    final rows = await journals.listTrialBalance(isPosted: true);
    expect(rows, hasLength(2));
    final byCode = {for (final row in rows) row.accountCode: row};
    expect(byCode['1211']!.debit, 100);
    expect(byCode['1211']!.credit, 0);
    expect(byCode['4100']!.debit, 0);
    expect(byCode['4100']!.credit, 100);

    final totalDebit = rows.fold<double>(0, (s, r) => s + r.debit);
    final totalCredit = rows.fold<double>(0, (s, r) => s + r.credit);
    expect(totalDebit, totalCredit);
    expect(totalDebit, 100);

    final adapter = TrialBalanceReportDataAdapter(
      journals: journals,
      loadCompanyProfile: () async =>
          const CompanyProfile(defaultCurrencyCode: 'YER'),
    );
    const labels = TrialBalanceReportLabels(
      companyName: 'Demo',
      reportTitle: 'Trial balance',
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
    final payload = await adapter.load(postedOnly: true, labels: labels);
    expect(payload.rows, hasLength(2));
    expect(payload.totalsDebit, payload.totalsCredit);
    expect(payload.isBalanced, isTrue);
    expect(payload.baseCurrencyCode, 'YER');
  });
}
