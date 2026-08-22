import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/authenticated_http_client.dart';
import '../../../../core/network/http_client_providers.dart';
import '../../../../core/network/sync_api_config.dart';
import '../../../../core/network/token_refresh_outcome.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/tenancy/session_company.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/local_auth_repository.dart';
import '../../data/local_auth_store.dart';
import '../../data/secure_token_storage.dart';
import '../../data/sync_login_credential_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mutable callbacks shared between HTTP client and auth without Riverpod cycles.
class AuthCallbackHub {
  Future<TokenRefreshOutcome> Function()? onRefresh;
  void Function()? onSessionExpired;
}

final authCallbackHubProvider = Provider<AuthCallbackHub>((ref) {
  return AuthCallbackHub();
});

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final syncLoginCredentialStoreProvider = Provider<SyncLoginCredentialStore>((
  ref,
) {
  return SyncLoginCredentialStore();
});

/// Stable HTTP client — must NOT rebuild when [syncApiConfigProvider] changes,
/// or login mid-flight disposes [AuthController].
final authenticatedHttpClientProvider = Provider<AuthenticatedHttpClient>((
  ref,
) {
  final storage = ref.watch(secureTokenStorageProvider);
  final hub = ref.watch(authCallbackHubProvider);
  final client = AuthenticatedHttpClient(
    config: ref.read(syncApiConfigProvider),
    tokenStore: storage,
    onRefresh: () async {
      final cb = hub.onRefresh;
      if (cb == null) return TokenRefreshOutcome.unauthorized;
      return cb();
    },
    onSessionExpired: () => hub.onSessionExpired?.call(),
  );
  ref.listen<SyncApiConfig>(syncApiConfigProvider, (_, next) {
    client.updateConfig(next);
  });
  ref.onDispose(client.dispose);
  return client;
});

final authSyncHttpOverride = syncAuthenticatedHttpClientProvider.overrideWith(
  (ref) => ref.watch(authenticatedHttpClientProvider),
);

final sessionCompanyIdOverride = sessionCompanyIdProvider.overrideWith((ref) {
  return ref.watch(
    authStateProvider.select((s) => s.session?.currentCompanyId),
  );
});

List<Override> authenticationOverrides() => [
  authSyncHttpOverride,
  sessionCompanyIdOverride,
];

final localAuthStoreProvider = Provider<LocalAuthStore>((ref) {
  return LocalAuthStore();
});

final localAuthRepositoryProvider = Provider<LocalAuthRepository>((ref) {
  return LocalAuthRepository(
    store: ref.watch(localAuthStoreProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
    readConfig: () => ref.read(syncApiConfigProvider),
    onConfigChanged: (config) {
      ref.read(syncApiConfigProvider.notifier).state = config;
    },
  );
});

final remoteAuthRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final repo = AuthRepositoryImpl(
    http: ref.watch(authenticatedHttpClientProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
    readConfig: () => ref.read(syncApiConfigProvider),
    onConfigChanged: (config) {
      ref.read(syncApiConfigProvider.notifier).state = config;
    },
  );
  ref.onDispose(repo.dispose);
  return repo;
});

/// Active auth repository — remote when a sync session is active, else local.
///
/// Prefer [AuthController] APIs (`loginForSync`, `returnToLocalMode`) rather
/// than calling this directly for mode switches.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Default for bootstrap / generic callers: local until sync login succeeds.
  return ref.watch(localAuthRepositoryProvider);
});

enum AuthStatus { unknown, unauthenticated, needsCompany, authenticated }

/// Whether the current [AuthState] came from the remote JWT backend.
enum AuthBackend { local, remote }

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.backend = AuthBackend.local,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final AuthSessionSnapshot? session;
  final String? errorMessage;
  final AuthBackend backend;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated || status == AuthStatus.needsCompany;

  bool get mustChangePassword => session?.mustChangePassword == true;

  bool get isRemoteSession => backend == AuthBackend.remote;

  /// Refresh failed / tokens cleared — UI keeps [session] permissions offline.
  bool get needsSessionRenewal => errorMessage == 'session_expired';

  /// Live credentials available for SyncManager / online APIs.
  bool get canUseRemoteSync =>
      isRemoteSession && isAuthenticated && !needsSessionRenewal;

  /// Admin-approved sync disable is pending application on this device.
  bool get syncDisableApprovedByAdmin =>
      errorMessage == 'sync_disable_approved';

  /// Whether this account may turn sync off on the device without approval.
  bool get canDisableSyncLocally {
    if (!isRemoteSession) return true;
    if (session?.user.isSuperAdmin == true) return true;
    if (hasPermission('devices.revoke')) return true;
    if (hasPermission('platform.users.manage')) return true;
    return false;
  }

  /// UI-facing account type derived from the server snapshot (not a security boundary).
  String get accountType {
    final session = this.session;
    if (session == null) return 'anonymous';
    if (session.user.isSuperAdmin) return 'admin';
    final roles = session.roles.map((r) => r.toLowerCase());
    if (roles.any((r) => r.contains('admin'))) return 'admin';
    return 'user';
  }

  bool hasPermission(String code) => session?.hasPermission(code) ?? false;

  bool hasAnyPermission(Iterable<String> codes) =>
      session?.hasAnyPermission(codes) ?? false;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required LocalAuthRepository local,
    required AuthRepositoryImpl remote,
  }) : _local = local,
       _remote = remote,
       super(const AuthState.unknown());

  final LocalAuthRepository _local;
  final AuthRepositoryImpl _remote;

  void _set(AuthState next) {
    if (!mounted) return;
    state = next;
  }

  /// Widget-test helper: seed session without Hive/repositories.
  @visibleForTesting
  void replaceStateForTest(AuthState next) => _set(next);

  /// Offline-first bootstrap: check stored credentials and enforce mandatory login gate on launch.
  Future<void> bootstrap({bool preferRemote = false}) async {
    try {
      if (preferRemote) {
        final remoteSession = await _remote.restoreSession();
        if (remoteSession != null) {
          final base = _stateFor(remoteSession, AuthBackend.remote);
          _set(
            AuthState(
              status: AuthStatus.unauthenticated,
              session: base.session,
              backend: AuthBackend.remote,
            ),
          );
          return;
        }
      }
      final session = await _local.restoreSession();
      if (session != null) {
        final base = _stateFor(session, AuthBackend.local);
        _set(
          AuthState(
            status: AuthStatus.unauthenticated,
            session: base.session,
            backend: AuthBackend.local,
          ),
        );
        return;
      }
      _set(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      _set(
        AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Local offline login against the Hive identity store.
  Future<void> loginLocal({
    required String email,
    required String password,
    String? companyId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  }) async {
    final session = await _local.login(
      email: email,
      password: password,
      companyId: companyId,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      appVersion: appVersion,
    );
    _set(_stateFor(session, AuthBackend.local));
  }

  /// Local offline password change (seeded admin first-login gate).
  Future<void> changeLocalPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = state.session?.user.id;
    if (userId == null || userId.isEmpty) {
      throw const AuthenticationFailure('No local session');
    }
    final session = await _local.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _set(_stateFor(session, AuthBackend.local));
  }

  /// Remote login used when enabling synchronization. Does not persist the
  /// password. On success, [state] becomes a remote session.
  Future<AuthSessionSnapshot> loginForSync({
    required String email,
    required String password,
    String? companyId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  }) async {
    final session = await _remote.login(
      email: email,
      password: password,
      companyId: companyId,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      appVersion: appVersion,
    );
    _set(_stateFor(session, AuthBackend.remote));
    return session;
  }

  Future<void> login({
    required String email,
    required String password,
    String? companyId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  }) async {
    await loginLocal(
      email: email,
      password: password,
      companyId: companyId,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      appVersion: appVersion,
    );
  }

  Future<void> switchCompany(String companyId) async {
    final session = await _remote.switchCompany(companyId);
    _set(_stateFor(session, AuthBackend.remote));
  }

  Future<void> logoutRemote() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Best-effort; always clear local remote state next.
    }
  }

  /// After disabling sync: drop remote session and restore local offline admin.
  Future<void> returnToLocalMode() async {
    await logoutRemote();
    await bootstrap(preferRemote: false);
  }

  /// Refresh failed: clear tokens, keep RBAC snapshot + UI access offline.
  Future<void> enterOfflineExpiredSession() async {
    final snapshot = state.session ?? await _remote.restoreSession();
    try {
      await _remote.clearTokensKeepSnapshot();
    } catch (_) {}
    if (snapshot == null) {
      _set(
        const AuthState(
          status: AuthStatus.unauthenticated,
          backend: AuthBackend.remote,
          errorMessage: 'session_expired',
        ),
      );
      return;
    }
    final base = _stateFor(snapshot, AuthBackend.remote);
    _set(
      AuthState(
        status: base.status,
        session: snapshot,
        backend: AuthBackend.remote,
        errorMessage: 'session_expired',
      ),
    );
  }

  /// Single-flight refresh used by [AuthenticatedHttpClient] on HTTP 401.
  Future<TokenRefreshOutcome> tryRefreshSession() async {
    if (!state.isRemoteSession || state.needsSessionRenewal) {
      return TokenRefreshOutcome.unauthorized;
    }
    if (state.syncDisableApprovedByAdmin) {
      return TokenRefreshOutcome.syncDisableApproved;
    }
    try {
      final session = await _remote.refreshSession();
      _set(_stateFor(session, AuthBackend.remote));
      return TokenRefreshOutcome.refreshed;
    } on NetworkFailure {
      return TokenRefreshOutcome.unavailable;
    } on AuthenticationFailure catch (e) {
      if (e.reason == 'sync_disable_approved') {
        final snapshot = state.session;
        _set(
          AuthState(
            status: snapshot == null
                ? AuthStatus.unauthenticated
                : (snapshot.hasCompany
                      ? AuthStatus.authenticated
                      : AuthStatus.needsCompany),
            session: snapshot,
            backend: AuthBackend.remote,
            errorMessage: 'sync_disable_approved',
          ),
        );
        return TokenRefreshOutcome.syncDisableApproved;
      }
      return TokenRefreshOutcome.unauthorized;
    } catch (_) {
      return TokenRefreshOutcome.unauthorized;
    }
  }

  Future<void> logout() async {
    if (state.isRemoteSession) {
      await logoutRemote();
    } else {
      await _local.logout();
    }
    _set(const AuthState(status: AuthStatus.unauthenticated));
  }

  void markSessionExpired() {
    if (state.syncDisableApprovedByAdmin) return;
    if (state.needsSessionRenewal) return;
    final session = state.session;
    if (session == null) {
      _set(
        const AuthState(
          status: AuthStatus.unauthenticated,
          backend: AuthBackend.remote,
          errorMessage: 'session_expired',
        ),
      );
      return;
    }
    // Keep authenticated status so module launcher / PermissionGate stay intact.
    _set(
      AuthState(
        status: session.hasCompany
            ? AuthStatus.authenticated
            : AuthStatus.needsCompany,
        session: session,
        backend: AuthBackend.remote,
        errorMessage: 'session_expired',
      ),
    );
  }

  void markUnauthenticated() {
    markSessionExpired();
  }

  AuthState _stateFor(AuthSessionSnapshot? session, AuthBackend backend) {
    if (session == null) {
      return AuthState(status: AuthStatus.unauthenticated, backend: backend);
    }
    if (!session.hasCompany) {
      return AuthState(
        status: AuthStatus.needsCompany,
        session: session,
        backend: backend,
      );
    }
    return AuthState(
      status: AuthStatus.authenticated,
      session: session,
      backend: backend,
    );
  }
}

final authStateProvider = StateNotifierProvider<AuthController, AuthState>((
  ref,
) {
  final hub = ref.read(authCallbackHubProvider);
  final controller = AuthController(
    local: ref.watch(localAuthRepositoryProvider),
    remote: ref.watch(remoteAuthRepositoryProvider),
  );

  Future<TokenRefreshOutcome> refreshCb() => controller.tryRefreshSession();
  void expiredCb() => controller.markSessionExpired();

  hub.onRefresh = refreshCb;
  hub.onSessionExpired = expiredCb;
  ref.onDispose(() {
    if (identical(hub.onRefresh, refreshCb)) {
      hub.onRefresh = null;
    }
    if (identical(hub.onSessionExpired, expiredCb)) {
      hub.onSessionExpired = null;
    }
  });
  return controller;
});

final currentPermissionsProvider = Provider<Set<String>>((ref) {
  return ref.watch(authStateProvider).session?.permissions ?? {};
});

/// Domain RBAC gate — use cases must call [PermissionGuard.requireAny].
final permissionGuardProvider = Provider<PermissionGuard>((ref) {
  return CallbackPermissionGuard((codes) {
    return ref.read(authStateProvider).hasAnyPermission(codes);
  });
});
