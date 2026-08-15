import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/hive_boxes.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';
import '../domain/local_permissions.dart';

/// Offline identity store (Hive). No network required.
class LocalAuthStore {
  LocalAuthStore();

  static const boxName = HiveBoxes.localAuth;
  static const _usersKey = 'users';
  static const _companiesKey = 'companies';
  static const _sessionKey = 'session_snapshot';
  static const _seededKey = 'seeded_v1';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }
    return Hive.openBox<dynamic>(boxName);
  }

  /// Ensures local company + admin with full permissions exist.
  Future<void> ensureSeeded() async {
    final box = await _box();
    if (box.get(_seededKey) == true) {
      // Still repair admin if somehow deleted.
      final users = _readUsers(box);
      if (users.any((u) => u.email == LocalAuthDefaults.adminEmail)) {
        return;
      }
    }

    final salt = generateUuidV4();
    final admin = _LocalUserRecord(
      id: LocalAuthDefaults.adminUserId,
      name: LocalAuthDefaults.adminName,
      email: LocalAuthDefaults.adminEmail,
      passwordSalt: salt,
      passwordHash: _hashPassword(LocalAuthDefaults.adminPassword, salt),
      status: 'active',
      isSuperAdmin: true,
      companyIds: const [LocalAuthDefaults.companyId],
      rolesByCompany: const {
        LocalAuthDefaults.companyId: LocalAuthDefaults.adminRole,
      },
      permissionsByCompany: {
        LocalAuthDefaults.companyId: List<String>.from(kAllLocalPermissions),
      },
    );

    final company = AuthCompany(
      id: LocalAuthDefaults.companyId,
      name: LocalAuthDefaults.companyName,
      code: LocalAuthDefaults.companyCode,
      role: LocalAuthDefaults.adminRole,
    );

    await box.put(_usersKey, [admin.toJson()]);
    await box.put(_companiesKey, [company.toJson()]);
    await box.put(_seededKey, true);
  }

  Future<AuthSessionSnapshot?> login({
    required String email,
    required String password,
    required String deviceId,
    String? companyId,
  }) async {
    await ensureSeeded();
    final box = await _box();
    final users = _readUsers(box);
    final normalized = email.trim().toLowerCase();
    _LocalUserRecord? user;
    for (final u in users) {
      if (u.email == normalized) {
        user = u;
        break;
      }
    }
    if (user == null || user.status != 'active') {
      return null;
    }
    final matched = user;
    final hash = _hashPassword(password.trim(), matched.passwordSalt);
    if (hash != matched.passwordHash) {
      return null;
    }

    final companies = _readCompanies(box)
        .where((c) => matched.companyIds.contains(c.id))
        .map((c) {
          final role = matched.rolesByCompany[c.id];
          return AuthCompany(
            id: c.id,
            name: c.name,
            code: c.code,
            role: role ?? c.role,
          );
        })
        .toList();

    if (companies.isEmpty) {
      return null;
    }

    var selectedId = companyId;
    if (selectedId == null ||
        !companies.any((c) => c.id == selectedId)) {
      selectedId = companies.first.id;
    }

    final permissions = Set<String>.from(
      matched.permissionsByCompany[selectedId] ??
          (matched.isSuperAdmin ? kAllLocalPermissions : const <String>[]),
    );
    final roles = <String>[
      if (matched.rolesByCompany[selectedId] != null)
        matched.rolesByCompany[selectedId]!,
      if (matched.isSuperAdmin &&
          matched.rolesByCompany[selectedId] != LocalAuthDefaults.adminRole)
        LocalAuthDefaults.adminRole,
    ];

    final snapshot = AuthSessionSnapshot(
      user: AuthUser(
        id: matched.id,
        name: matched.name,
        email: matched.email,
        status: matched.status,
        isSuperAdmin: matched.isSuperAdmin,
      ),
      companies: companies,
      roles: roles.toSet().toList(),
      permissions: permissions,
      capturedAt: DateTime.now().toUtc(),
      currentCompanyId: selectedId,
      deviceId: deviceId,
      sessionId: generateUuidV4(),
    );
    await saveSession(snapshot);
    return snapshot;
  }

  Future<void> saveSession(AuthSessionSnapshot? snapshot) async {
    final box = await _box();
    if (snapshot == null) {
      await box.delete(_sessionKey);
      return;
    }
    await box.put(_sessionKey, jsonEncode(snapshot.toJson()));
  }

  Future<AuthSessionSnapshot?> loadSession() async {
    final box = await _box();
    final raw = box.get(_sessionKey);
    if (raw is! String || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        return AuthSessionSnapshot.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (_) {}
    return null;
  }

  Future<AuthSessionSnapshot?> switchCompany({
    required AuthSessionSnapshot current,
    required String companyId,
  }) async {
    await ensureSeeded();
    final box = await _box();
    final users = _readUsers(box);
    _LocalUserRecord? user;
    for (final u in users) {
      if (u.id == current.user.id) {
        user = u;
        break;
      }
    }
    if (user == null || !user.companyIds.contains(companyId)) {
      return null;
    }
    AuthCompany? company;
    for (final c in _readCompanies(box)) {
      if (c.id == companyId) {
        company = c;
        break;
      }
    }
    if (company == null) return null;

    final permissions = Set<String>.from(
      user.permissionsByCompany[companyId] ??
          (user.isSuperAdmin ? kAllLocalPermissions : const <String>[]),
    );
    final role = user.rolesByCompany[companyId];
    final next = current.copyWith(
      currentCompanyId: companyId,
      permissions: permissions,
      roles: [
        if (role != null) role,
        if (user.isSuperAdmin) LocalAuthDefaults.adminRole,
      ].toSet().toList(),
      companies: current.companies,
      capturedAt: DateTime.now().toUtc(),
      sessionId: generateUuidV4(),
    );
    // Ensure selected company appears in list with role.
    final companies = [
      for (final c in current.companies)
        if (c.id == companyId)
          AuthCompany(
            id: c.id,
            name: c.name,
            code: c.code,
            role: role ?? c.role,
          )
        else
          c,
    ];
    final withCompanies = AuthSessionSnapshot(
      user: next.user,
      companies: companies,
      roles: next.roles,
      permissions: next.permissions,
      capturedAt: next.capturedAt,
      currentCompanyId: companyId,
      deviceId: next.deviceId,
      sessionId: next.sessionId,
    );
    await saveSession(withCompanies);
    return withCompanies;
  }

  List<_LocalUserRecord> _readUsers(Box<dynamic> box) {
    final raw = box.get(_usersKey);
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          _LocalUserRecord.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  List<AuthCompany> _readCompanies(Box<dynamic> box) {
    final raw = box.get(_companiesKey);
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          AuthCompany.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  static String _hashPassword(String password, String salt) {
    final digest = sha256.convert(utf8.encode('$salt::$password'));
    return digest.toString();
  }
}

class _LocalUserRecord {
  const _LocalUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordSalt,
    required this.passwordHash,
    required this.status,
    required this.isSuperAdmin,
    required this.companyIds,
    required this.rolesByCompany,
    required this.permissionsByCompany,
  });

  final String id;
  final String name;
  final String email;
  final String passwordSalt;
  final String passwordHash;
  final String status;
  final bool isSuperAdmin;
  final List<String> companyIds;
  final Map<String, String> rolesByCompany;
  final Map<String, List<String>> permissionsByCompany;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordSalt': passwordSalt,
    'passwordHash': passwordHash,
    'status': status,
    'isSuperAdmin': isSuperAdmin,
    'companyIds': companyIds,
    'rolesByCompany': rolesByCompany,
    'permissionsByCompany': permissionsByCompany,
  };

  factory _LocalUserRecord.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['rolesByCompany'];
    final permsRaw = json['permissionsByCompany'];
    return _LocalUserRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: (json['email'] as String? ?? '').toLowerCase(),
      passwordSalt: json['passwordSalt'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      isSuperAdmin: json['isSuperAdmin'] == true,
      companyIds: [
        if (json['companyIds'] is List)
          for (final id in json['companyIds'] as List)
            if (id is String) id,
      ],
      rolesByCompany: {
        if (rolesRaw is Map)
          for (final e in rolesRaw.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
      },
      permissionsByCompany: {
        if (permsRaw is Map)
          for (final e in permsRaw.entries)
            if (e.key is String && e.value is List)
              e.key as String: [
                for (final p in e.value as List)
                  if (p is String) p,
              ],
      },
    );
  }
}
