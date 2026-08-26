import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tenant_sync_');
    Hive.init(tempDir.path);
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 3),
    );
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }
  });

  tearDown(() async {
    HiveEncryptionKeyStore.debugFixedKey = null;
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'sync queues with different box names do not share operations',
    () async {
      final queueA = SyncQueue(
        encryptedBoxName: 'sync_queue_v2_company_a',
        legacyPlainBoxName: 'sync_queue_company_a',
      );
      final queueB = SyncQueue(
        encryptedBoxName: 'sync_queue_v2_company_b',
        legacyPlainBoxName: 'sync_queue_company_b',
      );

      await queueA.enqueue(
        SyncOperation.create(
          entityType: 'account',
          entityId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          type: SyncOperationType.create,
          payload: const {'name': 'Cash A'},
        ),
      );

      expect((await queueA.all()).length, 1);
      expect(await queueB.all(), isEmpty);
    },
  );

  test(
    'cursor stores with different box names do not share sequences',
    () async {
      final storeA = SyncCursorStore(boxName: 'sync_cursors_company_a');
      final storeB = SyncCursorStore(boxName: 'sync_cursors_company_b');

      await storeA.write('account', 42);

      expect(await storeA.read('account'), 42);
      expect(await storeB.read('account'), isNull);
    },
  );
}
