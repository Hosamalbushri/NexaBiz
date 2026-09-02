import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/encrypted_hive_box.dart';
import '../../../core/database/hive_boxes.dart';
import '../domain/entities/offline_authorization_snapshot.dart';

/// Secure storage provider for [OfflineAuthorizationSnapshot]s.
///
/// Encrypts and isolates permissions snapshots by (serverBaseUrl, companyId, userId).
///
/// Security guarantees:
/// - A snapshot for (User A, Company A) can NEVER be loaded for (User B, Company A).
/// - Every snapshot key includes a SHA-256 hash of the server URL, the companyId,
///   and the userId, preventing cross-context reuse.
/// - Logout MUST call [deleteSnapshot] or [deleteAllSnapshotsForUser] to remove
///   stale authorization state.
class OfflineAuthorizationStore {
  OfflineAuthorizationStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _boxName = HiveBoxes.localAuthEncrypted;
  static const _userIndexPrefix = 'offline_user_idx_';
  final FlutterSecureStorage _secure;
  bool? _secureAvailable;

  Future<bool> _canUseSecure() async {
    if (_secureAvailable != null) return _secureAvailable!;
    try {
      await _secure.read(key: '__probe__');
      _secureAvailable = true;
    } catch (_) {
      _secureAvailable = false;
    }
    return _secureAvailable!;
  }

  Future<Box<dynamic>> _hiveBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return EncryptedHive.openMigrated<dynamic>(
      encryptedBoxName: _boxName,
      legacyPlainBoxName: HiveBoxes.localAuth,
    );
  }

  /// Builds a storage key scoped to (serverBaseUrl, companyId, userId).
  ///
  /// Uses SHA-256 to produce a short, URL-safe, collision-resistant key.
  String _buildKey({
    required String serverBaseUrl,
    required String companyId,
    required String userId,
  }) {
    final cleanUrl = serverBaseUrl.trim().toLowerCase();
    final urlHash = sha256.convert(utf8.encode(cleanUrl)).toString().substring(0, 16);
    return 'offline_auth_${urlHash}_${companyId.trim()}_${userId.trim()}';
  }

  String _buildLegacyKey({
    required String serverBaseUrl,
    required String companyId,
    required String userId,
  }) {
    final cleanUrl = serverBaseUrl.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'offline_perm_snapshot_${cleanUrl}_${companyId.trim()}_${userId.trim()}';
  }

  String _userIndexKey(String userId) => '$_userIndexPrefix$userId';

  /// Saves or replaces an authorization snapshot for the given context.
  Future<void> saveSnapshot(OfflineAuthorizationSnapshot snapshot) async {
    final key = _buildKey(
      serverBaseUrl: snapshot.serverBaseUrl,
      companyId: snapshot.companyId,
      userId: snapshot.userId,
    );
    final jsonStr = jsonEncode(snapshot.toJson());

    if (await _canUseSecure()) {
      await _secure.write(key: key, value: jsonStr);
      await _addToUserIndex(snapshot.userId, key);
    } else {
      final box = await _hiveBox();
      await box.put(key, jsonStr);
      await _addToUserIndexHive(box, snapshot.userId, key);
    }
  }

  /// Loads an authorization snapshot matching the exact (serverBaseUrl, companyId, userId) context.
  /// Includes safe migration from legacy keys.
  Future<OfflineAuthorizationSnapshot?> loadSnapshot({
    required String serverBaseUrl,
    required String companyId,
    required String userId,
  }) async {
    final key = _buildKey(
      serverBaseUrl: serverBaseUrl,
      companyId: companyId,
      userId: userId,
    );

    String? raw;
    if (await _canUseSecure()) {
      raw = await _secure.read(key: key);
    } else {
      final box = await _hiveBox();
      raw = box.get(key) as String?;
    }

    // Try migrating from legacy key if new key format was not found
    if (raw == null || raw.isEmpty) {
      final legacyKey = _buildLegacyKey(
        serverBaseUrl: serverBaseUrl,
        companyId: companyId,
        userId: userId,
      );

      String? legacyRaw;
      if (await _canUseSecure()) {
        legacyRaw = await _secure.read(key: legacyKey);
      } else {
        final box = await _hiveBox();
        legacyRaw = box.get(legacyKey) as String?;
      }

      if (legacyRaw != null && legacyRaw.isNotEmpty) {
        // Save to new key format
        if (await _canUseSecure()) {
          await _secure.write(key: key, value: legacyRaw);
          await _secure.delete(key: legacyKey);
        } else {
          final box = await _hiveBox();
          await box.put(key, legacyRaw);
          await box.delete(legacyKey);
        }
        raw = legacyRaw;
      }
    }

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) {
        return null;
      }
      final snapshot = OfflineAuthorizationSnapshot.fromJson(map);
      if (!snapshot.matchesContext(
        userId: userId,
        companyId: companyId,
        serverBaseUrl: serverBaseUrl,
      )) {
        debugPrint('OfflineAuthorizationStore: Snapshot context mismatch for key $key');
        return null;
      }
      return snapshot;
    } catch (e) {
      debugPrint('OfflineAuthorizationStore: Failed to decode snapshot for key $key: $e');
      return null;
    }
  }

  /// Deletes a specific snapshot.
  Future<void> deleteSnapshot({
    required String serverBaseUrl,
    required String companyId,
    required String userId,
  }) async {
    final key = _buildKey(
      serverBaseUrl: serverBaseUrl,
      companyId: companyId,
      userId: userId,
    );
    final legacyKey = _buildLegacyKey(
      serverBaseUrl: serverBaseUrl,
      companyId: companyId,
      userId: userId,
    );

    if (await _canUseSecure()) {
      await _secure.delete(key: key);
      await _secure.delete(key: legacyKey);
      await _removeFromUserIndex(userId, key);
      await _removeFromUserIndex(userId, legacyKey);
    } else {
      final box = await _hiveBox();
      await box.delete(key);
      await box.delete(legacyKey);
      await _removeFromUserIndexHive(box, userId, key);
      await _removeFromUserIndexHive(box, userId, legacyKey);
    }
  }
  /// MUST be called on logout to prevent stale authorization state from being
  /// inherited by the next user who logs in on this device.
  Future<void> deleteAllSnapshotsForUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      if (await _canUseSecure()) {
        final indexKey = _userIndexKey(userId);
        final raw = await _secure.read(key: indexKey);
        if (raw != null && raw.isNotEmpty) {
          final keys = _parseIndex(raw);
          for (final k in keys) {
            await _secure.delete(key: k);
          }
        }
        await _secure.delete(key: indexKey);
      } else {
        final box = await _hiveBox();
        final indexKey = _userIndexKey(userId);
        final raw = box.get(indexKey) as String?;
        if (raw != null && raw.isNotEmpty) {
          final keys = _parseIndex(raw);
          for (final k in keys) {
            await box.delete(k);
          }
        }
        await box.delete(indexKey);
      }
    } catch (e) {
      debugPrint('OfflineAuthorizationStore: deleteAllSnapshotsForUser failed for $userId: $e');
    }
  }

  // ---- Index helpers -------------------------------------------------------

  Future<void> _addToUserIndex(String userId, String snapshotKey) async {
    try {
      final indexKey = _userIndexKey(userId);
      final raw = await _secure.read(key: indexKey);
      final keys = raw != null && raw.isNotEmpty ? _parseIndex(raw) : <String>{};
      keys.add(snapshotKey);
      await _secure.write(key: indexKey, value: keys.join(','));
    } catch (_) {}
  }

  Future<void> _removeFromUserIndex(String userId, String snapshotKey) async {
    try {
      final indexKey = _userIndexKey(userId);
      final raw = await _secure.read(key: indexKey);
      if (raw == null || raw.isEmpty) return;
      final keys = _parseIndex(raw)..remove(snapshotKey);
      await _secure.write(key: indexKey, value: keys.join(','));
    } catch (_) {}
  }

  Future<void> _addToUserIndexHive(Box<dynamic> box, String userId, String snapshotKey) async {
    try {
      final indexKey = _userIndexKey(userId);
      final raw = box.get(indexKey) as String?;
      final keys = raw != null && raw.isNotEmpty ? _parseIndex(raw) : <String>{};
      keys.add(snapshotKey);
      await box.put(indexKey, keys.join(','));
    } catch (_) {}
  }

  Future<void> _removeFromUserIndexHive(Box<dynamic> box, String userId, String snapshotKey) async {
    try {
      final indexKey = _userIndexKey(userId);
      final raw = box.get(indexKey) as String?;
      if (raw == null || raw.isEmpty) return;
      final keys = _parseIndex(raw)..remove(snapshotKey);
      await box.put(indexKey, keys.join(','));
    } catch (_) {}
  }

  Set<String> _parseIndex(String raw) {
    return raw.split(',').where((k) => k.isNotEmpty).toSet();
  }
}



