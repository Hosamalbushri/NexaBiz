import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/domain/entities/currency_rate.dart';
import 'package:stock_count/modules/accounting/domain/entities/fiscal_year.dart';
import 'package:stock_count/modules/accounting/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/domain/services/period_closing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late AccountingDatabase db;
  late AccountRepositoryImpl accounts;
  late CurrencyRateRepositoryImpl rates;
  late FiscalYearRepositoryImpl fyRepo;
  late JournalRepositoryImpl journals;
  late JournalPostingService posting;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fx_diff_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue_fx');
    final queue = SyncQueue(box: syncBox);

    db = AccountingDatabase.memory();
    accounts = AccountRepositoryImpl(db, syncQueue: queue);
    await accounts.ensureDefaultChartSeeded();
    rates = CurrencyRateRepositoryImpl(db);
    fyRepo = FiscalYearRepositoryImpl(db);
    journals = JournalRepositoryImpl(
      db,
      accounts: accounts,
      rates: rates,
      periodValidator: AccountingPeriodValidator(
        repository: fyRepo,
        legacyPolicyReader: () => const FiscalPeriodPolicy(
          fiscalYearStartMonth: 1,
          closedThrough: null,
        ),
      ),
      syncQueue: queue,
    );
    posting = JournalPostingService(
      journals: journals,
      periodValidator: AccountingPeriodValidator(
        repository: fyRepo,
        legacyPolicyReader: () => const FiscalPeriodPolicy(
          fiscalYearStartMonth: 1,
          closedThrough: null,
        ),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('upsert writes dated rate history and getRateOn respects as-of',
      () async {
    await rates.upsert(
      CurrencyRateDraft(
        currencyCode: 'USD',
        rateToBase: 3.5,
        asOfDate: DateTime.utc(2026, 1, 10),
      ),
    );
    await rates.upsert(
      CurrencyRateDraft(
        currencyCode: 'USD',
        rateToBase: 3.75,
        asOfDate: DateTime.utc(2026, 2, 1),
      ),
    );

    expect(await rates.getRateOn('USD', DateTime.utc(2026, 1, 15)), 3.5);
    expect(await rates.getRateOn('USD', DateTime.utc(2026, 2, 10)), 3.75);
    final history = await rates.listHistory('USD');
    expect(history.length, greaterThanOrEqualTo(2));
  });

  test('journal post stores base debit/credit from exchange rate', () async {
    await rates.upsert(
      const CurrencyRateDraft(currencyCode: 'USD', rateToBase: 4),
    );
    final cash = await accounts.getByAccountCode('1211');
    final revenue = await accounts.getByAccountCode('4100');
    expect(cash, isNotNull);
    expect(revenue, isNotNull);

    final entry = await posting.post(
      JournalEntryDraft(
        entryDate: DateTime.utc(2026, 3, 1),
        voucherNumber: 'JV-FX-1',
        voucherType: 'manual',
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        lines: [
          JournalLineDraft(
            accountUuid: cash!.uuid,
            debit: 10,
            credit: 0,
            currencyCode: 'USD',
            exchangeRateToBase: 4,
          ),
          JournalLineDraft(
            accountUuid: revenue!.uuid,
            debit: 0,
            credit: 10,
            currencyCode: 'USD',
            exchangeRateToBase: 4,
          ),
        ],
      ),
    );

    expect(entry.lines[0].baseDebit, 40);
    expect(entry.lines[0].exchangeRateToBase, 4);
    expect(entry.lines[1].baseCredit, 40);
  });

  test('close with FX posts revaluation journal for rate change', () async {
    final create = CreateFiscalYear(repository: fyRepo, accounts: accounts);
    final fy = await create(
      FiscalYearDraft(
        code: '2026',
        name: '2026',
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 12, 31),
        baseCurrencyCode: 'SAR',
        periodCount: 12,
        periodFrequency: PeriodFrequency.monthly,
        fxRevaluationEnabled: true,
        fxGainAccountUuid: systemAccountUuid('fx_gain'),
        fxLossAccountUuid: systemAccountUuid('fx_loss'),
        createdBy: 'tester',
      ),
    );

    final periods = await fyRepo.listPeriods(fy.uuid);
    final jan = periods.firstWhere((p) => p.periodNumber == 1);
    await fyRepo.openPeriod(periodUuid: jan.uuid, openedBy: 'tester');

    await rates.upsert(
      CurrencyRateDraft(
        currencyCode: 'USD',
        rateToBase: 3.75,
        asOfDate: DateTime.utc(2026, 1, 5),
      ),
    );

    final cash = (await accounts.getByAccountCode('1211'))!;
    final revenue = (await accounts.getByAccountCode('4100'))!;

    await posting.post(
      JournalEntryDraft(
        entryDate: DateTime.utc(2026, 1, 10),
        voucherNumber: 'JV-1',
        voucherType: 'manual',
        currencyCode: 'USD',
        baseCurrencyCode: 'SAR',
        lines: [
          JournalLineDraft(
            accountUuid: cash.uuid,
            debit: 100,
            credit: 0,
            currencyCode: 'USD',
            exchangeRateToBase: 3.75,
          ),
          JournalLineDraft(
            accountUuid: revenue.uuid,
            debit: 0,
            credit: 100,
            currencyCode: 'USD',
            exchangeRateToBase: 3.75,
          ),
        ],
      ),
    );

    await rates.upsert(
      CurrencyRateDraft(
        currencyCode: 'USD',
        rateToBase: 4.0,
        asOfDate: DateTime.utc(2026, 1, 31),
      ),
    );

    final closer = PeriodClosingService(
      repository: fyRepo,
      rates: rates,
      posting: posting,
      journals: journals,
    );
    final result = await closer.close(
      periodUuid: jan.uuid,
      closedBy: 'tester',
    );

    expect(result.record.fxRevaluationEnabled, isTrue);
    expect(result.record.fxRevaluationExecuted, isTrue);
    expect(result.record.fxGain, 25);
    expect(result.record.journalEntryUuid, isNotNull);

    final fxEntry = await journals.getByUuid(result.record.journalEntryUuid!);
    expect(fxEntry, isNotNull);
    expect(fxEntry!.sourceType, PeriodClosingService.fxSourceType);
  });
}
