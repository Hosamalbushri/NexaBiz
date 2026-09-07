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
    tempDir = await Directory.systemTemp.createTemp(
      'hive_company_context_test_',
    );
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

  group('Company Selection & Context (AU-05)', () {
    test('Unauthorized company selection fails context switch', () async {
      await controller.loginLocal(
        email: 'admin@nexabiz.local',
        password: 'admin',
        deviceId: 'device_01',
        deviceName: 'Test Device',
        platform: 'flutter',
      );

      final result = await controller.switchCompany('unauthorized_company_999');

      expect(result.isSuccess, isFalse);
    });

    test(
      'Company switching A -> B updates active company ID on state',
      () async {
        await controller.loginLocal(
          email: 'admin@nexabiz.local',
          password: 'admin',
          deviceId: 'device_01',
          deviceName: 'Test Device',
          platform: 'flutter',
        );

        final companyA = await controller.createCompanyWithAdmin(
          companyName: 'Company A',
          companyCode: 'CMPA',
          adminName: 'Admin A',
          adminEmail: 'admin@nexabiz.local',
          adminPassword: 'AdminP@ss123!',
        );

        final companyB = await controller.createCompanyWithAdmin(
          companyName: 'Company B',
          companyCode: 'CMPB',
          adminName: 'Admin B',
          adminEmail: 'admin@nexabiz.local',
          adminPassword: 'AdminP@ss123!',
        );

        expect(controller.state.session?.currentCompanyId, companyB.id);

        final result = await controller.switchCompany(companyA.id);
        expect(result.isSuccess, isTrue);
        expect(controller.state.session?.currentCompanyId, companyA.id);
      },
    );
  });
}
