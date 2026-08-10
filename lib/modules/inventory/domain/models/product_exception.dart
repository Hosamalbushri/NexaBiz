/// Domain errors for product catalog operations.
class ProductException implements Exception {
  const ProductException(this.code, [this.message]);

  static const String duplicateItemCode = 'duplicate_item_code';
  static const String duplicateBarcode = 'duplicate_barcode';
  static const String notFound = 'not_found';
  static const String invalidPackSize = 'invalid_pack_size';
  static const String invalidPrice = 'invalid_price';
  static const String invalidItemCode = 'invalid_item_code';
  static const String invalidName = 'invalid_name';

  final String code;
  final String? message;

  @override
  String toString() => 'ProductException($code${message == null ? '' : ': $message'})';
}
