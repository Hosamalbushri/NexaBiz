import '../auth/domain/services/local_authorization_guard.dart';
import '../tenancy/tenant_context.dart';

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
        expectedCompanyId: activeCompanyId.trim(),
        actualCompanyId: companyId.trim(),
      );
    }
    return companyId.trim();
  }

  /// Validates that the active company context [companyId] is present in the list of
  /// authorized company IDs [authorizedCompanyIds] for the authenticated user identity.
  /// Throws [MissingCompanyContextException] if [companyId] is missing or
  /// [CompanyContextMismatchException] if unauthorized.
  static String enforceCompanyAuthorization({
    required String? companyId,
    required List<String> authorizedCompanyIds,
  }) {
    if (companyId == null || companyId.trim().isEmpty) {
      throw const MissingCompanyContextException(
        'Company authorization check failed: companyId is empty or null.',
      );
    }
    final trimmedId = companyId.trim();
    final trimmedAuthorized = authorizedCompanyIds.map((e) => e.trim()).toList();
    if (!trimmedAuthorized.contains(trimmedId)) {
      throw CompanyContextMismatchException(
        message:
            'Company authorization check failed: user is not authorized to operate against company ($trimmedId).',
        expectedCompanyId: trimmedAuthorized.join(','),
        actualCompanyId: trimmedId,
      );
    }
    return trimmedId;
  }

  /// Enforces scope boundary check on [tenantContext] for target operational [targetScope].
  ///
  /// - [CompanyScope]: Validates active company context presence and target match.
  /// - [SystemScope]: Permits execution for system-scoped operations without manufacturing a fake company.
  /// - [GlobalScope]: Permits execution for global reference data access.
  /// - [ContextualScope]: Resolves to companyId if active, or throws [MissingCompanyContextException] if unassigned.
  static String? enforceScopeContext({
    required TenantContext tenantContext,
    required ScopeContext targetScope,
  }) {
    switch (targetScope) {
      case CompanyScope(:final companyId):
        return enforceCompanyContext(
          companyId: companyId,
          activeCompanyId: tenantContext.companyId,
        );
      case SystemScope():
        return null;
      case GlobalScope():
        return null;
      case ContextualScope():
        if (tenantContext.hasActiveCompany) {
          return tenantContext.companyId;
        }
        throw const MissingCompanyContextException(
          'Scope boundary check failed: ContextualScope cannot resolve an authorized company identity.',
        );
    }
  }
}
