import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists a 256-bit AES key for [HiveAesCipher] in secure storage.
///
/// Falls back to a private Hive box when secure storage is unavailable
/// (same degraded path as [SecureTokenStorage]).
class HiveEncryptionKeyStore {
  HiveEncryptionKeyStore({
    FlutterSecureStorage? secureStorage,
    this._fixedKeyForTests,
  }) : _secure =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  static const storageKey = 'hive_aes_encryption_key_v1';
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
      await _secure.read(key: '__hive_key_probe__');
      _secureAvailable = true;
    } catch (e, st) {
      debugPrint('HiveEncryptionKeyStore: secure storage unavailable ($e)');
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

  /// Returns 32 raw bytes for [HiveAesCipher]. Creates + persists if missing.
  Future<Uint8List> getOrCreateKey() async {
    final fixed = _fixedKeyForTests ?? debugFixedKey;
    if (fixed != null) {
      if (fixed.length != 32) {
        throw ArgumentError('Hive AES key must be 32 bytes');
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
