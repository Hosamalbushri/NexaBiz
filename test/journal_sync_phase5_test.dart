import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/app/sales/accounting_sale_ledger_adapter.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/sync/accounting_sync_handlers.dart';
import 'package:stock_count/modules/accounting/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/domain/entities/account_type.dart';
import 'helpers/journal_posting_test_helper.dart';
import 'package:stock_count/modules/sales/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  late Directory tempDir;
  late Box<SyncOperation> syncBoxA;
  late Box<SyncOperation> syncBoxB;
  late StreamController<List<ConnectivityResult>> connectivityStream;
  late ConnectivityService connectivity;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('journal_sync_p5_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    syncBoxA = await Hive.openBox<SyncOperation>('sync_queue_a');
    syncBoxB = await Hive.openBox<SyncOperation>('sync_queue_b');
    connectivityStream = StreamController<List<ConnectivityResult>>.broadcast();
    connectivity = ConnectivityService(
      connectivityStream: connectivityStream.stream,
      initialResults: const [ConnectivityResult.wifi],
    );
    await connectivity.start();
  });

  tearDown(() async {
    await connectivity.dispose();
    await connectivityStream.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Device A sale journal pushes and Device B pulls same UUID+lines', () async {
    final remote = InMemoryRemoteSyncApi();

    final dbA = AccountingDatabase.memory();
    final queueA = SyncQueue(box: syncBoxA);
    final accountsA = AccountRepositoryImpl(dbA, syncQueue: queueA);
    final journalsA = JournalRepositoryImpl(
      dbA,
      accounts: accountsA,
      periodValidator: legacyPeriodValidator(),
      syncQueue: queueA,
    );
    await accountsA.ensureDefaultChartSeeded();

    final dbB = AccountingDatabase.memory();
    final queueB = SyncQueue(box: syncBoxB);
    final accountsB = AccountRepositoryImpl(dbB, syncQueue: queueB);
    final journalsB = JournalRepositoryImpl(
      dbB,
      accounts: accountsB,
      periodValidator: legacyPeriodValidator(),
      syncQueue: queueB,
    );
    await accountsB.ensureDefaultChartSeeded();

    // System CoA seeds may share stable UUIDs; custom cash accounts do not.
    final revenueA = await accountsA.getByAccountCode('4100');
    final revenueB = await accountsB.getByAccountCode('4100');
    expect(revenueA, isNotNull);
    expect(revenueB, isNotNull);

    final parentA = await accountsA.getByAccountCode('1221');
    final cashA = await accountsA.insert(
      AccountDraft(
        parentId: parentA!.uuid,
        accountCode: '12210099',
        name: 'Cash till A',
        accountType: AccountType.asset,
        isGroup: false,
      ),
    );
    final parentB = await accountsB.getByAccountCode('1221');
    final cashBLocal = await accountsB.insert(
      AccountDraft(
        parentId: parentB!.uuid,
        accountCode: '12210099',
        name: 'Cash till B',
        accountType: AccountType.asset,
        isGroup: false,
      ),
    );
    expect(cashA.uuid, isNot(cashBLocal.uuid));

    final postingA = journalPostingWithLegacyPolicy(journals: journalsA);
    final ledgerA = AccountingSaleLedgerAdapter(
      posting: postingA,
      accounts: accountsA,
    );

    final saleUuid = generateUuidV4();
    final sale = Sale(
      id: 1,
      uuid: saleUuid,
      saleNumber: 'INV-P5-1',
      saleDate: DateTime.utc(2026, 8, 15),
      settlementType: SaleSettlementType.cash,
      cashAccountId: cashA.uuid,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1,
      items: const [],
      payments: const [],
      subtotal: 100,
      itemDiscountTotal: 0,
      discountType: DiscountType.fixed,
      discountValue: 0,
      discountAmount: 0,
      taxRate: 0,
      taxAmount: 0,
      total: 100,
      paidAmount: 100,
      remainingAmount: 0,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: PaymentMethod.cash,
      saleStatus: SaleStatus.posted,
      dataSource: SaleDataSource.local,
      createdAt: DateTime.utc(2026, 8, 15),
      updatedAt: DateTime.utc(2026, 8, 15),
    );

    await ledgerA.syncSale(sale);

    final localJournal = await journalsA.findBySource(
      sourceType: 'sale',
      sourceId: saleUuid,
    );
    expect(localJournal, isNotNull);
    expect(localJournal!.syncStatus, SyncStatus.pending);
    expect(localJournal.uuid, isNotEmpty);

    final pending = await queueA.all();
    expect(
      pending.any(
        (op) =>
            op.entityType == JournalRepositoryImpl.entityType &&
            op.entityId == localJournal.uuid,
      ),
      isTrue,
    );

    final managerA = SyncManager(
      queue: queueA,
      connectivity: connectivity,
      remote: remote,
    );
    managerA.registerHandler(
      AccountSyncHandler(repository: accountsA, remote: remote),
    );
    managerA.registerHandler(
      JournalSyncHandler(repository: journalsA, remote: remote),
    );
    await managerA.start(enabled: true);
    final passA = await managerA.syncNow();
    expect(passA.uploaded, greaterThan(0));

    final managerB = SyncManager(
      queue: queueB,
      connectivity: connectivity,
      remote: remote,
    );
    managerB.registerHandler(
      AccountSyncHandler(repository: accountsB, remote: remote),
    );
    managerB.registerHandler(
      JournalSyncHandler(repository: journalsB, remote: remote),
    );
    await managerB.start(enabled: true);
    final passB = await managerB.syncNow();
    expect(passB.downloaded, greaterThan(0));

    final remoteJournal = await journalsB.findBySource(
      sourceType: 'sale',
      sourceId: saleUuid,
    );
    expect(remoteJournal, isNotNull);
    expect(remoteJournal!.uuid, localJournal.uuid);
    expect(remoteJournal.voucherNumber, 'INV-P5-1');
    expect(remoteJournal.isPosted, isTrue);
    expect(remoteJournal.lines.length, localJournal.lines.length);

    final revenueLineB = remoteJournal.lines.firstWhere((l) => l.credit > 0);
    expect(revenueLineB.accountUuid, revenueB!.uuid);
    expect(revenueLineB.credit, 100);

    final debitLineB = remoteJournal.lines.firstWhere((l) => l.debit > 0);
    final cashB = await accountsB.getByAccountCode('12210099');
    expect(cashB, isNotNull);
    expect(debitLineB.accountUuid, cashB!.uuid);
    expect(debitLineB.debit, 100);

    expect(
      remoteJournal.lines.map((l) => l.uuid).toSet(),
      localJournal.lines.map((l) => l.uuid).toSet(),
    );

    await managerA.dispose();
    await managerB.dispose();
    await dbA.close();
    await dbB.close();
  });
}
