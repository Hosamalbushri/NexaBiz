import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/encrypted_hive_box.dart';
import '../../../core/database/hive_boxes.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/entities/active_company_context.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/auth_user.dart';
import '../domain/entities/system_role.dart';
import '../domain/entities/user_company_membership.dart';
import '../domain/local_permissions.dart';
import '../domain/models/password_change_exception.dart';
import '../domain/services/local_brute_force_protector.dart';

export '../domain/local_permissions.dart';

class CompanyCreationException implements Exception {
  const CompanyCreationException([this.message = 'فشلت عملية إنشاء الشركة.']);
  final String message;

  @override
  String toString() => message;
}

/// Offline identity store (Hive). No network required.
class LocalAuthStore {
  LocalAuthStore({
    Box<dynamic>? box,
    LocalBruteForceProtector? bruteForceProtector,
  })  : _injectedBox = box,
        _bruteForceProtector =
            bruteForceProtector ?? LocalBruteForceProtector();

  final Box<dynamic>? _injectedBox;
  final LocalBruteForceProtector _bruteForceProtector;
  final Set<String> _terminatedSessionIds = {};

  LocalBruteForceProtector get bruteForceProtector => _bruteForceProtector;

  static const boxName = HiveBoxes.localAuthEncrypted;
  static const _legacyBoxName = HiveBoxes.localAuth;
  static const _usersKey = 'users';
  static const _companiesKey = 'companies';
  static const _membershipsKey = 'memberships';
  static const _sessionKey = 'session_snapshot';
  static const _seededKey = 'seeded_v1';

  Future<Box<dynamic>> _box() async {
    final injected = _injectedBox;
    if (injected != null && injected.isOpen) {
      return injected;
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<dynamic>(boxName);
    }
    return EncryptedHive.openMigrated<dynamic>(
      encryptedBoxName: boxName,
      legacyPlainBoxName: _legacyBoxName,
    );
  }

  /// Ensures super admin permissions are synced for existing users.
  Future<void> ensureSeeded() async {
    final box = await _box();
    final users = _readUsers(box);
    if (users.isNotEmpty) {
      await _syncSuperAdminPermissions(box, users);
    }
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
      final companyIds = user.companyIds;
      for (final companyId in companyIds) {
        final existing =
            user.permissionsByCompany[companyId] ?? const <String>[];
        final merged = {...existing, ...catalog}.toList(growable: false)
          ..sort();
        nextPerms[companyId] = merged;
        if (merged.length != existing.length ||
            !existing.toSet().containsAll(catalog)) {
          changed = true;
        }
      }
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
    await box.put(_usersKey, [for (final u in nextUsers) u.toJson()]);

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
      admin ??= nextUsers.firstWhere(
        (u) => u.isSuperAdmin,
        orElse: () => nextUsers.first,
      );
      final companyId =
          snapshot.currentCompanyId ?? LocalAuthDefaults.companyId;
      final companyPerms = admin.permissionsByCompany[companyId];
      final refreshed = snapshot.copyWith(
        permissions: {...snapshot.permissions, ...catalog, ...?companyPerms},
      );
      await saveSession(refreshed);
    } catch (_) {}
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

    _bruteForceProtector.checkLockout(normalized);

    _LocalUserRecord? user;
    for (final u in users) {
      if (u.email == normalized || u.name.trim().toLowerCase() == normalized) {
        user = u;
        break;
      }
    }
    if (user == null || user.status != 'active') {
      _bruteForceProtector.recordFailedAttempt(normalized);
      return null;
    }
    final matched = user;

    if (!_verifyAndMigratePassword(matched, password, box, users)) {
      _bruteForceProtector.recordFailedAttempt(normalized);
      return null;
    }

    _bruteForceProtector.recordSuccess(normalized);

    final allMemberships = _readMemberships(box);
    final userMemberships = allMemberships
        .where((m) => m.userId == matched.id && m.isActive)
        .toList();

    if (userMemberships.isEmpty) {
      if (matched.companyIds.isNotEmpty) {
        for (final cid in matched.companyIds) {
          final role = matched.rolesByCompany[cid] ?? 'Owner';
          final perms = matched.permissionsByCompany[cid] ?? kAllLocalPermissions;
          userMemberships.add(
            UserCompanyMembership(
              userId: matched.id,
              companyId: cid,
              role: role,
              status: 'active',
              permissions: perms,
            ),
          );
        }
        await _writeMemberships(box, [...allMemberships, ...userMemberships]);
      }
    }

    final allCompanies = _readCompanies(box);
    final authorizedCompanyIds = userMemberships.map((m) => m.companyId).toSet();
    final companies = allCompanies
        .where((c) => matched.isSuperAdmin || authorizedCompanyIds.contains(c.id))
        .map((c) {
          final m = userMemberships.firstWhere(
            (mem) => mem.companyId == c.id,
            orElse: () => UserCompanyMembership(
              userId: matched.id,
              companyId: c.id,
              role: 'Member',
              status: 'active',
              permissions: const [],
            ),
          );
          return AuthCompany(
            id: c.id,
            name: c.name,
            code: c.code,
            role: m.role,
          );
        })
        .toList();

    String? selectedId = companyId;
    if (selectedId != null && selectedId.isNotEmpty) {
      final hasAccess = authorizedCompanyIds.contains(selectedId) ||
          (matched.isSuperAdmin && allCompanies.any((c) => c.id == selectedId));
      if (!hasAccess) {
        return null;
      }
    } else {
      if (companies.isNotEmpty) {
        selectedId = companies.first.id;
      } else {
        selectedId = null;
      }
    }

    UserCompanyMembership? activeMembership;
    Set<String> permissions = {};
    List<String> roles = [];

    if (selectedId != null) {
      activeMembership = userMemberships.firstWhere(
        (m) => m.companyId == selectedId,
        orElse: () => UserCompanyMembership(
          userId: matched.id,
          companyId: selectedId!,
          role: matched.rolesByCompany[selectedId] ?? 'Member',
          status: 'active',
          permissions: matched.permissionsByCompany[selectedId] ?? const [],
        ),
      );

      final stored = matched.permissionsByCompany[selectedId];
      final isOwnerOrAdmin = matched.isSuperAdmin ||
          activeMembership.role == 'Owner' ||
          activeMembership.role == LocalAuthDefaults.adminRole;

      permissions = Set<String>.from(
        isOwnerOrAdmin
            ? {...?stored, ...kAllLocalPermissions}
            : (activeMembership.permissions.isNotEmpty
                ? activeMembership.permissions
                : (stored ?? const <String>[])),
      );

      roles = [activeMembership.role];
    }

    final activeCompanyContext = (activeMembership != null &&
            selectedId != null &&
            activeMembership.companyId == selectedId &&
            activeMembership.status == 'active')
        ? ActiveCompanyContext.fromMembership(
            membership: activeMembership,
            authenticatedUserId: matched.id,
            companyName: companies
                .cast<AuthCompany?>()
                .firstWhere((c) => c?.id == selectedId, orElse: () => null)
                ?.name,
            companyCode: companies
                .cast<AuthCompany?>()
                .firstWhere((c) => c?.id == selectedId, orElse: () => null)
                ?.code,
          )
        : null;

    final snapshot = AuthSessionSnapshot(
      user: AuthUser(
        id: matched.id,
        name: matched.name,
        email: matched.email,
        status: matched.status,
        systemRole: matched.isSuperAdmin ? SystemRole.systemAdmin : SystemRole.regularUser,
      ),
      companies: companies,
      roles: roles,
      permissions: permissions,
      capturedAt: DateTime.now().toUtc(),
      currentCompanyId: selectedId,
      activeMembership: activeMembership,
      activeCompanyContext: activeCompanyContext,
      deviceId: deviceId,
      sessionId: generateUuidV4(),
      mustChangePassword: matched.mustChangePassword,
    );

    await saveSession(snapshot);
    return snapshot;
  }

  /// Generates or retrieves an OS-protected biometric token for the specified user.
  Future<String?> getOrCreateBiometricToken(String email) async {
    await ensureSeeded();
    final box = await _box();
    final users = _readUsers(box);
    final normalized = email.trim().toLowerCase();

    _LocalUserRecord? user;
    for (final u in users) {
      if (u.email == normalized || u.name.trim().toLowerCase() == normalized) {
        user = u;
        break;
      }
    }
    if (user == null || user.status != 'active') return null;

    final key = 'biometric_token_${user.id}';
    var token = box.get(key) as String?;
    if (token == null || token.isEmpty) {
      token = generateUuidV4();
      await box.put(key, token);
    }
    return token;
  }

  /// Authenticates user using an OS-protected biometric token without raw passwords.
  Future<AuthSessionSnapshot?> loginWithBiometricToken({
    required String email,
    required String biometricToken,
    required String deviceId,
    String? companyId,
  }) async {
    await ensureSeeded();
    final box = await _box();
    final users = _readUsers(box);
    final normalized = email.trim().toLowerCase();

    _bruteForceProtector.checkLockout(normalized);

    _LocalUserRecord? user;
    for (final u in users) {
      if (u.email == normalized || u.name.trim().toLowerCase() == normalized) {
        user = u;
        break;
      }
    }
    if (user == null || user.status != 'active') {
      _bruteForceProtector.recordFailedAttempt(normalized);
      return null;
    }
    final matched = user;

    final key = 'biometric_token_${matched.id}';
    final storedToken = box.get(key) as String?;
    if (storedToken == null || storedToken.isEmpty || storedToken != biometricToken) {
      _bruteForceProtector.recordFailedAttempt(normalized);
      return null;
    }

    _bruteForceProtector.recordSuccess(normalized);

    final allMemberships = _readMemberships(box);
    final userMemberships = allMemberships
        .where((m) => m.userId == matched.id && m.isActive)
        .toList();

    if (userMemberships.isEmpty) {
      if (matched.companyIds.isNotEmpty) {
        for (final cid in matched.companyIds) {
          final role = matched.rolesByCompany[cid] ?? 'Owner';
          final perms = matched.permissionsByCompany[cid] ?? kAllLocalPermissions;
          userMemberships.add(
            UserCompanyMembership(
              userId: matched.id,
              companyId: cid,
              role: role,
              status: 'active',
              permissions: perms,
            ),
          );
        }
        await _writeMemberships(box, [...allMemberships, ...userMemberships]);
      }
    }

    final allCompanies = _readCompanies(box);
    final authorizedCompanyIds = userMemberships.map((m) => m.companyId).toSet();
    final companies = allCompanies
        .where((c) => matched.isSuperAdmin || authorizedCompanyIds.contains(c.id))
        .map((c) {
          final m = userMemberships.firstWhere(
            (mem) => mem.companyId == c.id,
            orElse: () => UserCompanyMembership(
              userId: matched.id,
              companyId: c.id,
              role: 'Member',
              status: 'active',
              permissions: const [],
            ),
          );
          return AuthCompany(
            id: c.id,
            name: c.name,
            code: c.code,
            role: m.role,
          );
        })
        .toList();

    String? selectedId = companyId;
    if (selectedId != null && selectedId.isNotEmpty) {
      final hasAccess = authorizedCompanyIds.contains(selectedId) ||
          (matched.isSuperAdmin && allCompanies.any((c) => c.id == selectedId));
      if (!hasAccess) {
        return null;
      }
    } else {
      if (companies.length == 1 &&
          authorizedCompanyIds.contains(companies.first.id)) {
        selectedId = companies.first.id;
      } else {
        selectedId = null;
      }
    }

    UserCompanyMembership? activeMembership;
    Set<String> permissions = {};
    List<String> roles = [];

    if (selectedId != null) {
      activeMembership = userMemberships.firstWhere(
        (m) => m.companyId == selectedId,
        orElse: () => UserCompanyMembership(
          userId: matched.id,
          companyId: selectedId!,
          role: matched.rolesByCompany[selectedId] ?? 'Member',
          status: 'active',
          permissions: matched.permissionsByCompany[selectedId] ?? const [],
        ),
      );

      final stored = matched.permissionsByCompany[selectedId];
      final isOwnerOrAdmin = matched.isSuperAdmin ||
          activeMembership.role == 'Owner' ||
          activeMembership.role == LocalAuthDefaults.adminRole;

      permissions = Set<String>.from(
        isOwnerOrAdmin
            ? {...?stored, ...kAllLocalPermissions}
            : (activeMembership.permissions.isNotEmpty
                ? activeMembership.permissions
                : (stored ?? const <String>[])),
      );

      roles = [activeMembership.role];
    }

    final activeCompanyContext = (activeMembership != null &&
            selectedId != null &&
            activeMembership.companyId == selectedId &&
            activeMembership.status == 'active')
        ? ActiveCompanyContext.fromMembership(
            membership: activeMembership.copyWith(permissions: permissions.toList()),
            authenticatedUserId: matched.id,
            companyName: companies
                .cast<AuthCompany?>()
                .firstWhere((c) => c?.id == selectedId, orElse: () => null)
                ?.name,
            companyCode: companies
                .cast<AuthCompany?>()
                .firstWhere((c) => c?.id == selectedId, orElse: () => null)
                ?.code,
          )
        : null;

    final snapshot = AuthSessionSnapshot(
      user: AuthUser(
        id: matched.id,
        name: matched.name,
        email: matched.email,
        status: matched.status,
        systemRole: matched.isSuperAdmin ? SystemRole.systemAdmin : SystemRole.regularUser,
      ),
      companies: companies,
      roles: roles,
      permissions: permissions,
      capturedAt: DateTime.now().toUtc(),
      currentCompanyId: selectedId,
      activeMembership: activeMembership,
      activeCompanyContext: activeCompanyContext,
      deviceId: deviceId,
      sessionId: generateUuidV4(),
      mustChangePassword: matched.mustChangePassword,
    );

    await saveSession(snapshot);
    return snapshot;
  }

  /// Invalidates biometric authentication token for user (e.g. on password change).
  Future<void> revokeBiometricToken(String userId) async {
    final box = await _box();
    await box.delete('biometric_token_$userId');
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
      final isOwnerOrAdmin = snapshot.user.isSuperAdmin ||
          snapshot.roles.contains('Owner') ||
          snapshot.roles.contains(LocalAuthDefaults.adminRole) ||
          snapshot.roles.contains(LocalAuthDefaults.ownerRole);
      final allCompanies = _readCompanies(box);
      bool dirty = false;
      List<AuthCompany> updatedCompanies = _readAuthorizedCompanies(box, snapshot.user);

      if (updatedCompanies.length != snapshot.companies.length) {
        dirty = true;
      }

      if ((snapshot.currentCompanyId == null || snapshot.currentCompanyId!.isEmpty) &&
          updatedCompanies.isNotEmpty) {
        final firstCid = updatedCompanies.first.id;
        final memberships = _readMemberships(box);
        final m = memberships.firstWhere(
          (mem) => mem.userId == snapshot.user.id && mem.companyId == firstCid && mem.isActive,
          orElse: () => UserCompanyMembership(
            userId: snapshot.user.id,
            companyId: firstCid,
            role: snapshot.user.isSuperAdmin ? 'Owner' : 'Member',
            status: 'active',
            permissions: snapshot.user.isSuperAdmin ? kAllLocalPermissions.toList() : const [],
          ),
        );
        final activeContext = ActiveCompanyContext.fromMembership(
          membership: m,
          authenticatedUserId: snapshot.user.id,
          companyName: updatedCompanies.first.name,
          companyCode: updatedCompanies.first.code,
        );
        snapshot = snapshot.copyWith(
          currentCompanyId: firstCid,
          activeMembership: m,
          activeCompanyContext: activeContext,
          roles: [m.role],
          permissions: Set<String>.from(m.permissions.isNotEmpty
              ? m.permissions
              : (snapshot.user.isSuperAdmin ? kAllLocalPermissions : const [])),
        );
        dirty = true;
      } else if (snapshot.currentCompanyId != null) {
        final cid = snapshot.currentCompanyId!;
        final companyExists = allCompanies.any((c) => c.id == cid);
        final memberships = _readMemberships(box);
        final hasActiveMembership = snapshot.user.isSuperAdmin ||
            memberships.any((m) => m.userId == snapshot.user.id && m.companyId == cid && m.isActive);

        if (!companyExists || !hasActiveMembership) {
          snapshot = snapshot.copyWith(
            clearCompany: true,
            roles: const [],
            permissions: snapshot.user.isSuperAdmin ? kAllLocalPermissions.toSet() : const {},
          );
          dirty = true;
        }
      }

      if (isOwnerOrAdmin && snapshot.currentCompanyId != null) {
        final merged = {...snapshot.permissions, ...kAllLocalPermissions};
        if (merged.length != snapshot.permissions.length ||
            !snapshot.permissions.containsAll(kAllLocalPermissions)) {
          snapshot = snapshot.copyWith(permissions: merged, companies: updatedCompanies);
          await saveSession(snapshot);
          dirty = false;
        }
      }
      if (dirty) {
        snapshot = snapshot.copyWith(companies: updatedCompanies);
        await saveSession(snapshot);
      }
      return snapshot;
    } catch (_) {}
    return null;
  }

  bool isSessionActive(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) return false;
    return !_terminatedSessionIds.contains(sessionId);
  }

  Future<void> terminateCurrentCompanySession(AuthSessionSnapshot? session) async {
    if (session == null) return;
    if (session.sessionId != null && session.sessionId!.isNotEmpty) {
      _terminatedSessionIds.add(session.sessionId!);
    }
    await saveSession(null);
  }

  Future<void> logout([AuthSessionSnapshot? session]) async {
    final current = session ?? await loadSession();
    if (current != null && current.sessionId != null && current.sessionId!.isNotEmpty) {
      _terminatedSessionIds.add(current.sessionId!);
    }
    await saveSession(null);
  }

  Future<AuthSessionSnapshot?> validateAndRestoreSession() async {
    final session = await loadSession();
    if (session == null) return null;

    if (session.sessionId != null && _terminatedSessionIds.contains(session.sessionId)) {
      await saveSession(null);
      return null;
    }

    final box = await _box();
    final users = _readUsers(box);
    final user = users.firstWhere(
      (u) => u.id == session.user.id && u.status == 'active',
      orElse: () => const _LocalUserRecord(
        id: '',
        name: '',
        email: '',
        passwordSalt: '',
        passwordHash: '',
        status: '',
        isSuperAdmin: false,
        companyIds: [],
        rolesByCompany: {},
        permissionsByCompany: {},
      ),
    );
    if (user.id.isEmpty) {
      await saveSession(null);
      return null;
    }

    if (session.currentCompanyId == null ||
        session.currentCompanyId!.isEmpty ||
        session.activeMembership == null) {
      return session;
    }

    final companies = _readCompanies(box);
    final companyExists = companies.any((c) => c.id == session.currentCompanyId);

    final memberships = _readMemberships(box);
    final membership = memberships.firstWhere(
      (m) =>
          m.userId == session.user.id &&
          m.companyId == session.currentCompanyId &&
          m.isActive,
      orElse: () => const UserCompanyMembership(userId: '', companyId: '', role: '', status: 'inactive'),
    );

    if (!companyExists || (!membership.isActive && !session.user.isSuperAdmin)) {
      final safeSnapshot = session.copyWith(
        clearCompany: true,
        roles: const [],
        permissions: session.user.isSuperAdmin ? kAllLocalPermissions.toSet() : const {},
      );
      await saveSession(safeSnapshot);
      return safeSnapshot;
    }

    return session;
    return session;
  }

  Future<AuthSessionSnapshot?> switchCompany({
    required AuthSessionSnapshot current,
    required String companyId,
  }) async {
    // 0. Idempotency Check: Same-company switch returns current snapshot (Rule 11)
    if (current.currentCompanyId == companyId) {
      return current;
    }

    await ensureSeeded();
    final box = await _box();

    // 1. Validate Membership in Target Company (Rule 3)
    final memberships = _readMemberships(box);
    var membership = memberships.firstWhere(
      (m) => m.userId == current.user.id && m.companyId == companyId && m.isActive,
      orElse: () => const UserCompanyMembership(userId: '', companyId: '', role: '', status: 'inactive'),
    );

    if ((!membership.isActive || membership.companyId != companyId) && current.user.isSuperAdmin) {
      membership = UserCompanyMembership(
        userId: current.user.id,
        companyId: companyId,
        role: 'Owner',
        status: 'active',
        permissions: kAllLocalPermissions,
      );
    }

    if (!membership.isActive || membership.companyId != companyId) {
      // Rule 12: Preserve current session context on failure (no saveSession(null))
      return null;
    }

    // 2. Validate Company Exists
    AuthCompany? company;
    for (final c in _readCompanies(box)) {
      if (c.id == companyId) {
        company = c;
        break;
      }
    }
    if (company == null) {
      // Rule 12: Preserve current session context on failure
      return null;
    }

    // 3. Validate User Status
    final users = _readUsers(box);
    _LocalUserRecord? user;
    for (final u in users) {
      if (u.id == current.user.id && u.status == 'active') {
        user = u;
        break;
      }
    }
    if (user == null) {
      // Rule 12: Preserve current session context on failure
      return null;
    }

    // 4. Build Target Company permissions
    final stored = user.permissionsByCompany[companyId];
    final isOwnerOrAdmin = membership.role == 'Owner' ||
        membership.role == LocalAuthDefaults.adminRole;

    final permissions = Set<String>.from(
      isOwnerOrAdmin
          ? {...?stored, ...kAllLocalPermissions}
          : (membership.permissions.isNotEmpty
              ? membership.permissions
              : (stored ?? const <String>[])),
    );

    // Rules 1 & 2: Preserve existing session identity — sessionIdBefore == sessionIdAfter
    final stableSessionId = (current.sessionId != null && current.sessionId!.isNotEmpty)
        ? current.sessionId!
        : generateUuidV4();

    final updatedMembership = membership.copyWith(
      permissions: permissions.toList(),
    );

    final activeCompanyContext = ActiveCompanyContext.fromMembership(
      membership: updatedMembership,
      authenticatedUserId: current.user.id,
      companyName: company.name,
      companyCode: company.code,
    );

    final authorizedCompanies = _readAuthorizedCompanies(box, current.user);

    final next = current.copyWith(
      currentCompanyId: companyId,
      activeMembership: updatedMembership,
      activeCompanyContext: activeCompanyContext,
      permissions: permissions,
      roles: [membership.role],
      companies: authorizedCompanies,
      capturedAt: DateTime.now().toUtc(),
      sessionId: stableSessionId,
    );

    await saveSession(next);
    return next;
  }

  Future<AuthSessionSnapshot> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw const PasswordChangeException(PasswordChangeException.tooShort);
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

    if (!_verifyAndMigratePassword(user, currentPassword, box, users)) {
      throw const PasswordChangeException(
        PasswordChangeException.wrongCurrent,
      );
    }

    final salt = generateUuidV4();
    final updated = user.copyWith(
      passwordSalt: salt,
      passwordHash: hashPassword(newPassword, salt),
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

  Future<void> updateLocalAdminCredentials({
    required String newEmail,
    required String newPassword,
    String? newName,
  }) async {
    final box = await _box();
    final users = _readUsers(box);
    if (users.isEmpty) return;
    _LocalUserRecord? primaryOwner;
    for (final u in users) {
      if (u.isSuperAdmin) {
        primaryOwner = u;
        break;
      }
    }
    primaryOwner ??= users.first;
    final salt = generateUuidV4();
    final updated = primaryOwner.copyWith(
      email: newEmail.trim().toLowerCase(),
      name: newName != null && newName.trim().isNotEmpty
          ? newName.trim()
          : primaryOwner.name,
      passwordSalt: salt,
      passwordHash: hashPassword(newPassword, salt),
      mustChangePassword: false,
    );
    await _writeUsers(box, [
      for (final u in users)
        if (u.id == primaryOwner.id) updated else u,
    ]);
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

  List<UserCompanyMembership> _readMemberships(Box<dynamic> box) {
    final raw = box.get(_membershipsKey);
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          UserCompanyMembership.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<void> _writeMemberships(
    Box<dynamic> box,
    List<UserCompanyMembership> memberships,
  ) {
    return box.put(_membershipsKey, [for (final m in memberships) m.toJson()]);
  }

  Future<void> addMembership(UserCompanyMembership membership) async {
    final box = await _box();
    final memberships = _readMemberships(box);
    final updated = [
      for (final m in memberships)
        if (!(m.userId == membership.userId && m.companyId == membership.companyId)) m,
      membership,
    ];
    await _writeMemberships(box, updated);
  }

  Future<void> revokeMembership(String userId, String companyId) async {
    final box = await _box();
    final memberships = _readMemberships(box);
    final updated = memberships
        .where((m) => !(m.userId == userId && m.companyId == companyId))
        .toList();
    await _writeMemberships(box, updated);

    final currentSession = await loadSession();
    if (currentSession != null &&
        currentSession.user.id == userId &&
        currentSession.currentCompanyId == companyId) {
      if (currentSession.sessionId != null && currentSession.sessionId!.isNotEmpty) {
        _terminatedSessionIds.add(currentSession.sessionId!);
      }
      await saveSession(null);
    }
  }

  Future<AuthCompany> createCompanyWithAdmin({
    required AuthSessionSnapshot creatorSession,
    required String companyName,
    required String companyCode,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    String adminRole = 'Admin',
    List<String>? adminPermissions,
  }) async {
    // 1. Authorization Check: Creator must be authenticated and authorized
    if (!creatorSession.isCompanyBoundSession && !creatorSession.user.isSuperAdmin) {
      throw const CompanyCreationException('يجب توفر جلسة مصادقة صالحة لإنشاء شركة جديدة.');
    }

    final canCreateCompany = creatorSession.hasPermission('manage_companies') ||
        creatorSession.roles.contains('Owner') ||
        creatorSession.roles.contains('Admin') ||
        creatorSession.user.isSuperAdmin;

    if (!canCreateCompany) {
      throw const CompanyCreationException('ليس لديك صلاحية لإنشاء شركة جديدة.');
    }

    // 2. Credentials Validation: Password must not be default/weak
    final normPassword = adminPassword.trim();
    if (normPassword.length < 8 ||
        normPassword.toLowerCase() == 'admin123' ||
        normPassword.toLowerCase() == 'password123' ||
        normPassword.toLowerCase() == '12345678') {
      throw const CompanyCreationException('كلمة مرور مسؤول الشركة غير آمنة أو تستخدم القيمة الافتراضية.');
    }

    final box = await _box();

    final origCompanies = box.get(_companiesKey);
    final origUsers = box.get(_usersKey);
    final origMemberships = box.get(_membershipsKey);

    try {
      final companyId = generateUuidV4();
      final newCompany = AuthCompany(
        id: companyId,
        name: companyName.trim(),
        code: companyCode.trim(),
        role: adminRole,
      );

      final normEmail = adminEmail.trim().toLowerCase();
      final users = _readUsers(box);
      _LocalUserRecord? adminUser;
      for (final u in users) {
        if (u.email == normEmail) {
          adminUser = u;
          break;
        }
      }

      final String adminUserId;
      final List<_LocalUserRecord> updatedUsers = [...users];

      if (adminUser != null) {
        adminUserId = adminUser.id;
        final updatedCompanyIds = {...adminUser.companyIds, companyId}.toList();
        final updatedRoles = Map<String, String>.from(adminUser.rolesByCompany);
        updatedRoles[companyId] = adminRole;
        final updatedPerms = Map<String, List<String>>.from(adminUser.permissionsByCompany);
        updatedPerms[companyId] = adminPermissions ?? kAllLocalPermissions;

        final updatedRecord = adminUser.copyWith(
          companyIds: updatedCompanyIds,
          rolesByCompany: updatedRoles,
          permissionsByCompany: updatedPerms,
        );

        for (var i = 0; i < updatedUsers.length; i++) {
          if (updatedUsers[i].id == adminUserId) {
            updatedUsers[i] = updatedRecord;
            break;
          }
        }
      } else {
        adminUserId = generateUuidV4();
        final salt = generateUuidV4();
        final passHash = hashPassword(normPassword, salt);
        final newUserRecord = _LocalUserRecord(
          id: adminUserId,
          name: adminName.trim(),
          email: normEmail,
          passwordSalt: salt,
          passwordHash: passHash,
          status: 'active',
          isSuperAdmin: false,
          mustChangePassword: false,
          companyIds: [companyId],
          rolesByCompany: {companyId: adminRole},
          permissionsByCompany: {companyId: adminPermissions ?? kAllLocalPermissions},
        );
        updatedUsers.add(newUserRecord);
      }

      final memberships = _readMemberships(box);
      final newMembership = UserCompanyMembership(
        userId: adminUserId,
        companyId: companyId,
        role: adminRole,
        status: 'active',
        permissions: adminPermissions ?? kAllLocalPermissions,
        createdAt: DateTime.now().toUtc(),
      );

      final addedMemberships = [newMembership];
      if (creatorSession.user.id != adminUserId) {
        addedMemberships.add(
          UserCompanyMembership(
            userId: creatorSession.user.id,
            companyId: companyId,
            role: 'Owner',
            status: 'active',
            permissions: kAllLocalPermissions,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }

      final allCompanies = _readCompanies(box);
      await box.put(_companiesKey, [for (final c in [...allCompanies, newCompany]) c.toJson()]);
      await _writeUsers(box, updatedUsers);
      await _writeMemberships(box, [...memberships, ...addedMemberships]);

      final currentSession = await loadSession();
      if (currentSession != null) {
        final isCreatorAdmin = (currentSession.user.id == adminUserId);
        if (isCreatorAdmin) {
          final hasComp = currentSession.companies.any((c) => c.id == newCompany.id);
          final updatedCompanies = hasComp
              ? currentSession.companies
              : [...currentSession.companies, newCompany];
          final activeId = (currentSession.currentCompanyId != null &&
                  currentSession.currentCompanyId!.isNotEmpty)
              ? currentSession.currentCompanyId
              : newCompany.id;
          final updatedSession = currentSession.copyWith(
            companies: updatedCompanies,
            currentCompanyId: activeId,
          );
          await saveSession(updatedSession);
        }
      }

      return newCompany;
    } catch (e) {
      if (origCompanies != null) await box.put(_companiesKey, origCompanies);
      if (origUsers != null) await box.put(_usersKey, origUsers);
      if (origMemberships != null) await box.put(_membershipsKey, origMemberships);
      rethrow;
    }
  }

  Future<AuthCompany> createCompany({
    required String name,
    required String code,
  }) async {
    await ensureSeeded();
    final box = await _box();
    final allCompanies = _readCompanies(box);

    final cleanName = name.trim();
    final cleanCode = code.trim();
    if (cleanName.isEmpty || cleanCode.isEmpty) {
      throw ArgumentError('اسم وكود الشركة يجب ألا يكونا فارغين.');
    }

    final existing = allCompanies.cast<AuthCompany?>().firstWhere(
      (c) =>
          c != null &&
          (c.code.toLowerCase() == cleanCode.toLowerCase() ||
              c.name.toLowerCase() == cleanName.toLowerCase()),
      orElse: () => null,
    );
    if (existing != null) {
      throw StateError('الشركة موجودة بالفعل بنفس الكود أو الاسم.');
    }

    final companyId = generateUuidV4();
    final newCompany = AuthCompany(
      id: companyId,
      name: cleanName,
      code: cleanCode,
      role: LocalAuthDefaults.adminRole,
    );

    final updatedCompanies = [...allCompanies, newCompany];
    await box.put(_companiesKey, [for (final c in updatedCompanies) c.toJson()]);
    return newCompany;
  }

  Future<AuthUser> createUser({
    required String name,
    required String email,
    required String password,
    SystemRole systemRole = SystemRole.regularUser,
  }) async {
    final box = await _box();
    final users = [..._readUsers(box)];

    final normEmail = email.trim().toLowerCase();
    final normName = name.trim();

    if (normEmail.isEmpty || normName.isEmpty) {
      throw ArgumentError('الاسم والبريد الإلكتروني مطلوبان.');
    }

    final existing = users.cast<_LocalUserRecord?>().firstWhere(
      (u) => u != null && u.email == normEmail,
      orElse: () => null,
    );
    if (existing != null) {
      throw StateError('يوجد مستخدم مسجل بالفعل بهذا البريد الإلكتروني.');
    }

    final userId = generateUuidV4();
    final salt = generateUuidV4();
    final passHash = hashPassword(password, salt);

    final newUserRecord = _LocalUserRecord(
      id: userId,
      name: normName,
      email: normEmail,
      passwordSalt: salt,
      passwordHash: passHash,
      status: 'active',
      isSuperAdmin: systemRole == SystemRole.systemAdmin,
      mustChangePassword: false,
      companyIds: const [],
      rolesByCompany: const {},
      permissionsByCompany: const {},
    );

    users.add(newUserRecord);
    await _writeUsers(box, users);

    return AuthUser(
      id: userId,
      name: normName,
      email: normEmail,
      systemRole: systemRole,
      status: 'active',
    );
  }

  Future<UserCompanyMembership> createMembership({
    required String userId,
    required String companyId,
    required String role,
    List<String> permissions = const [],
    String status = 'active',
  }) async {
    final box = await _box();
    final users = [..._readUsers(box)];
    final companies = _readCompanies(box);
    final memberships = _readMemberships(box);

    final user = users.cast<_LocalUserRecord?>().firstWhere(
      (u) => u != null && u.id == userId,
      orElse: () => null,
    );
    if (user == null) {
      throw ArgumentError('المستخدم المطلوب غير موجود.');
    }

    final company = companies.cast<AuthCompany?>().firstWhere(
      (c) => c != null && c.id == companyId,
      orElse: () => null,
    );
    if (company == null) {
      throw ArgumentError('الشركة المطلوبة غير موجودة.');
    }

    final existingMembership = memberships.cast<UserCompanyMembership?>().firstWhere(
      (m) => m != null && m.userId == userId && m.companyId == companyId,
      orElse: () => null,
    );
    if (existingMembership != null) {
      throw StateError('يوجد انتماء مسجل بالفعل للمستخدم في هذه الشركة.');
    }

    final newMembership = UserCompanyMembership(
      userId: userId,
      companyId: companyId,
      role: role.trim().isNotEmpty ? role.trim() : 'Member',
      status: status,
      permissions: permissions,
      createdAt: DateTime.now().toUtc(),
    );

    await _writeMemberships(box, [...memberships, newMembership]);

    // Synchronize user record mappings for compatibility
    final updatedCompanyIds = {...user.companyIds, companyId}.toList();
    final updatedRoles = Map<String, String>.from(user.rolesByCompany);
    updatedRoles[companyId] = role;
    final updatedPerms = Map<String, List<String>>.from(user.permissionsByCompany);
    updatedPerms[companyId] = permissions;

    final updatedRecord = user.copyWith(
      companyIds: updatedCompanyIds,
      rolesByCompany: updatedRoles,
      permissionsByCompany: updatedPerms,
    );

    for (var i = 0; i < users.length; i++) {
      if (users[i].id == userId) {
        users[i] = updatedRecord;
        break;
      }
    }
    await _writeUsers(box, users);

    return newMembership;
  }

  Future<UserCompanyMembership> updateMembershipStatus({
    required String userId,
    required String companyId,
    required String status,
  }) async {
    final box = await _box();
    final memberships = _readMemberships(box);

    final idx = memberships.indexWhere(
      (m) => m.userId == userId && m.companyId == companyId,
    );

    if (idx == -1) {
      throw ArgumentError('انتماء المستخدم في هذه الشركة غير موجود.');
    }

    final updated = UserCompanyMembership(
      userId: userId,
      companyId: companyId,
      role: memberships[idx].role,
      status: status,
      permissions: memberships[idx].permissions,
      createdAt: memberships[idx].createdAt,
    );

    memberships[idx] = updated;
    await _writeMemberships(box, memberships);
    return updated;
  }

  Future<AuthCompany?> getPrimaryCompany() async {
    final box = await _box();
    final companies = _readCompanies(box);
    if (companies.isEmpty) return null;
    return companies.first;
  }

  Future<LocalOwnerUserRecord?> getPrimaryOwnerUser() async {
    final box = await _box();
    final users = _readUsers(box);
    if (users.isEmpty) return null;
    _LocalUserRecord? owner;
    for (final u in users) {
      if (u.isSuperAdmin && u.status == 'active') {
        owner = u;
        break;
      }
    }
    owner ??= users.firstWhere(
      (u) => u.status == 'active',
      orElse: () => users.first,
    );
    return LocalOwnerUserRecord(
      id: owner.id,
      name: owner.name,
      email: owner.email,
      companyIds: owner.companyIds,
      rolesByCompany: owner.rolesByCompany,
      permissionsByCompany: owner.permissionsByCompany,
    );
  }

  Future<void> createOwnerAndCompany({
    required String companyId,
    required String companyName,
    required String companyCode,
    required String ownerEmail,
    required String ownerPassword,
    required String ownerName,
  }) async {
    final box = await _box();
    final salt = generateUuidV4();
    final cleanEmail = ownerEmail.trim().toLowerCase();
    final cleanName = ownerName.trim().isNotEmpty ? ownerName.trim() : 'Owner';
    final cleanCompanyId = companyId.trim().isNotEmpty
        ? companyId.trim()
        : LocalAuthDefaults.companyId;
    final cleanCompanyName = companyName.trim();
    final cleanCompanyCode = companyCode.trim();

    final company = AuthCompany(
      id: cleanCompanyId,
      name: cleanCompanyName,
      code: cleanCompanyCode,
      role: 'Owner',
    );

    final ownerUserId = generateUuidV4();
    final ownerUser = _LocalUserRecord(
      id: ownerUserId,
      name: cleanName,
      email: cleanEmail,
      passwordSalt: salt,
      passwordHash: hashPassword(ownerPassword, salt),
      status: 'active',
      isSuperAdmin: true,
      mustChangePassword: false,
      companyIds: [cleanCompanyId],
      rolesByCompany: {
        cleanCompanyId: 'Owner',
      },
      permissionsByCompany: {
        cleanCompanyId: List<String>.from(kAllLocalPermissions),
      },
    );

    final membership = UserCompanyMembership(
      userId: ownerUserId,
      companyId: cleanCompanyId,
      role: 'Owner',
      status: 'active',
      permissions: List<String>.from(kAllLocalPermissions),
      createdAt: DateTime.now().toUtc(),
    );

    await box.put(_companiesKey, [company.toJson()]);
    await box.put(_usersKey, [ownerUser.toJson()]);
    await box.put(_membershipsKey, [membership.toJson()]);
    await box.put(_seededKey, true);
  }

  /// Creates the initial System Administrator without creating an automatic company or membership.
  ///
  /// The initial administrator is a SYSTEM identity with SystemRole.systemAdmin
  /// and exists with activeCompanyContext == null.
  Future<AuthUser> createInitialSystemAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final box = await _box();
    final users = [..._readUsers(box)];

    final existing = users.cast<_LocalUserRecord?>().firstWhere(
      (u) => u != null && u.isSuperAdmin,
      orElse: () => null,
    );

    if (existing != null) {
      return AuthUser(
        id: existing.id,
        name: existing.name,
        email: existing.email,
        systemRole: SystemRole.systemAdmin,
        status: existing.status,
      );
    }

    final salt = generateUuidV4();
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'System Admin';

    final adminUserId = generateUuidV4();
    final adminUserRecord = _LocalUserRecord(
      id: adminUserId,
      name: cleanName,
      email: cleanEmail,
      passwordSalt: salt,
      passwordHash: hashPassword(password, salt),
      status: 'active',
      isSuperAdmin: true,
      mustChangePassword: false,
      companyIds: const [],
      rolesByCompany: const {},
      permissionsByCompany: const {},
    );

    users.add(adminUserRecord);
    await box.put(_usersKey, users.map((u) => u.toJson()).toList());
    await box.put(_seededKey, true);

    return AuthUser(
      id: adminUserId,
      name: cleanName,
      email: cleanEmail,
      systemRole: SystemRole.systemAdmin,
      status: 'active',
    );
  }

  Future<void> clearAuthData() async {
    final box = await _box();
    await box.delete(_companiesKey);
    await box.delete(_usersKey);
    await box.delete(_membershipsKey);
    await box.delete(_sessionKey);
    await box.delete(_seededKey);
  }

  Future<String?> getAdminEmail() async {
    await ensureSeeded();
    final box = await _box();
    final users = _readUsers(box);
    for (final u in users) {
      if ((u.isSuperAdmin || u.id == LocalAuthDefaults.adminUserId) &&
          u.email.trim().isNotEmpty) {
        return u.email;
      }
    }
    if (users.isNotEmpty) {
      return users.first.email;
    }
    return null;
  }

  Future<bool> hasConfiguredAdmin() async {
    final box = await _box();
    final users = _readUsers(box);
    for (final u in users) {
      if ((u.isSuperAdmin || u.id == LocalAuthDefaults.adminUserId) &&
          u.email.trim().isNotEmpty) {
        return true;
      }
    }
    return users.isNotEmpty &&
        users.any((u) => u.email.trim().isNotEmpty && u.status == 'active');
  }

  List<AuthCompany> _readCompanies(Box<dynamic> box) {
    final raw = box.get(_companiesKey);
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) AuthCompany.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  List<AuthCompany> _readAuthorizedCompanies(Box<dynamic> box, AuthUser user) {
    final allCompanies = _readCompanies(box);
    final memberships = _readMemberships(box);
    final userMemberships = memberships
        .where((m) => m.userId == user.id && m.isActive)
        .toList();
    final authorizedCompanyIds = userMemberships.map((m) => m.companyId).toSet();

    return allCompanies
        .where((c) => user.isSuperAdmin || authorizedCompanyIds.contains(c.id))
        .map((c) {
          final m = userMemberships.firstWhere(
            (mem) => mem.companyId == c.id,
            orElse: () => UserCompanyMembership(
              userId: user.id,
              companyId: c.id,
              role: user.isSuperAdmin ? 'Owner' : 'Member',
              status: 'active',
              permissions: const [],
            ),
          );
          return AuthCompany(
            id: c.id,
            name: c.name,
            code: c.code,
            role: m.role,
          );
        })
        .toList();
  }

  static String hashPassword(String password, String salt) {
    final hmacSha256 = Hmac(sha256, utf8.encode(password));
    final saltBytes = utf8.encode(salt);
    var u = hmacSha256.convert([...saltBytes, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < 100000; i++) {
      u = hmacSha256.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    final hexDigest =
        result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '\$pbkdf2-sha256\$v=1\$i=100000\$$hexDigest';
  }

  static String _legacy10kHashPassword(String password, String salt) {
    final hmacSha256 = Hmac(sha256, utf8.encode(password));
    final saltBytes = utf8.encode(salt);
    var u = hmacSha256.convert([...saltBytes, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < 10000; i++) {
      u = hmacSha256.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _legacySingleSha256HashPassword(String password, String salt) {
    final digest = sha256.convert(utf8.encode('$salt::$password'));
    return digest.toString();
  }

  bool _verifyAndMigratePassword(
    _LocalUserRecord user,
    String rawPassword,
    Box<dynamic> box,
    List<_LocalUserRecord> users,
  ) {
    if (rawPassword.isEmpty && user.passwordHash.isNotEmpty) {
      return false;
    }

    final modernHash = hashPassword(rawPassword, user.passwordSalt);
    if (_constantTimeEquals(modernHash, user.passwordHash)) {
      return true;
    }

    final legacy10k = _legacy10kHashPassword(rawPassword, user.passwordSalt);
    if (_constantTimeEquals(legacy10k, user.passwordHash)) {
      _rehashAndPersist(user, rawPassword, box, users);
      return true;
    }

    final legacySingleSha256 =
        _legacySingleSha256HashPassword(rawPassword, user.passwordSalt);
    if (_constantTimeEquals(legacySingleSha256, user.passwordHash)) {
      _rehashAndPersist(user, rawPassword, box, users);
      return true;
    }

    return false;
  }

  void _rehashAndPersist(
    _LocalUserRecord user,
    String rawPassword,
    Box<dynamic> box,
    List<_LocalUserRecord> users,
  ) {
    final newSalt = generateUuidV4();
    final newHash = hashPassword(rawPassword, newSalt);
    final updatedUser = user.copyWith(
      passwordSalt: newSalt,
      passwordHash: newHash,
    );
    final updatedUsers = [
      for (final u in users)
        if (u.id == user.id) updatedUser else u,
    ];
    _writeUsers(box, updatedUsers);
  }

  static bool _constantTimeEquals(String a, String b) {
    final aUnits = utf8.encode(a);
    final bUnits = utf8.encode(b);
    if (aUnits.length != bUnits.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < aUnits.length; i++) {
      result |= aUnits[i] ^ bUnits[i];
    }
    return result == 0;
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
    String? name,
    String? email,
    String? passwordSalt,
    String? passwordHash,
    bool? mustChangePassword,
    List<String>? companyIds,
    Map<String, String>? rolesByCompany,
    Map<String, List<String>>? permissionsByCompany,
  }) {
    return _LocalUserRecord(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      passwordHash: passwordHash ?? this.passwordHash,
      status: status,
      isSuperAdmin: isSuperAdmin,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      companyIds: companyIds ?? this.companyIds,
      rolesByCompany: rolesByCompany ?? this.rolesByCompany,
      permissionsByCompany: permissionsByCompany ?? this.permissionsByCompany,
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

class LocalOwnerUserRecord {
  const LocalOwnerUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.companyIds,
    required this.rolesByCompany,
    required this.permissionsByCompany,
  });

  final String id;
  final String name;
  final String email;
  final List<String> companyIds;
  final Map<String, String> rolesByCompany;
  final Map<String, List<String>> permissionsByCompany;
}
