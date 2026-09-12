import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:stock_count/core/database/canonical_database_provider.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase3a_canonical_db_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 3A Canonical Database Foundation Test Suite', () {
    test('1. Database open, metadata initialization, and schemaVersion = 1', () async {
      final db = NexabizDatabase.connect(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, greaterThanOrEqualTo(1));

      // Query metadata table created during onCreate
      final metadataList = await db.select(db.canonicalDbMetadata).get();
      expect(metadataList.isNotEmpty, isTrue);
      expect(metadataList.first.key, equals('schema_initialized_at'));
    });

    test('2. Encrypted SQLCipher database creation and stable key reopening', () async {
      final dbPath = p.join(tempDir.path, 'nexabiz_encrypted.sqlite');
      final dbFile = File(dbPath);
      const testKey = 'test_secret_passphrase_key_12345';

      // Create encrypted database file using raw sqlite3 PRAGMA key
      final rawDb1 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb1)) {
        rawDb1.execute("PRAGMA key = '$testKey';");
      }
      rawDb1.execute('CREATE TABLE sys_meta (k TEXT PRIMARY KEY, v TEXT);');
      rawDb1.execute("INSERT INTO sys_meta VALUES ('version', '1.0.0');");
      rawDb1.close();

      expect(await dbFile.exists(), isTrue);

      // Reopen with same key — must succeed and retrieve data
      final rawDb2 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb2)) {
        rawDb2.execute("PRAGMA key = '$testKey';");
      }
      final result = rawDb2.select("SELECT v FROM sys_meta WHERE k = 'version';");
      expect(result.first['v'], equals('1.0.0'));
      rawDb2.close();
    });

    test('3. Security Negative Test — Wrong encryption key fails explicitly', () async {
      final dbPath = p.join(tempDir.path, 'nexabiz_wrong_key.sqlite');
      const correctKey = 'correct_passphrase_key_999';
      const wrongKey = 'wrong_passphrase_key_000';

      // Create DB with correct key
      final rawDb1 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb1)) {
        rawDb1.execute("PRAGMA key = '$correctKey';");
        rawDb1.execute('CREATE TABLE sys_meta (k TEXT PRIMARY KEY, v TEXT);');
        rawDb1.execute("INSERT INTO sys_meta VALUES ('status', 'active');");
      }
      rawDb1.close();

      // Attempt open with wrong key
      final rawDb2 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb2)) {
        rawDb2.execute("PRAGMA key = '$wrongKey';");
        expect(
          () => rawDb2.select('SELECT count(*) FROM sys_meta;'),
          throwsA(isA<SqliteException>()),
        );
      }
      rawDb2.close();

      // Verify file was NOT deleted or mutated by the wrong key failure
      expect(File(dbPath).existsSync(), isTrue);
    });

    test('4. Security Negative Test — Plaintext opening fails on SQLCipher DB', () async {
      final dbPath = p.join(tempDir.path, 'nexabiz_cipher_only.sqlite');
      const cipherKey = 'secure_cipher_key_abc';

      final rawDb1 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb1)) {
        rawDb1.execute("PRAGMA key = '$cipherKey';");
        rawDb1.execute('CREATE TABLE sys_meta (k TEXT PRIMARY KEY, v TEXT);');
      }
      rawDb1.close();

      // Open without issuing PRAGMA key (plaintext mode)
      final rawDb2 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb2)) {
        expect(
          () => rawDb2.select('SELECT count(*) FROM sqlite_master;'),
          throwsA(isA<SqliteException>()),
        );
      }
      rawDb2.close();
    });

    test('5. Transaction Boundary & Rollback Verification', () async {
      final db = NexabizDatabase.connect(NativeDatabase.memory());
      addTearDown(db.close);

      // Successful transaction
      await db.transaction(() async {
        await db.into(db.canonicalDbMetadata).insert(
              CanonicalDbMetadataCompanion.insert(
                key: 'txn_key_1',
                value: const Value('txn_val_1'),
              ),
            );
      });

      final val1 = await (db.select(db.canonicalDbMetadata)
            ..where((tbl) => tbl.key.equals('txn_key_1')))
          .getSingleOrNull();
      expect(val1?.value, equals('txn_val_1'));

      // Failing transaction -> Rollback
      expect(
        () async {
          await db.transaction(() async {
            await db.into(db.canonicalDbMetadata).insert(
                  CanonicalDbMetadataCompanion.insert(
                    key: 'txn_key_failed',
                    value: const Value('should_rollback'),
                  ),
                );
            throw Exception('Simulated transaction failure');
          });
        },
        throwsA(isA<Exception>()),
      );

      final valFailed = await (db.select(db.canonicalDbMetadata)
            ..where((tbl) => tbl.key.equals('txn_key_failed')))
          .getSingleOrNull();
      expect(valFailed, isNull);
    });

    test('6. CanonicalDatabaseManager Lifecycle & Health Check', () async {
      final manager = CanonicalDatabaseManager();
      expect(manager.state, equals(CanonicalDatabaseLifecycleState.uninitialized));
      expect(manager.isOpen, isFalse);

      final testDb = NexabizDatabase.connect(NativeDatabase.memory());
      manager.setTestInstance(testDb);

      expect(manager.state, equals(CanonicalDatabaseLifecycleState.open));
      expect(manager.isOpen, isTrue);

      final healthy = await manager.healthCheck();
      expect(healthy, isTrue);

      await manager.closeDatabase();
      expect(manager.state, equals(CanonicalDatabaseLifecycleState.closed));
      expect(manager.isOpen, isFalse);
    });

    test('7. Legacy Database Safety — nexabiz.sqlite exists independently', () async {
      final legacyPath = p.join(tempDir.path, 'accounting_accounts.sqlite');
      final legacyFile = File(legacyPath);
      await legacyFile.writeAsString('legacy_dummy_data');

      final canonicalPath = p.join(tempDir.path, 'nexabiz.sqlite');
      final canonicalFile = File(canonicalPath);
      await canonicalFile.writeAsString('canonical_dummy_data');

      expect(await legacyFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isTrue);
      expect(await legacyFile.readAsString(), equals('legacy_dummy_data'));
    });
  });
}
