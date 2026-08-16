/// Primary financial document type for Receipts & Payments.
enum TransactionType {
  receipt,
  payment,
}

extension TransactionTypeX on TransactionType {
  String get storageValue => name;

  bool get isReceipt => this == TransactionType.receipt;

  bool get isPayment => this == TransactionType.payment;

  static TransactionType fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return TransactionType.receipt;
    }
    return TransactionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TransactionType.receipt,
    );
  }
}
