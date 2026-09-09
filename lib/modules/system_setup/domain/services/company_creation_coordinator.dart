import 'package:stock_count/core/auth/auth_core.dart';


class CompanyCreationCoordinator {
  CompanyCreationCoordinator({required this._authStore});

  final LocalAuthStore _authStore;

  /// Atomically creates a new company, creates its Admin user, assigns explicit membership,
  /// and initializes company foundations.
  Future<AuthCompany> createCompanyWithAdmin({
    required AuthSessionSnapshot creatorSession,
    required String companyName,
    required String companyCode,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    String adminRole = 'Admin',
    List<String>? adminPermissions,
  }) async {
    return _authStore.createCompanyWithAdmin(
      creatorSession: creatorSession,
      companyName: companyName,
      companyCode: companyCode,
      adminName: adminName,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      adminRole: adminRole,
      adminPermissions: adminPermissions,
    );
  }
}
