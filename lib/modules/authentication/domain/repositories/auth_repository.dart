import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSessionSnapshot?> restoreSession();

  Future<AuthSessionSnapshot> login({
    required String email,
    required String password,
    String? companyId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  });

  Future<AuthSessionSnapshot> refreshSession();

  Future<AuthSessionSnapshot> fetchMe();

  Future<AuthSessionSnapshot> switchCompany(String companyId);

  Future<void> logout({bool clearLocalBusinessData = false});

  Future<String?> readAccessToken();

  Future<void> registerDevice({
    required String deviceId,
    required String deviceName,
    required String platform,
    String? appVersion,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Stream<AuthSessionSnapshot?> watchSession();
}
