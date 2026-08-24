import 'package:flutter/foundation.dart';

/// Domain snapshot of server-assigned roles & permissions for offline RBAC.
///
/// Security Invariants:
/// - Password hashes, access tokens, and biometric templates MUST NOT be stored.
/// - Snapshots are strictly bound to (userId, companyId, serverBaseUrl).
@immutable
class OfflineAuthorizationSnapshot {
  const OfflineAuthorizationSnapshot({
    required this.userId,
    required this.companyId,
    required this.email,
    required this.roles,
    required this.permissions,
    required this.snapshotCreatedAt,
    required this.lastServerAuthenticatedAt,
    required this.serverBaseUrl,
    this.authorizationVersion = 1,
    this.snapshotVersion = 1,
  });

  final String userId;
  final String companyId;
  final String email;
  final List<String> roles;
  final Set<String> permissions;
  final DateTime snapshotCreatedAt;
  final DateTime lastServerAuthenticatedAt;
  final String serverBaseUrl;
  final int authorizationVersion;
  final int snapshotVersion;

  /// Verifies if this snapshot matches the active user, company, and server context.
  bool matchesContext({
    required String userId,
    required String companyId,
    required String serverBaseUrl,
  }) {
    return this.userId == userId &&
        this.companyId == companyId &&
        _normalizeUrl(this.serverBaseUrl) == _normalizeUrl(serverBaseUrl);
  }

  static String _normalizeUrl(String url) {
    var u = url.trim().toLowerCase();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'companyId': companyId,
        'email': email,
        'roles': roles,
        'permissions': permissions.toList(),
        'snapshotCreatedAt': snapshotCreatedAt.toIso8601String(),
        'lastServerAuthenticatedAt': lastServerAuthenticatedAt.toIso8601String(),
        'serverBaseUrl': serverBaseUrl,
        'authorizationVersion': authorizationVersion,
        'snapshotVersion': snapshotVersion,
      };

  factory OfflineAuthorizationSnapshot.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final permsSet = <String>{};
    if (rawPerms is List) {
      for (final p in rawPerms) {
        if (p is String && p.isNotEmpty) permsSet.add(p);
      }
    }
    final rawRoles = json['roles'];
    final rolesList = <String>[];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String && r.isNotEmpty) rolesList.add(r);
      }
    }
    return OfflineAuthorizationSnapshot(
      userId: json['userId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: rolesList,
      permissions: permsSet,
      snapshotCreatedAt:
          DateTime.tryParse(json['snapshotCreatedAt'] as String? ?? '') ??
              DateTime.now(),
      lastServerAuthenticatedAt:
          DateTime.tryParse(json['lastServerAuthenticatedAt'] as String? ?? '') ??
              DateTime.now(),
      serverBaseUrl: json['serverBaseUrl'] as String? ?? '',
      authorizationVersion: json['authorizationVersion'] as int? ?? 1,
      snapshotVersion: json['snapshotVersion'] as int? ?? 1,
    );
  }

  OfflineAuthorizationSnapshot copyWith({
    String? userId,
    String? companyId,
    String? email,
    List<String>? roles,
    Set<String>? permissions,
    DateTime? snapshotCreatedAt,
    DateTime? lastServerAuthenticatedAt,
    String? serverBaseUrl,
    int? authorizationVersion,
    int? snapshotVersion,
  }) {
    return OfflineAuthorizationSnapshot(
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      snapshotCreatedAt: snapshotCreatedAt ?? this.snapshotCreatedAt,
      lastServerAuthenticatedAt:
          lastServerAuthenticatedAt ?? this.lastServerAuthenticatedAt,
      serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
      authorizationVersion: authorizationVersion ?? this.authorizationVersion,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
    );
  }
}
