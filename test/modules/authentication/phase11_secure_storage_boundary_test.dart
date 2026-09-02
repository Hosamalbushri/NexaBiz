import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 11: Secure Storage Boundary Tests', () {
    late SecureTokenStorage tokenStorage;
    late Map<String, String> mockSecureStore;

    setUp(() {
      mockSecureStore = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(mockSecureStore);
      tokenStorage = SecureTokenStorage();
    });

    test('1. Write & Read: Tokens are successfully written and read from secure storage', () async {
      const accessToken = 'jwt_access_token_12345';
      const refreshToken = 'jwt_refresh_token_67890';
      const expiresIn = 3600;

      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresInSeconds: expiresIn,
      );

      final readAccess = await tokenStorage.readAccessToken();
      final readRefresh = await tokenStorage.readRefreshToken();
      final expiresAt = await tokenStorage.readAccessExpiresAt();

      expect(readAccess, equals(accessToken));
      expect(readRefresh, equals(refreshToken));
      expect(expiresAt, isNotNull);
      expect(expiresAt!.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('2. Replace: Overwriting tokens replaces previous values atomically', () async {
      await tokenStorage.saveTokens(
        accessToken: 'old_access_token',
        refreshToken: 'old_refresh_token',
        expiresInSeconds: 1800,
      );

      const newAccess = 'new_access_token_999';
      const newRefresh = 'new_refresh_token_999';

      await tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        expiresInSeconds: 3600,
      );

      final readAccess = await tokenStorage.readAccessToken();
      final readRefresh = await tokenStorage.readRefreshToken();

      expect(readAccess, equals(newAccess));
      expect(readRefresh, equals(newRefresh));
      expect(readAccess, isNot(equals('old_access_token')));
    });

    test('3. Delete: Bootstrap token can be selectively deleted', () async {
      const bootstrapToken = 'bootstrap_token_abc123';
      await tokenStorage.saveBootstrapToken(bootstrapToken);

      final readBefore = await tokenStorage.readBootstrapToken();
      expect(readBefore, equals(bootstrapToken));

      await tokenStorage.clearBootstrapToken();

      final readAfter = await tokenStorage.readBootstrapToken();
      expect(readAfter, isNull);
    });

    test('4. Logout Cleanup: clear() purges all stored tokens completely', () async {
      await tokenStorage.saveTokens(
        accessToken: 'active_access_token',
        refreshToken: 'active_refresh_token',
        expiresInSeconds: 3600,
      );
      await tokenStorage.saveBootstrapToken('active_bootstrap_token');

      // Execute logout cleanup
      await tokenStorage.clear();

      final readAccess = await tokenStorage.readAccessToken();
      final readRefresh = await tokenStorage.readRefreshToken();
      final readExpires = await tokenStorage.readAccessExpiresAt();
      final readBootstrap = await tokenStorage.readBootstrapToken();

      expect(readAccess, isNull);
      expect(readRefresh, isNull);
      expect(readExpires, isNull);
      expect(readBootstrap, isNull);
    });

    test('5. Session Metadata Separation: Session json does NOT contain passwords or raw secrets', () {
      const user = AuthUser(
        id: 'user-777',
        email: 'admin@nexabiz.com',
        name: 'Admin',
        systemRole: SystemRole.systemAdmin,
      );

      const company = AuthCompany(
        id: 'company-777',
        name: 'NexaBiz Corp',
        code: 'NEXA',
      );

      final session = AuthSessionSnapshot(
        user: user,
        companies: [company],
        roles: ['System Admin'],
        permissions: kSystemLevelPermissions,
        currentCompanyId: company.id,
        capturedAt: DateTime.now().toUtc(),
      );

      final json = session.toJson();

      // Ensure JSON contains identity & permissions, but NO passwords or security tokens
      expect(json['user']['id'], equals('user-777'));
      expect(json['user']['email'], equals('admin@nexabiz.com'));
      expect(json.containsKey('password'), isFalse);
      expect(json.containsKey('access_token'), isFalse);
      expect(json.containsKey('refresh_token'), isFalse);
      expect(json.containsKey('secret'), isFalse);
    });

    test('6. Invalid State: Reading non-existent tokens safely returns null', () async {
      final freshStorage = SecureTokenStorage();

      final access = await freshStorage.readAccessToken();
      final refresh = await freshStorage.readRefreshToken();
      final expiresAt = await freshStorage.readAccessExpiresAt();

      expect(access, isNull);
      expect(refresh, isNull);
      expect(expiresAt, isNull);
    });
  });
}
