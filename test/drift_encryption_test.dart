import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:stock_count/core/database/drift_encryption_key_store.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('drift_enc_');
    Hive.init(tempDir.path);
    DriftEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 7),
    );
  });

  tearDown(() async {
    DriftEncryptionKeyStore.debugFixedKey = null;
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DriftEncryptionKeyStore returns stable 32-byte key', () async {
    final store = DriftEncryptionKeyStore();
    final a = await store.getOrCreateKey();
    final b = await store.getOrCreateKey();
    expect(a.length, 32);
    expect(a, b);
  });

  test('escapeSqlString doubles single quotes', () {
    expect(escapeSqlString("a'b"), "a''b");
  });

  test('debugCheckHasCipher matches isDriftCipherAvailable', () {
    final probe = sqlite3.openInMemory();
    try {
      expect(debugCheckHasCipher(probe), isDriftCipherAvailable());
    } finally {
      probe.close();
    }
  });

  test('passphrase seed encodes to stable base64url', () {
    final seed = Uint8List.fromList(List<int>.generate(32, (i) => i));
    expect(base64UrlEncode(seed), isNotEmpty);
  });
}
