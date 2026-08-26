import 'package:flutter/foundation.dart';

/// Domain snapshot of server-assigned roles & permissions for offline RBAC.
///
/// Security Invariants:
/// - Password hashes, access tokens, and biometric templates MUST NOT be stored.
/// - Snapshots are strictly bound to (userId, companyId, serverBaseUrl).
/// - [deviceId] binds this snapshot to a specific device when present.
///   Legacy snapshots without deviceId are treated as unbound (no restriction).
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
    this.deviceId,
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

  /// Optional device identifier for device-bound offline authorization.
  ///
  /// When non-null, offline login MUST reject requests from a different device.
  /// When null (legacy snapshots), no device restriction is applied.
  final String? deviceId;

  /// Returns true when the offline authorization snapshot has exceeded its
  /// valid window since the last server authentication.
  ///
  /// Uses the same [graceDuration] policy as [EntitlementServiceImpl]
  /// (default 14 days) so there is a single source of truth for the grace period.
  bool isExpired({Duration graceDuration = const Duration(days: 14)}) {
    final deadline = lastServerAuthenticatedAt.add(graceDuration);
    return DateTime.now().toUtc().isAfter(deadline);
  }

  /// Returns the UTC timestamp at which this snapshot expires.
  DateTime expiresAt({Duration graceDuration = const Duration(days: 14)}) {
    return lastServerAuthenticatedAt.add(graceDuration);
  }

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

  /// Verifies device binding when [deviceId] is present in this snapshot.
  ///
  /// Returns true when:
  /// - This snapshot has no [deviceId] (legacy / unbound).
  /// - The provided [currentDeviceId] matches this snapshot's [deviceId].
  bool matchesDevice(String? currentDeviceId) {
    if (deviceId == null || deviceId!.isEmpty) {
      // No device binding recorded — allow (backward compat).
      return true;
    }
    return deviceId == currentDeviceId;
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
        if (deviceId != null) 'deviceId': deviceId,
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
      // deviceId defaults to null — legacy snapshots are unbound (backward compat).
      deviceId: json['deviceId'] as String?,
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
    Object? deviceId = _sentinel,
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
      deviceId: identical(deviceId, _sentinel)
          ? this.deviceId
          : deviceId as String?,
    );
  }

  static const Object _sentinel = Object();
}
