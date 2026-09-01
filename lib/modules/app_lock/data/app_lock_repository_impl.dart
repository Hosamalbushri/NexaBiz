import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/database/encrypted_hive_box.dart';
import '../../../core/database/hive_boxes.dart';
import '../domain/entities/app_lock_state.dart';
import '../domain/repositories/app_lock_repository.dart';

/// Hive-backed App Lock store. Persists only salt + PIN hash (never raw PIN).
class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl({Box<dynamic>? box}) : _box = box;

  Box<dynamic>? _box;

  static const boxName = HiveBoxes.appLockEncrypted;
  static const _legacyBoxName = HiveBoxes.appLock;

  static const _enabledKey = 'enabled';
  static const _policyKey = 'policy';
  static const _saltKey = 'pin_salt';
  static const _hashKey = 'pin_hash';
  static const _biometricKey = 'biometric_enabled';
  static const _failedKey = 'failed_attempts';
  static const _lockoutKey = 'lockout_until';

  Future<Box<dynamic>> _open() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<dynamic>(boxName);
      return _box!;
    }
    _box = await EncryptedHive.openMigrated<dynamic>(
      encryptedBoxName: boxName,
      legacyPlainBoxName: _legacyBoxName,
    );
    return _box!;
  }

  @override
  Future<bool> isEnabled() async {
    final box = await _open();
    return box.get(_enabledKey) == true;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final box = await _open();
    await box.put(_enabledKey, enabled);
  }

  @override
  Future<bool> isBiometricEnabled() async {
    final box = await _open();
    return box.get(_biometricKey) == true;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    final box = await _open();
    await box.put(_biometricKey, enabled);
  }

  @override
  Future<bool> hasPin() async {
    final box = await _open();
    final hash = box.get(_hashKey) as String?;
    final salt = box.get(_saltKey) as String?;
    return hash != null &&
        hash.isNotEmpty &&
        salt != null &&
        salt.isNotEmpty;
  }

  @override
  Future<AppLockPolicy> getPolicy() async {
    final box = await _open();
    return AppLockPolicy.fromStorage(box.get(_policyKey) as String?);
  }

  @override
  Future<void> setPolicy(AppLockPolicy policy) async {
    final box = await _open();
    await box.put(_policyKey, policy.storageValue);
  }

  @override
  Future<void> setPin(String pin) async {
    final normalized = _normalizePin(pin);
    final salt = _randomSalt();
    final hash = _hashPin(normalized, salt);
    final box = await _open();
    await box.put(_saltKey, salt);
    await box.put(_hashKey, hash);
    await box.put(_failedKey, 0);
    await box.delete(_lockoutKey);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final box = await _open();
    final salt = box.get(_saltKey) as String?;
    final hash = box.get(_hashKey) as String?;
    if (salt == null || hash == null || salt.isEmpty || hash.isEmpty) {
      return false;
    }
    final normalized = _normalizePin(pin);
    final pbkdf2Hash = _hashPin(normalized, salt);
    if (_constantTimeEquals(pbkdf2Hash, hash)) {
      return true;
    }
    // Backward compatibility for legacy single-round SHA256 PIN hashes
    final legacyHash = _legacyHashPin(normalized, salt);
    if (_constantTimeEquals(legacyHash, hash)) {
      // Opportunistically upgrade legacy hash to PBKDF2
      await box.put(_hashKey, pbkdf2Hash);
      return true;
    }
    return false;
  }

  @override
  Future<void> clearPin() async {
    final box = await _open();
    await box.delete(_saltKey);
    await box.delete(_hashKey);
    await box.put(_biometricKey, false);
    await box.put(_failedKey, 0);
    await box.delete(_lockoutKey);
  }

  @override
  Future<int> loadFailedAttempts() async {
    final box = await _open();
    final value = box.get(_failedKey);
    return value is int ? value : 0;
  }

  @override
  Future<void> saveFailedAttempts(int count) async {
    final box = await _open();
    await box.put(_failedKey, count);
  }

  @override
  Future<DateTime?> loadLockoutUntil() async {
    final box = await _open();
    final raw = box.get(_lockoutKey) as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> saveLockoutUntil(DateTime? until) async {
    final box = await _open();
    if (until == null) {
      await box.delete(_lockoutKey);
      return;
    }
    await box.put(_lockoutKey, until.toUtc().toIso8601String());
  }

  static String _normalizePin(String pin) => pin.trim();

  static String _randomSalt() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    final hmacSha256 = Hmac(sha256, utf8.encode(pin));
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

  static String _legacyHashPin(String pin, String salt) {
    final digest = sha256.convert(utf8.encode('$salt::$pin'));
    return digest.toString();
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
