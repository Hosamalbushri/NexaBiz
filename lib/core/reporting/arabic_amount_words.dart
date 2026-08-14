/// Converts numeric amounts to Arabic words for invoices / statements.
class ArabicAmountWords {
  ArabicAmountWords._();

  static const _ones = <String>[
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];

  static const _tens = <String>[
    '',
    'عشرة',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];

  static const _hundreds = <String>[
    '',
    'مائة',
    'مائتان',
    'ثلاثمائة',
    'أربعمائة',
    'خمسمائة',
    'ستمائة',
    'سبعمائة',
    'ثمانمائة',
    'تسعمائة',
  ];

  /// Returns e.g. `فقط ستمائة وخمسون ريال يمني`.
  ///
  /// [currencyLabel] should come from the system catalog Arabic name
  /// (e.g. `AppCurrency.nameAr`).
  static String forAmount(double amount, String currencyLabel) {
    final label = currencyLabel.trim();
    final whole = amount.round().abs();
    if (whole == 0) {
      return label.isEmpty ? 'فقط صفر' : 'فقط صفر $label';
    }
    final words = _convert(whole);
    return label.isEmpty ? 'فقط $words' : 'فقط $words $label';
  }

  static String _convert(int n) {
    if (n < 20) {
      return _ones[n];
    }
    if (n < 100) {
      final t = n ~/ 10;
      final o = n % 10;
      if (o == 0) {
        return _tens[t];
      }
      return '${_ones[o]} و${_tens[t]}';
    }
    if (n < 1000) {
      final h = n ~/ 100;
      final rest = n % 100;
      if (rest == 0) {
        return _hundreds[h];
      }
      return '${_hundreds[h]} و${_convert(rest)}';
    }
    if (n < 2000) {
      final rest = n % 1000;
      if (rest == 0) {
        return 'ألف';
      }
      return 'ألف و${_convert(rest)}';
    }
    if (n < 1000000) {
      final thousands = n ~/ 1000;
      final rest = n % 1000;
      final thousandsWord = thousands == 2
          ? 'ألفان'
          : thousands < 11
          ? '${_convert(thousands)} آلاف'
          : '${_convert(thousands)} ألفاً';
      if (rest == 0) {
        return thousandsWord;
      }
      return '$thousandsWord و${_convert(rest)}';
    }
    final millions = n ~/ 1000000;
    final rest = n % 1000000;
    final millionsWord = millions == 1
        ? 'مليون'
        : millions == 2
        ? 'مليونان'
        : '${_convert(millions)} ملايين';
    if (rest == 0) {
      return millionsWord;
    }
    return '$millionsWord و${_convert(rest)}';
  }
}
