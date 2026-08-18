import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';
import 'package:stock_count/modules/authentication/domain/models/password_change_exception.dart';

void main() {
  late Directory tempDir;
  late LocalAuthStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('local_auth_pw_');
    Hive.init(tempDir.path);
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 3),
    );
    store = LocalAuthStore();
  });

  tearDown(() async {
    HiveEncryptionKeyStore.debugFixedKey = null;
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('seeded admin login with default password requires a change', () async {
    await store.ensureSeeded();
    final session = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: LocalAuthDefaults.adminPassword,
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    expect(session, isNotNull);
    expect(session!.mustChangePassword, isTrue);
  });

  test('changePassword rejects the bootstrap default as the new value', () async {
    await store.ensureSeeded();
    final session = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: LocalAuthDefaults.adminPassword,
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    expect(
      () => store.changePassword(
        userId: session!.user.id,
        currentPassword: LocalAuthDefaults.adminPassword,
        newPassword: LocalAuthDefaults.adminPassword,
      ),
      throwsA(
        isA<PasswordChangeException>().having(
          (e) => e.code,
          'code',
          PasswordChangeException.sameAsDefault,
        ),
      ),
    );
  });

  test('changePassword unlocks the session and invalidates the seed password', () async {
    await store.ensureSeeded();
    final session = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: LocalAuthDefaults.adminPassword,
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    final updated = await store.changePassword(
      userId: session!.user.id,
      currentPassword: LocalAuthDefaults.adminPassword,
      newPassword: 'NewSafePass!1',
    );
    expect(updated.mustChangePassword, isFalse);

    final rejected = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: LocalAuthDefaults.adminPassword,
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    expect(rejected, isNull);

    final next = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: 'NewSafePass!1',
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    expect(next, isNotNull);
    expect(next!.mustChangePassword, isFalse);
  });
}
