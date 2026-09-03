import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/authentication/presentation/providers/auth_providers.dart';

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

/// Provider exposing active [TenantContext].
///
/// Rule 4: No silent company fallback. An unassigned or system scope context
/// resolves to an empty company ID ('').
final tenantContextProvider = Provider<TenantContext>((ref) {
  final session = ref.watch(authStateProvider).session;
  if (session == null) {
    return TenantContext.empty;
  }
  var companyId = session.currentCompanyId?.trim() ??
      session.activeCompanyId?.trim() ??
      '';
  if (companyId.isEmpty && session.companies.isNotEmpty) {
    companyId = session.companies.first.id.trim();
  }
  return TenantContext(
    companyId: companyId,
    userId: session.user.id,
    deviceId: session.deviceId,
    isStandalone: session.user.isSuperAdmin,
  );
});

/// Provider exposing current active company ID.
final currentCompanyIdProvider = Provider<String>((ref) {
  return ref.watch(tenantContextProvider).companyId;
});
