import 'package:flutter/foundation.dart';

/// Defensive utility for extracting and parsing URL route path/query parameters.
///
/// Prevents unhandled [FormatException] runtime crashes when invalid, empty,
/// or malformed parameter values are encountered during deep-linking.
@immutable
class AppRouteParamParser {
  const AppRouteParamParser._();

  /// Safely parses a positive integer parameter (e.g. `:id` or `?page=1`).
  ///
  /// Returns `null` if [raw] is `null`, empty, not a valid integer, or <= 0.
  static int? tryParseInt(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final val = int.tryParse(trimmed);
    if (val == null || val <= 0) return null;
    return val;
  }

  /// Safely parses a non-empty String parameter.
  ///
  /// Returns `null` if [raw] is `null` or whitespace-only.
  static String? tryParseString(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Safely parses a double parameter (e.g. `?amount=12.50`).
  static double? tryParseDouble(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  /// Safely parses a boolean parameter (e.g. `?active=true`).
  static bool? tryParseBool(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim().toLowerCase();
    if (trimmed == 'true' || trimmed == '1') return true;
    if (trimmed == 'false' || trimmed == '0') return false;
    return null;
  }
}
