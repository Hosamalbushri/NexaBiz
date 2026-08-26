/// Silent numeric lane per device so plain invoice numbers stay unique
/// across phones **without** showing a device code in the UI.
///
/// Example (stride = 1_000_000):
/// - device `…00a1` → base `161000000`
/// - device `…00b2` → base `178000000`
///
/// Stored sale numbers remain absolute integers (`161000041`) for sync
/// uniqueness. The UI shows the short local sequence (`41`) via
/// [SaleNumberView].
int deviceSaleNumberBase(String deviceId, {int stride = kSaleNumberStride}) {
  final hex = deviceId.replaceAll('-', '');
  if (hex.isEmpty) {
    return 0;
  }
  final slice = hex.length <= 4 ? hex : hex.substring(hex.length - 4);
  final n = int.tryParse(slice, radix: 16) ?? 0;
  return n * stride;
}

/// Per-device exclusive range size for absolute sale numbers.
const int kSaleNumberStride = 1000000;

/// Sale numbers are plain integers only (no device label / prefix).
String formatSaleNumber(int sequence) => '$sequence';

/// Absolute invoice number for this device lane + local/book sequence.
int absoluteSaleNumber({
  required String deviceId,
  required int sequence,
  int stride = kSaleNumberStride,
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

/// Human-facing split of a stored sale number.
///
/// Users see [primaryLabel] (short local sequence). Sync/search still use
/// the full absolute [raw] / [referenceLabel].
class SaleNumberView {
  const SaleNumberView({
    required this.raw,
    required this.primaryLabel,
    this.referenceLabel,
    this.localSequence,
    this.absolute,
    this.lane,
  });

  /// Stored / synced value.
  final String raw;

  /// Short label for lists, form header, app bar (e.g. `42`).
  final String primaryLabel;

  /// Full absolute when it differs from [primaryLabel] (e.g. `161000042`).
  final String? referenceLabel;

  final int? localSequence;
  final int? absolute;
  final int? lane;

  bool get hasSeparateReference =>
      referenceLabel != null &&
      referenceLabel!.isNotEmpty &&
      referenceLabel != primaryLabel;
}

/// Builds a [SaleNumberView] for UI. Keeps storage format unchanged.
SaleNumberView saleNumberView(
  String raw, {
  int stride = kSaleNumberStride,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '—') {
    return SaleNumberView(raw: trimmed, primaryLabel: trimmed);
  }

  final absolute = parseSaleNumberSequence(trimmed);
  if (absolute == null) {
    return SaleNumberView(raw: trimmed, primaryLabel: trimmed);
  }

  if (absolute < stride) {
    final label = '$absolute';
    return SaleNumberView(
      raw: trimmed,
      primaryLabel: label,
      localSequence: absolute,
      absolute: absolute,
      lane: 0,
    );
  }

  final rem = absolute % stride;
  final local = rem == 0 ? stride : rem;
  final lane = absolute ~/ stride;
  final primary = '$local';
  final reference = '$absolute';
  return SaleNumberView(
    raw: trimmed,
    primaryLabel: primary,
    referenceLabel: reference == primary ? null : reference,
    localSequence: local,
    absolute: absolute,
    lane: lane,
  );
}

/// Short label helper for one-liners.
String formatSaleNumberPrimary(String raw) => saleNumberView(raw).primaryLabel;
