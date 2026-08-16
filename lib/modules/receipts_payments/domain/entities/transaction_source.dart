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
  cashBoxTransfer,
  currencyExchange,
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

  bool get isPaymentSource => switch (this) {
        TransactionSource.manualPayment ||
        TransactionSource.expensePayment ||
        TransactionSource.otherPayment ||
        TransactionSource.purchaseRelatedPayment => true,
        _ => false,
      };

  bool get isTransferSource => this == TransactionSource.cashBoxTransfer;

  bool get isCurrencyExchangeSource =>
      this == TransactionSource.currencyExchange;

  TransactionType get defaultTransactionType {
    if (isTransferSource) {
      return TransactionType.transfer;
    }
    if (isCurrencyExchangeSource) {
      return TransactionType.currencyExchange;
    }
    return isReceiptSource ? TransactionType.receipt : TransactionType.payment;
  }

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
        .where((s) {
          if (type.isTransfer) {
            return s.isTransferSource;
          }
          if (type.isCurrencyExchange) {
            return s.isCurrencyExchangeSource;
          }
          if (type.isReceipt) {
            return s.isReceiptSource;
          }
          return s.isPaymentSource;
        })
        .toList(growable: false);
  }
}
