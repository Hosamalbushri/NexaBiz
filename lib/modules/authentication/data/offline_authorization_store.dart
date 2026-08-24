import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/encrypted_hive_box.dart';
import '../../../core/database/hive_boxes.dart';
import '../domain/entities/offline_authorization_snapshot.dart';

/// Secure storage provider for [OfflineAuthorizationSnapshot]s.
///
/// Encrypts and isolates permissions snapshots by (serverBaseUrl, companyId, userId).
class OfflineAuthorizationStore {
  OfflineAuthorizationStore({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _boxName = HiveBoxes.localAuthEncrypted;
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

  String _buildKey({
    required String serverBaseUrl,
    required String companyId,
    required String userId,
  }) {
    final cleanUrl = serverBaseUrl.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'offline_perm_snapshot_${cleanUrl}_${companyId.trim()}_${userId.trim()}';
  }

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
    } else {
      final box = await _hiveBox();
      await box.put(key, jsonStr);
    }
  }

  /// Loads an authorization snapshot matching the exact (serverBaseUrl, companyId, userId) context.
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

    if (await _canUseSecure()) {
      await _secure.delete(key: key);
    } else {
      final box = await _hiveBox();
      await box.delete(key);
    }
  }
}
