import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/authentication/data/sync_login_credential_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({
      'sync_login_password': 'stale_raw_password_123',
      'local_login_password': 'stale_raw_password_456',
    });
    Hive.init('./test_tmp_phase1_security');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('SEC-01: Biometric Secret Token Storage Remediation', () {
    late SyncLoginCredentialStore credentialStore;

    setUp(() {
      credentialStore = SyncLoginCredentialStore();
    });

    test('saveBiometricCredentials stores secret token and purges legacy raw password keys', () async {
      await credentialStore.saveBiometricCredentials(
        email: 'admin@nexabiz.com',
        biometricToken: 'bio_secret_token_uuid_12345',
        mode: AuthenticationMode.local,
      );

      final email = await credentialStore.readEmail(mode: AuthenticationMode.local);
      final token = await credentialStore.readBiometricToken(mode: AuthenticationMode.local);
      final isEnabled = await credentialStore.isBiometricLoginEnabled(mode: AuthenticationMode.local);

      expect(email, equals('admin@nexabiz.com'));
      expect(token, equals('bio_secret_token_uuid_12345'));
      expect(isEnabled, isTrue);

      // Verify raw password keys are completely gone
      const secure = FlutterSecureStorage();
      final syncRawPwd = await secure.read(key: 'sync_login_password');
      final localRawPwd = await secure.read(key: 'local_login_password');

      expect(syncRawPwd, isNull);
      expect(localRawPwd, isNull);
    });

    test('clear() purges email, biometric token, and enabled flags', () async {
      await credentialStore.saveBiometricCredentials(
        email: 'user@nexabiz.com',
        biometricToken: 'bio_secret_token_uuid_99999',
        mode: AuthenticationMode.local,
      );

      await credentialStore.clear(mode: AuthenticationMode.local);

      final email = await credentialStore.readEmail(mode: AuthenticationMode.local);
      final token = await credentialStore.readBiometricToken(mode: AuthenticationMode.local);
      final hasSaved = await credentialStore.hasSavedCredentials(mode: AuthenticationMode.local);

      expect(email, isNull);
      expect(token, isNull);
      expect(hasSaved, isFalse);
    });
  });

  group('SEC-01: LocalAuthStore Biometric Authentication Token Flow', () {
    late LocalAuthStore localStore;

    setUp(() async {
      localStore = LocalAuthStore();
      await localStore.ensureSeeded();
      if (!await localStore.hasConfiguredAdmin()) {
        await localStore.createInitialSystemAdmin(
          name: 'Admin User',
          email: 'admin@local.test',
          password: 'Password123!',
        );
      }
    });

    test('getOrCreateBiometricToken issues a persistent token for active user', () async {
      final token1 = await localStore.getOrCreateBiometricToken('admin@local.test');
      expect(token1, isNotNull);
      expect(token1!.isNotEmpty, isTrue);

      final token2 = await localStore.getOrCreateBiometricToken('admin@local.test');
      expect(token2, equals(token1));
    });

    test('loginWithBiometricToken succeeds with valid token and fails with invalid token', () async {
      final validToken = await localStore.getOrCreateBiometricToken('admin@local.test');
      expect(validToken, isNotNull);

      // Valid token login
      final session = await localStore.loginWithBiometricToken(
        email: 'admin@local.test',
        biometricToken: validToken!,
        deviceId: 'device_test_123',
      );
      expect(session, isNotNull);
      expect(session!.user.email, equals('admin@local.test'));

      // Invalid token login failure
      final invalidSession = await localStore.loginWithBiometricToken(
        email: 'admin@local.test',
        biometricToken: 'invalid_forged_token',
        deviceId: 'device_test_123',
      );
      expect(invalidSession, isNull);
    });
  });

  group('SEC-02: SecureTokenStorage Dual-Storage Purge', () {
    late SecureTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = SecureTokenStorage();
    });

    test('saveTokens and clear purge tokens deterministically', () async {
      await tokenStorage.saveTokens(
        accessToken: 'access_test_123',
        refreshToken: 'refresh_test_123',
        expiresInSeconds: 3600,
      );

      final tokenBefore = await tokenStorage.readAccessToken();
      expect(tokenBefore, equals('access_test_123'));

      await tokenStorage.clear();

      final tokenAfter = await tokenStorage.readAccessToken();
      expect(tokenAfter, isNull);
    });
  });
}
