import 'package:stock_count/app/localization/app_localizations.dart';
import '../../domain/entities/rp_payment_method.dart';
import '../../domain/entities/transaction_source.dart';
import '../../domain/entities/transaction_status.dart';
import '../../domain/entities/transaction_type.dart';

String rpTransactionStatusLabel(
  AppLocalizations l10n,
  TransactionStatus status,
) {
  return switch (status) {
    TransactionStatus.unposted => l10n.rpStatusUnposted,
    TransactionStatus.posted => l10n.rpStatusPosted,
  };
}

String rpTransactionTypeLabel(AppLocalizations l10n, TransactionType type) {
  return switch (type) {
    TransactionType.receipt => l10n.rpTypeReceipt,
    TransactionType.payment => l10n.rpTypePayment,
    TransactionType.transfer => l10n.rpTypeTransfer,
    TransactionType.currencyExchange => l10n.rpTypeExchange,
  };
}

String rpTransactionSourceLabel(
  AppLocalizations l10n,
  TransactionSource source,
) {
  return switch (source) {
    TransactionSource.manualReceipt => l10n.rpSourceManualReceipt,
    TransactionSource.manualPayment => l10n.rpSourceManualPayment,
    TransactionSource.customerReceipt => l10n.rpSourceCustomerReceipt,
    TransactionSource.expensePayment => l10n.rpSourceExpensePayment,
    TransactionSource.otherReceipt => l10n.rpSourceOtherReceipt,
    TransactionSource.otherPayment => l10n.rpSourceOtherPayment,
    TransactionSource.salesRelatedReceipt => l10n.rpSourceSalesRelatedReceipt,
    TransactionSource.purchaseRelatedPayment =>
      l10n.rpSourcePurchaseRelatedPayment,
    TransactionSource.cashBoxTransfer => l10n.rpSourceCashBoxTransfer,
    TransactionSource.currencyExchange => l10n.rpSourceCurrencyExchange,
  };
}

String rpPaymentMethodLabel(AppLocalizations l10n, RpPaymentMethod method) {
  return switch (method) {
    RpPaymentMethod.cash => l10n.rpPaymentCash,
    RpPaymentMethod.card => l10n.rpPaymentCard,
    RpPaymentMethod.bankTransfer => l10n.rpPaymentBankTransfer,
    RpPaymentMethod.other => l10n.rpPaymentOther,
  };
}
