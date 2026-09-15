import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Hive.init('/tmp/hive_test_db');
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '/tmp/hive_test_db',
    );
  });

  test('GATE-07 SQLite PRAGMA Inspection', () async {
    final db = NexabizDatabase();

    print('\n==================== SQLITE PRAGMA RESULTS ====================');
    
    print('\n--- PRAGMA foreign_keys ---');
    final fkEnabled = await db.customSelect('PRAGMA foreign_keys;').get();
    for (final row in fkEnabled) {
      print(row.data);
    }

    print('\n--- PRAGMA table_info(financial_accounts) ---');
    final tableInfo = await db.customSelect('PRAGMA table_info(financial_accounts);').get();
    for (final row in tableInfo) {
      print(row.data);
    }

    print('\n--- PRAGMA foreign_key_list(financial_accounts) ---');
    final fkList = await db.customSelect('PRAGMA foreign_key_list(financial_accounts);').get();
    for (final row in fkList) {
      print(row.data);
    }
    if (fkList.isEmpty) {
      print('(No physical FK constraints on financial_accounts table)');
    }

    print('\n--- PRAGMA index_list(financial_accounts) ---');
    final indexList = await db.customSelect('PRAGMA index_list(financial_accounts);').get();
    for (final row in indexList) {
      print(row.data);
      final indexName = row.data['name'] as String;
      final indexInfo = await db.customSelect("PRAGMA index_info('$indexName');").get();
      print('   -> PRAGMA index_info($indexName):');
      for (final infoRow in indexInfo) {
        print('      ${infoRow.data}');
      }

    }
    print('===============================================================\n');


    await db.close();
  });
}
