import 'transaction_type.dart';

/// Business origin of a financial transaction (not hardcoded in UI).
enum TransactionSource {
  manualReceipt,
  manualPayment,
  customerReceipt,
  expensePayment,
  otherReceipt,
  otherPayment,
  salesRelatedReceipt,
  purchaseRelatedPayment,
}

extension TransactionSourceX on TransactionSource {
  String get storageValue => name;

  bool get requiresCustomer => this == TransactionSource.customerReceipt;

  bool get isReceiptSource => switch (this) {
        TransactionSource.manualReceipt ||
        TransactionSource.customerReceipt ||
        TransactionSource.otherReceipt ||
        TransactionSource.salesRelatedReceipt => true,
        _ => false,
      };

  bool get isPaymentSource => !isReceiptSource;

  TransactionType get defaultTransactionType =>
      isReceiptSource ? TransactionType.receipt : TransactionType.payment;

  static TransactionSource fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return TransactionSource.manualReceipt;
    }
    return TransactionSource.values.firstWhere(
      (s) => s.name == value,
      orElse: () => TransactionSource.manualReceipt,
    );
  }

  static List<TransactionSource> forType(TransactionType type) {
    return TransactionSource.values
        .where(
          (s) => type.isReceipt ? s.isReceiptSource : s.isPaymentSource,
        )
        .toList(growable: false);
  }
}
