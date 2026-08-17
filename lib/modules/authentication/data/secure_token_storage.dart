import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/encrypted_hive_box.dart';
import '../../../core/database/hive_boxes.dart';
import '../../../core/network/token_store.dart';

/// Token store: prefers [FlutterSecureStorage], falls back to a private Hive box
/// when the secure-storage plugin is unavailable (e.g. hot-restart after add).
///
/// Passwords are never stored. Tokens are never written to SharedPreferences
/// or the general settings Hive box. The Hive fallback is AES-encrypted.
class SecureTokenStorage implements TokenStore {
  SecureTokenStorage({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_access_expires_at';

  final FlutterSecureStorage _secure;
  bool? _secureAvailable;

  Future<bool> _canUseSecure() async {
    if (_secureAvailable != null) return _secureAvailable!;
    try {
      await _secure.read(key: '__probe__');
      _secureAvailable = true;
    } catch (e, st) {
      debugPrint('SecureTokenStorage: falling back to Hive ($e)');
      debugPrintStack(stackTrace: st);
      _secureAvailable = false;
    }
    return _secureAvailable!;
  }

  Future<Box<String>> _hiveBox() async {
    if (Hive.isBoxOpen(HiveBoxes.authTokenStoreEncrypted)) {
      return Hive.box<String>(HiveBoxes.authTokenStoreEncrypted);
    }
    return EncryptedHive.openMigrated<String>(
      encryptedBoxName: HiveBoxes.authTokenStoreEncrypted,
      legacyPlainBoxName: HiveBoxes.authTokenStore,
    );
  }

  Future<bool> _hiveFallbackExists() async {
    return Hive.isBoxOpen(HiveBoxes.authTokenStoreEncrypted) ||
        await Hive.boxExists(HiveBoxes.authTokenStoreEncrypted) ||
        Hive.isBoxOpen(HiveBoxes.authTokenStore) ||
        await Hive.boxExists(HiveBoxes.authTokenStore);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    final expiresAt = DateTime.now()
        .toUtc()
        .add(Duration(seconds: expiresInSeconds))
        .toIso8601String();
    if (await _canUseSecure()) {
      await _secure.write(key: _accessKey, value: accessToken);
      await _secure.write(key: _refreshKey, value: refreshToken);
      await _secure.write(key: _expiresAtKey, value: expiresAt);
      // Clear any legacy Hive copy so tokens are not duplicated.
      if (await _hiveFallbackExists()) {
        final box = await _hiveBox();
        await box.clear();
      }
      return;
    }
    final box = await _hiveBox();
    await box.put(_accessKey, accessToken);
    await box.put(_refreshKey, refreshToken);
    await box.put(_expiresAtKey, expiresAt);
  }

  @override
  Future<String?> readAccessToken() async {
    if (await _canUseSecure()) {
      return _secure.read(key: _accessKey);
    }
    return (await _hiveBox()).get(_accessKey);
  }

  @override
  Future<String?> readRefreshToken() async {
    if (await _canUseSecure()) {
      return _secure.read(key: _refreshKey);
    }
    return (await _hiveBox()).get(_refreshKey);
  }

  @override
  Future<DateTime?> readAccessExpiresAt() async {
    final raw = await _canUseSecure()
        ? await _secure.read(key: _expiresAtKey)
        : (await _hiveBox()).get(_expiresAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> clear() async {
    if (await _canUseSecure()) {
      await _secure.delete(key: _accessKey);
      await _secure.delete(key: _refreshKey);
      await _secure.delete(key: _expiresAtKey);
    }
    if (await _hiveFallbackExists()) {
      final box = await _hiveBox();
      await box.delete(_accessKey);
      await box.delete(_refreshKey);
      await box.delete(_expiresAtKey);
    }
  }
}
