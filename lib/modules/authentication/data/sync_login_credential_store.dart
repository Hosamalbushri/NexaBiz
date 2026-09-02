import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/authentication_mode.dart';

/// Opt-in biometric token store.
///
/// Plaintext passwords MUST NOT be stored. Biometric authentication uses
/// an OS-protected biometric secret token (`biometricToken`) stored in encrypted secure storage.
class SyncLoginCredentialStore {
  SyncLoginCredentialStore({FlutterSecureStorage? secureStorage})
    : _secure =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _syncEmailKey = 'sync_login_email';
  static const _syncBiometricTokenKey = 'sync_login_biometric_token';
  static const _syncEnabledKey = 'sync_login_biometric_enabled';
  static const _syncServerContextKey = 'sync_login_server_context';

  static const _localEmailKey = 'local_login_email';
  static const _localBiometricTokenKey = 'local_login_biometric_token';
  static const _localEnabledKey = 'local_login_biometric_enabled';

  // Legacy keys retained strictly for automated cleanup/migration
  static const _legacySyncPasswordKey = 'sync_login_password';
  static const _legacyLocalPasswordKey = 'local_login_password';

  final FlutterSecureStorage _secure;

  bool _resolveIsSyncMode(AuthenticationMode? mode, bool? isSyncMode) {
    if (mode != null) return mode.isSync;
    return isSyncMode ?? true;
  }

  String _emailKey(bool isSyncMode) =>
      isSyncMode ? _syncEmailKey : _localEmailKey;
  String _biometricTokenKey(bool isSyncMode) =>
      isSyncMode ? _syncBiometricTokenKey : _localBiometricTokenKey;
  String _enabledKey(bool isSyncMode) =>
      isSyncMode ? _syncEnabledKey : _localEnabledKey;

  Future<bool> isBiometricLoginEnabled({
    AuthenticationMode? mode,
    bool? isSyncMode,
    String? serverContext,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    try {
      if (isSync && serverContext != null && serverContext.isNotEmpty) {
        final savedContext = await _secure.read(key: _syncServerContextKey);
        if (savedContext != serverContext) {
          return false;
        }
      }
      return await _secure.read(key: _enabledKey(isSync)) == 'true';
    } catch (_) {
      debugPrint('SyncLoginCredentialStore: failed reading enabled flag');
      return false;
    }
  }

  Future<bool> hasSavedCredentials({
    AuthenticationMode? mode,
    bool? isSyncMode,
    String? serverContext,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    if (!await isBiometricLoginEnabled(isSyncMode: isSync, serverContext: serverContext)) {
      return false;
    }
    final email = await readEmail(isSyncMode: isSync);
    final token = await readBiometricToken(isSyncMode: isSync);
    return email != null &&
        email.isNotEmpty &&
        token != null &&
        token.isNotEmpty;
  }

  Future<String?> readEmail({
    AuthenticationMode? mode,
    bool? isSyncMode,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    try {
      final value = await _secure.read(key: _emailKey(isSync));
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } catch (_) {
      debugPrint('SyncLoginCredentialStore: failed reading saved email');
      return null;
    }
  }

  /// Reads stored biometric authentication token. Never returns raw passwords.
  Future<String?> readBiometricToken({
    AuthenticationMode? mode,
    bool? isSyncMode,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    try {
      // Purge any legacy plaintext passwords if found
      await _purgeLegacyPasswords();
      final value = await _secure.read(key: _biometricTokenKey(isSync));
      if (value == null || value.isEmpty) return null;
      return value;
    } catch (_) {
      debugPrint('SyncLoginCredentialStore: failed reading biometric token');
      return null;
    }
  }

  /// Persists biometric credentials with OS-protected secret token.
  /// Passwords MUST NOT be passed or stored.
  Future<void> saveBiometricCredentials({
    required String email,
    required String biometricToken,
    AuthenticationMode? mode,
    bool? isSyncMode,
    String? serverContext,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || biometricToken.isEmpty) {
      await clear(isSyncMode: isSync);
      return;
    }
    await _purgeLegacyPasswords();
    await _secure.write(key: _emailKey(isSync), value: trimmedEmail);
    await _secure.write(key: _biometricTokenKey(isSync), value: biometricToken);
    await _secure.write(key: _enabledKey(isSync), value: 'true');
    if (isSync && serverContext != null && serverContext.isNotEmpty) {
      await _secure.write(key: _syncServerContextKey, value: serverContext);
    }
  }

  Future<void> setBiometricEnabled({
    required bool enabled,
    AuthenticationMode? mode,
    bool? isSyncMode,
    String? serverContext,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    await _secure.write(
      key: _enabledKey(isSync),
      value: enabled ? 'true' : 'false',
    );
    if (!enabled) {
      await _secure.delete(key: _biometricTokenKey(isSync));
    }
    if (isSync && serverContext != null && serverContext.isNotEmpty) {
      await _secure.write(key: _syncServerContextKey, value: serverContext);
    }
  }

  Future<void> clear({
    AuthenticationMode? mode,
    bool? isSyncMode,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    try {
      await _secure.delete(key: _emailKey(isSync));
      await _secure.delete(key: _biometricTokenKey(isSync));
      await _secure.delete(key: _enabledKey(isSync));
      await _purgeLegacyPasswords();
      if (isSync) {
        await _secure.delete(key: _syncServerContextKey);
      }
    } catch (_) {
      debugPrint('SyncLoginCredentialStore: clear failed');
    }
  }

  Future<void> clearAll() async {
    await clear(isSyncMode: true);
    await clear(isSyncMode: false);
  }

  Future<void> _purgeLegacyPasswords() async {
    try {
      await _secure.delete(key: _legacySyncPasswordKey);
      await _secure.delete(key: _legacyLocalPasswordKey);
    } catch (_) {}
  }
}

