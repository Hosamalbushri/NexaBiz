import '../auth/domain/entities/authorization_context.dart';
import '../auth/domain/services/local_authorization_guard.dart';
export '../auth/domain/services/local_authorization_guard.dart';

/// Centralized service enforcing strict company context invariants across domain services and repositories.
///
/// Invariants enforced:
/// 1. Active company exists in the authorization context.
/// 2. Request or entity [companyId] matches active company context.
/// 3. User is authorized for the company.
/// 4. No silent/implicit fallbacks to default company IDs are permitted.
class CompanyContextResolver {
  const CompanyContextResolver();

  /// Resolves the authoritative active company ID from [context].
  ///
  /// Throws:
  /// - [MissingCompanyContextException] if context or companyId is missing/empty.
  /// - [CompanyContextMismatchException] if [requestedCompanyId] does not match active company.
  String resolveActiveCompanyId({
    required AuthorizationContext? context,
    String? requestedCompanyId,
  }) {
    if (context == null) {
      throw const MissingCompanyContextException(
        'Company context resolution failed: missing authorization context.',
      );
    }
    final activeId = context.companyId.trim();
    if (activeId.isEmpty) {
      throw const MissingCompanyContextException(
        'Company context resolution failed: no active company context assigned to session.',
      );
    }

    if (requestedCompanyId != null && requestedCompanyId.trim().isNotEmpty) {
      final cleanRequested = requestedCompanyId.trim();
      if (cleanRequested != activeId) {
        throw CompanyContextMismatchException(
          message: 'Company context mismatch: requested company ($cleanRequested) does not match active context ($activeId).',
          expectedCompanyId: activeId,
          actualCompanyId: cleanRequested,
        );
      }
    }

    return activeId;
  }

  /// Asserts that an entity's [entityCompanyId] belongs to the active company context.
  void assertEntityBelongsToActiveCompany({
    required AuthorizationContext? context,
    required String entityCompanyId,
    required String entityName,
  }) {
    final activeId = resolveActiveCompanyId(context: context);
    final cleanEntityCompanyId = entityCompanyId.trim();

    if (cleanEntityCompanyId.isEmpty) {
      throw MissingCompanyContextException(
        'Entity invariant violated: $entityName is missing companyId.',
      );
    }

    if (cleanEntityCompanyId != activeId) {
      throw CompanyContextMismatchException(
        message: 'Entity invariant violated: $entityName companyId ($cleanEntityCompanyId) does not match active company context ($activeId).',
        expectedCompanyId: activeId,
        actualCompanyId: cleanEntityCompanyId,
      );
    }
  }
}
