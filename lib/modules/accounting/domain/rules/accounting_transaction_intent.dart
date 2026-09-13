import '../foundation/accounting_source_reference.dart';

enum AccountingTransactionType {
  saleCash,
  saleCredit,
  saleReturn,
  purchaseCash,
  purchaseCredit,
  purchaseReturn,
  stockReceipt,
  stockIssue,
  stockTransfer,
  stockAdjustment,
  customerReceipt,
  customerPayment,
  supplierPayment,
  cashTransfer,
  bankTransfer,
  expense,
  income,
  tax,
  fxGain,
  fxLoss,
  openingBalance,
}

class AccountingBusinessTransaction {
  const AccountingBusinessTransaction({
    required this.companyId,
    required this.transactionType,
    required this.sourceReference,
    required this.transactionDate,
    required this.amount,
    required this.currencyCode,
    required this.baseCurrencyCode,
    this.exchangeRate,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.warehouseId,
    this.customDebitAccountUuid,
    this.customCreditAccountUuid,
    this.voucherNumber,
    this.voucherType,
    this.description,
  });

  final String companyId;
  final AccountingTransactionType transactionType;
  final AccountingSourceReference sourceReference;
  final DateTime transactionDate;
  final double amount;
  final double taxAmount;
  final double discountAmount;
  final String currencyCode;
  final String baseCurrencyCode;
  final double? exchangeRate;
  final String? warehouseId;
  final String? customDebitAccountUuid;
  final String? customCreditAccountUuid;
  final String? voucherNumber;
  final String? voucherType;
  final String? description;
}
