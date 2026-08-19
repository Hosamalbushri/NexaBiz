import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/encrypted_hive_box.dart';
import '../../../core/database/hive_boxes.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';
import '../domain/local_permissions.dart';
import '../domain/models/password_change_exception.dart';

/// Offline identity store (Hive). No network required.
class LocalAuthStore {
  LocalAuthStore();

  static const boxName = HiveBoxes.localAuthEncrypted;
  static const _legacyBoxName = HiveBoxes.localAuth;
  static const _usersKey = 'users';
  static const _companiesKey = 'companies';
  static const _sessionKey = 'session_snapshot';
  static const _seededKey = 'seeded_v1';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }
    return EncryptedHive.openMigrated<dynamic>(
      encryptedBoxName: boxName,
      legacyPlainBoxName: _legacyBoxName,
    );
  }

  /// Ensures local company + admin with full permissions exist.
  ///
  /// When already seeded, keeps Super Admin permission lists in sync with
  /// [kAllLocalPermissions] so newly added module codes appear after upgrades.
  Future<void> ensureSeeded() async {
    final box = await _box();
    if (box.get(_seededKey) == true) {
      final users = _readUsers(box);
      final adminExists =
          users.any((u) => u.email == LocalAuthDefaults.adminEmail);
      if (adminExists) {
        await _syncSuperAdminPermissions(box, users);
        await _flagDefaultPasswordUsers(box);
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
      mustChangePassword: true,
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

  /// Merges newly catalogued permission codes into every Super Admin user.
  Future<void> _syncSuperAdminPermissions(
    Box<dynamic> box,
    List<_LocalUserRecord> users,
  ) async {
    final catalog = kAllLocalPermissions.toSet();
    var changed = false;
    final nextUsers = <_LocalUserRecord>[];
    for (final user in users) {
      if (!user.isSuperAdmin) {
        nextUsers.add(user);
        continue;
      }
      final nextPerms = <String, List<String>>{};
      final companyIds = user.companyIds.isEmpty
          ? const [LocalAuthDefaults.companyId]
          : user.companyIds;
      for (final companyId in companyIds) {
        final existing = user.permissionsByCompany[companyId] ?? const <String>[];
        final merged = {...existing, ...catalog}.toList(growable: false)
          ..sort();
        nextPerms[companyId] = merged;
        if (merged.length != existing.length ||
            !existing.toSet().containsAll(catalog)) {
          changed = true;
        }
      }
      // Also refresh any other company keys already stored.
      for (final entry in user.permissionsByCompany.entries) {
        if (nextPerms.containsKey(entry.key)) continue;
        final merged = {...entry.value, ...catalog}.toList(growable: false)
          ..sort();
        nextPerms[entry.key] = merged;
        if (merged.length != entry.value.length) changed = true;
      }
      nextUsers.add(
        _LocalUserRecord(
          id: user.id,
          name: user.name,
          email: user.email,
          passwordSalt: user.passwordSalt,
          passwordHash: user.passwordHash,
          status: user.status,
          isSuperAdmin: user.isSuperAdmin,
          mustChangePassword: user.mustChangePassword,
          companyIds: user.companyIds,
          rolesByCompany: user.rolesByCompany,
          permissionsByCompany: nextPerms,
        ),
      );
    }
    if (!changed) return;
    await box.put(
      _usersKey,
      [for (final u in nextUsers) u.toJson()],
    );

    // Refresh persisted session so the launcher sees new codes without logout.
    // Session is stored as a JSON string (see [saveSession]).
    final rawSession = box.get(_sessionKey);
    if (rawSession is! String || rawSession.isEmpty) return;
    try {
      final decoded = jsonDecode(rawSession);
      if (decoded is! Map) return;
      final snapshot = AuthSessionSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!snapshot.user.isSuperAdmin &&
          !snapshot.roles.contains(LocalAuthDefaults.adminRole)) {
        return;
      }
      _LocalUserRecord? admin;
      for (final u in nextUsers) {
        if (u.id == snapshot.user.id && u.isSuperAdmin) {
          admin = u;
          break;
        }
      }
      if (admin == null) {
        for (final u in nextUsers) {
          if (u.isSuperAdmin) {
            admin = u;
            break;
          }
        }
      }
      final companyId =
          snapshot.currentCompanyId ?? LocalAuthDefaults.companyId;
      final companyPerms = admin?.permissionsByCompany[companyId];
      final refreshed = snapshot.copyWith(
        permissions: {
          ...snapshot.permissions,
          ...catalog,
          ...?companyPerms,
        },
      );
      await saveSession(refreshed);
    } catch (_) {
      // Keep user rows updated; next login rebuilds the session.
    }
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

    final stored = matched.permissionsByCompany[selectedId];
    final permissions = Set<String>.from(
      matched.isSuperAdmin
          ? {...?stored, ...kAllLocalPermissions}
          : (stored ?? const <String>[]),
    );
    final roles = <String>[
      if (matched.rolesByCompany[selectedId] != null)
        matched.rolesByCompany[selectedId]!,
      if (matched.isSuperAdmin &&
          matched.rolesByCompany[selectedId] != LocalAuthDefaults.adminRole)
        LocalAuthDefaults.adminRole,
    ];

    var mustChange = matched.mustChangePassword ||
        _usesDefaultPassword(matched);
    if (mustChange && !matched.mustChangePassword) {
      await _writeUsers(box, [
        for (final u in users)
          if (u.id == matched.id)
            u.copyWith(mustChangePassword: true)
          else
            u,
      ]);
    }

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
      mustChangePassword: mustChange,
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
      if (map is! Map) return null;
      var snapshot = AuthSessionSnapshot.fromJson(
        Map<String, dynamic>.from(map),
      );
      // Safety net: Super Admin sessions always include the current catalog
      // so new modules appear after app upgrades without wiping Hive.
      if (snapshot.user.isSuperAdmin ||
          snapshot.roles.contains(LocalAuthDefaults.adminRole)) {
        final merged = {...snapshot.permissions, ...kAllLocalPermissions};
        if (merged.length != snapshot.permissions.length ||
            !snapshot.permissions.containsAll(kAllLocalPermissions)) {
          snapshot = snapshot.copyWith(permissions: merged);
          await saveSession(snapshot);
        }
      }
      final users = _readUsers(box);
      for (final u in users) {
        if (u.id == snapshot.user.id) {
          final mustChange = u.mustChangePassword || _usesDefaultPassword(u);
          if (mustChange != snapshot.mustChangePassword) {
            snapshot = snapshot.copyWith(mustChangePassword: mustChange);
            await saveSession(snapshot);
          }
          break;
        }
      }
      return snapshot;
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

    final stored = user.permissionsByCompany[companyId];
    final permissions = Set<String>.from(
      user.isSuperAdmin
          ? {...?stored, ...kAllLocalPermissions}
          : (stored ?? const <String>[]),
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
      mustChangePassword: user.mustChangePassword || _usesDefaultPassword(user),
    );
    await saveSession(withCompanies);
    return withCompanies;
  }

  /// Replaces the local password and clears [mustChangePassword].
  Future<AuthSessionSnapshot> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final next = newPassword.trim();
    if (next.length < 8) {
      throw const PasswordChangeException(PasswordChangeException.tooShort);
    }
    if (next == LocalAuthDefaults.adminPassword) {
      throw const PasswordChangeException(PasswordChangeException.sameAsDefault);
    }

    final box = await _box();
    final users = _readUsers(box);
    _LocalUserRecord? user;
    for (final u in users) {
      if (u.id == userId) {
        user = u;
        break;
      }
    }
    if (user == null) {
      throw const PasswordChangeException(PasswordChangeException.notFound);
    }
    final hash = _hashPassword(currentPassword, user.passwordSalt);
    if (hash != user.passwordHash) {
      throw const PasswordChangeException(PasswordChangeException.wrongCurrent);
    }

    final salt = generateUuidV4();
    final updated = user.copyWith(
      passwordSalt: salt,
      passwordHash: _hashPassword(next, salt),
      mustChangePassword: false,
    );
    await _writeUsers(box, [
      for (final u in users)
        if (u.id == userId) updated else u,
    ]);

    final existing = await loadSession();
    if (existing == null || existing.user.id != userId) {
      throw const PasswordChangeException(PasswordChangeException.notFound);
    }
    final snapshot = existing.copyWith(mustChangePassword: false);
    await saveSession(snapshot);
    return snapshot;
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

  Future<void> _writeUsers(Box<dynamic> box, List<_LocalUserRecord> users) {
    return box.put(_usersKey, [for (final u in users) u.toJson()]);
  }

  Future<void> _flagDefaultPasswordUsers(Box<dynamic> box) async {
    final users = _readUsers(box);
    var changed = false;
    final next = <_LocalUserRecord>[];
    for (final u in users) {
      if (!u.mustChangePassword && _usesDefaultPassword(u)) {
        changed = true;
        next.add(u.copyWith(mustChangePassword: true));
      } else {
        next.add(u);
      }
    }
    if (changed) {
      await _writeUsers(box, next);
    }
  }

  bool _usesDefaultPassword(_LocalUserRecord user) {
    if (user.passwordSalt.isEmpty || user.passwordHash.isEmpty) {
      return false;
    }
    return user.passwordHash ==
        _hashPassword(LocalAuthDefaults.adminPassword, user.passwordSalt);
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
    this.mustChangePassword = false,
  });

  final String id;
  final String name;
  final String email;
  final String passwordSalt;
  final String passwordHash;
  final String status;
  final bool isSuperAdmin;
  final bool mustChangePassword;
  final List<String> companyIds;
  final Map<String, String> rolesByCompany;
  final Map<String, List<String>> permissionsByCompany;

  _LocalUserRecord copyWith({
    String? passwordSalt,
    String? passwordHash,
    bool? mustChangePassword,
  }) {
    return _LocalUserRecord(
      id: id,
      name: name,
      email: email,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
      status: status,
      isSuperAdmin: isSuperAdmin,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      companyIds: companyIds,
      rolesByCompany: rolesByCompany,
      permissionsByCompany: permissionsByCompany,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordSalt': passwordSalt,
    'passwordHash': passwordHash,
    'status': status,
    'isSuperAdmin': isSuperAdmin,
    'mustChangePassword': mustChangePassword,
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
      mustChangePassword: json['mustChangePassword'] == true,
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
