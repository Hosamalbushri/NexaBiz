import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

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
String generateUuidV5({
  required String namespaceUuid,
  required String name,
}) {
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
