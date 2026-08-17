import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/database/encrypted_hive_box.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';

void main() {
  late Directory tempDir;
  late Uint8List key;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_enc_');
    Hive.init(tempDir.path);
    key = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    HiveEncryptionKeyStore.debugFixedKey = key;
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

  test('migrates plaintext sync_queue into encrypted sync_queue_v2', () async {
    final legacy = await Hive.openBox<SyncOperation>(HiveBoxes.syncQueue);
    final op = SyncOperation.create(
      entityType: 'account',
      entityId: '00000000-0000-4000-8000-000000000001',
      type: SyncOperationType.create,
      baseVersion: 0,
      payload: const {'accountCode': '1100', 'name': 'Cash'},
    );
    await legacy.put(op.id, op);
    await legacy.close();

    final encrypted = await EncryptedHive.openMigrated<SyncOperation>(
      encryptedBoxName: HiveBoxes.syncQueueEncrypted,
      legacyPlainBoxName: HiveBoxes.syncQueue,
      cipher: HiveAesCipher(key),
    );

    expect(encrypted.length, 1);
    expect(encrypted.values.single.payload['accountCode'], '1100');
    expect(await Hive.boxExists(HiveBoxes.syncQueue), isFalse);
    expect(Hive.isBoxOpen(HiveBoxes.syncQueueEncrypted), isTrue);
  });

  test('reopening encrypted box with same key restores values', () async {
    final first = await EncryptedHive.openMigrated<String>(
      encryptedBoxName: HiveBoxes.authTokenStoreEncrypted,
      legacyPlainBoxName: HiveBoxes.authTokenStore,
      cipher: HiveAesCipher(key),
    );
    await first.put('auth_access_token', 'token-abc');
    await first.close();

    final second = await EncryptedHive.openMigrated<String>(
      encryptedBoxName: HiveBoxes.authTokenStoreEncrypted,
      legacyPlainBoxName: HiveBoxes.authTokenStore,
      cipher: HiveAesCipher(key),
    );
    expect(second.get('auth_access_token'), 'token-abc');
  });
}
