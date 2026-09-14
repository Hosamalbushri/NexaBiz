import 'package:drift/drift.dart';

import '../../../../modules/authentication/domain/entities/auth_user.dart';
import '../../../database/nexabiz_database.dart';
import '../../../database/repositories/canonical_identity_repository.dart';
import '../../domain/repositories/company_repository.dart';

/// Concrete adapter implementing [CompanyRepository] via [CanonicalIdentityRepository].
class CanonicalCompanyRepositoryAdapter implements CompanyRepository {
  CanonicalCompanyRepositoryAdapter(this._identityRepository);

  final CanonicalIdentityRepository _identityRepository;

  @override
  Future<AuthCompany?> findById(String id) async {
    final data = await _identityRepository.getCompanyByUuid(id);
    if (data == null) return null;
    return _toAuthCompany(data);
  }

  @override
  Future<AuthCompany?> findByCode(String code) async {
    final data = await _identityRepository.getCompanyByCode(code);
    if (data == null) return null;
    return _toAuthCompany(data);
  }

  @override
  Future<AuthCompany> create(AuthCompany company) async {
    final companion = CompaniesCompanion.insert(
      id: Value(company.id),
      code: company.code,
      name: company.name,
      status: const Value('active'),
    );
    final created = await _identityRepository.createCompany(companion);
    return _toAuthCompany(created);
  }

  @override
  Future<String?> getStatus(String id) async {
    final company = await _identityRepository.getCompanyByUuid(id);
    return company?.status;
  }

  AuthCompany _toAuthCompany(CompanyData data) {
    return AuthCompany(
      id: data.id,
      name: data.name,
      code: data.code,
    );
  }
}
