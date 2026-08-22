/// Reusable utility for parsing and extracting numeric IDs from raw values,
/// IRI strings, URLs, and notification payloads.
abstract final class IdParser {
  /// Safely extracts a positive integer ID from a variety of dynamic inputs.
  ///
  /// Supported inputs:
  /// - [int]: Returns [rawInput] directly if positive.
  /// - [String]: Parses pure numeric strings ("577"), path IRIs ("/api/v1/orders/577"),
  ///   full URLs ("https://example.com/api/orders/577?tab=details"), and query strings.
  ///
  /// Returns `null` if [rawInput] is null, malformed, empty, or contains no valid numeric ID.
  static int? extractNumericId(dynamic rawInput) {
    if (rawInput == null) {
      return null;
    }

    if (rawInput is int) {
      return rawInput > 0 ? rawInput : null;
    }

    if (rawInput is double) {
      return rawInput.isFinite && rawInput > 0 && rawInput == rawInput.truncateToDouble()
          ? rawInput.toInt()
          : null;
    }

    if (rawInput is! String) {
      return null;
    }

    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // 1. Check if the string is a pure integer first
    final directParsed = int.tryParse(trimmed);
    if (directParsed != null) {
      return directParsed > 0 ? directParsed : null;
    }

    // 2. Decode Uri component to handle encoded characters like %2F
    String decoded;
    try {
      decoded = Uri.decodeComponent(trimmed);
    } catch (_) {
      decoded = trimmed;
    }

    // Strip trailing query parameters or fragments if present
    final queryIndex = decoded.indexOf('?');
    if (queryIndex != -1) {
      decoded = decoded.substring(0, queryIndex);
    }

    final fragmentIndex = decoded.indexOf('#');
    if (fragmentIndex != -1) {
      decoded = decoded.substring(0, fragmentIndex);
    }

    // Split path into segments
    final segments = decoded.split('/').where((s) => s.isNotEmpty).toList();

    // Iterate backwards through path segments to find the last numeric segment
    for (var i = segments.length - 1; i >= 0; i--) {
      final segment = segments[i];
      final parsed = int.tryParse(segment);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }
}
