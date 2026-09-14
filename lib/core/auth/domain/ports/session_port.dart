import '../../../../modules/authentication/domain/entities/auth_session.dart';

/// Dedicated Domain Port for runtime Session lifecycle operations.
///
/// Controls runtime session persistence, restoration hints, and updates.
/// Session snapshot is NOT authoritative DB truth — restoration must revalidate SQLite identity.
abstract class SessionPort {
  Future<AuthSessionSnapshot?> restoreSession();
  Future<void> saveSession(AuthSessionSnapshot? snapshot);
  Future<void> clearSession();
  AuthSessionSnapshot? getCurrentSession();
  Future<void> replaceSession(AuthSessionSnapshot snapshot);
  Stream<AuthSessionSnapshot?> watchSession();
}
