import '../exceptions/import_engine_exception.dart';

/// Context carrying tenant isolation, user authorization, localization, and execution metadata.
class ImportContext {
  const ImportContext({
    required this.companyId,
    this.tenantId,
    this.userId,
    this.permissions = const {},
    this.locale = 'ar',
    this.currencyContext,
    this.executionMetadata = const {},
  });

  /// The active company ID (tenant isolation context).
  final String companyId;

  /// Optional sub-tenant or multi-tenant system ID.
  final String? tenantId;

  /// Active user ID performing the import.
  final String? userId;

  /// Set of permissions assigned to the active user session.
  final Set<String> permissions;

  /// Preferred locale for localized error messages (e.g. 'ar', 'en').
  final String locale;

  /// Currency code context (e.g. 'SAR', 'USD').
  final String? currencyContext;

  /// Arbitrary execution metadata for auditing and tracing.
  final Map<String, dynamic> executionMetadata;

  /// Returns true if the company context is non-empty and valid.
  bool get hasValidCompanyContext => companyId.trim().isNotEmpty;

  /// Requires a valid non-empty company context or throws [ImportContextException].
  void requireCompanyContext() {
    if (!hasValidCompanyContext) {
      throw const ImportContextException(
        'Company-scoped import requires a valid non-empty company context.',
        'MISSING_COMPANY_CONTEXT',
      );
    }
  }

  /// Checks whether a specific permission is present in the context.
  bool hasPermission(String permission) => permissions.contains(permission);

  ImportContext copyWith({
    String? companyId,
    String? tenantId,
    String? userId,
    Set<String>? permissions,
    String? locale,
    String? currencyContext,
    Map<String, dynamic>? executionMetadata,
  }) {
    return ImportContext(
      companyId: companyId ?? this.companyId,
      tenantId: tenantId ?? this.tenantId,
      userId: userId ?? this.userId,
      permissions: permissions ?? this.permissions,
      locale: locale ?? this.locale,
      currencyContext: currencyContext ?? this.currencyContext,
      executionMetadata: executionMetadata ?? this.executionMetadata,
    );
  }
}
