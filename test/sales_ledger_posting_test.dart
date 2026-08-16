import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/app/reports/account_statement_report_data_adapter.dart';
import 'package:stock_count/app/sales/accounting_sale_ledger_adapter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/domain/models/account_exception.dart';
import 'package:stock_count/modules/accounting/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/reports/domain/services/account_statement_report_data_port.dart';
import 'package:stock_count/modules/sales/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  late AccountingDatabase db;
  late AccountRepositoryImpl accounts;
  late JournalRepositoryImpl journals;
  late CurrencyRateRepositoryImpl rates;
  late Directory tempDir;
  late Box<SyncOperation> syncBox;
  late SyncQueue queue;
  var customerCodeSeq = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sales_ledger_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: syncBox);
    db = AccountingDatabase.memory();
    accounts = AccountRepositoryImpl(db, syncQueue: queue);
    journals = JournalRepositoryImpl(db, accounts: accounts, syncQueue: queue);
    rates = CurrencyRateRepositoryImpl(db);
    await accounts.ensureDefaultChartSeeded();
    customerCodeSeq = 0;
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> customerAccountUuid() async {
    final parent = await accounts.getByAccountCode('1221');
    expect(parent, isNotNull);
    customerCodeSeq += 1;
    final child = await accounts.insert(
      AccountDraft(
        parentId: parent!.uuid,
        accountCode: '12219$customerCodeSeq',
        name: 'Customer $customerCodeSeq',
        accountType: AccountType.asset,
        isGroup: false,
      ),
    );
    return child.uuid;
  }

  JournalPostingService postingService({DateTime? closedThrough}) {
    return JournalPostingService(
      journals: journals,
      fiscalPolicyReader: () => FiscalPeriodPolicy(
        fiscalYearStartMonth: 1,
        closedThrough: closedThrough,
      ),
    );
  }

  AccountingSaleLedgerAdapter saleAdapter({DateTime? closedThrough}) {
    return AccountingSaleLedgerAdapter(
      posting: postingService(closedThrough: closedThrough),
      accounts: accounts,
    );
  }

  group('JournalRepository', () {
    test('posts balanced entry and rejects unbalanced', () async {
      final cash = await accounts.getByAccountCode('1211');
      final revenue = await accounts.getByAccountCode('4100');
      expect(cash, isNotNull);
      expect(revenue, isNotNull);

      final entry = await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 1),
          voucherNumber: 'JV-1',
          voucherType: 'قيود يومية',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: cash!.uuid,
              debit: 50,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue!.uuid,
              debit: 0,
              credit: 50,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      expect(entry.lines, hasLength(2));
      expect(
        entry.lines.fold<double>(0, (s, l) => s + l.debit),
        entry.lines.fold<double>(0, (s, l) => s + l.credit),
      );

      await expectLater(
        journals.post(
          JournalEntryDraft(
            entryDate: DateTime.utc(2026, 8, 1),
            voucherNumber: 'JV-bad',
            voucherType: 'قيود يومية',
            currencyCode: 'YER',
            lines: [
              JournalLineDraft(
                accountUuid: cash.uuid,
                debit: 10,
                credit: 0,
                currencyCode: 'YER',
              ),
            ],
          ),
        ),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.unbalanced,
          ),
        ),
      );
    });

    test('rounds line amounts to cents before persist', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final entry = await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 1),
          voucherNumber: 'JV-round',
          voucherType: 'قيود يومية',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 10.004,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 10.004,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      expect(entry.lines.map((l) => l.debit).where((d) => d > 0).single, 10.0);
      expect(entry.lines.map((l) => l.credit).where((c) => c > 0).single, 10.0);

      await expectLater(
        journals.post(
          JournalEntryDraft(
            entryDate: DateTime.utc(2026, 8, 1),
            voucherNumber: 'JV-round-bad',
            voucherType: 'قيود يومية',
            currencyCode: 'YER',
            lines: [
              JournalLineDraft(
                accountUuid: cash.uuid,
                debit: 10.006,
                credit: 0,
                currencyCode: 'YER',
              ),
              JournalLineDraft(
                accountUuid: revenue.uuid,
                debit: 0,
                credit: 10.004,
                currencyCode: 'YER',
              ),
            ],
          ),
        ),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.unbalanced,
          ),
        ),
      );
    });

    test('blocks soft-delete of account used on journal lines', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final customerUuid = await customerAccountUuid();

      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 3),
          voucherNumber: 'S-use',
          voucherType: 'بيع آجل',
          currencyCode: 'YER',
          sourceType: 'sale',
          sourceId: 'sale-in-use',
          lines: [
            JournalLineDraft(
              accountUuid: customerUuid,
              debit: 15,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 15,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      expect(await accounts.isUsedInTransactions(customerUuid), isTrue);
      expect(await accounts.isUsedInTransactions(cash.uuid), isFalse);

      final customer = (await accounts.getByUuid(customerUuid))!;
      await expectLater(
        accounts.softDelete(customer.id),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.accountInUse,
          ),
        ),
      );

      // Soft-deleted journals still block account soft-delete (audit history).
      await journals.softDeleteBySource(
        sourceType: 'sale',
        sourceId: 'sale-in-use',
      );
      expect(await accounts.isUsedInTransactions(customerUuid), isTrue);
      await expectLater(
        accounts.softDelete(customer.id),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.accountInUse,
          ),
        ),
      );
    });

    test('sumNetBefore aggregates in SQL and listCurrencyCodes is distinct',
        () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;

      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 7, 1),
          voucherNumber: 'JV-open',
          voucherType: 'قيود يومية',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 100,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 100,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 5),
          voucherNumber: 'JV-usd',
          voucherType: 'قيود يومية',
          currencyCode: 'USD',
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 10,
              credit: 0,
              currencyCode: 'USD',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 10,
              currencyCode: 'USD',
            ),
          ],
        ),
      );

      expect(
        await journals.sumNetBefore(
          accountUuid: cash.uuid,
          beforeDate: DateTime.utc(2026, 8, 1),
          currencyCode: 'YER',
        ),
        100,
      );
      expect(
        await journals.sumNetBefore(
          accountUuid: cash.uuid,
          beforeDate: DateTime.utc(2026, 8, 1),
          currencyCode: 'USD',
        ),
        0,
      );

      final codes = await journals.listCurrencyCodesForAccount(
        accountUuid: cash.uuid,
        toDate: DateTime.utc(2026, 8, 5),
      );
      expect(codes, containsAll(<String>['USD', 'YER']));
    });

    test('listMovementsForAccount supports keyset pagination', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;

      for (var i = 1; i <= 3; i++) {
        await journals.post(
          JournalEntryDraft(
            entryDate: DateTime.utc(2026, 8, i),
            voucherNumber: 'JV-p$i',
            voucherType: 'قيود يومية',
            currencyCode: 'YER',
            lines: [
              JournalLineDraft(
                accountUuid: cash.uuid,
                debit: i.toDouble(),
                credit: 0,
                currencyCode: 'YER',
              ),
              JournalLineDraft(
                accountUuid: revenue.uuid,
                debit: 0,
                credit: i.toDouble(),
                currencyCode: 'YER',
              ),
            ],
          ),
        );
      }

      final page1 = await journals.listMovementsForAccount(
        accountUuid: cash.uuid,
        limit: 2,
      );
      expect(page1, hasLength(2));
      expect(page1.map((m) => m.debit).toList(), [1.0, 2.0]);

      final page2 = await journals.listMovementsForAccount(
        accountUuid: cash.uuid,
        limit: 2,
        after: AccountLedgerCursor.fromMovement(page1.last),
      );
      expect(page2, hasLength(1));
      expect(page2.single.debit, 3.0);
    });

    test('keeps same uuid by sourceType + sourceId and replaces lines', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2026, 8, 2),
        voucherNumber: 'S-1',
        voucherType: 'بيع آجل',
        currencyCode: 'YER',
        isPosted: false,
        sourceType: 'sale',
        sourceId: 'sale-uuid-1',
        lines: [
          JournalLineDraft(
            accountUuid: cash.uuid,
            debit: 20,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: revenue.uuid,
            debit: 0,
            credit: 20,
            currencyCode: 'YER',
          ),
        ],
      );
      final first = await journals.post(draft);
      final second = await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 3),
          voucherNumber: 'S-1-upd',
          voucherType: 'بيع آجل',
          currencyCode: 'YER',
          isPosted: true,
          description: 'updated',
          sourceType: 'sale',
          sourceId: 'sale-uuid-1',
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 35,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 35,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      expect(second.uuid, first.uuid);
      expect(second.voucherNumber, 'S-1-upd');
      expect(second.isPosted, isTrue);
      expect(second.lines.singleWhere((l) => l.debit > 0).debit, 35);
      final found = await journals.findBySource(
        sourceType: 'sale',
        sourceId: 'sale-uuid-1',
      );
      expect(found?.uuid, first.uuid);
      expect(found?.lines, hasLength(2));
    });

    test('listHeaders returns lightweight totals without requiring line load',
        () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 8),
          voucherNumber: 'JV-H1',
          voucherType: 'قيود يومية',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 40,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 40,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      final headers = await journals.listHeaders(limit: 10);
      expect(headers, isNotEmpty);
      final hit = headers.firstWhere((h) => h.voucherNumber == 'JV-H1');
      expect(hit.totalDebit, 40);
      expect(hit.totalCredit, 40);
    });
  });

  group('JournalPostingService', () {
    test('rejects posting into a closed fiscal period', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final posting = postingService(closedThrough: DateTime.utc(2026, 8, 15));

      await expectLater(
        posting.post(
          JournalEntryDraft(
            entryDate: DateTime.utc(2026, 8, 10),
            voucherNumber: 'JV-closed',
            voucherType: 'قيود يومية',
            currencyCode: 'YER',
            lines: [
              JournalLineDraft(
                accountUuid: cash.uuid,
                debit: 5,
                credit: 0,
                currencyCode: 'YER',
              ),
              JournalLineDraft(
                accountUuid: revenue.uuid,
                debit: 0,
                credit: 5,
                currencyCode: 'YER',
              ),
            ],
          ),
        ),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
    });
  });

  group('AccountingSaleLedgerAdapter', () {
    late AccountingSaleLedgerAdapter adapter;

    setUp(() {
      adapter = saleAdapter();
    });

    test('credit sale syncs Dr customer / Cr 4100 linked to sale uuid', () async {
      final customerAccount = await customerAccountUuid();
      final sale = _sale(
        settlement: SaleSettlementType.credit,
        customerAccountId: customerAccount,
        total: 150,
        uuid: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        saleStatus: SaleStatus.posted,
      );

      await adapter.syncSale(sale);

      final entry = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      expect(entry, isNotNull);
      expect(entry!.voucherType, 'بيع آجل');
      expect(entry.voucherNumber, sale.saleNumber);
      expect(entry.isPosted, isTrue);
      expect(entry.lines, hasLength(2));
      final debit = entry.lines.singleWhere((l) => l.debit > 0);
      final credit = entry.lines.singleWhere((l) => l.credit > 0);
      expect(debit.accountUuid, customerAccount);
      expect(debit.debit, 150);
      expect(credit.credit, 150);
      final revenue = await accounts.getByAccountCode('4100');
      expect(credit.accountUuid, revenue!.uuid);
    });

    test('unposted credit sale syncs journal with isPosted false', () async {
      final customerAccount = await customerAccountUuid();
      final sale = _sale(
        settlement: SaleSettlementType.credit,
        customerAccountId: customerAccount,
        total: 90,
        uuid: 'aaaaaaaa-bbbb-cccc-dddd-ffffffffffff',
        saleStatus: SaleStatus.unposted,
      );

      await adapter.syncSale(sale);

      final entry = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      expect(entry, isNotNull);
      expect(entry!.isPosted, isFalse);

      final movements = await journals.listMovementsForAccount(
        accountUuid: customerAccount,
        isPosted: false,
      );
      expect(movements.where((m) => m.debit == 90), hasLength(1));
      expect(movements.single.isPosted, isFalse);
    });

    test('re-sync updates amounts and does not duplicate', () async {
      final customerAccount = await customerAccountUuid();
      final sale = _sale(
        settlement: SaleSettlementType.credit,
        customerAccountId: customerAccount,
        total: 80,
        uuid: 'bbbbbbbb-bbbb-cccc-dddd-eeeeeeeeeeee',
        saleStatus: SaleStatus.unposted,
      );
      await adapter.syncSale(sale);
      await adapter.syncSale(
        _sale(
          settlement: SaleSettlementType.credit,
          customerAccountId: customerAccount,
          total: 120,
          uuid: sale.uuid,
          saleStatus: SaleStatus.unposted,
        ),
      );
      final movements = await journals.listMovementsForAccount(
        accountUuid: customerAccount,
      );
      expect(movements.where((m) => m.entryUuid != null), hasLength(1));
      expect(movements.single.debit, 120);
    });

    test('cash sale syncs Dr cash / Cr 4100', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final sale = _sale(
        settlement: SaleSettlementType.cash,
        customerAccountId: null,
        cashAccountId: cash.uuid,
        total: 99,
        uuid: 'cccccccc-bbbb-cccc-dddd-eeeeeeeeeeee',
        saleStatus: SaleStatus.unposted,
      );
      await adapter.syncSale(sale);
      final entry = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      expect(entry, isNotNull);
      expect(entry!.voucherType, 'بيع نقدي');
      expect(entry.isPosted, isFalse);
      final debit = entry.lines.singleWhere((l) => l.debit > 0);
      final credit = entry.lines.singleWhere((l) => l.credit > 0);
      expect(debit.accountUuid, cash.uuid);
      expect(debit.debit, 99);
      expect(credit.credit, 99);
      final revenue = await accounts.getByAccountCode('4100');
      expect(credit.accountUuid, revenue!.uuid);
    });

    test('sale with discounts Dr 5170 and Cr 4100 gross', () async {
      final customerAccount = await customerAccountUuid();
      final sale = _sale(
        settlement: SaleSettlementType.credit,
        customerAccountId: customerAccount,
        total: 80,
        itemDiscountTotal: 10,
        discountAmount: 10,
        uuid: 'dddddddd-aaaa-cccc-dddd-eeeeeeeeeeee',
        saleStatus: SaleStatus.unposted,
      );
      await adapter.syncSale(sale);

      final entry = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      expect(entry, isNotNull);
      expect(entry!.lines, hasLength(3));
      final customerLine = entry.lines.singleWhere(
        (l) => l.accountUuid == customerAccount,
      );
      expect(customerLine.debit, 80);
      final discount = await accounts.getByAccountCode('5170');
      final discountLine = entry.lines.singleWhere(
        (l) => l.accountUuid == discount!.uuid,
      );
      expect(discountLine.debit, 20);
      final revenue = await accounts.getByAccountCode('4100');
      final revenueLine = entry.lines.singleWhere(
        (l) => l.accountUuid == revenue!.uuid,
      );
      expect(revenueLine.credit, 100);
    });
  });

  group('AccountStatementReportDataAdapter', () {
    test('shows customer movement after credit sync', () async {
      final customerAccount = await customerAccountUuid();
      final adapter = saleAdapter();
      final sale = _sale(
        settlement: SaleSettlementType.credit,
        customerAccountId: customerAccount,
        total: 200,
        uuid: 'dddddddd-bbbb-cccc-dddd-eeeeeeeeeeee',
        saleDate: DateTime.utc(2026, 8, 10),
        saleStatus: SaleStatus.posted,
      );
      await adapter.syncSale(sale);

      final statement = AccountStatementReportDataAdapter(
        accounts: accounts,
        currencyRates: rates,
        journals: journals,
        loadCompanyProfile: () async => const CompanyProfile(),
      );

      final payload = await statement.load(
        accountUuid: customerAccount,
        fromDate: DateTime.utc(2026, 8, 1),
        toDate: DateTime.utc(2026, 8, 31),
        statementType: AccountStatementType.cumulativeAccountCurrency,
        postingFilter: AccountStatementPostingFilter.posted,
        labels: _labels(),
      );

      expect(payload.lines, isNotEmpty);
      expect(
        payload.lines.any((l) => l.voucherNumber == sale.saleNumber),
        isTrue,
      );
      expect(payload.totalDebit, 200);
      expect(payload.closingBalance, 200);
      expect(payload.lines.first.sideLabel, 'م');
      expect(payload.balancesByCurrency, hasLength(1));
      expect(payload.balancesByCurrency.single.currencyCode, 'YER');
    });

    test('all currencies keeps separate running balances per currency', () async {
      final customerAccount = await customerAccountUuid();
      final revenue = (await accounts.getByAccountCode('4100'))!;

      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 5),
          voucherNumber: 'Y-1',
          voucherType: 'بيع آجل',
          currencyCode: 'YER',
          sourceType: 'sale',
          sourceId: 'multi-yer',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccount,
              debit: 100,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 100,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 6),
          voucherNumber: 'U-1',
          voucherType: 'بيع آجل',
          currencyCode: 'USD',
          sourceType: 'sale',
          sourceId: 'multi-usd',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccount,
              debit: 50,
              credit: 0,
              currencyCode: 'USD',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 50,
              currencyCode: 'USD',
            ),
          ],
        ),
      );
      await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 7),
          voucherNumber: 'Y-2',
          voucherType: 'بيع آجل',
          currencyCode: 'YER',
          sourceType: 'sale',
          sourceId: 'multi-yer-2',
          lines: [
            JournalLineDraft(
              accountUuid: customerAccount,
              debit: 25,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 25,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      final statement = AccountStatementReportDataAdapter(
        accounts: accounts,
        currencyRates: rates,
        journals: journals,
        loadCompanyProfile: () async =>
            const CompanyProfile(defaultCurrencyCode: 'YER'),
      );

      final payload = await statement.load(
        accountUuid: customerAccount,
        currencyCode: null, // كل العملات
        fromDate: DateTime.utc(2026, 8, 1),
        toDate: DateTime.utc(2026, 8, 31),
        statementType: AccountStatementType.cumulativeAccountCurrency,
        postingFilter: AccountStatementPostingFilter.posted,
        labels: _labels(),
      );

      expect(payload.balancesByCurrency, hasLength(2));
      expect(payload.balancesByCurrency.first.currencyCode, 'YER');
      expect(payload.baseCurrencyCode, 'YER');
      expect(payload.balancesByCurrency.first.displayCurrencyCode, 'ر.ي');
      expect(
        payload.balancesByCurrency.first.amountInWords,
        contains('ريال يمني'),
      );
      final usd = payload.balancesByCurrency.singleWhere(
        (b) => b.currencyCode == 'USD',
      );
      expect(usd.displayCurrencyCode, '\$');
      expect(usd.amountInWords, contains('دولار أمريكي'));
      final yer = payload.balancesByCurrency.singleWhere(
        (b) => b.currencyCode == 'YER',
      );
      expect(usd.closingBalance, 50);
      expect(yer.closingBalance, 125);

      final yerLines = payload.lines
          .where((l) => l.currencyCode == 'YER')
          .toList();
      expect(yerLines, hasLength(2));
      expect(yerLines.first.balance, 100);
      expect(yerLines.last.balance, 125);

      final usdLines = payload.lines
          .where((l) => l.currencyCode == 'USD')
          .toList();
      expect(usdLines, hasLength(1));
      expect(usdLines.single.balance, 50);

      // Default currency (YER) block appears first.
      expect(payload.lines.first.currencyCode, 'YER');
      expect(payload.lines.last.currencyCode, 'USD');
    });
    test('shows unposted credit sale on statement with all/unposted filters',
        () async {
      final customerAccount = await customerAccountUuid();
      final adapter = saleAdapter();
      // Mimic composer DateTime.now() (local wall clock with time-of-day).
      final nowLocal = DateTime.now();
      final sale = _sale(
        settlement: SaleSettlementType.credit,
        customerAccountId: customerAccount,
        total: 75,
        uuid: 'eeeeeeee-bbbb-cccc-dddd-eeeeeeeeeeee',
        saleDate: nowLocal,
        saleStatus: SaleStatus.unposted,
      );
      await adapter.syncSale(sale);

      final statement = AccountStatementReportDataAdapter(
        accounts: accounts,
        currencyRates: rates,
        journals: journals,
        loadCompanyProfile: () async => const CompanyProfile(),
      );

      final todayLocal = DateTime(
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
      );
      for (final filter in [
        AccountStatementPostingFilter.all,
        AccountStatementPostingFilter.unposted,
      ]) {
        final payload = await statement.load(
          accountUuid: customerAccount,
          fromDate: todayLocal,
          toDate: todayLocal,
          statementType: AccountStatementType.cumulativeAccountCurrency,
          postingFilter: filter,
          labels: _labels(),
        );
        expect(
          payload.lines.any((l) => l.voucherNumber == sale.saleNumber),
          isTrue,
          reason: 'filter=$filter should include unposted same-day sale',
        );
        expect(
          payload.lines
              .where((l) => l.voucherNumber == sale.saleNumber)
              .every((l) => l.isPosted == false),
          isTrue,
        );
      }

      final postedOnly = await statement.load(
        accountUuid: customerAccount,
        fromDate: todayLocal,
        toDate: todayLocal,
        statementType: AccountStatementType.cumulativeAccountCurrency,
        postingFilter: AccountStatementPostingFilter.posted,
        labels: _labels(),
      );
      expect(
        postedOnly.lines.any((l) => l.voucherNumber == sale.saleNumber),
        isFalse,
      );
    });

    test('backfills missing unposted credit journal before load', () async {
      final customerAccount = await customerAccountUuid();
      final sale = _sale(
        settlement: SaleSettlementType.credit,
        customerAccountId: customerAccount,
        total: 40,
        uuid: 'ffffffff-bbbb-cccc-dddd-eeeeeeeeeeee',
        saleDate: DateTime.utc(2026, 8, 12),
        saleStatus: SaleStatus.unposted,
      );
      expect(
        await journals.findBySource(sourceType: 'sale', sourceId: sale.uuid),
        isNull,
      );

      final statement = AccountStatementReportDataAdapter(
        accounts: accounts,
        currencyRates: rates,
        journals: journals,
        loadCompanyProfile: () async => const CompanyProfile(),
        loadSalesForAccount: (_) async => [sale],
        ledger: saleAdapter(),
      );

      final payload = await statement.load(
        accountUuid: customerAccount,
        fromDate: DateTime.utc(2026, 8, 1),
        toDate: DateTime.utc(2026, 8, 31),
        statementType: AccountStatementType.cumulativeAccountCurrency,
        postingFilter: AccountStatementPostingFilter.all,
        labels: _labels(),
      );
      expect(
        payload.lines.any((l) => l.voucherNumber == sale.saleNumber),
        isTrue,
      );
      final entry = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      expect(entry, isNotNull);
      expect(entry!.isPosted, isFalse);
    });
  });
}

Sale _sale({
  required SaleSettlementType settlement,
  String? customerAccountId,
  required double total,
  required String uuid,
  String? cashAccountId,
  DateTime? saleDate,
  SaleStatus saleStatus = SaleStatus.posted,
  double itemDiscountTotal = 0,
  double discountAmount = 0,
  double? subtotal,
}) {
  final now = DateTime.utc(2026, 8, 14);
  final resolvedSubtotal =
      subtotal ?? (total + itemDiscountTotal + discountAmount);
  return Sale(
    id: 1,
    uuid: uuid,
    saleNumber: '42',
    saleDate: saleDate ?? now,
    settlementType: settlement,
    customerName: 'Test Customer',
    customerAccountId: customerAccountId,
    cashAccountId: cashAccountId,
    currencyCode: 'YER',
    baseCurrencyCode: 'YER',
    exchangeRate: 1,
    items: const [],
    payments: const [],
    subtotal: resolvedSubtotal,
    itemDiscountTotal: itemDiscountTotal,
    discountType: DiscountType.fixed,
    discountValue: discountAmount,
    discountAmount: discountAmount,
    taxRate: 0,
    taxAmount: 0,
    total: total,
    paidAmount: settlement.isCash ? total : 0,
    remainingAmount: settlement.isCash ? 0 : total,
    paymentStatus: settlement.isCash
        ? PaymentStatus.paid
        : PaymentStatus.unpaid,
    paymentMethod: PaymentMethod.cash,
    saleStatus: saleStatus,
    dataSource: SaleDataSource.local,
    createdAt: now,
    updatedAt: now,
    confirmedAt: saleStatus.isPosted ? now : null,
  );
}

AccountStatementReportLabels _labels() {
  return AccountStatementReportLabels(
    companyName: 'Co',
    reportTitle: 'Statement',
    printedByLabel: 'Printed',
    fromDateLabel: 'From',
    toDateLabel: 'To',
    accountNameLabel: 'Account',
    accountNumberLabel: 'Number',
    currencyAll: 'All',
    columnSide: 'م/د',
    columnDescription: 'Desc',
    columnVoucherType: 'Type',
    columnVoucherNumber: 'No',
    columnDate: 'Date',
    columnDebit: 'Debit',
    columnCredit: 'Credit',
    columnBalance: 'Balance',
    columnCurrency: 'Cur',
    columnInCurrency: 'In currency',
    totalsDebitLabel: 'Debit',
    totalsCreditLabel: 'Credit',
    finalBalanceByCurrencyLabel: 'Final',
    disclaimer: 'Note',
    accountantLabel: 'Acc',
    reviewerLabel: 'Rev',
    financeManagerLabel: 'FM',
    emptyMessage: 'Empty',
    statementTypeLabelOf: (_) => 'Cumulative',
    postingFilterLabelOf: (_) => 'Posted',
    accountDisplayNameOf: (a) => a.name,
  );
}
