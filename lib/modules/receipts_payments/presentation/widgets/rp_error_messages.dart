import '../../../../app/localization/app_localizations.dart';
import '../../domain/models/financial_transaction_exception.dart';

String rpErrorMessage(AppLocalizations l10n, Object error) {
  if (error is FinancialTransactionException) {
    return switch (error.code) {
      FinancialTransactionException.notFound => l10n.rpNotFound,
      FinancialTransactionException.amountMustBePositive =>
        l10n.rpErrorAmountMustBePositive,
      FinancialTransactionException.counterAmountMustBePositive =>
        l10n.rpErrorCounterAmountMustBePositive,
      FinancialTransactionException.cashAccountRequired =>
        l10n.rpErrorCashAccountRequired,
      FinancialTransactionException.counterAccountRequired =>
        l10n.rpErrorCounterAccountRequired,
      FinancialTransactionException.customerRequired =>
        l10n.rpErrorCustomerRequired,
      FinancialTransactionException.sameAccounts => l10n.rpErrorSameAccounts,
      FinancialTransactionException.voucherBookRequired =>
        l10n.rpErrorVoucherBookRequired,
      FinancialTransactionException.notEditable => l10n.rpErrorNotEditable,
      FinancialTransactionException.cannotPost => l10n.rpErrorCannotPost,
      FinancialTransactionException.cannotCancel => l10n.rpErrorCannotCancel,
      FinancialTransactionException.alreadyCancelled =>
        l10n.rpErrorAlreadyCancelled,
      FinancialTransactionException.ledgerPostingFailed =>
        l10n.rpErrorLedgerPostingFailed,
      FinancialTransactionException.currencyRequired =>
        l10n.rpErrorCurrencyRequired,
      FinancialTransactionException.unbalanced => l10n.rpErrorUnbalanced,
      FinancialTransactionException.savingInProgress =>
        l10n.rpErrorSavingInProgress,
      _ => l10n.somethingWentWrong,
    };
  }
  return l10n.somethingWentWrong;
}
