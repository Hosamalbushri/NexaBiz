import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists a passphrase seed for Drift / SQLite3MultipleCiphers.
///
/// Separate from [HiveEncryptionKeyStore] so Hive and Drift keys can rotate
/// independently. The raw bytes are base64url-encoded before use as SQLCipher
/// passphrase (see [EncryptedDriftConnection]).
class DriftEncryptionKeyStore {
  DriftEncryptionKeyStore({
    FlutterSecureStorage? secureStorage,
    this._fixedKeyForTests,
  }) : _secure =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  static const storageKey = 'drift_sqlcipher_key_v1';
  static const _fallbackBoxName = 'hive_key_fallback';

  final FlutterSecureStorage _secure;
  final Uint8List? _fixedKeyForTests;
  bool? _secureAvailable;

  /// Test override — when set, [getOrCreateKey] returns this without I/O.
  static Uint8List? debugFixedKey;

  Future<bool> _canUseSecure() async {
    if (_secureAvailable != null) {
      return _secureAvailable!;
    }
    try {
      await _secure.read(key: '__drift_key_probe__');
      _secureAvailable = true;
    } catch (e, st) {
      debugPrint('DriftEncryptionKeyStore: secure storage unavailable ($e)');
      debugPrintStack(stackTrace: st);
      _secureAvailable = false;
    }
    return _secureAvailable!;
  }

  Future<Box<String>> _fallbackBox() async {
    if (Hive.isBoxOpen(_fallbackBoxName)) {
      return Hive.box<String>(_fallbackBoxName);
    }
    return Hive.openBox<String>(_fallbackBoxName);
  }

  /// Returns 32 raw bytes used as the encryption passphrase seed.
  Future<Uint8List> getOrCreateKey() async {
    final fixed = _fixedKeyForTests ?? debugFixedKey;
    if (fixed != null) {
      if (fixed.length != 32) {
        throw ArgumentError('Drift SQLCipher key seed must be 32 bytes');
      }
      return Uint8List.fromList(fixed);
    }

    if (await _canUseSecure()) {
      final existing = await _secure.read(key: storageKey);
      if (existing != null && existing.isNotEmpty) {
        return Uint8List.fromList(base64Url.decode(existing));
      }
      final key = _generateKey();
      await _secure.write(key: storageKey, value: base64UrlEncode(key));
      return key;
    }

    final box = await _fallbackBox();
    final existing = box.get(storageKey);
    if (existing != null && existing.isNotEmpty) {
      return Uint8List.fromList(base64Url.decode(existing));
    }
    final key = _generateKey();
    await box.put(storageKey, base64UrlEncode(key));
    return key;
  }

  Uint8List _generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  /// Test helper — clears persisted key material.
  Future<void> clearForTests() async {
    debugFixedKey = null;
    try {
      await _secure.delete(key: storageKey);
    } catch (_) {}
    if (Hive.isBoxOpen(_fallbackBoxName) ||
        await Hive.boxExists(_fallbackBoxName)) {
      final box = await _fallbackBox();
      await box.delete(storageKey);
    }
  }
}
