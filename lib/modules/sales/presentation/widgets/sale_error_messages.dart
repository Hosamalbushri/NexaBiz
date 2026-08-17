import '../../../../app/localization/app_localizations.dart';
import '../../../../core/permissions/permission_error_messages.dart';
import '../../../accounting/domain/models/journal_exception.dart';
import '../../../accounting/presentation/widgets/journal_exception_messages.dart';
import '../../domain/models/sale_exception.dart';

/// Maps sales domain / unexpected errors to user-facing localized text.
String saleErrorMessage(AppLocalizations l10n, Object error) {
  final denied = permissionDeniedMessage(l10n, error);
  if (denied != null) {
    return denied;
  }
  if (error is JournalException) {
    return journalExceptionMessage(l10n, error);
  }
  if (error is SaleException) {
    return switch (error.code) {
      SaleException.emptyItems => l10n.salesErrorEmptyItems,
      SaleException.invalidQuantity => l10n.salesErrorInvalidQuantity,
      SaleException.invalidPrice => l10n.salesErrorInvalidPrice,
      SaleException.priceBelowCatalog => l10n.salesErrorPriceBelowCatalog,
      SaleException.invalidDiscount => l10n.salesErrorInvalidDiscount,
      SaleException.invalidTax => l10n.salesErrorInvalidTax,
      SaleException.invalidPayment => l10n.salesErrorInvalidPayment,
      SaleException.productRequired => l10n.salesErrorEmptyItems,
      SaleException.productNotFound => l10n.salesProductNotFound,
      SaleException.customerNotFound => l10n.salesCustomerNotFound,
      SaleException.customerRequired => l10n.salesErrorCustomerRequired,
      SaleException.customerAccountRequired =>
        l10n.salesErrorCustomerAccountRequired,
      SaleException.cashAccountRequired => l10n.salesErrorCashAccountRequired,
      SaleException.voucherBookRequired => l10n.salesErrorVoucherBookRequired,
      SaleException.currencyRequired => l10n.salesErrorCurrencyRequired,
      SaleException.invalidStatusTransition => l10n.salesErrorInvalidStatus,
      SaleException.notFound => l10n.salesNotFound,
      SaleException.duplicateSaleNumber => l10n.salesErrorInvalidStatus,
      SaleException.insufficientStock => l10n.salesErrorInvalidQuantity,
      SaleException.syncFailed => l10n.somethingWentWrong,
      SaleException.externalIntegrationFailed => l10n.somethingWentWrong,
      SaleException.ledgerPostingFailed => l10n.somethingWentWrong,
      SaleException.postingRequiresInventory =>
        l10n.salesPostRequiresInventory,
      _ => l10n.somethingWentWrong,
    };
  }
  return l10n.somethingWentWrong;
}
