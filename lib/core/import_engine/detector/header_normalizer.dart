/// Normalizes raw header labels (Arabic, English, mixed) into canonical metadata tokens.
class HeaderNormalizer {
  const HeaderNormalizer();

  /// Returns a clean canonical metadata token for a raw header string.
  /// Example: "Product Name" -> "product_name", "اسم المنتج" -> "اسم_المنتج".
  static String normalize(String rawHeader) {
    var text = rawHeader.trim();
    if (text.isEmpty) return '';

    // Remove Arabic diacritics (tashkeel) and tatweel (kashida)
    text = _removeArabicDiacritics(text);
    text = _normalizeArabicAlef(text);

    // Replace spaces, hyphens, and non-alphanumeric punctuation with underscores
    text = text.replaceAll(RegExp(r'[\s\-\.]+'), '_');

    // Remove illegal punctuation characters (keep Arabic letters, Latin letters, digits, underscores)
    text = text.replaceAll(RegExp(r'[^\w\u0600-\u06FF_]'), '');

    // Collapse consecutive underscores
    text = text.replaceAll(RegExp(r'_{2,}'), '_');

    // Strip leading/trailing underscores and lowercase English characters
    text = text.replaceAll(RegExp(r'^_+|_+$'), '').toLowerCase();

    return text;
  }

  /// Removes Tashkeel (Arabic diacritics) and Tatweel (ـ).
  static String _removeArabicDiacritics(String input) {
    // Range of Arabic diacritics: \u064B to \u0652 plus \u0640 (tatweel)
    return input.replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '');
  }

  /// Normalizes Arabic Alef variations (أ, إ, آ -> ا).
  static String _normalizeArabicAlef(String input) {
    return input
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }
}
