import 'dart:async';
import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/hive_boxes.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/authenticated_http_client.dart';
import '../../../core/network/sync_api_config.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'secure_token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthenticatedHttpClient http,
    required SecureTokenStorage tokenStorage,
    required SyncApiConfig Function() readConfig,
    void Function(SyncApiConfig config)? onConfigChanged,
  }) : _http = http,
       _tokenStorage = tokenStorage,
       _readConfig = readConfig,
       _onConfigChanged = onConfigChanged;

  static const _snapshotKey = 'auth_session_snapshot';

  final AuthenticatedHttpClient _http;
  final SecureTokenStorage _tokenStorage;
  final SyncApiConfig Function() _readConfig;
  final void Function(SyncApiConfig config)? _onConfigChanged;
  final _sessionController = StreamController<AuthSessionSnapshot?>.broadcast();

  AuthSessionSnapshot? _cached;

  @override
  Stream<AuthSessionSnapshot?> watchSession() => _sessionController.stream;

  @override
  Future<String?> readAccessToken() => _tokenStorage.readAccessToken();

  Future<Box<dynamic>> get _box async {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      return Hive.box<dynamic>(HiveBoxes.settings);
    }
    return Hive.openBox<dynamic>(HiveBoxes.settings);
  }

  Future<void> _persistSnapshot(AuthSessionSnapshot? snapshot) async {
    _cached = snapshot;
    final box = await _box;
    if (snapshot == null) {
      await box.delete(_snapshotKey);
    } else {
      await box.put(_snapshotKey, jsonEncode(snapshot.toJson()));
    }
    if (!_sessionController.isClosed) {
      _sessionController.add(snapshot);
    }
  }

  Future<AuthSessionSnapshot?> _loadSnapshot() async {
    if (_cached != null) return _cached;
    final box = await _box;
    final raw = box.get(_snapshotKey);
    if (raw is! String || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        _cached = AuthSessionSnapshot.fromJson(Map<String, dynamic>.from(map));
        return _cached;
      }
    } catch (_) {}
    return null;
  }

  void _applySessionToConfig(AuthSessionSnapshot snapshot) {
    final current = _readConfig();
    final next = current.copyWith(
      apiToken: '', // token comes from secure storage
      companyId: snapshot.currentCompanyId ?? current.companyId,
      userId: snapshot.user.id,
      deviceId: snapshot.deviceId ?? current.deviceId,
    );
    _onConfigChanged?.call(next);
    _http.updateConfig(next);
  }

  AuthSessionSnapshot _snapshotFromAuthPayload(Map<String, dynamic> data) {
    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map? ?? const {}),
    );
    final companiesRaw = data['companies'];
    final companies = <AuthCompany>[];
    if (companiesRaw is List) {
      for (final item in companiesRaw) {
        if (item is Map) {
          companies.add(AuthCompany.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final roles = <String>[
      if (data['roles'] is List)
        for (final r in data['roles'] as List)
          if (r is String) r,
    ];
    final permissions = <String>{
      if (data['permissions'] is List)
        for (final p in data['permissions'] as List)
          if (p is String) p,
    };
    final device = data['device'];
    String? deviceId;
    if (device is Map) {
      deviceId = device['device_identifier'] as String? ?? device['id'] as String?;
    }
    return AuthSessionSnapshot(
      user: user,
      companies: companies,
      roles: roles,
      permissions: permissions,
      capturedAt: DateTime.now().toUtc(),
      currentCompanyId: data['current_company_id'] as String? ??
          (data['current_company'] is Map
              ? (data['current_company'] as Map)['id'] as String?
              : null),
      deviceId: deviceId ?? _readConfig().deviceId,
      sessionId: data['session_id'] as String?,
    );
  }

  @override
  Future<AuthSessionSnapshot?> restoreSession() async {
    final snapshot = await _loadSnapshot();
    final access = await _tokenStorage.readAccessToken();
    final refresh = await _tokenStorage.readRefreshToken();
    if (snapshot == null || (access == null && refresh == null)) {
      await _persistSnapshot(null);
      return null;
    }
    _applySessionToConfig(snapshot);
    try {
      if (access != null) {
        return await fetchMe();
      }
      return await refreshSession();
    } on AuthenticationFailure {
      await logout();
      return null;
    } on NetworkFailure {
      // Offline: keep local authorization snapshot.
      return snapshot;
    }
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
    final response = await _http.postPublic(
      '/api/v1/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        if (companyId != null) 'company_id': companyId,
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        if (appVersion != null) 'app_version': appVersion,
      },
    );
    final data = _http.decodeData(response);
    await _tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresInSeconds: (data['expires_in'] as num?)?.toInt() ?? 900,
    );
    var snapshot = _snapshotFromAuthPayload(data);
    snapshot = snapshot.copyWith(deviceId: deviceId);
    _applySessionToConfig(snapshot);
    // If company not selected yet but only one company, backend may have set it.
    if (!snapshot.hasCompany && snapshot.companies.length == 1) {
      snapshot = await switchCompany(snapshot.companies.first.id);
    } else if (snapshot.hasCompany && snapshot.permissions.isEmpty) {
      snapshot = await fetchMe();
    }
    await _persistSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<AuthSessionSnapshot> refreshSession() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw const AuthenticationFailure('No refresh token');
    }
    final response = await _http.postPublic(
      '/api/v1/auth/refresh',
      body: {'refresh_token': refresh},
    );
    final data = _http.decodeData(response);
    await _tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresInSeconds: (data['expires_in'] as num?)?.toInt() ?? 900,
    );
    final existing = await _loadSnapshot();
    if (existing == null) {
      return fetchMe();
    }
    final next = existing.copyWith(
      currentCompanyId: data['current_company_id'] as String?,
      sessionId: data['session_id'] as String?,
      capturedAt: DateTime.now().toUtc(),
    );
    _applySessionToConfig(next);
    await _persistSnapshot(next);
    return next;
  }

  @override
  Future<AuthSessionSnapshot> fetchMe() async {
    final response = await _http.get('/api/v1/auth/me');
    final data = _http.decodeData(response);
    final existing = await _loadSnapshot();
    final snapshot = _snapshotFromAuthPayload({
      ...data,
      'session_id': existing?.sessionId,
      'current_company_id': data['current_company'] is Map
          ? (data['current_company'] as Map)['id']
          : existing?.currentCompanyId,
    }).copyWith(deviceId: existing?.deviceId ?? _readConfig().deviceId);
    _applySessionToConfig(snapshot);
    await _persistSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<AuthSessionSnapshot> switchCompany(String companyId) async {
    final response = await _http.post(
      '/api/v1/auth/switch-company',
      body: {'company_id': companyId},
    );
    final data = _http.decodeData(response);
    await _tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresInSeconds: (data['expires_in'] as num?)?.toInt() ?? 900,
    );
    final existing = await _loadSnapshot();
    final companies = existing?.companies ?? const <AuthCompany>[];
    final snapshot = AuthSessionSnapshot(
      user: existing?.user ??
          AuthUser(id: '', name: '', email: ''),
      companies: companies,
      roles: [
        if (data['roles'] is List)
          for (final r in data['roles'] as List)
            if (r is String) r,
      ],
      permissions: {
        if (data['permissions'] is List)
          for (final p in data['permissions'] as List)
            if (p is String) p,
      },
      capturedAt: DateTime.now().toUtc(),
      currentCompanyId: data['current_company_id'] as String? ?? companyId,
      deviceId: existing?.deviceId,
      sessionId: data['session_id'] as String?,
    );
    _applySessionToConfig(snapshot);
    await _persistSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<void> logout({bool clearLocalBusinessData = false}) async {
    try {
      await _http.post('/api/v1/auth/logout');
    } catch (_) {
      // Best-effort server revoke.
    }
    await _tokenStorage.clear();
    await _persistSnapshot(null);
    // Intentionally do NOT wipe Drift/Hive business data by default.
    // Company/user switch isolation is a follow-up hardening item.
    if (clearLocalBusinessData) {
      // Reserved for future per-tenant DB wipe policy.
    }
  }

  @override
  Future<void> registerDevice({
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  }) async {
    final response = await _http.post(
      '/api/v1/devices/register',
      body: {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        if (appVersion != null) 'app_version': appVersion,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _http.mapFailure(response);
    }
  }

  void dispose() {
    _sessionController.close();
  }
}
