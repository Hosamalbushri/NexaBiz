import '../auth/domain/services/local_authorization_guard.dart';

/// Enforces fail-closed multi-tenancy isolation for all local database queries & mutations.
class MultiTenantRepositoryGuard {
  const MultiTenantRepositoryGuard();

  /// Validates that [companyId] is provided and matches active tenant context [activeCompanyId].
  /// Throws [MissingCompanyContextException] or [CompanyContextMismatchException] if invalid.
  static String enforceCompanyContext({
    required String? companyId,
    required String? activeCompanyId,
  }) {
    if (companyId == null || companyId.trim().isEmpty) {
      throw const MissingCompanyContextException(
        'Database operation blocked: target companyId is empty or null.',
      );
    }
    if (activeCompanyId == null || activeCompanyId.trim().isEmpty) {
      throw const MissingCompanyContextException(
        'Database operation blocked: no active company context set in current session.',
      );
    }
    if (companyId.trim() != activeCompanyId.trim()) {
      throw CompanyContextMismatchException(
        message:
            'Database operation blocked: target company ($companyId) does not match active session tenant ($activeCompanyId).',
        expectedCompanyId: activeCompanyId,
        actualCompanyId: companyId,
      );
    }
    return companyId.trim();
  }
}
