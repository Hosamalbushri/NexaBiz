import '../../../../modules/authentication/domain/entities/auth_session.dart';
import '../entities/authentication_result.dart';

/// Dedicated Domain Port for Authentication operations.
///
/// Answers:
/// - WHO IS THIS USER?
/// - IS THE CREDENTIAL VALID?
/// - CAN A SECURITY SESSION BE CREATED?
///
/// Implementations MUST NOT depend on Flutter UI, GoRouter, or Riverpod.
abstract class AuthenticationPort {
  Future<AuthenticationResult> authenticateLocal({
    required String email,
    required String password,
    required String deviceId,
    String? companyId,
  });

  Future<AuthenticationResult> authenticateRemote({
    required String email,
    required String password,
    required String deviceId,
    String? companyId,
  });

  Future<AuthSessionSnapshot?> restoreSession();

  Future<void> logout({bool clearLocalData = false});

  Future<AuthSessionSnapshot?> switchCompany(String userId, String companyId);
}
