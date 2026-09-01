import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/permissions/permission_error_messages.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/core/widgets/journal_exception_messages.dart';
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
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }
    final localized = switch (error.code) {
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
      SaleException.postingRequiresInventory =>
        l10n.salesPostRequiresInventory,
      _ => null,
    };
    if (localized != null) {
      return localized;
    }
  }

  if (error is StateError) {
    if (error.message.toString().trim().isNotEmpty) {
      return error.message.toString();
    }
  }

  final rawStr = error.toString();
  final cleaned = rawStr
      .replaceFirst(RegExp(r'^(Bad state|StateError|Error|Exception):\s*'), '')
      .trim();

  if (cleaned.isNotEmpty && !cleaned.startsWith('Instance of')) {
    return cleaned;
  }

  return l10n.somethingWentWrong;
}
