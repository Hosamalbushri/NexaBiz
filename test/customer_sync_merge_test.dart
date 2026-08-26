import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/customers/data/database/customers_database.dart';
import 'package:stock_count/modules/customers/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/domain/entities/customer_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  late Directory tempDir;
  late CustomersDatabase db;
  late SyncQueue queue;
  late CustomerRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('customer_merge_sync_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
    final box = await Hive.openBox<SyncOperation>('sync_queue');
    queue = SyncQueue(box: box);
    db = CustomersDatabase.memory();
    repo = CustomerRepositoryImpl(db, syncQueue: queue);
  });

  tearDown(() async {
    await db.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('applyRemotePayload merges same customerCode onto remote UUID', () async {
    final local = await repo.insert(
      const CustomerDraft(
        customerCode: '12210002',
        name: 'ناصر محلي',
        dataSource: CustomerDataSource.local,
      ),
    );
    expect(local.uuid, isNotEmpty);

    await queue.enqueue(
      SyncOperation.create(
        entityType: CustomerRepositoryImpl.entityType,
        entityId: local.uuid,
        type: SyncOperationType.create,
        payload: {'uuid': local.uuid, 'customerCode': '12210002'},
        baseVersion: 1,
      ),
    );

    const remoteUuid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    await repo.applyRemotePayload({
      'uuid': remoteUuid,
      'customerCode': '12210002',
      'name': 'ناصر من جهاز آخر',
      'isActive': true,
      'dataSource': 'local',
      'version': 2,
      'updatedAt': DateTime.utc(2026, 8, 14).millisecondsSinceEpoch,
    });

    final byOld = await repo.getByUuid(local.uuid);
    expect(byOld, isNull);

    final merged = await repo.getByUuid(remoteUuid);
    expect(merged, isNotNull);
    expect(merged!.customerCode, '12210002');
    expect(merged.name, 'ناصر من جهاز آخر');
    expect(merged.syncStatus, SyncStatus.synced);

    final pending = await queue.all();
    expect(
      pending.where((op) => op.entityId == local.uuid),
      isEmpty,
    );
  });
}
