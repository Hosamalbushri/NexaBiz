import 'package:drift/drift.dart';

import '../../../../modules/authentication/domain/entities/auth_user.dart';
import '../../../database/nexabiz_database.dart';
import '../../../database/repositories/canonical_identity_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// Concrete adapter implementing [UserRepository] via [CanonicalIdentityRepository].
class CanonicalUserRepositoryAdapter implements UserRepository {
  CanonicalUserRepositoryAdapter(this._identityRepository);

  final CanonicalIdentityRepository _identityRepository;

  @override
  Future<AuthUser?> findById(String id) async {
    final data = await _identityRepository.getUserByUuid(id);
    if (data == null) return null;
    return _toAuthUser(data);
  }

  @override
  Future<AuthUser?> findByEmail(String email) async {
    final data = await _identityRepository.getUserByEmail(email);
    if (data == null) return null;
    return _toAuthUser(data);
  }

  @override
  Future<AuthUser> create(AuthUser user) async {
    final companion = UsersCompanion.insert(
      id: Value(user.id),
      email: user.email,
      name: user.name,
      status: Value(user.status),
      isSuperAdmin: Value(user.isSuperAdmin),
    );
    final created = await _identityRepository.createUser(companion);
    return _toAuthUser(created);
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    final existing = await _identityRepository.getUserByUuid(id);
    if (existing != null) {
      await _identityRepository.upsertUser(
        UsersCompanion(
          id: Value(existing.id),
          email: Value(existing.email),
          name: Value(existing.name),
          passwordHash: Value(existing.passwordHash),
          status: Value(status),
          isSuperAdmin: Value(existing.isSuperAdmin),
        ),
      );
    }
  }

  AuthUser _toAuthUser(UserData data) {
    return AuthUser(
      id: data.id,
      name: data.name,
      email: data.email,
      status: data.status,
      isSuperAdmin: data.isSuperAdmin,
    );
  }
}
