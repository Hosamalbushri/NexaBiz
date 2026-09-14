import 'package:drift/drift.dart';

import '../../../../modules/authentication/domain/entities/user_company_membership.dart';
import '../../../database/nexabiz_database.dart';
import '../../../database/repositories/canonical_identity_repository.dart';
import '../../domain/repositories/membership_repository.dart';

/// Concrete adapter implementing [MembershipRepository] via [CanonicalIdentityRepository].
class CanonicalMembershipRepositoryAdapter implements MembershipRepository {
  CanonicalMembershipRepositoryAdapter(this._identityRepository);

  final CanonicalIdentityRepository _identityRepository;

  @override
  Future<UserCompanyMembership?> findByUserAndCompany(
    String userId,
    String companyId,
  ) async {
    final data = await _identityRepository.validateMembership(
      userUuid: userId,
      companyUuid: companyId,
    );
    if (data == null) return null;
    return _toUserCompanyMembership(data);
  }

  @override
  Future<List<UserCompanyMembership>> findByUser(String userId) async {
    final list = await _identityRepository.getUserMemberships(userId);
    return list.map(_toUserCompanyMembership).toList();
  }

  @override
  Future<List<UserCompanyMembership>> findActiveByUser(String userId) async {
    final list = await _identityRepository.getUserMemberships(userId);
    return list
        .where((m) => m.status == 'active')
        .map(_toUserCompanyMembership)
        .toList();
  }

  @override
  Future<UserCompanyMembership> create(UserCompanyMembership membership) async {
    final companion = CompanyMembershipsCompanion.insert(
      id: Value('${membership.userId}_${membership.companyId}'),
      userId: membership.userId,
      companyId: membership.companyId,
      role: Value(membership.role),
      status: Value(membership.status),
    );
    final created = await _identityRepository.createMembership(companion);
    return _toUserCompanyMembership(created);
  }

  @override
  Future<bool> validateMembership(String userId, String companyId) async {
    final mem = await _identityRepository.validateMembership(
      userUuid: userId,
      companyUuid: companyId,
    );
    return mem != null && mem.status == 'active';
  }

  UserCompanyMembership _toUserCompanyMembership(CompanyMembershipData data) {
    return UserCompanyMembership(
      userId: data.userId,
      companyId: data.companyId,
      role: data.role,
      status: data.status,
    );
  }
}
