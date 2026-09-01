import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class AuthenticateUserUseCase {
  const AuthenticateUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSessionSnapshot> login({
    required String email,
    required String password,
    String? companyId,
    required String deviceId,
    required String deviceName,
    required String platform,
  }) {
    return _repository.login(
      email: email,
      password: password,
      companyId: companyId,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
    );
  }

  Future<void> logout() => _repository.logout();

  Future<AuthSessionSnapshot?> restoreSession() =>
      _repository.restoreSession();
}
