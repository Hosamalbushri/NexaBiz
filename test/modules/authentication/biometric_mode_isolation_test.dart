import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:stock_count/modules/authentication/data/sync_login_credential_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SyncLoginCredentialStore store;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    store = SyncLoginCredentialStore(
      secureStorage: const FlutterSecureStorage(),
    );
    await store.clearAll();
  });

  group('Biometric Mode Isolation Tests', () {
    test('1. Default biometric status is disabled for both modes', () async {
      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.local),
        isFalse,
      );
      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.sync),
        isFalse,
      );
    });

    test('2. Enabling Local biometric does NOT enable Sync biometric', () async {
      await store.saveCredentials(
        email: 'localuser@nexabiz.com',
        password: 'localpassword123',
        mode: AuthenticationMode.local,
      );

      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.local),
        isTrue,
      );
      expect(
        await store.hasSavedCredentials(mode: AuthenticationMode.local),
        isTrue,
      );

      // Sync mode remains disabled and empty
      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.sync),
        isFalse,
      );
      expect(
        await store.hasSavedCredentials(mode: AuthenticationMode.sync),
        isFalse,
      );
      expect(await store.readEmail(mode: AuthenticationMode.sync), null);
    });

    test('3. Enabling Sync biometric does NOT enable Local biometric', () async {
      await store.saveCredentials(
        email: 'syncuser@nexabiz.com',
        password: 'syncpassword123',
        mode: AuthenticationMode.sync,
      );

      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.sync),
        isTrue,
      );
      expect(
        await store.hasSavedCredentials(mode: AuthenticationMode.sync),
        isTrue,
      );

      // Local mode remains disabled and empty
      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.local),
        isFalse,
      );
      expect(
        await store.hasSavedCredentials(mode: AuthenticationMode.local),
        isFalse,
      );
      expect(await store.readEmail(mode: AuthenticationMode.local), null);
    });

    test('4. Disabling Local biometric does NOT clear Sync credentials', () async {
      // Enable both
      await store.saveCredentials(
        email: 'local@nexabiz.com',
        password: 'localpwd',
        mode: AuthenticationMode.local,
      );
      await store.saveCredentials(
        email: 'sync@nexabiz.com',
        password: 'syncpwd',
        mode: AuthenticationMode.sync,
      );

      // Clear Local
      await store.clear(mode: AuthenticationMode.local);

      // Verify Local is cleared
      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.local),
        isFalse,
      );
      expect(await store.readEmail(mode: AuthenticationMode.local), null);

      // Verify Sync remains untouched
      expect(
        await store.isBiometricLoginEnabled(mode: AuthenticationMode.sync),
        isTrue,
      );
      expect(await store.readEmail(mode: AuthenticationMode.sync), 'sync@nexabiz.com');
      expect(await store.readPassword(mode: AuthenticationMode.sync), 'syncpwd');
    });

    test('5. Credential values are mode-isolated', () async {
      await store.saveCredentials(
        email: 'admin_local',
        password: 'pass_local',
        mode: AuthenticationMode.local,
      );
      await store.saveCredentials(
        email: 'admin_sync@server.com',
        password: 'pass_sync',
        mode: AuthenticationMode.sync,
      );

      expect(await store.readEmail(mode: AuthenticationMode.local), 'admin_local');
      expect(await store.readPassword(mode: AuthenticationMode.local), 'pass_local');

      expect(await store.readEmail(mode: AuthenticationMode.sync), 'admin_sync@server.com');
      expect(await store.readPassword(mode: AuthenticationMode.sync), 'pass_sync');
    });
  });
}
