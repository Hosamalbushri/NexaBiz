import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/auth/domain/services/offline_login_policy.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/authenticated_http_client.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/modules/authentication/data/auth_repository_impl.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/offline_authorization_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/domain/entities/offline_authorization_snapshot.dart';
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
    tempDir = await Directory.systemTemp.createTemp('hive_offline_auth_test_');
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

  group('Offline Authentication Policy (AU-08)', () {
    test('OfflineLoginPolicy evaluates valid snapshot as allowed', () {
      const policy = OfflineLoginPolicy(
        expectedServerUrl: 'https://api.test',
        currentDeviceId: 'device_01',
      );

      final snapshot = OfflineAuthorizationSnapshot(
        serverBaseUrl: 'https://api.test',
        companyId: 'company_01',
        userId: 'user_01',
        email: 'user@test.com',
        roles: const ['admin'],
        permissions: const {'sales.view'},
        snapshotCreatedAt: DateTime.now(),
        lastServerAuthenticatedAt: DateTime.now(),
      );

      final result = policy.evaluate(
        snapshot: snapshot,
        requestedUserId: 'user_01',
        requestedCompanyId: 'company_01',
        userStatus: 'active',
        userCompanyIds: const ['company_01'],
        companyEntitlement: Entitlement.freeLocal('company_01'),
      );

      expect(result.isAllowed, isTrue);
    });

    test(
      'Offline login with invalid password throws AuthenticationFailure',
      () async {
        expect(
          () => controller.loginLocal(
            email: 'admin@nexabiz.local',
            password: 'wrong_password',
            deviceId: 'device_01',
            deviceName: 'Test Device',
            platform: 'flutter',
          ),
          throwsA(isA<AuthenticationFailure>()),
        );
      },
    );

    test(
      'Offline login with unknown user email throws AuthenticationFailure',
      () async {
        expect(
          () => controller.loginLocal(
            email: 'nonexistent@nexabiz.local',
            password: 'password',
            deviceId: 'device_01',
            deviceName: 'Test Device',
            platform: 'flutter',
          ),
          throwsA(isA<AuthenticationFailure>()),
        );
      },
    );

    test(
      'Valid offline login establishes authenticated session state',
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
  });
}
