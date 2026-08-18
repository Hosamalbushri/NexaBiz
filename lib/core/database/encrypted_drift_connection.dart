import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import 'drift_encryption_key_store.dart';

/// Opens `$name.sqlite` under the app documents directory.
///
/// When SQLite3MultipleCiphers is linked (via pub `hooks`), the file is
/// encrypted with a device key from [DriftEncryptionKeyStore]. Existing
/// plaintext databases from older builds are migrated on first open.
QueryExecutor encryptedDriftDatabase({required String name}) {
  if (kIsWeb) {
    return driftDatabase(name: name);
  }

  return DatabaseConnection.delayed(
    Future(() async {
      final dbPath = await _databasePath(name);
      if (!isDriftCipherAvailable()) {
        if (kDebugMode) {
          debugPrint(
            'EncryptedDriftConnection: cipher unavailable — opening $name '
            'without SQLCipher (configure pub hooks sqlite3: sqlite3mc).',
          );
        }
        return NativeDatabase.createBackgroundConnection(File(dbPath));
      }

      final keySeed = await DriftEncryptionKeyStore().getOrCreateKey();
      final escapedKey = escapeSqlString(base64UrlEncode(keySeed));
      await _migratePlaintextIfNeeded(dbPath: dbPath, escapedKey: escapedKey);

      return NativeDatabase.createBackgroundConnection(
        File(dbPath),
        setup: (db) {
          assert(
            debugCheckHasCipher(db),
            'SQLite3MultipleCiphers not linked — check pubspec hooks',
          );
          db.execute("PRAGMA key = '$escapedKey';");
        },
      );
    }),
  );
}

/// Whether the linked `sqlite3` build exposes encryption (`PRAGMA cipher`).
bool isDriftCipherAvailable() {
  if (kIsWeb) {
    return false;
  }
  final db = sqlite3.openInMemory();
  try {
    return debugCheckHasCipher(db);
  } finally {
    db.close();
  }
}

bool debugCheckHasCipher(CommonDatabase database) {
  return database.select('PRAGMA cipher;').isNotEmpty;
}

String escapeSqlString(String source) {
  return source.replaceAll("'", "''");
}

Future<String> _databasePath(String name) async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, '$name.sqlite');
}

Future<void> _migratePlaintextIfNeeded({
  required String dbPath,
  required String escapedKey,
}) async {
  final file = File(dbPath);
  if (!await file.exists()) {
    return;
  }

  if (await _opensWithEncryption(dbPath, escapedKey)) {
    return;
  }

  if (!await _isPlaintextDatabase(dbPath)) {
    return;
  }

  final tmp = File('$dbPath.migrate.tmp');
  if (await tmp.exists()) {
    await tmp.delete();
  }

  final plaintext = sqlite3.open(dbPath);
  try {
    plaintext.execute("VACUUM INTO '${escapeSqlString(tmp.path)}';");
  } finally {
    plaintext.close();
  }

  final encrypted = sqlite3.open(tmp.path);
  try {
    encrypted.execute("PRAGMA rekey = '$escapedKey';");
  } finally {
    encrypted.close();
  }

  await file.delete();
  await tmp.rename(dbPath);
}

Future<bool> _opensWithEncryption(String dbPath, String escapedKey) async {
  final db = sqlite3.open(dbPath);
  try {
    if (!debugCheckHasCipher(db)) {
      return false;
    }
    db.execute("PRAGMA key = '$escapedKey';");
    db.select('SELECT count(*) FROM sqlite_master');
    return true;
  } catch (_) {
    return false;
  } finally {
    db.close();
  }
}

Future<bool> _isPlaintextDatabase(String dbPath) async {
  final db = sqlite3.open(dbPath);
  try {
    db.select('SELECT count(*) FROM sqlite_master');
    return true;
  } catch (_) {
    return false;
  } finally {
    db.close();
  }
}
