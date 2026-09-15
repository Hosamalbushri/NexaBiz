import '../domain/common/financial_exceptions.dart';

/// Single canonical financial persistence boundary validator for scaled integers (SQLite 64-bit signed int).
class FinancialInt64Boundary {
  /// Minimum allowed SQLite signed 64-bit integer (-2^63).
  static final BigInt int64Min = BigInt.parse('-9223372036854775808');

  /// Maximum allowed SQLite signed 64-bit integer (2^63 - 1).
  static final BigInt int64Max = BigInt.parse('9223372036854775807');

  const FinancialInt64Boundary._();

  /// Validates that [value] is strictly within SQLite Int64 limits [-2^63, 2^63 - 1].
  ///
  /// Throws [FinancialInt64BoundaryException] if [value] is outside the boundary.
  static BigInt check(BigInt value, String fieldName) {
    if (value < int64Min || value > int64Max) {
      throw FinancialInt64BoundaryException(
        fieldName: fieldName,
        attemptedValue: value,
      );
    }
    return value;
  }
}
