/// How the customer settles (or intends to settle) a sale.
enum PaymentMethod { cash, card, bankTransfer, credit, other }

extension PaymentMethodX on PaymentMethod {
  String get storageValue => name;

  static PaymentMethod fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return PaymentMethod.cash;
    }
    return PaymentMethod.values.firstWhere(
      (m) => m.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}
