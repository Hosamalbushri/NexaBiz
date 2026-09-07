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

  const config = SyncApiConfig(
    baseUrl: '',
    apiToken: '',
    companyId: '',
    userId: '',
    deviceId: '',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_session_test_');
    Hive.init(tempDir.path);

    store = LocalAuthStore();
    tokenStorage = SecureTokenStorage();
    offlineAuthStore = OfflineAuthorizationStore();

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

  group('Session Persistence (AU-03)', () {
    test('Valid session survives restart', () async {
      // 1. Perform login
      await controller.loginLocal(
        email: 'admin@nexabiz.local',
        password: 'admin',
        deviceId: 'device_restoration_01',
        deviceName: 'Test Device',
        platform: 'flutter',
      );

      expect(controller.state.isAuthenticated, isTrue);

      // 2. Simulate restart: instantiate new controller instance reading same persisted store
      final restoredController = AuthController(
        local: localRepo,
        remote: remoteRepo,
      );

      final restoredSession = await restoredController.restoreSession();

      expect(restoredSession, isNotNull);
      expect(restoredController.state.isAuthenticated, isTrue);
      expect(
        restoredController.state.session?.user.email,
        'admin@nexabiz.local',
      );
    });

    test(
      'Logout survives restart: restored session is null after logout',
      () async {
        await controller.loginLocal(
          email: 'admin@nexabiz.local',
          password: 'admin',
          deviceId: 'device_restoration_01',
          deviceName: 'Test Device',
          platform: 'flutter',
        );

        await controller.logout();

        final restoredController = AuthController(
          local: localRepo,
          remote: remoteRepo,
        );

        final restoredSession = await restoredController.restoreSession();

        expect(restoredSession, isNull);
        expect(restoredController.state.isAuthenticated, isFalse);
        expect(restoredController.state.status, AuthStatus.unauthenticated);
      },
    );

    test('Corrupted session data triggers fail-closed invalidation', () async {
      // Corrupt key tokens in storage
      await tokenStorage.clear();

      final restoredController = AuthController(
        local: localRepo,
        remote: remoteRepo,
      );

      final restoredSession = await restoredController.restoreSession();

      expect(restoredSession, isNull);
      expect(restoredController.state.isAuthenticated, isFalse);
    });
  });
}
