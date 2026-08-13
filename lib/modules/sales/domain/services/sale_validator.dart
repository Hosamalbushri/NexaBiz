import '../entities/discount_type.dart';
import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../entities/sale_settlement_type.dart';
import '../models/sale_exception.dart';
import 'sale_currency_converter.dart';
import 'sale_money.dart';

/// Validates sale drafts before persistence.
class SaleValidator {
  const SaleValidator();

  void validate(SaleDraft draft) {
    if (draft.voucherBookId == null || draft.voucherBookId!.trim().isEmpty) {
      throw const SaleException(SaleException.voucherBookRequired);
    }
    if (draft.currencyCode.trim().isEmpty) {
      throw const SaleException(SaleException.currencyRequired);
    }
    if (draft.exchangeRate <= 0) {
      throw const SaleException(SaleException.currencyRequired);
    }

    if (draft.settlementType.isCredit) {
      if (draft.customerId == null || draft.customerId!.trim().isEmpty) {
        throw const SaleException(SaleException.customerRequired);
      }
      if (draft.customerAccountId == null ||
          draft.customerAccountId!.trim().isEmpty) {
        throw const SaleException(SaleException.customerAccountRequired);
      }
    }

    if (draft.settlementType.isCash) {
      if (draft.cashAccountId == null || draft.cashAccountId!.trim().isEmpty) {
        throw const SaleException(SaleException.cashAccountRequired);
      }
    }

    if (draft.items.isEmpty) {
      throw const SaleException(SaleException.emptyItems);
    }

    for (final item in draft.items) {
      validateItem(item, exchangeRate: draft.exchangeRate);
    }

    if (draft.taxRate < 0 || draft.taxRate > 100) {
      throw const SaleException(SaleException.invalidTax);
    }

    _validateDiscount(
      draft.discountType,
      draft.discountValue,
      code: SaleException.invalidDiscount,
    );

    if (draft.paidAmount < 0) {
      throw const SaleException(SaleException.invalidPayment);
    }
  }

  void validateItem(SaleItemDraft item, {double exchangeRate = 1}) {
    if (item.productId.trim().isEmpty) {
      throw const SaleException(SaleException.productRequired);
    }
    if (item.quantity <= 0) {
      throw const SaleException(SaleException.invalidQuantity);
    }
    if (item.unitPrice < 0 || item.baseUnitPrice < 0) {
      throw const SaleException(SaleException.invalidPrice);
    }
    const converter = SaleCurrencyConverter();
    final minSalePrice = converter.baseToSale(item.baseUnitPrice, exchangeRate);
    if (SaleMoney.toCents(item.unitPrice) < SaleMoney.toCents(minSalePrice)) {
      throw const SaleException(SaleException.priceBelowCatalog);
    }
    _validateDiscount(
      item.discountType,
      item.discountValue,
      code: SaleException.invalidDiscount,
    );
  }

  void assertPaidNotOverTotal({
    required double total,
    required double paidAmount,
    bool allowOverpayment = false,
  }) {
    if (allowOverpayment) {
      return;
    }
    if (SaleMoney.toCents(paidAmount) > SaleMoney.toCents(total)) {
      throw const SaleException(SaleException.invalidPayment);
    }
  }

  void _validateDiscount(
    DiscountType type,
    double value, {
    required String code,
  }) {
    if (value < 0) {
      throw SaleException(code);
    }
    if (type == DiscountType.percentage && value > 100) {
      throw SaleException(code);
    }
  }
}
