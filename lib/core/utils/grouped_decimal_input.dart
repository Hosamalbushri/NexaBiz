import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'digit_normalization.dart';

export 'digit_normalization.dart'
    show normalizeDigitsToWestern, WesternDigitsInputFormatter;

/// Parses a user-typed amount that may include thousand separators.
///
/// `,` / `٬` are **always** thousand separators — never fractions.
/// Only `.` is accepted as a decimal point (when fractional input is allowed).
///
/// Returns a locale-independent [double], or `null` when empty/invalid.
double? parseGroupedDecimal(String raw) {
  var text = normalizeDigitsToWestern(raw)
      .replaceAll('\u00A0', '')
      .replaceAll(' ', '')
      .replaceAll('٬', '')
      .replaceAll(',', '')
      .trim();
  if (text.isEmpty || text == '-' || text == '.' || text == '-.') {
    return null;
  }
  return double.tryParse(text);
}

final Map<String, NumberFormat> _formatCache = {};

NumberFormat _numberFormat(String pattern) {
  return _formatCache.putIfAbsent(
    pattern,
    () => NumberFormat(pattern, 'en_US'),
  );
}

/// Formats [value] with thousand separators (e.g. `10,000` or `1,234.56`).
///
/// Display-only — never persist this string as a domain/database value.
String formatGroupedDecimal(
  double value, {
  int decimalPlaces = 2,
  bool emptyWhenZero = false,
  bool trimTrailingZeros = false,
}) {
  if (emptyWhenZero && value == 0) {
    return '';
  }
  if (decimalPlaces <= 0) {
    return _numberFormat('#,##0').format(value.round());
  }
  if (trimTrailingZeros && value == value.roundToDouble()) {
    return _numberFormat('#,##0').format(value);
  }
  if (trimTrailingZeros) {
    return _numberFormat('#,##0.##').format(value);
  }
  final pattern = '#,##0.${'0' * decimalPlaces}';
  return _numberFormat(pattern).format(value);
}

/// Live formatter: thousand separators (`,`) and optional `.` decimals.
///
/// Preserves caret position by digit-count mapping so typing, backspace,
/// mid-string edits, and selection replacement stay stable.
class GroupedDecimalInputFormatter extends TextInputFormatter {
  const GroupedDecimalInputFormatter({
    this.decimalPlaces = 2,
    this.allowEmpty = true,
    this.allowNegative = false,
  });

  final int decimalPlaces;
  final bool allowEmpty;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeDigitsToWestern(newValue.text);
    if (normalized.trim().isEmpty) {
      if (!allowEmpty) {
        return oldValue;
      }
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final selectionEnd = newValue.selection.end;
    final rawBeforeCaret = selectionEnd < 0
        ? normalized
        : normalized.substring(0, selectionEnd.clamp(0, normalized.length));
    final digitsBeforeCaret = _significantCount(rawBeforeCaret);

    final stripped = _stripGrouping(normalized);
    if (!_isValidPartial(
      stripped,
      decimalPlaces: decimalPlaces,
      allowNegative: allowNegative,
    )) {
      return oldValue;
    }

    final negative = allowNegative && stripped.startsWith('-');
    final unsigned = negative ? stripped.substring(1) : stripped;

    if (decimalPlaces <= 0) {
      var intPart = unsigned.replaceAll('.', '');
      intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      if (intPart.isEmpty) {
        intPart = negative ? '' : '0';
      }
      final grouped = _groupThousands(intPart);
      final formatted = negative ? '-$grouped' : (grouped.isEmpty ? '0' : grouped);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: _offsetForSignificantCount(formatted, digitsBeforeCaret),
        ),
      );
    }

    final parts = unsigned.split('.');
    var intPart = parts.isEmpty ? '' : parts.first;
    var fracPart = parts.length > 1 ? parts.sublist(1).join() : null;

    if (fracPart != null && fracPart.length > decimalPlaces) {
      fracPart = fracPart.substring(0, decimalPlaces);
    }

    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (intPart.isEmpty) {
      intPart = '0';
    }

    final groupedInt = _groupThousands(intPart);
    var body = fracPart == null
        ? (unsigned.endsWith('.') ? '$groupedInt.' : groupedInt)
        : '$groupedInt.$fracPart';
    if (negative) {
      body = '-$body';
    }

    return TextEditingValue(
      text: body,
      selection: TextSelection.collapsed(
        offset: _offsetForSignificantCount(body, digitsBeforeCaret),
      ),
    );
  }

  /// Strips thousand separators. Comma is never a decimal point.
  static String _stripGrouping(String input) {
    return input
        .replaceAll('٬', '')
        .replaceAll(' ', '')
        .replaceAll(',', '');
  }

  static bool _isValidPartial(
    String stripped, {
    required int decimalPlaces,
    required bool allowNegative,
  }) {
    final body = stripped.startsWith('-') ? stripped.substring(1) : stripped;
    if (stripped.startsWith('-') && !allowNegative) {
      return false;
    }
    if (stripped == '-') {
      return allowNegative;
    }
    if (decimalPlaces <= 0) {
      return RegExp(r'^\d*$').hasMatch(body);
    }
    if (body == '.' || body == '0.') {
      return true;
    }
    return RegExp(r'^\d*\.?\d*$').hasMatch(body);
  }

  static String _groupThousands(String digits) {
    if (digits.isEmpty) {
      return digits;
    }
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return buf.toString();
  }

  /// Digits and optional leading minus / decimal point for caret mapping.
  static int _significantCount(String text) {
    var count = 0;
    for (final c in text.codeUnits) {
      if (c >= 0x30 && c <= 0x39) {
        count++;
      } else if (c == 0x2E /* . */) {
        count++;
      } else if (c == 0x2D /* - */) {
        count++;
      }
    }
    return count;
  }

  static int _offsetForSignificantCount(String formatted, int target) {
    if (target <= 0) {
      return 0;
    }
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final c = formatted.codeUnitAt(i);
      if ((c >= 0x30 && c <= 0x39) || c == 0x2E || c == 0x2D) {
        seen++;
        if (seen >= target) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }
}
