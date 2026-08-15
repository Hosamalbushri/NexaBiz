import 'auth_user.dart';

/// Local authorization snapshot used offline for UI gating.
///
/// Tokens are NOT stored here — they live in secure storage.
class AuthSessionSnapshot {
  const AuthSessionSnapshot({
    required this.user,
    required this.companies,
    required this.roles,
    required this.permissions,
    required this.capturedAt,
    this.currentCompanyId,
    this.deviceId,
    this.sessionId,
  });

  final AuthUser user;
  final List<AuthCompany> companies;
  final List<String> roles;
  final Set<String> permissions;
  final DateTime capturedAt;
  final String? currentCompanyId;
  final String? deviceId;
  final String? sessionId;

  bool get hasCompany =>
      currentCompanyId != null && currentCompanyId!.isNotEmpty;

  bool hasPermission(String code) => permissions.contains(code);

  bool hasAnyPermission(Iterable<String> codes) =>
      codes.any(permissions.contains);

  AuthCompany? get currentCompany {
    final id = currentCompanyId;
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
    bool clearCompany = false,
    String? deviceId,
    String? sessionId,
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
      deviceId: deviceId ?? this.deviceId,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'companies': companies.map((c) => c.toJson()).toList(),
    'roles': roles,
    'permissions': permissions.toList(),
    'capturedAt': capturedAt.toIso8601String(),
    'currentCompanyId': currentCompanyId,
    'deviceId': deviceId,
    'sessionId': sessionId,
  };

  factory AuthSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final companiesRaw = json['companies'];
    final rolesRaw = json['roles'];
    final permsRaw = json['permissions'];
    return AuthSessionSnapshot(
      user: AuthUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
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
      deviceId: json['deviceId'] as String?,
      sessionId: json['sessionId'] as String?,
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
