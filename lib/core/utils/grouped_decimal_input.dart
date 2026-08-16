import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'digit_normalization.dart';

/// Parses a user-typed amount that may include thousand separators.
///
/// Accepts Western/Arabic/Persian digits, `,` or `.` as decimal separator,
/// and strips grouping commas/spaces.
double? parseGroupedDecimal(String raw) {
  var text = normalizeDigitsToWestern(raw)
      .replaceAll('\u00A0', '')
      .replaceAll(' ', '')
      .replaceAll('٬', '') // Arabic thousands separator
      .trim();
  if (text.isEmpty) {
    return null;
  }

  // Keep the last `.` or `,` as the decimal separator when both appear.
  final lastDot = text.lastIndexOf('.');
  final lastComma = text.lastIndexOf(',');
  if (lastDot >= 0 && lastComma >= 0) {
    if (lastComma > lastDot) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    final parts = text.split(',');
    if (parts.length == 2 && parts[1].length <= 2) {
      text = '${parts[0]}.${parts[1]}';
    } else {
      text = text.replaceAll(',', '');
    }
  }

  return double.tryParse(text);
}

/// Formats [value] with thousand separators (e.g. `1,234.56`).
String formatGroupedDecimal(
  double value, {
  int decimalPlaces = 2,
  bool emptyWhenZero = false,
  bool trimTrailingZeros = false,
}) {
  if (emptyWhenZero && value == 0) {
    return '';
  }
  if (trimTrailingZeros && value == value.roundToDouble()) {
    return NumberFormat('#,##0', 'en_US').format(value);
  }
  if (trimTrailingZeros) {
    return NumberFormat('#,##0.##', 'en_US').format(value);
  }
  final pattern = decimalPlaces <= 0
      ? '#,##0'
      : '#,##0.${'0' * decimalPlaces}';
  return NumberFormat(pattern, 'en_US').format(value);
}

/// Live formatter: thousand separators + optional fixed decimal places.
class GroupedDecimalInputFormatter extends TextInputFormatter {
  const GroupedDecimalInputFormatter({
    this.decimalPlaces = 2,
    this.allowEmpty = true,
  });

  final int decimalPlaces;
  final bool allowEmpty;

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

    // Digits before the caret (ignoring separators) — used to restore caret.
    final selectionEnd = newValue.selection.end;
    final rawBeforeCaret = selectionEnd < 0
        ? normalized
        : normalized.substring(0, selectionEnd.clamp(0, normalized.length));
    final digitsBeforeCaret = _digitCount(rawBeforeCaret);

    final stripped = _stripGrouping(normalized);
    if (!_isValidPartial(stripped)) {
      return oldValue;
    }

    final parts = stripped.split('.');
    var intPart = parts.isEmpty ? '' : parts.first;
    var fracPart = parts.length > 1 ? parts.sublist(1).join() : null;

    if (fracPart != null && fracPart.length > decimalPlaces) {
      fracPart = fracPart.substring(0, decimalPlaces);
    }

    // Avoid leading zeros like 00012 → keep single 0 before decimal.
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (intPart.isEmpty) {
      intPart = '0';
    }

    final groupedInt = _groupThousands(intPart);
    final formatted = fracPart == null
        ? (stripped.endsWith('.') ? '$groupedInt.' : groupedInt)
        : '$groupedInt.$fracPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetForDigitCount(formatted, digitsBeforeCaret),
      ),
    );
  }

  static String _stripGrouping(String input) {
    // Normalize Arabic decimal comma to `.`, drop thousand separators.
    var text = input.replaceAll('٬', '').replaceAll(' ', '');
    final lastComma = text.lastIndexOf(',');
    final lastDot = text.lastIndexOf('.');
    if (lastComma >= 0 && lastDot < 0) {
      text = '${text.substring(0, lastComma)}.${text.substring(lastComma + 1)}';
    } else {
      text = text.replaceAll(',', '');
    }
    return text;
  }

  static bool _isValidPartial(String stripped) {
    if (stripped == '.' || stripped == '0.') {
      return true;
    }
    return RegExp(r'^\d*\.?\d*$').hasMatch(stripped);
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

  static int _digitCount(String text) {
    var count = 0;
    for (final c in text.codeUnits) {
      if (c >= 0x30 && c <= 0x39) {
        count++;
      }
    }
    return count;
  }

  static int _offsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final c = formatted.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) {
        seen++;
        if (seen >= digitCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }
}
