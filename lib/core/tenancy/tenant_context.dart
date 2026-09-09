export 'tenant_providers.dart';

/// Centralized tenancy context representing the active tenant boundary.
class TenantContext {
  const TenantContext({
    required this.companyId,
    this.userId,
    this.deviceId,
    this.isStandalone = false,
  });

  /// Authoritative company identifier for database and sync isolation.
  final String companyId;

  /// Active user identifier.
  final String? userId;

  /// Active device identifier.
  final String? deviceId;

  /// Whether the session is standalone local offline mode.
  final bool isStandalone;

  /// Unauthenticated/unassigned tenant context.
  static const empty = TenantContext(
    companyId: '',
    userId: null,
    isStandalone: true,
  );

  bool get hasActiveCompany => companyId.trim().isNotEmpty;

  TenantContext copyWith({
    String? companyId,
    String? userId,
    String? deviceId,
    bool? isStandalone,
  }) {
    return TenantContext(
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      isStandalone: isStandalone ?? this.isStandalone,
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
          isStandalone == other.isStandalone;

  @override
  int get hashCode =>
      companyId.hashCode ^
      userId.hashCode ^
      deviceId.hashCode ^
      isStandalone.hashCode;
}
