import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_repository.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/data/secure_token_storage.dart';
import 'package:stock_count/modules/authentication/domain/services/local_brute_force_protector.dart';
import 'package:stock_count/core/network/sync_api_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalAuthStore store;
  late LocalAuthRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auth_hardening_test_');
    Hive.init(tempDir.path);
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 7),
    );
    store = LocalAuthStore();
    repository = LocalAuthRepository(
      store: store,
      tokenStorage: SecureTokenStorage(),
      readConfig: () => const SyncApiConfig(
        baseUrl: '',
        deviceId: 'test_dev',
        companyId: '',
        userId: '',
        apiToken: '',
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

  group('Hardened Local Authentication (All 12 Requirements)', () {
    test('Requirement 1: Correct password succeeds', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'owner@acme.com',
        ownerPassword: 'CorrectHorseBatteryStaple123!',
        ownerName: 'Alice Owner',
      );

      final session = await repository.login(
        email: 'owner@acme.com',
        password: 'CorrectHorseBatteryStaple123!',
        deviceId: 'dev_01',
        deviceName: 'Test Desktop',
        platform: 'linux',
      );

      expect(session, isNotNull);
      expect(session.user.email, equals('owner@acme.com'));
      expect(session.currentCompanyId, equals('comp_01'));
    });

    test('Requirement 2: Wrong password fails', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'owner@acme.com',
        ownerPassword: 'CorrectHorseBatteryStaple123!',
        ownerName: 'Alice Owner',
      );

      await expectLater(
        repository.login(
          email: 'owner@acme.com',
          password: 'WrongPassword123!',
          deviceId: 'dev_01',
          deviceName: 'Test Desktop',
          platform: 'linux',
        ),
        throwsA(isA<Exception>()),
      );

      final session = await store.loadSession();
      expect(session, isNull);
    });

    test('Requirement 3: Empty password fails', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'owner@acme.com',
        ownerPassword: 'CorrectHorseBatteryStaple123!',
        ownerName: 'Alice Owner',
      );

      await expectLater(
        repository.login(
          email: 'owner@acme.com',
          password: '',
          deviceId: 'dev_01',
          deviceName: 'Test Desktop',
          platform: 'linux',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Requirement 4: Whitespace-only password fails', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'owner@acme.com',
        ownerPassword: 'CorrectHorseBatteryStaple123!',
        ownerName: 'Alice Owner',
      );

      await expectLater(
        repository.login(
          email: 'owner@acme.com',
          password: '   ',
          deviceId: 'dev_01',
          deviceName: 'Test Desktop',
          platform: 'linux',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Requirement 5: Password with leading/trailing space treated literally', () async {
      const paddedPassword = '  SpaceP@ssword123  ';

      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'owner@acme.com',
        ownerPassword: paddedPassword,
        ownerName: 'Alice Owner',
      );

      // Trimmed login attempt MUST fail
      await expectLater(
        repository.login(
          email: 'owner@acme.com',
          password: 'SpaceP@ssword123',
          deviceId: 'dev_01',
          deviceName: 'Test Desktop',
          platform: 'linux',
        ),
        throwsA(isA<Exception>()),
      );

      // Exact literal login attempt MUST succeed
      final session = await repository.login(
        email: 'owner@acme.com',
        password: paddedPassword,
        deviceId: 'dev_01',
        deviceName: 'Test Desktop',
        platform: 'linux',
      );

      expect(session, isNotNull);
    });

    test('Requirement 6: Default hardcoded password does not exist as auth credential', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'admin@local',
        ownerPassword: 'CustomSecureAdminPass123!',
        ownerName: 'Admin User',
      );

      // admin123 MUST be rejected
      await expectLater(
        repository.login(
          email: 'admin@local',
          password: 'admin123',
          deviceId: 'dev_01',
          deviceName: 'Test Desktop',
          platform: 'linux',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Requirement 7: Brute-force protection locks out identity after failures', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'target@acme.com',
        ownerPassword: 'CorrectPassword123!',
        ownerName: 'Target User',
      );

      // Perform 5 failed login attempts
      for (var i = 0; i < 5; i++) {
        final result = await store.login(
          email: 'target@acme.com',
          password: 'WrongPassword Attempt $i',
          deviceId: 'dev_01',
        );
        expect(result, isNull);
      }

      // 6th attempt MUST throw BruteForceLockoutException even with correct password
      await expectLater(
        store.login(
          email: 'target@acme.com',
          password: 'CorrectPassword123!',
          deviceId: 'dev_01',
        ),
        throwsA(isA<BruteForceLockoutException>()),
      );

      // Clearing brute-force state unlocks account
      store.bruteForceProtector.clearAll();

      final successSession = await store.login(
        email: 'target@acme.com',
        password: 'CorrectPassword123!',
        deviceId: 'dev_01',
      );
      expect(successSession, isNotNull);
    });

    test('Requirement 8: Failed authentication never creates a session', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'owner@acme.com',
        ownerPassword: 'CorrectPassword123!',
        ownerName: 'Alice Owner',
      );

      try {
        await repository.login(
          email: 'owner@acme.com',
          password: 'BadPassword!',
          deviceId: 'dev_01',
          deviceName: 'Test Desktop',
          platform: 'linux',
        );
      } catch (_) {}

      final session = await store.loadSession();
      expect(session, isNull);
    });

    test('Requirement 9: Authorization derives strictly from persisted domain role', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'owner@acme.com',
        ownerPassword: 'OwnerPassword123!',
        ownerName: 'Owner User',
      );

      final ownerSession = await repository.login(
        email: 'owner@acme.com',
        password: 'OwnerPassword123!',
        deviceId: 'dev_01',
        deviceName: 'Test Desktop',
        platform: 'linux',
      );

      expect(ownerSession.user.isSuperAdmin, isTrue);
      expect(ownerSession.permissions.contains('platform.companies.manage'), isTrue);
    });

    test('Requirement 10: Legacy single-round SHA256 hash migrates transparently to PBKDF2', () async {
      const salt = 'legacy_salt_123';
      const legacyPassword = 'LegacyPass123!';
      final legacySha256Hash = sha256.convert(utf8.encode('$salt::$legacyPassword')).toString();

      final box = await Hive.openBox<dynamic>(HiveBoxes.localAuthEncrypted);
      final legacyUserRecord = {
        'id': 'legacy_user_01',
        'name': 'Legacy Admin',
        'email': 'legacy@acme.com',
        'passwordSalt': salt,
        'passwordHash': legacySha256Hash,
        'status': 'active',
        'isSuperAdmin': true,
        'mustChangePassword': false,
        'companyIds': ['comp_01'],
        'rolesByCompany': {'comp_01': 'Owner'},
        'permissionsByCompany': {'comp_01': ['system.settings.write']},
      };
      final companyRecord = {
        'id': 'comp_01',
        'name': 'Legacy Co',
        'code': 'LEG',
        'role': 'Owner',
      };
      await box.put('users', [legacyUserRecord]);
      await box.put('companies', [companyRecord]);

      // Verify login succeeds with legacy hash
      final session = await store.login(
        email: 'legacy@acme.com',
        password: legacyPassword,
        deviceId: 'dev_01',
      );

      expect(session, isNotNull);

      // Verify that the stored user record hash in Hive was upgraded to modern PBKDF2 format
      final rawUsers = box.get('users') as List;
      final updatedUser = Map<String, dynamic>.from(rawUsers.first as Map);
      final newHash = updatedUser['passwordHash'] as String;

      expect(newHash.startsWith(r'$pbkdf2-sha256$v=1$i=100000$'), isTrue);
    });

    test('Requirement 11: Successful authentication creates correct local session', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'valid@acme.com',
        ownerPassword: 'ValidPassword123!',
        ownerName: 'Valid User',
      );

      final session = await repository.login(
        email: 'valid@acme.com',
        password: 'ValidPassword123!',
        deviceId: 'device_abc',
        deviceName: 'Desktop',
        platform: 'linux',
      );

      expect(session.user.id, isNotEmpty);
      expect(session.currentCompanyId, equals('comp_01'));
      expect(session.deviceId, equals('device_abc'));
      expect(session.sessionId, isNotEmpty);
      expect(session.permissions, isNotEmpty);
    });

    test('Requirement 12: Logout destroys active session', () async {
      await store.createOwnerAndCompany(
        companyId: 'comp_01',
        companyName: 'Acme Corp',
        companyCode: 'ACME',
        ownerEmail: 'user@acme.com',
        ownerPassword: 'UserPassword123!',
        ownerName: 'User Name',
      );

      await repository.login(
        email: 'user@acme.com',
        password: 'UserPassword123!',
        deviceId: 'device_abc',
        deviceName: 'Desktop',
        platform: 'linux',
      );

      final activeSession = await store.loadSession();
      expect(activeSession, isNotNull);

      await repository.logout();

      final clearedSession = await store.loadSession();
      expect(clearedSession, isNull);
    });
  });
}
