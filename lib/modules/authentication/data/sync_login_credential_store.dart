import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entities/authentication_mode.dart';

/// Opt-in credentials unlocked by device biometrics.
///
/// Password is stored only in encrypted secure storage after the user enables
/// fingerprint sign-in. Supports mode-specific keys (Local Mode vs Sync Mode)
/// and server/account context association.
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
  static const _syncServerContextKey = 'sync_login_server_context';

  static const _localEmailKey = 'local_login_email';
  static const _localPasswordKey = 'local_login_password';
  static const _localEnabledKey = 'local_login_biometric_enabled';

  final FlutterSecureStorage _secure;

  bool _resolveIsSyncMode(AuthenticationMode? mode, bool? isSyncMode) {
    if (mode != null) return mode.isSync;
    return isSyncMode ?? true;
  }

  String _emailKey(bool isSyncMode) =>
      isSyncMode ? _syncEmailKey : _localEmailKey;
  String _passwordKey(bool isSyncMode) =>
      isSyncMode ? _syncPasswordKey : _localPasswordKey;
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
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore read enabled failed: $e\n$st');
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
    final password = await readPassword(isSyncMode: isSync);
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
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
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore read email failed: $e\n$st');
      return null;
    }
  }

  Future<String?> readPassword({
    AuthenticationMode? mode,
    bool? isSyncMode,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    try {
      final value = await _secure.read(key: _passwordKey(isSync));
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
    AuthenticationMode? mode,
    bool? isSyncMode,
    String? serverContext,
  }) async {
    final isSync = _resolveIsSyncMode(mode, isSyncMode);
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      await clear(isSyncMode: isSync);
      return;
    }
    await _secure.write(key: _emailKey(isSync), value: trimmedEmail);
    await _secure.write(key: _passwordKey(isSync), value: password);
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
      await _secure.delete(key: _passwordKey(isSync));
      await _secure.delete(key: _enabledKey(isSync));
      if (isSync) {
        await _secure.delete(key: _syncServerContextKey);
      }
    } catch (e, st) {
      debugPrint('SyncLoginCredentialStore clear failed: $e\n$st');
    }
  }

  Future<void> clearAll() async {
    await clear(isSyncMode: true);
    await clear(isSyncMode: false);
  }
}
