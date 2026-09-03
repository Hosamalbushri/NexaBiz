import '../local_permissions.dart';
import 'active_company_context.dart';
import 'auth_user.dart';
import 'system_role.dart';
import 'user_company_membership.dart';

/// Local authorization snapshot used offline for UI gating.
///
/// Tokens are NOT stored here — they live in secure storage.
class AuthSessionSnapshot {
  AuthSessionSnapshot({
    required this.user,
    required this.companies,
    required this.roles,
    required this.permissions,
    required this.capturedAt,
    this.currentCompanyId,
    this.activeMembership,
    this.activeCompanyContext,
    this.deviceId,
    this.sessionId,
    this.mustChangePassword = false,
  }) : _effectiveCompanyContext = activeCompanyContext ?? _buildContextFallback(user, activeMembership, currentCompanyId);

  final AuthUser user;
  final List<AuthCompany> companies;
  final List<String> roles;
  final Set<String> permissions;
  final DateTime capturedAt;
  final String? currentCompanyId;
  final UserCompanyMembership? activeMembership;
  final ActiveCompanyContext? activeCompanyContext;
  final ActiveCompanyContext? _effectiveCompanyContext;
  final String? deviceId;
  final String? sessionId;

  /// Local seeded admin still using the bootstrap password.
  final bool mustChangePassword;

  SystemRole get systemRole => user.systemRole;

  ActiveCompanyContext? get companyContext => _effectiveCompanyContext;

  static ActiveCompanyContext? _buildContextFallback(
    AuthUser user,
    UserCompanyMembership? membership,
    String? currentCompanyId,
  ) {
    if (membership == null || !membership.isActive || membership.userId != user.id) {
      return null;
    }
    if (currentCompanyId != null && currentCompanyId.isNotEmpty && membership.companyId != currentCompanyId) {
      return null;
    }
    try {
      return ActiveCompanyContext.fromMembership(
        membership: membership,
        authenticatedUserId: user.id,
      );
    } catch (_) {
      return null;
    }
  }

  String? get activeCompanyId {
    if (_effectiveCompanyContext != null) {
      return _effectiveCompanyContext.companyId;
    }
    if (activeMembership != null) {
      // Invalid or mismatched membership supplied ➔ Fail closed!
      return null;
    }
    return currentCompanyId;
  }
  List<String> get availableCompanyIds => companies.map((c) => c.id).toList();

  String? get membershipId => activeMembership != null
      ? '${activeMembership!.userId}_${activeMembership!.companyId}'
      : null;

  bool get isCompanyBoundSession =>
      currentCompanyId != null &&
      currentCompanyId!.isNotEmpty &&
      activeMembership != null &&
      activeMembership!.isActive &&
      sessionId != null &&
      sessionId!.isNotEmpty;

  bool get isUnattachedSession => !isCompanyBoundSession;

  bool get hasCompany =>
      currentCompanyId != null && currentCompanyId!.isNotEmpty;

  /// Authoritative security invariant checker for Phase 3.
  ///
  /// Enforces:
  /// - User ID must be non-empty and user status must be active.
  /// - If membership is present: user IDs match, status is active, company IDs match.
  /// - If company context is present: company ID matches currentCompanyId.
  /// - Allows valid authenticated sessions with [companyContext] == null.
  bool get isValidSecuritySession {
    if (user.id.isEmpty) return false;
    if (user.status != 'active') return false;

    // Check membership integrity if present
    final m = activeMembership;
    if (m != null) {
      if (m.userId != user.id) return false; // Cross-user membership rejected
      if (!m.isActive) return false;        // Inactive/revoked membership rejected
      if (currentCompanyId != null &&
          currentCompanyId!.isNotEmpty &&
          m.companyId != currentCompanyId) {
        return false;                       // Company ID mismatch rejected
      }
    }

    // Check company context integrity if present
    final ctx = companyContext;
    if (ctx != null) {
      if (ctx.companyId.isEmpty) return false;
      if (currentCompanyId != null &&
          currentCompanyId!.isNotEmpty &&
          ctx.companyId != currentCompanyId) {
        return false;
      }
    }

    return true;
  }

  bool hasPermission(String code) {
    if (isSystemLevelPermission(code)) {
      return user.isSystemAdmin || permissions.contains(code);
    }
    final ctx = companyContext;
    if (ctx == null) return false;
    return ctx.hasPermission(code);
  }

  bool hasAnyPermission(Iterable<String> codes) =>
      codes.any(hasPermission);

  AuthCompany? get currentCompany {
    final id = activeCompanyId;
    if (id == null) return null;
    for (final c in companies) {
      if (c.id == id) return c;
    }
    return null;
  }

  AuthSessionSnapshot copyWith({
    AuthUser? user,
    List<AuthCompany>? companies,
    List<String>? roles,
    Set<String>? permissions,
    DateTime? capturedAt,
    String? currentCompanyId,
    UserCompanyMembership? activeMembership,
    ActiveCompanyContext? activeCompanyContext,
    bool clearCompany = false,
    String? deviceId,
    String? sessionId,
    bool? mustChangePassword,
  }) {
    return AuthSessionSnapshot(
      user: user ?? this.user,
      companies: companies ?? this.companies,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      capturedAt: capturedAt ?? this.capturedAt,
      currentCompanyId: clearCompany
          ? null
          : (currentCompanyId ?? this.currentCompanyId),
      activeMembership: clearCompany
          ? null
          : (activeMembership ?? this.activeMembership),
      activeCompanyContext: clearCompany
          ? null
          : (activeCompanyContext ?? this.activeCompanyContext),
      deviceId: deviceId ?? this.deviceId,
      sessionId: sessionId ?? this.sessionId,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'companies': companies.map((c) => c.toJson()).toList(),
    'roles': roles,
    'permissions': permissions.toList(),
    'capturedAt': capturedAt.toIso8601String(),
    'currentCompanyId': currentCompanyId,
    'activeMembership': activeMembership?.toJson(),
    'activeCompanyContext': _effectiveCompanyContext?.toJson(),
    'deviceId': deviceId,
    'sessionId': sessionId,
    'mustChangePassword': mustChangePassword,
  };

  factory AuthSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final companiesRaw = json['companies'];
    final rolesRaw = json['roles'];
    final permsRaw = json['permissions'];
    final membershipRaw = json['activeMembership'];
    final contextRaw = json['activeCompanyContext'];
    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
    );
    final membership = membershipRaw is Map
        ? UserCompanyMembership.fromJson(Map<String, dynamic>.from(membershipRaw))
        : null;
    final context = contextRaw is Map
        ? ActiveCompanyContext.fromJson(Map<String, dynamic>.from(contextRaw))
        : null;

    return AuthSessionSnapshot(
      user: user,
      companies: companiesRaw is List
          ? [
              for (final item in companiesRaw)
                if (item is Map)
                  AuthCompany.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const [],
      roles: rolesRaw is List
          ? [for (final r in rolesRaw) if (r is String) r]
          : const [],
      permissions: permsRaw is List
          ? {for (final p in permsRaw) if (p is String) p}
          : {},
      capturedAt:
          DateTime.tryParse(json['capturedAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      currentCompanyId: json['currentCompanyId'] as String?,
      activeMembership: membership,
      activeCompanyContext: context,
      deviceId: json['deviceId'] as String?,
      sessionId: json['sessionId'] as String?,
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }
}


class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'bearer',
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
}
