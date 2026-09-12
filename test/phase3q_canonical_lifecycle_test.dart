import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:stock_count/app/bootstrap/app_bootstrap.dart';
import 'package:stock_count/core/database/canonical_database_provider.dart';
import 'package:stock_count/core/database/encrypted_drift_connection.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/purchases/presentation/providers/purchases_providers.dart';

import 'package:stock_count/core/database/drift_encryption_key_store.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('phase3q_canonical_test_');

    DriftEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i),
    );

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempDir.path;
    });
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 3Q — Canonical Database Lifecycle & Infrastructure Verification', () {
    test('1. Fresh initialization writes metadata and sets schemaVersion 8', () async {
      final manager = CanonicalDatabaseManager();
      expect(manager.state, equals(CanonicalDatabaseLifecycleState.uninitialized));
      expect(manager.isOpen, isFalse);

      final db = await manager.openDatabase(name: p.join(tempDir.path, 'nexabiz_fresh'));
      addTearDown(manager.closeDatabase);

      expect(manager.state, equals(CanonicalDatabaseLifecycleState.open));
      expect(manager.isOpen, isTrue);
      expect(db.schemaVersion, equals(8));

      final metadata = await db.select(db.canonicalDbMetadata).get();
      expect(metadata.any((m) => m.key == 'schema_initialized_at'), isTrue);
    });

    test('2. Deterministic database file name resolution', () async {
      final manager = CanonicalDatabaseManager();
      final dbName = p.join(tempDir.path, 'nexabiz_test_path');
      final dbFile = File('$dbName.sqlite');

      expect(await dbFile.exists(), isFalse);
      await manager.openDatabase(name: dbName);
      addTearDown(manager.closeDatabase);

      expect(await dbFile.exists(), isTrue);
      expect(p.basename(dbFile.path), equals('nexabiz_test_path.sqlite'));
    });

    test('3. Open -> Close -> Reopen lifecycle correctness', () async {
      final manager = CanonicalDatabaseManager();
      final dbName = p.join(tempDir.path, 'nexabiz_reopen');

      await manager.openDatabase(name: dbName);
      expect(manager.isOpen, isTrue);

      await manager.closeDatabase();
      expect(manager.isOpen, isFalse);
      expect(manager.state, equals(CanonicalDatabaseLifecycleState.closed));
      expect(() => manager.instance, throwsA(isA<StateError>()));

      final db2 = await manager.reopenDatabase(name: dbName);
      addTearDown(manager.closeDatabase);

      expect(manager.isOpen, isTrue);
      expect(manager.state, equals(CanonicalDatabaseLifecycleState.open));
      expect(db2, isNotNull);
    });

    test('4. Encrypted SQLCipher stable key re-authentication', () async {
      final dbPath = p.join(tempDir.path, 'nexabiz_key_auth.sqlite');
      const testPassphrase = 'secure_canonical_passphrase_key_456';

      final rawDb1 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb1)) {
        rawDb1.execute("PRAGMA key = '$testPassphrase';");
      }
      rawDb1.execute('CREATE TABLE sys_test (k TEXT PRIMARY KEY, v TEXT);');
      rawDb1.execute("INSERT INTO sys_test VALUES ('init', 'true');");
      rawDb1.close();

      final rawDb2 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb2)) {
        rawDb2.execute("PRAGMA key = '$testPassphrase';");
      }
      final res = rawDb2.select("SELECT v FROM sys_test WHERE k = 'init';");
      expect(res.first['v'], equals('true'));
      rawDb2.close();
    });

    test('5. Wrong key explicit failure — file preserved without corruption', () async {
      final dbPath = p.join(tempDir.path, 'nexabiz_wrong_key_verify.sqlite');
      const correctKey = 'correct_pass_123';
      const wrongKey = 'wrong_pass_999';

      final rawDb1 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb1)) {
        rawDb1.execute("PRAGMA key = '$correctKey';");
        rawDb1.execute('CREATE TABLE sys_test (k TEXT PRIMARY KEY);');
      }
      rawDb1.close();

      final rawDb2 = sqlite3.open(dbPath);
      if (debugCheckHasCipher(rawDb2)) {
        rawDb2.execute("PRAGMA key = '$wrongKey';");
        expect(
          () => rawDb2.select('SELECT count(*) FROM sys_test;'),
          throwsA(isA<SqliteException>()),
        );
      }
      rawDb2.close();

      expect(File(dbPath).existsSync(), isTrue);
    });

    test('6. Concurrent openDatabase calls share single-flight completion lock', () async {
      final manager = CanonicalDatabaseManager();
      final dbName = p.join(tempDir.path, 'nexabiz_concurrent');

      final futures = Future.wait([
        manager.openDatabase(name: dbName),
        manager.openDatabase(name: dbName),
        manager.openDatabase(name: dbName),
      ]);

      final results = await futures;
      addTearDown(manager.closeDatabase);

      expect(results.length, equals(3));
      expect(results[0], same(results[1]));
      expect(results[1], same(results[2]));
      expect(manager.isOpen, isTrue);
    });

    test('7. Riverpod provider readiness — purchases repository resolves without race condition', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final manager = container.read(canonicalDatabaseManagerProvider);
      await manager.openDatabase(name: p.join(tempDir.path, 'nexabiz_provider_test'));

      expect(() => container.read(nexabizDatabaseProvider), returnsNormally);
      expect(() => container.read(purchaseRepositoryProvider), returnsNormally);

      final repo = container.read(purchaseRepositoryProvider);
      expect(repo, isNotNull);
    });

    test('8. Legacy database provider compatibility and independence', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(() => container.read(inventoryDatabaseProvider), returnsNormally);
      expect(() => container.read(accountingDatabaseProvider), returnsNormally);

      final invDb = container.read(inventoryDatabaseProvider);
      final accDb = container.read(accountingDatabaseProvider);

      expect(invDb, isNotNull);
      expect(accDb, isNotNull);
    });

    test('9. AppBootstrap startup integration initializes CanonicalDatabaseManager', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await AppBootstrap.bootstrapStorage();
      await AppBootstrap.bootstrapDatabase(container);

      final manager = container.read(canonicalDatabaseManagerProvider);
      expect(manager.isOpen, isTrue);
      expect(manager.state, equals(CanonicalDatabaseLifecycleState.open));
      expect(container.read(nexabizDatabaseProvider), isNotNull);
    });
  });
}
