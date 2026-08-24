import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Opt-in credentials unlocked by device biometrics.
///
/// Password is stored only in encrypted secure storage after the user enables
/// fingerprint sign-in. Supports mode-specific keys (Local Mode vs Sync Mode).
class SyncLoginCredentialStore {
  SyncLoginCredentialStore({FlutterSecureStorage? secureStorage})
    : _secure =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _syncEmailKey = 'sync_login_email';
  static const _syncPasswordKey = 'sync_login_password';
  static const _syncEnabledKey = 'sync_login_biometric_enabled';

  static const _localEmailKey = 'local_login_email';
  static const _localPasswordKey = 'local_login_password';
  static const _localEnabledKey = 'local_login_biometric_enabled';

  final FlutterSecureStorage _secure;

  String _emailKey(bool isSyncMode) =>
      isSyncMode ? _syncEmailKey : _localEmailKey;
  String _passwordKey(bool isSyncMode) =>
      isSyncMode ? _syncPasswordKey : _localPasswordKey;
  String _enabledKey(bool isSyncMode) =>
      isSyncMode ? _syncEnabledKey : _localEnabledKey;

  Future<bool> isBiometricLoginEnabled({bool isSyncMode = true}) async {
    try {
      return await _secure.read(key: _enabledKey(isSyncMode)) == 'true';
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore read enabled failed: $e\n$st');
      return false;
    }
  }

  Future<bool> hasSavedCredentials({bool isSyncMode = true}) async {
    if (!await isBiometricLoginEnabled(isSyncMode: isSyncMode)) return false;
    final email = await readEmail(isSyncMode: isSyncMode);
    final password = await readPassword(isSyncMode: isSyncMode);
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  Future<String?> readEmail({bool isSyncMode = true}) async {
    try {
      final value = await _secure.read(key: _emailKey(isSyncMode));
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore read email failed: $e\n$st');
      return null;
    }
  }

  Future<String?> readPassword({bool isSyncMode = true}) async {
    try {
      final value = await _secure.read(key: _passwordKey(isSyncMode));
      if (value == null || value.isEmpty) return null;
      return value;
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore read password failed: $e\n$st');
      return null;
    }
  }

  Future<void> saveCredentials({
    required String email,
    required String password,
    bool isSyncMode = true,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      await clear(isSyncMode: isSyncMode);
      return;
    }
    await _secure.write(key: _emailKey(isSyncMode), value: trimmedEmail);
    await _secure.write(key: _passwordKey(isSyncMode), value: password);
    await _secure.write(key: _enabledKey(isSyncMode), value: 'true');
  }

  Future<void> setBiometricEnabled({
    required bool enabled,
    bool isSyncMode = true,
  }) async {
    await _secure.write(
      key: _enabledKey(isSyncMode),
      value: enabled ? 'true' : 'false',
    );
  }

  Future<void> clear({bool isSyncMode = true}) async {
    try {
      await _secure.delete(key: _emailKey(isSyncMode));
      await _secure.delete(key: _passwordKey(isSyncMode));
      await _secure.delete(key: _enabledKey(isSyncMode));
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore clear failed: $e\n$st');
    }
  }

  Future<void> clearAll() async {
    await clear(isSyncMode: true);
    await clear(isSyncMode: false);
  }
}
