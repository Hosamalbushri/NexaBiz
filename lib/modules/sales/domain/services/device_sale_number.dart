/// Silent numeric lane per device so plain invoice numbers stay unique
/// across phones **without** showing a device code in the UI.
///
/// Example (stride = 1_000_000):
/// - device `…00a1` → base `161000000`
/// - device `…00b2` → base `178000000`
///
/// Displayed sale numbers remain plain integers: `161000001`, not `00A1-1`.
int deviceSaleNumberBase(String deviceId, {int stride = 1000000}) {
  final hex = deviceId.replaceAll('-', '');
  if (hex.isEmpty) {
    return 0;
  }
  final slice = hex.length <= 4 ? hex : hex.substring(hex.length - 4);
  final n = int.tryParse(slice, radix: 16) ?? 0;
  return n * stride;
}

/// Sale numbers are plain integers only (no device label / prefix).
String formatSaleNumber(int sequence) => '$sequence';

/// Absolute invoice number for this device lane + local/book sequence.
int absoluteSaleNumber({
  required String deviceId,
  required int sequence,
  int stride = 1000000,
}) {
  return deviceSaleNumberBase(deviceId, stride: stride) + sequence;
}

/// Parses a numeric sale number (plain, legacy INV-n, or old PREFIX-n).
int? parseSaleNumberSequence(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  final plain = RegExp(r'^(\d+)$').firstMatch(value);
  if (plain != null) {
    return int.tryParse(plain.group(1)!);
  }
  final legacyInv = RegExp(
    r'^INV-(\d+)$',
    caseSensitive: false,
  ).firstMatch(value);
  if (legacyInv != null) {
    return int.tryParse(legacyInv.group(1)!);
  }
  // Legacy experimental format PREFIX-n (no longer allocated).
  final legacyPrefixed = RegExp(
    r'^[A-Z0-9]{2,8}-(\d+)$',
    caseSensitive: false,
  ).firstMatch(value);
  if (legacyPrefixed != null) {
    return int.tryParse(legacyPrefixed.group(1)!);
  }
  return null;
}
