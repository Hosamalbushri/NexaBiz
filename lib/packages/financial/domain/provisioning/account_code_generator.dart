/// Generates deterministic, company-scoped child account codes under a parent account code.
class AccountCodeGenerator {
  /// Generates next child account code given a parent account code and existing sibling codes.
  /// Example: parent "1200", siblings ["120001", "120002"] -> "120003".
  static String generateNextChildCode({
    required String parentCode,
    required List<String> existingSiblingCodes,
  }) {
    final cleanParent = parentCode.trim();
    if (cleanParent.isEmpty) {
      throw ArgumentError('Parent account code cannot be empty');
    }

    int maxSuffix = 0;

    for (final rawCode in existingSiblingCodes) {
      final code = rawCode.trim();
      if (!code.startsWith(cleanParent)) continue;

      final suffixStr = code.substring(cleanParent.length);
      final parsed = int.tryParse(suffixStr);
      if (parsed != null && parsed > maxSuffix) {
        maxSuffix = parsed;
      }
    }

    final nextSuffix = maxSuffix + 1;
    final paddedSuffix = nextSuffix.toString().padLeft(2, '0');
    return '$cleanParent$paddedSuffix';
  }
}
