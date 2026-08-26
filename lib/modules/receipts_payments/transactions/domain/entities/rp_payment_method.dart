/// How cash/bank movement is effected (aligned with Sales payment methods).
enum RpPaymentMethod { cash, card, bankTransfer, other }

extension RpPaymentMethodX on RpPaymentMethod {
  String get storageValue => name;

  static RpPaymentMethod fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return RpPaymentMethod.cash;
    }
    return RpPaymentMethod.values.firstWhere(
      (m) => m.name == value,
      orElse: () => RpPaymentMethod.cash,
    );
  }
}
