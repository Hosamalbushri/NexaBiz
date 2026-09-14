import '../../../../modules/authentication/domain/entities/auth_session.dart';
import '../../../../modules/authentication/domain/repositories/auth_repository.dart';
import '../domain/entities/authentication_result.dart';
import '../domain/ports/authentication_port.dart';

/// Concrete adapter implementing [AuthenticationPort].
class DefaultAuthenticationPortAdapter implements AuthenticationPort {
  DefaultAuthenticationPortAdapter(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<AuthenticationResult> authenticateLocal({
    required String email,
    required String password,
    required String deviceId,
    String? companyId,
  }) async {
    try {
      final snapshot = await _authRepository.login(
        email: email,
        password: password,
        companyId: companyId,
        deviceId: deviceId,
        deviceName: 'LocalDevice',
        platform: 'standalone',
      );

      return AuthenticationResult.success(
        user: snapshot.user,
        companies: snapshot.companies,
        memberships: snapshot.activeMembership != null
            ? [snapshot.activeMembership!]
            : const [],
        activeMembership: snapshot.activeMembership,
        activeCompanyContext: snapshot.companyContext,
        sessionSnapshot: snapshot,
      );
    } catch (e) {
      return AuthenticationResult.failure(message: e.toString());
    }
  }

  @override
  Future<AuthenticationResult> authenticateRemote({
    required String email,
    required String password,
    required String deviceId,
    String? companyId,
  }) async {
    // Remote authentication delegates to same canonical pipeline semantics
    return authenticateLocal(
      email: email,
      password: password,
      deviceId: deviceId,
      companyId: companyId,
    );
  }

  @override
  Future<AuthSessionSnapshot?> restoreSession() {
    return _authRepository.restoreSession();
  }

  @override
  Future<void> logout({bool clearLocalData = false}) {
    return _authRepository.logout(clearLocalBusinessData: clearLocalData);
  }

  @override
  Future<AuthSessionSnapshot?> switchCompany(
    String userId,
    String companyId,
  ) async {
    try {
      return await _authRepository.switchCompany(companyId);
    } catch (_) {
      return null;
    }
  }
}
