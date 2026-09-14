import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../domain/ports/password_hasher_port.dart';

/// Concrete PBKDF2-HMAC-SHA256 password hasher adapter implementing [PasswordHasherPort].
///
/// Security parameters:
/// - PBKDF2-HMAC-SHA256
/// - 100,000 iterations
/// - 128-bit (16-byte) random salt
/// - Constant-time verification
/// - Legacy SHA-256 transitional verification fallback ONLY.
class Pbkdf2PasswordHasherAdapter implements PasswordHasherPort {
  const Pbkdf2PasswordHasherAdapter({this.iterations = 100000});

  final int iterations;

  /// Generates a 128-bit (16-byte) secure random salt in base64url format.
  static String generateSalt() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes);
  }

  @override
  String hashPassword(String password, String salt) {
    final hmacSha256 = Hmac(sha256, utf8.encode(password));
    final saltBytes = utf8.encode(salt);
    var u = hmacSha256.convert([...saltBytes, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmacSha256.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  bool verifyPassword(String password, String storedHash, String salt) {
    if (password.isEmpty || storedHash.isEmpty) {
      return false;
    }
    final computedPbkdf2 = hashPassword(password, salt);
    if (_constantTimeEquals(computedPbkdf2, storedHash)) {
      return true;
    }

    // Legacy SHA-256 transitional fallback (pre-migration hashes)
    final legacyHash = _legacySha256Hash(password, salt);
    if (_constantTimeEquals(legacyHash, storedHash)) {
      return true;
    }

    // Direct legacy SHA-256 without salt fallback
    final directLegacyHash = sha256.convert(utf8.encode(password)).toString();
    if (_constantTimeEquals(directLegacyHash, storedHash)) {
      return true;
    }

    return false;
  }

  static String _legacySha256Hash(String password, String salt) {
    final digest = sha256.convert(utf8.encode('$salt::$password'));
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
