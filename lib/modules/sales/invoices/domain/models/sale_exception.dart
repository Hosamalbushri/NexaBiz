/// Domain errors for the Sales module.
class SaleException implements Exception {
  const SaleException(this.code, [this.message]);

  static const invalidQuantity = 'invalid_quantity';
  static const invalidPrice = 'invalid_price';
  static const priceBelowCatalog = 'price_below_catalog';
  static const invalidDiscount = 'invalid_discount';
  static const invalidTax = 'invalid_tax';
  static const invalidPayment = 'invalid_payment';
  static const customerRequired = 'customer_required';
  static const customerNotFound = 'customer_not_found';
  static const customerAccountRequired = 'customer_account_required';
  static const cashAccountRequired = 'cash_account_required';
  static const voucherBookRequired = 'voucher_book_required';
  static const currencyRequired = 'currency_required';
  static const productRequired = 'product_required';
  static const productNotFound = 'product_not_found';
  static const emptyItems = 'empty_items';
  static const notFound = 'not_found';
  static const invalidStatusTransition = 'invalid_status_transition';
  static const duplicateSaleNumber = 'duplicate_sale_number';
  static const insufficientStock = 'insufficient_stock';
  static const syncFailed = 'sync_failed';
  static const externalIntegrationFailed = 'external_integration_failed';
  static const ledgerPostingFailed = 'ledger_posting_failed';
  static const postingRequiresInventory = 'posting_requires_inventory';
  static const postedImmutable = 'posted_immutable';
  static const concurrentOperationBlocked = 'concurrent_operation_blocked';

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}
