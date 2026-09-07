import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/network/authenticated_http_client.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/modules/authentication/data/auth_repository_impl.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/offline_authorization_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalAuthStore store;
  late SecureTokenStorage tokenStorage;
  late OfflineAuthorizationStore offlineAuthStore;
  late LocalAuthRepository localRepo;
  late AuthRepositoryImpl remoteRepo;
  late AuthenticatedHttpClient httpClient;
  late AuthController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_auth_test_');
    Hive.init(tempDir.path);

    store = LocalAuthStore();
    tokenStorage = SecureTokenStorage();
    offlineAuthStore = OfflineAuthorizationStore();

    const config = SyncApiConfig(
      baseUrl: '',
      apiToken: '',
      companyId: '',
      userId: '',
      deviceId: '',
    );

    httpClient = AuthenticatedHttpClient(
      config: config,
      tokenStore: tokenStorage,
    );

    localRepo = LocalAuthRepository(
      store: store,
      tokenStorage: tokenStorage,
      offlineAuthStore: offlineAuthStore,
      readConfig: () => config,
      onConfigChanged: (_) {},
    );

    remoteRepo = AuthRepositoryImpl(
      http: httpClient,
      tokenStorage: tokenStorage,
      offlineAuthStore: offlineAuthStore,
      readConfig: () => config,
      onConfigChanged: (_) {},
    );

    controller = AuthController(local: localRepo, remote: remoteRepo);

    await store.createInitialSystemAdmin(
      name: 'System Admin',
      email: 'admin@nexabiz.local',
      password: 'admin',
    );

    await localRepo.ensureReady();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Login / Logout Lifecycle (AU-02)', () {
    test('Fresh state starts as uninitialized / unauthenticated', () {
      expect(controller.state.status, AuthStatus.uninitialized);
    });

    test(
      'Login success establishes company context and authenticated status',
      () async {
        await controller.loginLocal(
          email: 'admin@nexabiz.local',
          password: 'admin',
          deviceId: 'device_01',
          deviceName: 'Test Device',
          platform: 'flutter',
        );

        expect(controller.state.isAuthenticated, isTrue);
        expect(controller.state.session?.user.email, 'admin@nexabiz.local');
      },
    );

    test(
      'Logout clears session snapshot and transitions to unauthenticated',
      () async {
        await controller.loginLocal(
          email: 'admin@nexabiz.local',
          password: 'admin',
          deviceId: 'device_01',
          deviceName: 'Test Device',
          platform: 'flutter',
        );

        expect(controller.state.isAuthenticated, isTrue);

        await controller.logout();

        expect(controller.state.isAuthenticated, isFalse);
        expect(controller.state.status, AuthStatus.unauthenticated);
        expect(controller.state.session, isNull);
      },
    );

    test(
      'Idempotency: calling logout repeatedly does not fail or corrupt state',
      () async {
        await controller.logout();
        await controller.logout();
        await controller.logout();

        expect(controller.state.status, AuthStatus.unauthenticated);
        expect(controller.state.session, isNull);
      },
    );
  });
}
