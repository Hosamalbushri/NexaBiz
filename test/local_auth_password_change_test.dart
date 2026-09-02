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

  test('admin password change requires valid current password', () async {
    await store.updateLocalAdminCredentials(
      newEmail: LocalAuthDefaults.adminEmail,
      newPassword: 'InitialPassword123!',
    );
    final session = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: 'InitialPassword123!',
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    expect(session, isNotNull);
  });

  test('changePassword enforces minimum length rule', () async {
    await store.updateLocalAdminCredentials(
      newEmail: LocalAuthDefaults.adminEmail,
      newPassword: 'InitialPassword123!',
    );
    final session = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: 'InitialPassword123!',
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    await expectLater(
      store.changePassword(
        userId: session!.user.id,
        currentPassword: 'InitialPassword123!',
        newPassword: 'short',
      ),
      throwsA(
        isA<PasswordChangeException>().having(
          (e) => e.code,
          'code',
          PasswordChangeException.tooShort,
        ),
      ),
    );
  });

  test('changePassword unlocks the session and invalidates the previous password', () async {
    await store.updateLocalAdminCredentials(
      newEmail: LocalAuthDefaults.adminEmail,
      newPassword: 'InitialPassword123!',
    );
    final session = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: 'InitialPassword123!',
      deviceId: '00000000-0000-4000-8000-0000000000d1',
    );
    final updated = await store.changePassword(
      userId: session!.user.id,
      currentPassword: 'InitialPassword123!',
      newPassword: 'NewSafePass!1',
    );
    expect(updated.mustChangePassword, isFalse);

    final rejected = await store.login(
      email: LocalAuthDefaults.adminEmail,
      password: 'InitialPassword123!',
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
