import 'dart:math' as math;

enum FixedRoundingMode { halfUp, halfEven, truncate, floor, ceil }

/// Fixed-precision monetary value backed by integer micro-units ([BigInt]),
/// completely eliminating binary floating-point rounding errors and drift.
class DecimalMoney implements Comparable<DecimalMoney> {
  static const int defaultScale = 8;

  final BigInt microUnits;
  final int scale;

  const DecimalMoney._(this.microUnits, [this.scale = defaultScale]);

  factory DecimalMoney.zero([int scale = defaultScale]) =>
      DecimalMoney._(BigInt.zero, scale);

  factory DecimalMoney.fromMicroUnits(
    BigInt units, {
    int scale = defaultScale,
  }) {
    return DecimalMoney._(units, scale);
  }

  factory DecimalMoney.fromInt(int amount, {int scale = defaultScale}) {
    final factor = BigInt.from(10).pow(scale);
    return DecimalMoney._(BigInt.from(amount) * factor, scale);
  }

  factory DecimalMoney.fromDouble(double amount, {int scale = defaultScale}) {
    if (amount.isNaN || amount.isInfinite) {
      throw ArgumentError('Invalid monetary double amount: $amount');
    }
    final factor = math.pow(10, scale).toDouble();
    final units = (amount * factor).round();
    return DecimalMoney._(BigInt.from(units), scale);
  }

  factory DecimalMoney.fromString(String raw, {int scale = defaultScale}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return DecimalMoney.zero(scale);
    }

    final parsedDouble = double.tryParse(trimmed);
    if (parsedDouble == null) {
      throw FormatException('Invalid decimal string: $raw');
    }
    return DecimalMoney.fromDouble(parsedDouble, scale: scale);
  }

  double toDouble() {
    final factor = math.pow(10, scale).toDouble();
    return microUnits.toDouble() / factor;
  }

  DecimalMoney roundTo(
    int decimalPlaces, {
    FixedRoundingMode roundingMode = FixedRoundingMode.halfUp,
  }) {
    if (decimalPlaces >= scale) {
      return this;
    }

    final dropDigits = scale - decimalPlaces;
    final divisor = BigInt.from(10).pow(dropDigits);
    final halfDivisor = divisor ~/ BigInt.two;

    BigInt rounded;
    final remainder = microUnits.abs() % divisor;
    final base = microUnits ~/ divisor;

    switch (roundingMode) {
      case FixedRoundingMode.halfUp:
        if (remainder >= halfDivisor) {
          rounded = microUnits.isNegative
              ? base - BigInt.one
              : base + BigInt.one;
        } else {
          rounded = base;
        }
        break;

      case FixedRoundingMode.halfEven:
        if (remainder > halfDivisor) {
          rounded = microUnits.isNegative
              ? base - BigInt.one
              : base + BigInt.one;
        } else if (remainder == halfDivisor) {
          if (base.isOdd) {
            rounded = microUnits.isNegative
                ? base - BigInt.one
                : base + BigInt.one;
          } else {
            rounded = base;
          }
        } else {
          rounded = base;
        }
        break;

      case FixedRoundingMode.truncate:
        rounded = base;
        break;

      case FixedRoundingMode.floor:
        if (microUnits.isNegative && remainder > BigInt.zero) {
          rounded = base - BigInt.one;
        } else {
          rounded = base;
        }
        break;

      case FixedRoundingMode.ceil:
        if (!microUnits.isNegative && remainder > BigInt.zero) {
          rounded = base + BigInt.one;
        } else {
          rounded = base;
        }
        break;
    }

    final scaledUp = rounded * divisor;
    return DecimalMoney._(scaledUp, scale);
  }

  DecimalMoney add(DecimalMoney other) {
    _checkSameScale(other);
    return DecimalMoney._(microUnits + other.microUnits, scale);
  }

  DecimalMoney subtract(DecimalMoney other) {
    _checkSameScale(other);
    return DecimalMoney._(microUnits - other.microUnits, scale);
  }

  DecimalMoney multiply(DecimalMoney multiplier) {
    _checkSameScale(multiplier);
    final factor = BigInt.from(10).pow(scale);
    final product = (microUnits * multiplier.microUnits) ~/ factor;
    return DecimalMoney._(product, scale);
  }

  DecimalMoney divide(DecimalMoney divisor) {
    _checkSameScale(divisor);
    if (divisor.microUnits == BigInt.zero) {
      throw UnsupportedError('Cannot divide monetary amount by zero');
    }
    final factor = BigInt.from(10).pow(scale);
    final quotient = (microUnits * factor) ~/ divisor.microUnits;
    return DecimalMoney._(quotient, scale);
  }

  DecimalMoney operator +(DecimalMoney other) => add(other);
  DecimalMoney operator -(DecimalMoney other) => subtract(other);
  DecimalMoney operator *(DecimalMoney other) => multiply(other);
  DecimalMoney operator /(DecimalMoney other) => divide(other);

  bool get isZero => microUnits == BigInt.zero;
  bool get isNegative => microUnits < BigInt.zero;
  bool get isPositive => microUnits > BigInt.zero;

  @override
  int compareTo(DecimalMoney other) {
    _checkSameScale(other);
    return microUnits.compareTo(other.microUnits);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DecimalMoney &&
            scale == other.scale &&
            microUnits == other.microUnits);
  }

  @override
  int get hashCode => Object.hash(microUnits, scale);

  @override
  String toString() {
    final doubleVal = toDouble();
    return doubleVal.toStringAsFixed(math.min(4, scale));
  }

  void _checkSameScale(DecimalMoney other) {
    if (scale != other.scale) {
      throw ArgumentError(
        'Scale mismatch: $scale vs ${other.scale}. Scale normalization required.',
      );
    }
  }
}

/// Fixed-precision exchange rate backed by integer micro-units, preventing binary
/// float imprecision in multi-currency ledger conversions.
class DecimalRate {
  static const int defaultScale = 8;

  final BigInt microRate;
  final int scale;

  const DecimalRate._(this.microRate, [this.scale = defaultScale]);

  factory DecimalRate.fromMicroUnits(BigInt units, {int scale = defaultScale}) {
    if (units <= BigInt.zero) {
      throw ArgumentError('Exchange rate must be strictly positive');
    }
    return DecimalRate._(units, scale);
  }

  factory DecimalRate.fromDouble(double rate, {int scale = defaultScale}) {
    if (rate <= 0 || rate.isNaN || rate.isInfinite) {
      throw ArgumentError('Exchange rate must be positive and finite: $rate');
    }
    final factor = math.pow(10, scale).toDouble();
    final units = (rate * factor).round();
    return DecimalRate._(BigInt.from(units), scale);
  }

  factory DecimalRate.fromRatio(
    BigInt numerator,
    BigInt denominator, {
    int scale = defaultScale,
  }) {
    if (numerator <= BigInt.zero || denominator <= BigInt.zero) {
      throw ArgumentError('Numerator and denominator must be positive');
    }
    final factor = BigInt.from(10).pow(scale);
    final micro = (numerator * factor) ~/ denominator;
    return DecimalRate._(micro, scale);
  }

  double toDouble() {
    final factor = math.pow(10, scale).toDouble();
    return microRate.toDouble() / factor;
  }

  /// Converts [amount] in source currency to target currency using this exchange rate
  /// with deterministic fixed-precision rounding.
  DecimalMoney convert(
    DecimalMoney amount, {
    required int targetPrecision,
    FixedRoundingMode roundingMode = FixedRoundingMode.halfUp,
  }) {
    final factor = BigInt.from(10).pow(scale);
    final rawTargetUnits = (amount.microUnits * microRate) ~/ factor;
    final unrounded = DecimalMoney.fromMicroUnits(
      rawTargetUnits,
      scale: amount.scale,
    );
    return unrounded.roundTo(targetPrecision, roundingMode: roundingMode);
  }

  /// Calculates the exact fixed-precision inverse rate (`1 / rate`).
  DecimalRate inverse({int scale = defaultScale}) {
    final scaleFactor = BigInt.from(10).pow(scale * 2);
    final invUnits = scaleFactor ~/ microRate;
    return DecimalRate._(invUnits, scale);
  }

  /// Combines two exchange rates: (A -> B) * (B -> C) = (A -> C).
  DecimalRate multiply(DecimalRate other) {
    final factor = BigInt.from(10).pow(scale);
    final productUnits = (microRate * other.microRate) ~/ factor;
    return DecimalRate._(productUnits, scale);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DecimalRate &&
            scale == other.scale &&
            microRate == other.microRate);
  }

  @override
  int get hashCode => Object.hash(microRate, scale);

  @override
  String toString() => toDouble().toString();
}
