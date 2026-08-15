import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/token_store.dart';

/// Stores access/refresh tokens outside ordinary Hive boxes.
class SecureTokenStorage implements TokenStore {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _expiresAtKey = 'auth_access_expires_at';

  final FlutterSecureStorage _storage;

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
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(key: _expiresAtKey, value: expiresAt);
  }

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<DateTime?> readAccessExpiresAt() async {
    final raw = await _storage.read(key: _expiresAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
