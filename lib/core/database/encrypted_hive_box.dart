import 'package:hive_flutter/hive_flutter.dart';

import 'hive_encryption_key_store.dart';

/// Opens AES-encrypted Hive boxes and copy-migrates legacy plaintext boxes.
class EncryptedHive {
  EncryptedHive._();

  /// Opens [encryptedBoxName] with AES. If [legacyPlainBoxName] still exists,
  /// copies all entries then deletes the plaintext box from disk.
  static Future<Box<T>> openMigrated<T>({
    required String encryptedBoxName,
    required String legacyPlainBoxName,
    HiveCipher? cipher,
    HiveEncryptionKeyStore? keyStore,
  }) async {
    if (Hive.isBoxOpen(encryptedBoxName)) {
      return Hive.box<T>(encryptedBoxName);
    }

    final resolvedCipher =
        cipher ??
        HiveAesCipher(await (keyStore ?? HiveEncryptionKeyStore()).getOrCreateKey());

    final encrypted = await Hive.openBox<T>(
      encryptedBoxName,
      encryptionCipher: resolvedCipher,
    );

    if (await Hive.boxExists(legacyPlainBoxName)) {
      final Box<T> legacy;
      if (Hive.isBoxOpen(legacyPlainBoxName)) {
        legacy = Hive.box<T>(legacyPlainBoxName);
      } else {
        legacy = await Hive.openBox<T>(legacyPlainBoxName);
      }
      if (legacy.isNotEmpty && encrypted.isEmpty) {
        for (final key in legacy.keys) {
          final value = legacy.get(key);
          if (value != null) {
            await encrypted.put(key, value);
          }
        }
      }
      await legacy.deleteFromDisk();
    }

    return encrypted;
  }
}
