import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authenticated_http_client.dart';
import '../../../../core/network/http_client_providers.dart';
import '../../../../core/network/sync_api_config.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/secure_token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

/// Late-bound refresh callback avoids Riverpod cycles between HTTP client and auth repo.
final tokenRefreshCallbackProvider =
    StateProvider<Future<bool> Function()?>((ref) => null);

final sessionExpiredCallbackProvider = StateProvider<void Function()?>((ref) => null);

final authenticatedHttpClientProvider = Provider<AuthenticatedHttpClient>((ref) {
  final storage = ref.watch(secureTokenStorageProvider);
  final client = AuthenticatedHttpClient(
    config: ref.watch(syncApiConfigProvider),
    tokenStore: storage,
    onRefresh: () async {
      final cb = ref.read(tokenRefreshCallbackProvider);
      if (cb == null) return false;
      return cb();
    },
    onSessionExpired: () {
      ref.read(sessionExpiredCallbackProvider)?.call();
    },
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

List<Override> authenticationOverrides() => [authSyncHttpOverride];

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepositoryImpl(
    http: ref.watch(authenticatedHttpClientProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
    readConfig: () => ref.read(syncApiConfigProvider),
    onConfigChanged: (config) {
      ref.read(syncApiConfigProvider.notifier).state = config;
    },
  );
  ref.read(tokenRefreshCallbackProvider.notifier).state = () async {
    try {
      await repo.refreshSession();
      return true;
    } catch (_) {
      return false;
    }
  };
  ref.onDispose(repo.dispose);
  return repo;
});

enum AuthStatus {
  unknown,
  unauthenticated,
  needsCompany,
  authenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  final AuthStatus status;
  final AuthSessionSnapshot? session;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated || status == AuthStatus.needsCompany;

  bool hasPermission(String code) => session?.hasPermission(code) ?? false;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState.unknown());

  final AuthRepository _repo;

  Future<void> bootstrap() async {
    try {
      final session = await _repo.restoreSession();
      state = _stateFor(session);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
    String? companyId,
  }) async {
    final session = await _repo.login(
      email: email,
      password: password,
      companyId: companyId,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      appVersion: appVersion,
    );
    state = _stateFor(session);
  }

  Future<void> switchCompany(String companyId) async {
    final session = await _repo.switchCompany(companyId);
    state = _stateFor(session);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void markUnauthenticated() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  AuthState _stateFor(AuthSessionSnapshot? session) {
    if (session == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    if (!session.hasCompany) {
      return AuthState(status: AuthStatus.needsCompany, session: session);
    }
    return AuthState(status: AuthStatus.authenticated, session: session);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(authRepositoryProvider));
  ref.read(sessionExpiredCallbackProvider.notifier).state = () {
    controller.markUnauthenticated();
  };
  return controller;
});

final currentPermissionsProvider = Provider<Set<String>>((ref) {
  return ref.watch(authStateProvider).session?.permissions ?? {};
});
