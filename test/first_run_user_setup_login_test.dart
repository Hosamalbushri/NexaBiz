import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/core/errors/app_failure.dart';
import 'package:stock_count/core/network/sync_api_config.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalAuthStore authStore;
  late SettingsRepository settingsRepo;
  late FirstRunSetupCoordinator coordinator;
  late LocalAuthRepository localAuthRepo;
  late SecureTokenStorage tokenStorage;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('first_run_login_test_');
    Hive.init(tempDir.path);
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 7),
    );

    authStore = LocalAuthStore();
    settingsRepo = SettingsRepository();
    coordinator = FirstRunSetupCoordinator(
      settingsRepository: settingsRepo,
      authStore: authStore,
    );
    tokenStorage = SecureTokenStorage();
    localAuthRepo = LocalAuthRepository(
      store: authStore,
      tokenStorage: tokenStorage,
      readConfig: () => const SyncApiConfig(
        baseUrl: '',
        apiToken: '',
        companyId: 'local-company',
        userId: 'admin-local-001',
        deviceId: '00000000-0000-4000-8000-000000000001',
      ),
    );
  });

  tearDown(() async {
    HiveEncryptionKeyStore.debugFixedKey = null;
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('admin credentials created in first run setup wizard authenticate successfully with full permissions', () async {
    const customEmail = 'manager@mybusiness.com';
    const customPassword = 'SecureAdminPassword2026!';
    const customName = 'Admin Manager';

    // 1. Commit First Run Setup
    const payload = FirstRunSetupPayload(
      language: 'ar',
      companyName: 'شركة النجاح',
      companyCode: 'SUCC-01',
      adminName: customName,
      adminEmail: customEmail,
      adminPassword: customPassword,
    );

    await coordinator.commitFirstRunSetup(payload);

    expect(await coordinator.isFirstRunCompleted(), isTrue);

    // 2. Verify getAdminEmail returns custom email
    final savedAdminEmail = await authStore.getAdminEmail();
    expect(savedAdminEmail, customEmail);

    // 3. Login with custom credentials through LocalAuthRepository
    final session = await localAuthRepo.login(
      email: customEmail,
      password: customPassword,
      deviceId: '00000000-0000-4000-8000-000000000001',
      deviceName: 'local_device',
      platform: 'linux',
    );

    expect(session, isNotNull);
    expect(session.user.email, customEmail);
    expect(session.user.name, customName);
    expect(session.user.isSuperAdmin, isTrue);
    expect(session.roles, contains(LocalAuthDefaults.adminRole));
    expect(session.permissions, containsAll(kAllLocalPermissions));

    // 4. Case-insensitive email login
    final upperEmailSession = await localAuthRepo.login(
      email: 'MANAGER@MYBUSINESS.COM',
      password: customPassword,
      deviceId: '00000000-0000-4000-8000-000000000001',
      deviceName: 'local_device',
      platform: 'linux',
    );
    expect(upperEmailSession.user.email, customEmail);

    // 5. Rejects wrong password
    expect(
      () => localAuthRepo.login(
        email: customEmail,
        password: 'WrongPassword123!',
        deviceId: '00000000-0000-4000-8000-000000000001',
        deviceName: 'local_device',
        platform: 'linux',
      ),
      throwsA(isA<AuthenticationFailure>()),
    );

    // 6. Rejects default unconfigured password
    expect(
      () => localAuthRepo.login(
        email: customEmail,
        password: LocalAuthDefaults.adminPassword,
        deviceId: '00000000-0000-4000-8000-000000000001',
        deviceName: 'local_device',
        platform: 'linux',
      ),
      throwsA(isA<AuthenticationFailure>()),
    );
  });
}
