import 'dart:async';

import '../../../core/auth/domain/services/offline_login_policy.dart';
import '../../../core/entitlements/data/entitlement_repository.dart';
import '../../../core/entitlements/domain/entities/entitlement.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/sync_api_config.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import 'local_auth_store.dart';
import 'offline_authorization_store.dart';
import 'secure_token_storage.dart';

/// Fully offline authentication against the local Hive identity store.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required this._store,
    required this._tokenStorage,
    OfflineAuthorizationStore? offlineAuthStore,
    EntitlementRepository? entitlementRepository,
    required this._readConfig,
    this._onConfigChanged,
  }) : _offlineAuthStore = offlineAuthStore ?? OfflineAuthorizationStore(),
       _entitlementRepository =
           entitlementRepository ?? EntitlementRepositoryImpl();

  final LocalAuthStore _store;
  final SecureTokenStorage _tokenStorage;
  final OfflineAuthorizationStore _offlineAuthStore;
  final EntitlementRepository _entitlementRepository;
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

  Future<AuthSessionSnapshot> _applyOfflineAuthorization(
    AuthSessionSnapshot snapshot,
  ) async {
    if (!snapshot.hasCompany) return snapshot;
    final config = _readConfig();
    // Standalone local mode & Super Admin accounts use local permissions directly
    if (config.baseUrl.isEmpty || snapshot.user.isSuperAdmin) {
      return snapshot;
    }

    final companyId = snapshot.currentCompanyId!;
    final cachedEntitlement = await _entitlementRepository.getCachedEntitlement(
      companyId,
    );
    final entitlement = cachedEntitlement ?? Entitlement.freeLocal(companyId);

    final restoredSnapshot = await _offlineAuthStore.loadSnapshot(
      serverBaseUrl: config.baseUrl,
      companyId: companyId,
      userId: snapshot.user.id,
    );

    final policy = OfflineLoginPolicy(
      expectedServerUrl: config.baseUrl,
      currentDeviceId: config.deviceId,
    );

    final result = policy.evaluate(
      snapshot: restoredSnapshot,
      requestedUserId: snapshot.user.id,
      requestedCompanyId: companyId,
      userStatus: snapshot.user.status,
      userCompanyIds: snapshot.companies.map((c) => c.id).toList(),
      companyEntitlement: entitlement,
    );

    if (result.isAllowed && restoredSnapshot != null) {
      return snapshot.copyWith(
        roles: restoredSnapshot.roles,
        permissions: restoredSnapshot.permissions,
      );
    }

    // Standalone local mode or super admin account
    if (snapshot.user.isSuperAdmin || config.baseUrl.isEmpty) {
      return snapshot;
    }

    // Fail closed for any failed policy checks
    return snapshot.copyWith(
      roles: const <String>[],
      permissions: const <String>{},
    );
  }

  @override
  Future<AuthSessionSnapshot?> restoreSession() async {
    await _store.ensureSeeded();
    final loaded = await _store.loadSession();
    if (loaded == null) {
      _emit(null);
      return null;
    }
    final snapshot = await _applyOfflineAuthorization(loaded);
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
    final loaded = await _store.login(
      email: email,
      password: password,
      deviceId: deviceId,
      companyId: companyId,
    );
    if (loaded == null) {
      throw const AuthenticationFailure('Invalid email or password');
    }
    final snapshot = await _applyOfflineAuthorization(loaded);
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

  /// Generates or retrieves an OS-protected biometric token for the specified user email.
  Future<String?> getOrCreateBiometricToken(String email) =>
      _store.getOrCreateBiometricToken(email);

  /// Authenticates user using an OS-protected biometric token without requiring raw passwords.
  Future<AuthSessionSnapshot> loginWithBiometricToken({
    required String email,
    required String biometricToken,
    String? companyId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  }) async {
    final loaded = await _store.loginWithBiometricToken(
      email: email,
      biometricToken: biometricToken,
      deviceId: deviceId,
      companyId: companyId,
    );
    if (loaded == null) {
      throw const AuthenticationFailure('Invalid biometric token');
    }
    final snapshot = await _applyOfflineAuthorization(loaded);
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

  Future<AuthSessionSnapshot> createCompany({
    required String name,
    required String code,
  }) async {
    final company = await _store.createCompany(name: name, code: code);
    return switchCompany(company.id);
  }

  Future<AuthCompany> createCompanyWithAdmin({
    required String companyName,
    required String companyCode,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    String adminRole = 'Admin',
    List<String>? adminPermissions,
  }) async {
    final session = _cached;
    if (session == null) {
      throw const CompanyCreationException('No active auth session');
    }
    final company = await _store.createCompanyWithAdmin(
      creatorSession: session,
      companyName: companyName,
      companyCode: companyCode,
      adminName: adminName,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      adminRole: adminRole,
      adminPermissions: adminPermissions,
    );

    final hasCompany = session.companies.any((c) => c.id == company.id);
    if (!hasCompany) {
      final updated = session.copyWith(
        companies: [...session.companies, company],
      );
      _emit(updated);
    }
    return company;
  }

  @override
  Future<void> logout({bool clearLocalBusinessData = false}) async {
    // G4 fix: delete all offline authorization snapshots for this user on logout.
    // This prevents stale authorization state from being reused by a subsequent user.
    final userId = _cached?.user.id;
    await _tokenStorage.clear();
    await _store.saveSession(null);
    if (userId != null && userId.isNotEmpty) {
      try {
        await _offlineAuthStore.deleteAllSnapshotsForUser(userId);
      } catch (_) {
        // Best-effort — session is already cleared above.
      }
    }
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

  @override
  Future<AuthSessionSnapshot> changePassword({
    required String currentPassword,
    required String newPassword,
    String? userId,
  }) async {
    final uid =
        userId ?? _cached?.user.id ?? (await _store.loadSession())?.user.id;
    if (uid == null || uid.isEmpty) {
      throw const AuthenticationFailure('No active session');
    }
    final snapshot = await _store.changePassword(
      userId: uid,
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
