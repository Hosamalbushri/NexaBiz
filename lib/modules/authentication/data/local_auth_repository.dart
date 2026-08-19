import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/sync_api_config.dart';
import '../domain/entities/auth_session.dart';
import '../domain/local_permissions.dart';
import '../domain/repositories/auth_repository.dart';
import 'local_auth_store.dart';
import 'secure_token_storage.dart';

/// Fully offline authentication against the local Hive identity store.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required LocalAuthStore store,
    required SecureTokenStorage tokenStorage,
    required SyncApiConfig Function() readConfig,
    void Function(SyncApiConfig config)? onConfigChanged,
  }) : _store = store,
       _tokenStorage = tokenStorage,
       _readConfig = readConfig,
       _onConfigChanged = onConfigChanged;

  final LocalAuthStore _store;
  final SecureTokenStorage _tokenStorage;
  final SyncApiConfig Function() _readConfig;
  final void Function(SyncApiConfig config)? _onConfigChanged;
  final _sessionController = StreamController<AuthSessionSnapshot?>.broadcast();

  AuthSessionSnapshot? _cached;

  Future<void> ensureReady() => _store.ensureSeeded();

  @override
  Stream<AuthSessionSnapshot?> watchSession() => _sessionController.stream;

  @override
  Future<String?> readAccessToken() => _tokenStorage.readAccessToken();

  void _emit(AuthSessionSnapshot? snapshot) {
    _cached = snapshot;
    if (!_sessionController.isClosed) {
      _sessionController.add(snapshot);
    }
  }

  void _applyConfig(AuthSessionSnapshot snapshot) {
    final current = _readConfig();
    _onConfigChanged?.call(
      current.copyWith(
        companyId: snapshot.currentCompanyId ?? current.companyId,
        userId: snapshot.user.id,
        deviceId: snapshot.deviceId ?? current.deviceId,
      ),
    );
  }

  @override
  Future<AuthSessionSnapshot?> restoreSession() async {
    await _store.ensureSeeded();
    final snapshot = await _store.loadSession();
    if (snapshot == null) {
      _emit(null);
      return null;
    }
    _applyConfig(snapshot);
    _emit(snapshot);
    return snapshot;
  }

  @override
  Future<AuthSessionSnapshot> login({
    required String email,
    required String password,
    String? companyId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  }) async {
    final snapshot = await _store.login(
      email: email,
      password: password,
      deviceId: deviceId,
      companyId: companyId ?? LocalAuthDefaults.companyId,
    );
    if (snapshot == null) {
      throw const AuthenticationFailure('Invalid email or password');
    }
    // Local opaque session marker (not a remote JWT).
    await _tokenStorage.saveTokens(
      accessToken: 'local:${snapshot.sessionId}',
      refreshToken: 'local-refresh:${snapshot.sessionId}',
      expiresInSeconds: 60 * 60 * 24 * 365,
    );
    _applyConfig(snapshot);
    _emit(snapshot);
    return snapshot;
  }

  @override
  Future<AuthSessionSnapshot> refreshSession() async {
    final existing = _cached ?? await _store.loadSession();
    if (existing == null) {
      throw const AuthenticationFailure('No local session');
    }
    return existing;
  }

  @override
  Future<AuthSessionSnapshot> fetchMe() async {
    final existing = _cached ?? await _store.loadSession();
    if (existing == null) {
      throw const AuthenticationFailure('No local session');
    }
    _emit(existing);
    return existing;
  }

  @override
  Future<AuthSessionSnapshot> switchCompany(String companyId) async {
    final current = _cached ?? await _store.loadSession();
    if (current == null) {
      throw const AuthenticationFailure('No local session');
    }
    final next = await _store.switchCompany(
      current: current,
      companyId: companyId,
    );
    if (next == null) {
      throw const AuthenticationFailure('Company not available');
    }
    _applyConfig(next);
    _emit(next);
    return next;
  }

  @override
  Future<void> logout({bool clearLocalBusinessData = false}) async {
    await _tokenStorage.clear();
    await _store.saveSession(null);
    _emit(null);
  }

  @override
  Future<void> registerDevice({
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  }) async {
    // Local-only: device id already bound on the session snapshot.
  }

  Future<AuthSessionSnapshot> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final snapshot = await _store.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _emit(snapshot);
    return snapshot;
  }

  void dispose() {
    _sessionController.close();
  }
}
