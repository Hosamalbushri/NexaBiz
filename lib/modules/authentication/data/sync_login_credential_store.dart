import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Opt-in sync login credentials unlocked by device biometrics.
///
/// Password is stored only in encrypted secure storage after the user enables
/// fingerprint sign-in. Cleared when sync is disabled or credentials fail.
class SyncLoginCredentialStore {
  SyncLoginCredentialStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _emailKey = 'sync_login_email';
  static const _passwordKey = 'sync_login_password';
  static const _enabledKey = 'sync_login_biometric_enabled';

  final FlutterSecureStorage _secure;

  Future<bool> isBiometricLoginEnabled() async {
    try {
      return await _secure.read(key: _enabledKey) == 'true';
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore read enabled failed: $e\n$st');
      return false;
    }
  }

  Future<bool> hasSavedCredentials() async {
    if (!await isBiometricLoginEnabled()) return false;
    final email = await readEmail();
    final password = await readPassword();
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  Future<String?> readEmail() async {
    try {
      final value = await _secure.read(key: _emailKey);
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore read email failed: $e\n$st');
      return null;
    }
  }

  Future<String?> readPassword() async {
    try {
      final value = await _secure.read(key: _passwordKey);
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
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      await clear();
      return;
    }
    await _secure.write(key: _emailKey, value: trimmedEmail);
    await _secure.write(key: _passwordKey, value: password);
    await _secure.write(key: _enabledKey, value: 'true');
  }

  Future<void> clear() async {
    try {
      await _secure.delete(key: _emailKey);
      await _secure.delete(key: _passwordKey);
      await _secure.delete(key: _enabledKey);
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore clear failed: $e\n$st');
    }
  }
}
