/// Primary financial document type for Receipts & Payments.
enum TransactionType {
  receipt,
  payment,
  transfer,
  currencyExchange,
}

extension TransactionTypeX on TransactionType {
  String get storageValue => name;

  bool get isReceipt => this == TransactionType.receipt;

  bool get isPayment => this == TransactionType.payment;

  bool get isTransfer => this == TransactionType.transfer;

  bool get isCurrencyExchange => this == TransactionType.currencyExchange;

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
