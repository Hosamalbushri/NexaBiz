import 'scope_context.dart';

export 'scope_context.dart';
export 'tenant_providers.dart';

/// Centralized tenancy context representing the active tenant boundary.
class TenantContext {
  const TenantContext({
    required this.companyId,
    this.userId,
    this.deviceId,
    this.isStandalone = false,
    ScopeContext? scope,
  }) : _explicitScope = scope;

  /// Authoritative company identifier for database and sync isolation.
  final String companyId;

  /// Active user identifier.
  final String? userId;

  /// Active device identifier.
  final String? deviceId;

  /// Whether the session is standalone local offline mode.
  final bool isStandalone;

  final ScopeContext? _explicitScope;

  /// Explicit scope context.
  ScopeContext get scope {
    final explicit = _explicitScope;
    if (explicit != null) return explicit;
    if (companyId.isNotEmpty) return CompanyScope(companyId);
    return const SystemScope();
  }

  /// Unauthenticated/unassigned tenant context.
  static const empty = TenantContext(
    companyId: '',
    userId: null,
    isStandalone: true,
    scope: SystemScope(),
  );

  bool get hasActiveCompany => companyId.trim().isNotEmpty;
  bool get isCompanyScope => scope.isCompany;
  bool get isSystemScope => scope.isSystem;
  bool get isGlobalScope => scope.isGlobal;

  TenantContext copyWith({
    String? companyId,
    String? userId,
    String? deviceId,
    bool? isStandalone,
    ScopeContext? scope,
  }) {
    return TenantContext(
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      isStandalone: isStandalone ?? this.isStandalone,
      scope: scope ?? this.scope,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenantContext &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          userId == other.userId &&
          deviceId == other.deviceId &&
          isStandalone == other.isStandalone &&
          scope == other.scope;

  @override
  int get hashCode =>
      companyId.hashCode ^
      userId.hashCode ^
      deviceId.hashCode ^
      isStandalone.hashCode ^
      scope.hashCode;
}
