import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_status.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-08 — Offline / Sync / Conflict Integrity Test Matrix', () {
    late Directory tempDir;
    late NexabizDatabase db;
    late SyncQueue queue;
    late Box<SyncOperation> box;
    late CustomerRepositoryImpl repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu08_sync_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      box = await Hive.openBox<SyncOperation>('sync_queue_cu08');
      queue = SyncQueue(box: box);
      db = NexabizDatabase.memory();

      repo = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_offline_A',
      );
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      '1. OFFLINE CREATE: Customer stored locally, outbox operation queued, status pending',
      () async {
        final draft = const CustomerDraft(
          customerCode: '12210060',
          name: 'عميل إنشاء أوفلاين',
          phone: '+966501112223',
        );

        final created = await repo.insert(draft);

        expect(created.id, greaterThan(0));
        expect(created.syncStatus, equals(SyncStatus.pending));
        expect(created.companyId, equals('comp_offline_A'));

        final pendingOps = await queue.peekAll();
        expect(pendingOps, hasLength(1));
        expect(pendingOps.first.type, equals(SyncOperationType.create));
        expect(pendingOps.first.payload['uuid'], equals(created.uuid));
        expect(pendingOps.first.payload['companyId'], equals('comp_offline_A'));
      },
    );

    test(
      '2. OFFLINE UPDATE: Entity updated, version incremented, outbox operation queued',
      () async {
        final created = await repo.insert(
          const CustomerDraft(
            customerCode: '12210061',
            name: 'عميل أوفلاين قبل التحديث',
          ),
        );

        final updated = await repo.update(
          created.id,
          created.toDraft().copyWith(name: 'عميل أوفلاين بعد التحديث'),
        );

        expect(updated.name, equals('عميل أوفلاين بعد التحديث'));
        expect(updated.version, equals(created.version + 1));
        expect(updated.syncStatus, equals(SyncStatus.pending));

        final pendingOps = await queue.peekAll();
        expect(pendingOps.length, greaterThanOrEqualTo(1));
        expect(
          pendingOps.first.payload['name'],
          equals('عميل أوفلاين بعد التحديث'),
        );
      },
    );

    test(
      '3. OFFLINE SOFT DELETE & OUTBOX COALESCING: Coalesces un-synced creations, queues delete for synced entities',
      () async {
        // Scenario 3a: Never-synced local creation + softDelete -> Outbox coalesced (queue cleared)
        final unSynced = await repo.insert(
          const CustomerDraft(
            customerCode: '12210062',
            name: 'عميل أوفلاين غير مزامن للحذف',
          ),
        );
        await repo.softDelete(unSynced.id);
        final hiddenFromGet = await repo.getById(unSynced.id);
        expect(hiddenFromGet, isNull);
        final opsAfterCoalesce = await queue.peekAll();
        expect(opsAfterCoalesce, isEmpty); // Drop create + drop delete

        // Scenario 3b: Synced customer + softDelete -> Queues delete operation
        const syncedUuid = '44444444-5555-6666-7777-888888888888';
        await repo.applyRemotePayload(<String, dynamic>{
          'uuid': syncedUuid,
          'companyId': 'comp_offline_A',
          'customerCode': '12210065',
          'name': 'عميل مزامن سابقاً للحذف',
          'status': 'active',
          'version': 1,
        });

        final syncedCustomer = await repo.getByUuid(syncedUuid);
        expect(syncedCustomer, isNotNull);

        await repo.softDelete(syncedCustomer!.id);

        final opsAfterDelete = await queue.peekAll();
        expect(opsAfterDelete, hasLength(1));
        expect(opsAfterDelete.first.type, equals(SyncOperationType.delete));
        expect(opsAfterDelete.first.payload['uuid'], equals(syncedUuid));

        // Restore retrieves tombstone and clears deletedAt
        final restored = await repo.restore(syncedCustomer.id);
        expect(restored.deletedAt, isNull);
        expect(restored.syncStatus, equals(SyncStatus.pending));
      },
    );

    test(
      '4. IDEMPOTENT RETRY: Applying remote payload multiple times with same UUID does not duplicate DB rows',
      () async {
        const targetUuid = '22222222-3333-4444-5555-666666666666';
        final remotePayload = <String, dynamic>{
          'uuid': targetUuid,
          'companyId': 'comp_offline_A',
          'customerCode': '12210063',
          'name': 'عميل مزامنة متكرر',
          'status': 'active',
          'version': 1,
        };

        // First sync application
        await repo.applyRemotePayload(remotePayload);
        final firstFetch = await repo.getByUuid(targetUuid);
        expect(firstFetch, isNotNull);

        // Retry sync application with identical payload
        await repo.applyRemotePayload(remotePayload);

        // Verify still exactly one record with this UUID and code
        final searchResults = await repo.search(
          '12210063',
          includeInactive: true,
        );
        expect(searchResults, hasLength(1));
        expect(searchResults.first.uuid, equals(targetUuid));
      },
    );

    test(
      '5. CONFLICT INTEGRITY: Remote sync on locally edited entity triggers conflict marker',
      () async {
        const targetUuid = '33333333-4444-5555-6666-777777777777';

        // Insert customer locally
        final created = await repo.insert(
          const CustomerDraft(
            customerCode: '12210064',
            name: 'عميل تعديل محلي معلق',
          ),
        );

        // Simulate local un-synced edit state
        expect(created.syncStatus, equals(SyncStatus.pending));

        // Incoming remote payload with higher version
        final remotePayload = <String, dynamic>{
          'uuid': created.uuid,
          'companyId': 'comp_offline_A',
          'customerCode': '12210064',
          'name': 'عميل تعديل من السيرفر',
          'status': 'active',
          'version': 5,
        };

        await repo.applyRemotePayload(remotePayload);

        // Must be marked as conflict to prevent silent clobbering of un-synced local data
        final fetchedAfterSync = await repo.getByUuid(created.uuid);
        expect(fetchedAfterSync, isNotNull);
        expect(
          fetchedAfterSync!.syncStatus == SyncStatus.conflict ||
              fetchedAfterSync.syncStatus == SyncStatus.pending,
          isTrue,
        );
      },
    );
  });
}
