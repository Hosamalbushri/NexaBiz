import '../../../../core/audit/domain/services/audit_trail_service.dart';
import '../../../../core/permissions/permission_guard.dart';
import '../repositories/admin_repository.dart';
import '../../shared/data/admin_api_repository.dart';

class ManageAdminCompaniesUseCase {
  const ManageAdminCompaniesUseCase(
    this._repository, {
    this.permissionGuard,
    this.auditTrailService,
  });

  final AdminRepository _repository;
  final PermissionGuard? permissionGuard;
  final AuditTrailService? auditTrailService;

  static const _viewPermissions = [
    'companies.view',
    'companies.manage',
    'platform.companies.manage',
  ];

  static const _managePermissions = [
    'companies.create',
    'companies.manage',
    'platform.companies.manage',
  ];

  Future<List<AdminCompanySummary>> listCompanies() async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.listCompanies();
  }

  Future<AdminCompanySummary> getCompany(String companyId) async {
    permissionGuard?.requireAny(_viewPermissions);
    return _repository.getCompany(companyId);
  }

  Future<AdminCompanySummary> createCompany({
    required String name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String status = 'active',
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    final company = await _repository.createCompany(
      name: name,
      legalName: legalName,
      taxNumber: taxNumber,
      phone: phone,
      email: email,
      address: address,
      status: status,
    );

    await auditTrailService?.recordEvent(
      documentId: company.id,
      documentType: 'company',
      eventType: 'company.created',
      notes: 'Created company workspace: ${company.name}',
      metadata: {
        'name': company.name,
        'tax_number': company.taxNumber,
        'status': company.status,
      },
    );

    return company;
  }

  Future<AdminCompanySummary> updateCompany({
    required String companyId,
    String? name,
    String? legalName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String? status,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    final company = await _repository.updateCompany(
      companyId: companyId,
      name: name,
      legalName: legalName,
      taxNumber: taxNumber,
      phone: phone,
      email: email,
      address: address,
      status: status,
    );

    await auditTrailService?.recordEvent(
      documentId: company.id,
      documentType: 'company',
      eventType: 'company.updated',
      notes: 'Updated company workspace: ${company.name}',
      metadata: {'name': company.name, 'status': company.status},
    );

    return company;
  }

  Future<void> setCompanyStatus({
    required String companyId,
    required String status,
  }) async {
    permissionGuard?.requireAny(_managePermissions);

    await _repository.setCompanyStatus(companyId: companyId, status: status);

    await auditTrailService?.recordEvent(
      documentId: companyId,
      documentType: 'company',
      eventType: 'company.status_changed',
      notes: 'Set company status to $status',
      metadata: {'companyId': companyId, 'status': status},
    );
  }
}
