import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

void main() {
  test('SQLite PRAGMA and Schema Audit', () async {
    final db = NexabizDatabase.memory();
    
    // Trigger initialization
    await db.customSelect('SELECT 1').get();

    final fk = await db.customSelect('PRAGMA foreign_keys;').get();
    print('--- PRAGMA foreign_keys ---');
    for (final row in fk) {
      print(row.data);
    }

    final uv = await db.customSelect('PRAGMA user_version;').get();
    print('--- PRAGMA user_version ---');
    for (final row in uv) {
      print(row.data);
    }

    final tables = await db.customSelect("SELECT name, type FROM sqlite_master WHERE type IN ('table','index') ORDER BY type, name;").get();
    print('--- sqlite_master (tables and indexes) ---');
    for (final row in tables) {
      print('${row.data['type']}: ${row.data['name']}');
    }

    print('--- PRAGMA table_info(users) ---');
    final usersInfo = await db.customSelect('PRAGMA table_info(users);').get();
    for (final row in usersInfo) {
      print(row.data);
    }

    print('--- PRAGMA table_info(companies) ---');
    final compInfo = await db.customSelect('PRAGMA table_info(companies);').get();
    for (final row in compInfo) {
      print(row.data);
    }

    print('--- PRAGMA table_info(company_memberships) ---');
    final memInfo = await db.customSelect('PRAGMA table_info(company_memberships);').get();
    for (final row in memInfo) {
      print(row.data);
    }

    print('--- PRAGMA table_info(system_setup_state) ---');
    final setupInfo = await db.customSelect('PRAGMA table_info(system_setup_state);').get();
    for (final row in setupInfo) {
      print(row.data);
    }

    print('--- PRAGMA foreign_key_list(users) ---');
    final fkUsers = await db.customSelect('PRAGMA foreign_key_list(users);').get();
    for (final row in fkUsers) {
      print(row.data);
    }

    print('--- PRAGMA foreign_key_list(companies) ---');
    final fkComp = await db.customSelect('PRAGMA foreign_key_list(companies);').get();
    for (final row in fkComp) {
      print(row.data);
    }

    print('--- PRAGMA foreign_key_list(company_memberships) ---');
    final fkMem = await db.customSelect('PRAGMA foreign_key_list(company_memberships);').get();
    for (final row in fkMem) {
      print(row.data);
    }

    print('--- PRAGMA index_list(users) ---');
    final idxUsers = await db.customSelect('PRAGMA index_list(users);').get();
    for (final row in idxUsers) {
      print(row.data);
    }

    print('--- PRAGMA index_list(companies) ---');
    final idxComp = await db.customSelect('PRAGMA index_list(companies);').get();
    for (final row in idxComp) {
      print(row.data);
    }

    print('--- PRAGMA index_list(company_memberships) ---');
    final idxMem = await db.customSelect('PRAGMA index_list(company_memberships);').get();
    for (final row in idxMem) {
      print(row.data);
    }

    await db.close();
  });
}
