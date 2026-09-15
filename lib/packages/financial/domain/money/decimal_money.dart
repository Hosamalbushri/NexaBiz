import '../common/financial_exceptions.dart';

/// Rounding modes supported by [DecimalMoney].
enum FinancialRoundingMode { halfUp, halfEven, truncate, floor, ceil }

/// Immutable, deterministic monetary value object backed by 64-bit/BigInt scaled units.
///
/// Canonical Scale: 8 decimal places (1 unit = 10^8 scaled units).
class DecimalMoney implements Comparable<DecimalMoney> {
  /// Canonical scale across all Financial Package operations (10^8).
  static const int canonicalScale = 8;
  static final BigInt scaleFactor = BigInt.from(10).pow(canonicalScale);

  /// Scaled integer value (`amount * 10^8`).
  final BigInt unitsScaled;

  /// ISO Currency code (e.g. 'USD', 'YER', 'SAR'). Immutable.
  final String currencyCode;

  const DecimalMoney._(this.unitsScaled, this.currencyCode);

  /// Creates a zero monetary value in [currencyCode].
  factory DecimalMoney.zero(String currencyCode) {
    _validateCurrencyCode(currencyCode);
    return DecimalMoney._(BigInt.zero, currencyCode.toUpperCase());
  }

  /// Creates a monetary value directly from raw scaled integer units (`amount * 10^8`).
  factory DecimalMoney.fromScaled(BigInt unitsScaled, String currencyCode) {
    _validateCurrencyCode(currencyCode);
    return DecimalMoney._(unitsScaled, currencyCode.toUpperCase());
  }

  /// Creates a monetary value from integer main units and fractional subunits.
  factory DecimalMoney.fromUnits(int units, String currencyCode, [int subunits = 0]) {
    _validateCurrencyCode(currencyCode);
    final mainScaled = BigInt.from(units) * scaleFactor;
    final subScaled = BigInt.from(subunits);
    return DecimalMoney._(mainScaled + subScaled, currencyCode.toUpperCase());
  }

  /// Parses a decimal string (e.g., "125.50" or "-10.00000001") without floating-point conversion.
  factory DecimalMoney.fromString(String raw, String currencyCode) {
    _validateCurrencyCode(currencyCode);
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return DecimalMoney.zero(currencyCode);
    }

    final isNeg = trimmed.startsWith('-');
    final clean = isNeg ? trimmed.substring(1) : trimmed;

    final parts = clean.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid monetary decimal string: $raw');
    }

    final integerPartStr = parts[0].isEmpty ? '0' : parts[0];
    final BigInt integerPart = BigInt.parse(integerPartStr);

    BigInt fractionPart = BigInt.zero;
    if (parts.length == 2 && parts[1].isNotEmpty) {
      String fracStr = parts[1];
      if (fracStr.length > canonicalScale) {
        fracStr = fracStr.substring(0, canonicalScale);
      } else if (fracStr.length < canonicalScale) {
        fracStr = fracStr.padRight(canonicalScale, '0');
      }
      fractionPart = BigInt.parse(fracStr);
    }

    BigInt totalScaled = (integerPart * scaleFactor) + fractionPart;
    if (isNeg) {
      totalScaled = -totalScaled;
    }

    return DecimalMoney._(totalScaled, currencyCode.toUpperCase());
  }

  /// Returns whether amount is exactly zero.
  bool get isZero => unitsScaled == BigInt.zero;

  /// Returns whether amount is strictly positive.
  bool get isPositive => unitsScaled > BigInt.zero;

  /// Returns whether amount is strictly negative.
  bool get isNegative => unitsScaled < BigInt.zero;

  /// Adds [other] to this amount. Requires identical currency codes.
  DecimalMoney add(DecimalMoney other) {
    _assertSameCurrency(other);
    return DecimalMoney._(unitsScaled + other.unitsScaled, currencyCode);
  }

  /// Subtracts [other] from this amount. Requires identical currency codes.
  DecimalMoney subtract(DecimalMoney other) {
    _assertSameCurrency(other);
    return DecimalMoney._(unitsScaled - other.unitsScaled, currencyCode);
  }

  /// Negates the monetary value.
  DecimalMoney negate() {
    return DecimalMoney._(-unitsScaled, currencyCode);
  }

  /// Multiplies by an integer factor.
  DecimalMoney multiplyByInteger(BigInt factor) {
    return DecimalMoney._(unitsScaled * factor, currencyCode);
  }

  /// Rounds scaled units to the target decimal places (0 to 8).
  DecimalMoney roundToDigits(
    int decimalPlaces, {
    FinancialRoundingMode roundingMode = FinancialRoundingMode.halfUp,
  }) {
    if (decimalPlaces >= canonicalScale) return this;
    if (decimalPlaces < 0) {
      throw ArgumentError('decimalPlaces cannot be negative: $decimalPlaces');
    }

    final dropDigits = canonicalScale - decimalPlaces;
    final divisor = BigInt.from(10).pow(dropDigits);
    final halfDivisor = divisor ~/ BigInt.two;

    final base = unitsScaled ~/ divisor;
    final remainder = (unitsScaled.abs()) % divisor;

    BigInt roundedBase;
    switch (roundingMode) {
      case FinancialRoundingMode.halfUp:
        if (remainder >= halfDivisor) {
          roundedBase = unitsScaled.isNegative ? base - BigInt.one : base + BigInt.one;
        } else {
          roundedBase = base;
        }
        break;

      case FinancialRoundingMode.halfEven:
        if (remainder > halfDivisor) {
          roundedBase = unitsScaled.isNegative ? base - BigInt.one : base + BigInt.one;
        } else if (remainder == halfDivisor) {
          if (base.isOdd) {
            roundedBase = unitsScaled.isNegative ? base - BigInt.one : base + BigInt.one;
          } else {
            roundedBase = base;
          }
        } else {
          roundedBase = base;
        }
        break;

      case FinancialRoundingMode.truncate:
        roundedBase = base;
        break;

      case FinancialRoundingMode.floor:
        if (unitsScaled.isNegative && remainder > BigInt.zero) {
          roundedBase = base - BigInt.one;
        } else {
          roundedBase = base;
        }
        break;

      case FinancialRoundingMode.ceil:
        if (!unitsScaled.isNegative && remainder > BigInt.zero) {
          roundedBase = base + BigInt.one;
        } else {
          roundedBase = base;
        }
        break;
    }

    return DecimalMoney._(roundedBase * divisor, currencyCode);
  }

  DecimalMoney operator +(DecimalMoney other) => add(other);
  DecimalMoney operator -(DecimalMoney other) => subtract(other);
  DecimalMoney operator -() => negate();

  @override
  int compareTo(DecimalMoney other) {
    _assertSameCurrency(other);
    return unitsScaled.compareTo(other.unitsScaled);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DecimalMoney &&
            currencyCode == other.currencyCode &&
            unitsScaled == other.unitsScaled);
  }

  @override
  int get hashCode => Object.hash(unitsScaled, currencyCode);

  /// Returns string representation formatted to specified decimal digits (default 2).
  String toFormattedString([int decimals = 2]) {
    final isNeg = unitsScaled < BigInt.zero;
    final absScaled = unitsScaled.abs();
    final integerPart = absScaled ~/ scaleFactor;
    final fracPart = absScaled % scaleFactor;

    String fracStr = fracPart.toString().padLeft(canonicalScale, '0');
    if (decimals < canonicalScale) {
      fracStr = fracStr.substring(0, decimals);
    }

    final prefix = isNeg ? '-' : '';
    if (decimals == 0) {
      return '$prefix$integerPart';
    }
    return '$prefix$integerPart.$fracStr';
  }

  @override
  String toString() => '$currencyCode ${toFormattedString(4)}';

  void _assertSameCurrency(DecimalMoney other) {
    if (currencyCode != other.currencyCode) {
      throw CurrencyMismatchException(
        expectedCurrency: currencyCode,
        actualCurrency: other.currencyCode,
      );
    }
  }

  static void _validateCurrencyCode(String code) {
    if (code.trim().isEmpty) {
      throw ArgumentError('Currency code cannot be empty');
    }
  }
}
