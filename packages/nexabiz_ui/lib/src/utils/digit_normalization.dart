import 'package:flutter/services.dart';

/// Converts Eastern Arabic (٠-٩) and Persian (۰-۹) digits to Western (0-9).
String normalizeDigitsToWestern(String input) {
  if (input.isEmpty) {
    return input;
  }

  final buffer = StringBuffer();
  for (final unit in input.codeUnits) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.writeCharCode(0x30 + (unit - 0x0660));
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      buffer.writeCharCode(0x30 + (unit - 0x06F0));
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// Live input formatter that rewrites Arabic/Persian digits as Western digits.
class WesternDigitsInputFormatter extends TextInputFormatter {
  const WesternDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeDigitsToWestern(newValue.text);
    if (normalized == newValue.text) {
      return newValue;
    }

    final base = newValue.selection.baseOffset;
    final extent = newValue.selection.extentOffset;
    return TextEditingValue(
      text: normalized,
      selection: TextSelection(
        baseOffset: base.clamp(0, normalized.length),
        extentOffset: extent.clamp(0, normalized.length),
      ),
    );
  }
}
