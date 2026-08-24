import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/domain/entities/fiscal_year.dart';
import 'package:stock_count/modules/accounting/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/domain/models/fiscal_year_exception.dart';
import 'package:stock_count/modules/accounting/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_period_generator.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/domain/services/period_closing_service.dart';
import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountingPeriodGenerator', () {
    const generator = AccountingPeriodGenerator();

    test('generates 12 contiguous months for calendar year', () {
      final specs = generator.generateMonthly(
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 12, 31),
        periodCount: 12,
      );
      expect(specs, hasLength(12));
      expect(specs.first.startDate, DateTime.utc(2026, 1, 1));
      expect(specs.first.endDate, DateTime.utc(2026, 1, 31));
      expect(specs[1].startDate, DateTime.utc(2026, 2, 1));
      expect(specs[1].endDate, DateTime.utc(2026, 2, 28));
      expect(specs.last.endDate, DateTime.utc(2026, 12, 31));
      for (var i = 0; i < specs.length - 1; i++) {
        expect(
          specs[i].endDate.add(const Duration(days: 1)),
          specs[i + 1].startDate,
        );
      }
    });

    test('handles leap year February', () {
      final specs = generator.generateMonthly(
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 12, 31),
        periodCount: 12,
      );
      expect(specs[1].endDate, DateTime.utc(2024, 2, 29));
    });

    test('rejects invalid period count', () {
      expect(
        () => generator.generateMonthly(
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 12, 31),
          periodCount: 0,
        ),
        throwsA(isA<FiscalYearException>()),
      );
    });
  });

  group('AccountingPeriodValidator legacy fallback', () {
    test('uses closedThrough when no fiscal years', () async {
      final validator = AccountingPeriodValidator(
        repository: EmptyFiscalYearRepository(),
        legacyPolicyReader: () => FiscalPeriodPolicy(
          fiscalYearStartMonth: 1,
          closedThrough: DateTime.utc(2026, 8, 1),
        ),
      );
      await expectLater(
        validator.assertEntryAllowed(DateTime.utc(2026, 8, 1)),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
      await expectLater(
        validator.assertEntryAllowed(DateTime.utc(2026, 8, 2)),
        completes,
      );
    });
  });

  group('Fiscal year persistence + enforcement', () {
    late AccountingDatabase db;
    late FiscalYearRepositoryImpl fyRepo;
    late AccountRepositoryImpl accounts;
    late JournalRepositoryImpl journals;
    late Directory tempDir;
    late Box<SyncOperation> syncBox;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fiscal_year_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      syncBox = await Hive.openBox<SyncOperation>('sync_queue_fy');
      final queue = SyncQueue(box: syncBox);
      db = AccountingDatabase.memory();
      fyRepo = FiscalYearRepositoryImpl(db);
      accounts = AccountRepositoryImpl(db, syncQueue: queue);
      journals = JournalRepositoryImpl(db, accounts: accounts, periodValidator: legacyPeriodValidator(), syncQueue: queue);
      await accounts.ensureDefaultChartSeeded();
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('create FY defaults periods to closed and blocks posting', () async {
      final create = CreateFiscalYear(
        repository: fyRepo,
        accounts: accounts,
      );
      final fy = await create(
        FiscalYearDraft(
          code: '2026',
          name: 'FY 2026',
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 12, 31),
          baseCurrencyCode: 'SAR',
          periodCount: 12,
          periodFrequency: PeriodFrequency.monthly,
          fxRevaluationEnabled: false,
        ),
      );
      final periods = await fyRepo.listPeriods(fy.uuid);
      expect(periods, hasLength(12));
      expect(
        periods.every((p) => p.status == AccountingPeriodStatus.closed),
        isTrue,
      );

      final validator = AccountingPeriodValidator(
        repository: fyRepo,
        legacyPolicyReader: () =>
            const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
      );
      final posting = JournalPostingService(
        journals: journals,
        periodValidator: validator,
      );

      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 15),
        voucherNumber: 'JV-1',
        voucherType: 'manual',
        currencyCode: 'SAR',
        lines: [
          JournalLineDraft(
            accountUuid: cash.uuid,
            debit: 10,
            credit: 0,
            currencyCode: 'SAR',
          ),
          JournalLineDraft(
            accountUuid: revenue.uuid,
            debit: 0,
            credit: 10,
            currencyCode: 'SAR',
          ),
        ],
      );

      await expectLater(
        posting.post(draft),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );

      final august = periods.firstWhere((p) => p.periodNumber == 8);
      await fyRepo.openPeriod(periodUuid: august.uuid, openedBy: 'tester');
      final posted = await posting.post(draft);
      expect(posted.uuid, isNotEmpty);

      final closer = PeriodClosingService(
        repository: fyRepo,
        rates: CurrencyRateRepositoryImpl(db),
        posting: posting,
        journals: journals,
      );
      final result = await closer.close(
        periodUuid: august.uuid,
        closedBy: 'tester',
      );
      expect(result.idempotentReplay, isFalse);
      final again = await closer.close(
        periodUuid: august.uuid,
        closedBy: 'tester',
      );
      expect(again.idempotentReplay, isTrue);

      await expectLater(
        posting.post(
          JournalEntryDraft(
            entryDate: DateTime.utc(2026, 8, 20),
            voucherNumber: 'JV-2',
            voucherType: 'manual',
            currencyCode: 'SAR',
            lines: draft.lines,
          ),
        ),
        throwsA(isA<JournalException>()),
      );
    });
  });
}
