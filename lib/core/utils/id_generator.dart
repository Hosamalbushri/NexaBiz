import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Generates RFC 9562 version-7 UUIDs for offline-created records.
String generateUuidV7([int? customTimestampMs, Random? random]) {
  final rng = random ?? Random.secure();
  final timestampMs = customTimestampMs ?? DateTime.now().millisecondsSinceEpoch;

  final bytes = Uint8List(16);

  // 48-bit timestamp
  bytes[0] = (timestampMs >> 40) & 0xff;
  bytes[1] = (timestampMs >> 32) & 0xff;
  bytes[2] = (timestampMs >> 24) & 0xff;
  bytes[3] = (timestampMs >> 16) & 0xff;
  bytes[4] = (timestampMs >> 8) & 0xff;
  bytes[5] = timestampMs & 0xff;

  // 4-bit version (7) + 12-bit random (rand_a)
  final randA = rng.nextInt(4096);
  bytes[6] = 0x70 | ((randA >> 8) & 0x0f);
  bytes[7] = randA & 0xff;

  // 2-bit variant (10) + 62-bit random (rand_b)
  bytes[8] = 0x80 | (rng.nextInt(64) & 0x3f);
  for (var i = 9; i < 16; i++) {
    bytes[i] = rng.nextInt(256);
  }

  return _formatUuid(bytes);
}

/// Generates RFC 4122 version-4 UUIDs for offline-created records.
String generateUuidV4([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  return _formatUuid(bytes);
}

/// RFC 4122 version-5 UUID from a fixed namespace + [name] (stable across devices).
///
/// Used for system Chart of Accounts seeds so installs share the same UUIDs.
String generateUuidV5({required String namespaceUuid, required String name}) {
  final namespaceBytes = _parseUuidBytes(namespaceUuid);
  final hash = sha1.convert([...namespaceBytes, ...utf8.encode(name)]).bytes;
  final bytes = List<int>.from(hash.take(16));
  bytes[6] = (bytes[6] & 0x0f) | 0x50; // version 5
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  return _formatUuid(bytes);
}

/// Namespace for system CoA account UUIDs (`system:<key>` names).
const String kSystemAccountUuidNamespace =
    '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

String systemAccountUuid(String systemKey) {
  return generateUuidV5(
    namespaceUuid: kSystemAccountUuidNamespace,
    name: 'system:$systemKey',
  );
}

String _formatUuid(List<int> bytes) {
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

Uint8List _parseUuidBytes(String uuid) {
  final hex = uuid.replaceAll('-', '');
  if (hex.length != 32) {
    throw ArgumentError.value(uuid, 'uuid', 'Expected 32 hex digits');
  }
  final out = Uint8List(16);
  for (var i = 0; i < 16; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}
