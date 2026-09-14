import 'dart:async';

import '../../../../modules/authentication/domain/entities/auth_session.dart';
import '../../../../modules/authentication/domain/repositories/auth_repository.dart';
import '../domain/ports/session_port.dart';

/// Concrete adapter implementing [SessionPort].
class LocalSessionPortAdapter implements SessionPort {
  LocalSessionPortAdapter(this._authRepository);

  final AuthRepository _authRepository;
  AuthSessionSnapshot? _cached;

  @override
  Future<AuthSessionSnapshot?> restoreSession() async {
    final session = await _authRepository.restoreSession();
    _cached = session;
    return session;
  }

  @override
  Future<void> saveSession(AuthSessionSnapshot? snapshot) async {
    _cached = snapshot;
    if (snapshot == null) {
      await _authRepository.logout();
    }
  }

  @override
  Future<void> clearSession() async {
    _cached = null;
    await _authRepository.logout();
  }

  @override
  AuthSessionSnapshot? getCurrentSession() => _cached;

  @override
  Future<void> replaceSession(AuthSessionSnapshot snapshot) async {
    _cached = snapshot;
    if (snapshot.currentCompanyId != null && snapshot.currentCompanyId!.isNotEmpty) {
      await _authRepository.switchCompany(snapshot.currentCompanyId!);
    }
  }

  @override
  Stream<AuthSessionSnapshot?> watchSession() {
    return _authRepository.watchSession();
  }
}
