import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/sales/accounting_sale_ledger_adapter.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/utils/async_search_token.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/domain/models/account_exception.dart';
import 'package:stock_count/modules/accounting/domain/models/account_tree_node.dart';
import 'package:stock_count/modules/accounting/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/presentation/widgets/account_tree.dart';
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

  group('AsyncSearchToken', () {
    test('discards stale generations while keeping the latest', () {
      final token = AsyncSearchToken();
      final first = token.next();
      final second = token.next();
      expect(token.isCurrent(first), isFalse);
      expect(token.isCurrent(second), isTrue);
      expect(token.value, second);
    });

    test('simulates overlapping async search completion order', () async {
      final token = AsyncSearchToken();
      String? applied;

      Future<void> search(String query, {required int delayMs}) async {
        final generation = token.next();
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        if (!token.isCurrent(generation)) {
          return;
        }
        applied = query;
      }

      // Slow "ca" then fast "cash" — only cash should stick.
      final slow = search('ca', delayMs: 40);
      final fast = search('cash', delayMs: 5);
      await Future.wait([slow, fast]);
      expect(applied, 'cash');
    });
  });

  group('AccountTreeNode.flatten', () {
    test('hides children until parent group is expanded', () {
      final now = DateTime.utc(2026, 8, 14);
      Account account({
        required String uuid,
        required String code,
        String? parentId,
        bool isGroup = false,
      }) {
        return Account(
          id: 1,
          uuid: uuid,
          parentId: parentId,
          accountCode: code,
          name: code,
          accountType: AccountType.asset,
          normalBalance: AccountType.asset.normalBalance,
          level: parentId == null ? 0 : 1,
          isGroup: isGroup,
          isActive: true,
          isSystemAccount: false,
          createdAt: now,
          updatedAt: now,
        );
      }

      final roots = AccountTreeNode.buildForest([
        account(uuid: 'a', code: '1000', isGroup: true),
        account(uuid: 'c', code: '1211', parentId: 'a'),
        account(uuid: 'b', code: '1100', parentId: 'a', isGroup: true),
      ]);

      final collapsed = AccountTreeNode.flatten(
        roots,
        expandedIds: const {},
      );
      expect(collapsed.map((e) => e.account.uuid).toList(), ['a']);

      final expandedRoot = AccountTreeNode.flatten(
        roots,
        expandedIds: {'a'},
      );
      expect(
        expandedRoot.map((e) => e.account.uuid).toList(),
        ['a', 'b', 'c'],
      );
    });
  });

  group('AccountTree widget', () {
    testWidgets('toggles expansion without losing root section', (tester) async {
      final now = DateTime.utc(2026, 8, 14);
      final root = Account(
        id: 1,
        uuid: 'root',
        accountCode: '1000',
        name: 'Assets',
        accountType: AccountType.asset,
        normalBalance: AccountType.asset.normalBalance,
        level: 0,
        isGroup: true,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      );
      final child = Account(
        id: 2,
        uuid: 'child',
        parentId: 'root',
        accountCode: '1211',
        name: 'Cash',
        accountType: AccountType.asset,
        normalBalance: AccountType.asset.normalBalance,
        level: 1,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        createdAt: now,
        updatedAt: now,
      );
      final roots = AccountTreeNode.buildForest([root, child]);
      final expanded = <String>{};

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AccountTree(
                  roots: roots,
                  expandedIds: expanded,
                  onToggleExpand: (id) {
                    setState(() {
                      if (!expanded.add(id)) {
                        expanded.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1000'), findsWidgets);
      expect(find.textContaining('1211'), findsNothing);

      await tester.tap(find.textContaining('1000').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('1211'), findsWidgets);

      await tester.tap(find.textContaining('1000').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('1211'), findsNothing);
      expect(find.textContaining('1000'), findsWidgets);
    });
  });

  group('Journal integrity & scale', () {
    late AccountingDatabase db;
    late AccountRepositoryImpl accounts;
    late JournalRepositoryImpl journals;
    late Directory tempDir;
    late Box<SyncOperation> syncBox;
    late SyncQueue queue;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('acct_phase5_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      syncBox = await Hive.openBox<SyncOperation>('sync_queue');
      queue = SyncQueue(box: syncBox);
      db = AccountingDatabase.memory();
      accounts = AccountRepositoryImpl(db, syncQueue: queue);
      journals = JournalRepositoryImpl(db, accounts: accounts);
      await accounts.ensureDefaultChartSeeded();
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    JournalPostingService postingService({DateTime? closedThrough}) {
      return JournalPostingService(
        journals: journals,
        fiscalPolicyReader: () => FiscalPeriodPolicy(
          fiscalYearStartMonth: 1,
          closedThrough: closedThrough,
        ),
      );
    }

    test('softDeleteByUuid hides ledger reads but keeps audit lines', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final custom = await accounts.insert(
        AccountDraft(
          parentId: cash.parentId,
          accountCode: '12991',
          name: 'Phase5 Cash Drawer',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );

      final posted = await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 10),
          voucherNumber: 'JV-del',
          voucherType: 'قيود يومية',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: custom.uuid,
              debit: 50,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 50,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      await journals.softDeleteByUuid(posted.uuid);

      expect(await journals.getByUuid(posted.uuid), isNull);
      expect(
        await journals.listMovementsForAccount(accountUuid: custom.uuid),
        isEmpty,
      );
      expect(
        await journals.sumNetBefore(
          accountUuid: custom.uuid,
          beforeDate: DateTime.utc(2026, 8, 11),
        ),
        0,
      );
      final headers = await journals.listHeaders(limit: 50);
      expect(headers.any((h) => h.uuid == posted.uuid), isFalse);

      expect(await accounts.isUsedInTransactions(custom.uuid), isTrue);
      await expectLater(
        accounts.softDelete(custom.id),
        throwsA(
          isA<AccountException>().having(
            (e) => e.code,
            'code',
            AccountException.accountInUse,
          ),
        ),
      );
    });

    test('soft-delete then re-post same source creates a new active entry',
        () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      const sourceId = 'sale-void-repost';

      final first = await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 4),
          voucherNumber: 'S-1',
          voucherType: 'بيع نقدي',
          currencyCode: 'YER',
          sourceType: 'sale',
          sourceId: sourceId,
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 10,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 10,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      await journals.softDeleteBySource(
        sourceType: 'sale',
        sourceId: sourceId,
      );
      expect(
        await journals.findBySource(sourceType: 'sale', sourceId: sourceId),
        isNull,
      );

      final second = await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 5),
          voucherNumber: 'S-2',
          voucherType: 'بيع نقدي',
          currencyCode: 'YER',
          sourceType: 'sale',
          sourceId: sourceId,
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 12,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 12,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      expect(second.uuid, isNot(first.uuid));
      expect(second.voucherNumber, 'S-2');
      final found = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sourceId,
      );
      expect(found?.uuid, second.uuid);
    });

    test('sale adapter soft-delete + re-sync stays single active journal',
        () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final adapter = AccountingSaleLedgerAdapter(
        posting: postingService(),
        accounts: accounts,
      );
      final sale = _sale(
        settlement: SaleSettlementType.cash,
        cashAccountId: cash.uuid,
        total: 25,
        uuid: 'sale-phase5-1',
      );

      await adapter.syncSale(sale);
      final first = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      expect(first, isNotNull);

      await adapter.voidSale(sale);
      expect(
        await journals.findBySource(sourceType: 'sale', sourceId: sale.uuid),
        isNull,
      );

      await adapter.syncSale(
        sale.copyWith(total: 30, paidAmount: 30, remainingAmount: 0),
      );
      final again = await journals.findBySource(
        sourceType: 'sale',
        sourceId: sale.uuid,
      );
      expect(again, isNotNull);
      expect(again!.uuid, isNot(first!.uuid));
      expect(again.lines.where((l) => l.debit > 0).single.debit, 30);
    });

    test('JournalPostingService blocks soft-delete in closed period', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final open = postingService();
      final entry = await open.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 1),
          voucherNumber: 'JV-closed-del',
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
      );

      final closed = postingService(closedThrough: DateTime.utc(2026, 8, 15));
      await expectLater(
        closed.softDeleteByUuid(entry.uuid),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
      expect(await journals.getByUuid(entry.uuid), isNotNull);
    });

    test('replace by draft.uuid updates in place', () async {
      final cash = (await accounts.getByAccountCode('1211'))!;
      final revenue = (await accounts.getByAccountCode('4100'))!;
      final first = await journals.post(
        JournalEntryDraft(
          entryDate: DateTime.utc(2026, 8, 6),
          voucherNumber: 'JV-u1',
          voucherType: 'قيود يومية',
          currencyCode: 'YER',
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 8,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 8,
              currencyCode: 'YER',
            ),
          ],
        ),
      );

      final second = await journals.post(
        JournalEntryDraft(
          uuid: first.uuid,
          entryDate: DateTime.utc(2026, 8, 7),
          voucherNumber: 'JV-u2',
          voucherType: 'قيود يومية',
          currencyCode: 'YER',
          description: 'edited',
          lines: [
            JournalLineDraft(
              accountUuid: cash.uuid,
              debit: 9,
              credit: 0,
              currencyCode: 'YER',
            ),
            JournalLineDraft(
              accountUuid: revenue.uuid,
              debit: 0,
              credit: 9,
              currencyCode: 'YER',
            ),
          ],
        ),
      );
      expect(second.uuid, first.uuid);
      expect(second.voucherNumber, 'JV-u2');
      expect(second.lines.where((l) => l.debit > 0).single.debit, 9);
    });

    test(
      'scale smoke: keyset pages + sumNetBefore over many movements',
      () async {
        final cash = (await accounts.getByAccountCode('1211'))!;
        final revenue = (await accounts.getByAccountCode('4100'))!;
        const entryCount = 1200;
        final sw = Stopwatch()..start();

        for (var i = 1; i <= entryCount; i++) {
          await journals.post(
            JournalEntryDraft(
              entryDate: DateTime.utc(2026, 1, 1).add(Duration(days: i % 200)),
              voucherNumber: 'JV-$i',
              voucherType: 'قيود يومية',
              currencyCode: 'YER',
              lines: [
                JournalLineDraft(
                  accountUuid: cash.uuid,
                  debit: 1,
                  credit: 0,
                  currencyCode: 'YER',
                ),
                JournalLineDraft(
                  accountUuid: revenue.uuid,
                  debit: 0,
                  credit: 1,
                  currencyCode: 'YER',
                ),
              ],
            ),
          );
        }
        sw.stop();

        expect(
          await journals.sumNetBefore(
            accountUuid: cash.uuid,
            beforeDate: DateTime.utc(2027, 1, 1),
            currencyCode: 'YER',
          ),
          entryCount.toDouble(),
        );

        final seen = <int>{};
        AccountLedgerCursor? cursor;
        var pages = 0;
        while (true) {
          final page = await journals.listMovementsForAccount(
            accountUuid: cash.uuid,
            currencyCode: 'YER',
            limit: 250,
            after: cursor,
          );
          if (page.isEmpty) {
            break;
          }
          pages += 1;
          for (final m in page) {
            expect(seen.add(m.lineId), isTrue, reason: 'duplicate ${m.lineId}');
          }
          cursor = AccountLedgerCursor.fromMovement(page.last);
          if (page.length < 250) {
            break;
          }
        }

        expect(seen.length, entryCount);
        expect(pages, greaterThan(1));
        // Smoke budget: keep under ~90s on typical CI/dev hosts.
        expect(sw.elapsed, lessThan(const Duration(seconds: 90)));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

Sale _sale({
  required SaleSettlementType settlement,
  String? customerAccountId,
  required double total,
  required String uuid,
  String? cashAccountId,
}) {
  final now = DateTime.utc(2026, 8, 14);
  return Sale(
    id: 1,
    uuid: uuid,
    saleNumber: '42',
    saleDate: now,
    settlementType: settlement,
    customerName: 'Test Customer',
    customerAccountId: customerAccountId,
    cashAccountId: cashAccountId,
    currencyCode: 'YER',
    baseCurrencyCode: 'YER',
    exchangeRate: 1,
    items: const [],
    payments: const [],
    subtotal: total,
    itemDiscountTotal: 0,
    discountType: DiscountType.fixed,
    discountValue: 0,
    discountAmount: 0,
    taxRate: 0,
    taxAmount: 0,
    total: total,
    paidAmount: settlement.isCash ? total : 0,
    remainingAmount: settlement.isCash ? 0 : total,
    paymentStatus: settlement.isCash
        ? PaymentStatus.paid
        : PaymentStatus.unpaid,
    paymentMethod: PaymentMethod.cash,
    saleStatus: SaleStatus.posted,
    dataSource: SaleDataSource.local,
    createdAt: now,
    updatedAt: now,
    confirmedAt: now,
  );
}
