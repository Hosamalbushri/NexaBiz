import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/data/sync/accounting_sync_handlers.dart';
import 'package:stock_count/modules/accounting/domain/entities/currency_rate.dart';
import 'package:stock_count/modules/accounting/domain/entities/fiscal_year.dart';
import 'package:stock_count/modules/accounting/domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/domain/services/accounting_period_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;


  late Directory tempDir;
  late Box<SyncOperation> syncBoxA;
  late Box<SyncOperation> syncBoxB;
  late StreamController<List<ConnectivityResult>> connectivityStream;
  late ConnectivityService connectivity;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fiscal_fx_sync_p4_');
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

  test('Device A USD rate pushes and Device B pulls same uuid+rate', () async {
    final remote = InMemoryRemoteSyncApi();

    final dbA = AccountingDatabase.memory();
    final queueA = SyncQueue(box: syncBoxA);
    final ratesA = CurrencyRateRepositoryImpl(dbA, syncQueue: queueA);

    final dbB = AccountingDatabase.memory();
    final queueB = SyncQueue(box: syncBoxB);
    final ratesB = CurrencyRateRepositoryImpl(dbB, syncQueue: queueB);

    final created = await ratesA.upsert(
      const CurrencyRateDraft(
        currencyCode: 'USD',
        rateToBase: 3.75,
        notes: 'spot',
      ),
    );
    expect(created.syncStatus, SyncStatus.pending);
    expect(created.uuid, isNotEmpty);

    final pending = await queueA.all();
    expect(
      pending.any(
        (op) =>
            op.entityType == CurrencyRateRepositoryImpl.entityType &&
            op.entityId == created.uuid,
      ),
      isTrue,
    );

    final managerA = SyncManager(
      queue: queueA,
      connectivity: connectivity,
      remoteProvider: () => remote,
    );
    managerA.registerHandler(
      CurrencyRateSyncHandler(repository: ratesA, remoteProvider: () => remote),
    );
    await managerA.start(enabled: true);
    final passA = await managerA.syncNow();
    expect(passA.uploaded, greaterThan(0));

    final managerB = SyncManager(
      queue: queueB,
      connectivity: connectivity,
      remoteProvider: () => remote,
    );
    managerB.registerHandler(
      CurrencyRateSyncHandler(repository: ratesB, remoteProvider: () => remote),
    );
    await managerB.start(enabled: true);
    final passB = await managerB.syncNow();
    expect(passB.downloaded, greaterThan(0));

    final remoteRate = await ratesB.getByCode('USD');
    expect(remoteRate, isNotNull);
    expect(remoteRate!.uuid, created.uuid);
    expect(remoteRate.rateToBase, 3.75);
    expect(remoteRate.notes, 'spot');

    await managerA.dispose();
    await managerB.dispose();
    await dbA.close();
    await dbB.close();
  });

  test('Device A fiscal year pushes and Device B pulls same uuid+periods',
      () async {
    final remote = InMemoryRemoteSyncApi();

    final dbA = AccountingDatabase.memory();
    final queueA = SyncQueue(box: syncBoxA);
    final fyA = FiscalYearRepositoryImpl(dbA, syncQueue: queueA);

    final dbB = AccountingDatabase.memory();
    final queueB = SyncQueue(box: syncBoxB);
    final fyB = FiscalYearRepositoryImpl(dbB, syncQueue: queueB);

    const generator = AccountingPeriodGenerator();
    final periods = generator.generateMonthly(
      startDate: DateTime.utc(2026, 1, 1),
      endDate: DateTime.utc(2026, 12, 31),
      periodCount: 12,
    );
    final created = await fyA.createFiscalYear(
      draft: FiscalYearDraft(
        code: '2026',
        name: 'FY 2026',
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 12, 31),
        baseCurrencyCode: 'SAR',
        periodCount: 12,
        periodFrequency: PeriodFrequency.monthly,
        fxRevaluationEnabled: false,
      ),
      periods: periods,
    );

    final localPeriods = await fyA.listPeriods(created.uuid);
    expect(localPeriods, hasLength(12));

    final pending = await queueA.all();
    expect(
      pending.any(
        (op) =>
            op.entityType == FiscalYearRepositoryImpl.entityType &&
            op.entityId == created.uuid,
      ),
      isTrue,
    );

    final managerA = SyncManager(
      queue: queueA,
      connectivity: connectivity,
      remoteProvider: () => remote,
    );
    managerA.registerHandler(
      FiscalYearSyncHandler(repository: fyA, remoteProvider: () => remote),
    );
    await managerA.start(enabled: true);
    final passA = await managerA.syncNow();
    expect(passA.uploaded, greaterThan(0));

    final managerB = SyncManager(
      queue: queueB,
      connectivity: connectivity,
      remoteProvider: () => remote,
    );
    managerB.registerHandler(
      FiscalYearSyncHandler(repository: fyB, remoteProvider: () => remote),
    );
    await managerB.start(enabled: true);
    final passB = await managerB.syncNow();
    expect(passB.downloaded, greaterThan(0));

    final remoteFy = await fyB.getByUuid(created.uuid);
    expect(remoteFy, isNotNull);
    expect(remoteFy!.uuid, created.uuid);
    expect(remoteFy.code, '2026');
    final remotePeriods = await fyB.listPeriods(created.uuid);
    expect(remotePeriods, hasLength(12));
    expect(
      remotePeriods.map((p) => p.uuid).toSet(),
      localPeriods.map((p) => p.uuid).toSet(),
    );

    await managerA.dispose();
    await managerB.dispose();
    await dbA.close();
    await dbB.close();
  });
}
