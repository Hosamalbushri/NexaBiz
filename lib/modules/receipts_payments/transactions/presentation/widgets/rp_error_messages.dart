import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/permissions/permission_error_messages.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/presentation/widgets/journal_exception_messages.dart';
import '../../domain/models/financial_transaction_exception.dart';

String rpErrorMessage(AppLocalizations l10n, Object error) {
  final denied = permissionDeniedMessage(l10n, error);
  if (denied != null) {
    return denied;
  }
  if (error is JournalException) {
    return journalExceptionMessage(l10n, error);
  }
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
      FinancialTransactionException.currenciesMustDiffer =>
        l10n.rpErrorCurrenciesMustDiffer,
      FinancialTransactionException.voucherBookRequired =>
        l10n.rpErrorVoucherBookRequired,
      FinancialTransactionException.notEditable => l10n.rpErrorNotEditable,
      FinancialTransactionException.cannotPost => l10n.rpErrorCannotPost,
      FinancialTransactionException.cannotUnpost => l10n.rpErrorCannotUnpost,
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
