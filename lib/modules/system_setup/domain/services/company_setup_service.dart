import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/settings/settings_repository.dart';
import '../../../authentication/domain/entities/auth_session.dart';
import '../repositories/company_initialization_repository.dart';

/// Exceptions thrown during Company Setup orchestration.
class CompanySetupException implements Exception {
  const CompanySetupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Service managing Post-Authentication Company Setup.
/// Enforces authentication, authorization, company context isolation, and duplicate protection.
class CompanySetupService {
  CompanySetupService({
    required this._settingsRepository,
    required this._initRepository,
  });

  final SettingsRepository _settingsRepository;
  final CompanyInitializationRepository _initRepository;

  /// Configures or updates company profile for the active authenticated session.
  ///
  /// Constraints:
  /// 1. Must be authenticated (`session` != null).
  /// 2. If user lacks administrative permission, setup is rejected.
  /// 3. Company ID is derived exclusively from active session (`session.currentCompanyId`).
  /// 4. Reuses existing company ID — does NOT duplicate company records.
  Future<CompanyProfile> setupCompany({
    required AuthSessionSnapshot? session,
    required CompanyProfile profile,
    List<String>? userPermissions,
    bool isSuperAdmin = false,
  }) async {
    // 1. Mandatory Authentication Gate
    if (session == null) {
      throw const CompanySetupException(
        'Authentication required: Company Setup cannot be performed without an active session.',
      );
    }

    // 2. Authorization Gate
    final hasPermission = isSuperAdmin ||
        (userPermissions != null &&
            (userPermissions.contains('system.setup') ||
                userPermissions.contains('settings.company')));

    if (!hasPermission) {
      throw const CompanySetupException(
        'Access Denied: You do not have permission to configure company settings.',
      );
    }

    // 3. Company Scoping & Existing Company Lookup
    final companyId = session.currentCompanyId?.trim();
    if (companyId == null || companyId.isEmpty) {
      throw const CompanySetupException(
        'Invalid session context: Active company ID is missing.',
      );
    }

    // 4. Input Validation
    final trimmedName = profile.name.trim();
    if (trimmedName.isEmpty) {
      throw const CompanySetupException(
        'Validation error: Company name cannot be empty.',
      );
    }

    // 5. Existing Company Profile Reuse & Mutation
    final existing = await _settingsRepository.loadCompanyProfile();
    final updatedProfile = existing.copyWith(
      name: trimmedName,
      legalName: profile.legalName,
      taxNumber: profile.taxNumber,
      commercialRegister: profile.commercialRegister,
      phone: profile.phone,
      email: profile.email,
      address: profile.address,
      city: profile.city,
      country: profile.country,
      website: profile.website,
      defaultCurrencyCode: profile.defaultCurrencyCode,
    );

    // Save company profile to persistent settings
    await _settingsRepository.saveCompanyProfile(updatedProfile);

    // 6. Update Initialization State Flag
    final initState = await _initRepository.getState();
    await _initRepository.saveState(
      initState.copyWith(
        companyId: companyId,
        companyCreated: true,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    return updatedProfile;
  }
}
