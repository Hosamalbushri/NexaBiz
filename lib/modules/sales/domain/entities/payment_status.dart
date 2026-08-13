/// Derived payment state for a sale (from paid vs total).
enum PaymentStatus { unpaid, partiallyPaid, paid }

extension PaymentStatusX on PaymentStatus {
  String get storageValue => name;

  static PaymentStatus fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return PaymentStatus.unpaid;
    }
    return PaymentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  /// Consistent derivation from monetary amounts (2-decimal tolerance).
  static PaymentStatus fromAmounts({
    required double total,
    required double paidAmount,
  }) {
    final totalCents = _toCents(total);
    final paidCents = _toCents(paidAmount);
    if (totalCents <= 0) {
      return paidCents <= 0 ? PaymentStatus.paid : PaymentStatus.paid;
    }
    if (paidCents <= 0) {
      return PaymentStatus.unpaid;
    }
    if (paidCents >= totalCents) {
      return PaymentStatus.paid;
    }
    return PaymentStatus.partiallyPaid;
  }

  static int _toCents(double value) => (value * 100).round();
}
