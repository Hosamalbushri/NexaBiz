import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/network/authenticated_http_client.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:stock_count/modules/authentication/data/auth_repository_impl.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/offline_authorization_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

class MockAppLockBiometrics implements AppLockBiometrics {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalAuthStore store;
  late SecureTokenStorage tokenStorage;
  late OfflineAuthorizationStore offlineAuthStore;
  late LocalAuthRepository localRepo;
  late AuthRepositoryImpl remoteRepo;
  late AuthenticatedHttpClient httpClient;
  late AuthController authController;
  late AppLockRepositoryImpl appLockRepository;
  late AppLockController appLockController;

  const config = SyncApiConfig(
    baseUrl: '',
    apiToken: '',
    companyId: '',
    userId: '',
    deviceId: '',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'hive_app_lock_company_test_',
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

    authController = AuthController(local: localRepo, remote: remoteRepo);

    appLockRepository = AppLockRepositoryImpl();
    appLockController = AppLockController(
      repository: appLockRepository,
      biometrics: MockAppLockBiometrics(),
      onChanged: () {},
    );

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

  group('Company-Aware App Lock (AL-05)', () {
    test('Company switching maintains active App Lock gating', () async {
      await authController.loginLocal(
        email: 'admin@nexabiz.local',
        password: 'admin',
        deviceId: 'device_01',
        deviceName: 'Test Device',
        platform: 'flutter',
      );

      final companyB = await authController.createCompanyWithAdmin(
        companyName: 'Branch B',
        companyCode: 'BRB',
        adminName: 'Admin B',
        adminEmail: 'adminB@nexabiz.local',
        adminPassword: 'AdminPassword123!',
      );

      await appLockController.enableWithPin(pin: '1234', confirmPin: '1234');
      appLockController.lock(returnTo: '/dashboard');

      expect(appLockController.state.isLocked, isTrue);
      expect(authController.state.session?.currentCompanyId, companyB.id);

      final unlocked = await appLockController.unlock('1234');
      expect(unlocked, isTrue);
      expect(appLockController.state.isLocked, isFalse);
      expect(authController.state.session?.currentCompanyId, companyB.id);
    });
  });
}
