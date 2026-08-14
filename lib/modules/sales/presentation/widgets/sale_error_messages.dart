import '../../../../app/localization/app_localizations.dart';
import '../../domain/models/sale_exception.dart';

/// Maps sales domain / unexpected errors to user-facing localized text.
String saleErrorMessage(AppLocalizations l10n, Object error) {
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
      _ => l10n.somethingWentWrong,
    };
  }
  return l10n.somethingWentWrong;
}
