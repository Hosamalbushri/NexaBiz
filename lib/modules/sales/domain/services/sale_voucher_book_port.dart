/// Opaque voucher book reference for sales numbering.
class SaleVoucherBookRef {
  const SaleVoucherBookRef({
    required this.bookId,
    required this.name,
    required this.nextNumber,
    required this.canAllocate,
  });

  /// VoucherBook.uuid
  final String bookId;
  final String name;

  /// Next number that will be allocated (preview).
  final int nextNumber;
  final bool canAllocate;

  String get previewNumber => nextNumber.toString();
}

/// App wires to Accounting voucher books (modules ↛ modules).
abstract class SaleVoucherBookPort {
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks();

  Future<SaleVoucherBookRef?> findById(String bookId);

  /// Atomically allocates the next number and returns a formatted sale number.
  Future<String> allocateSaleNumber(String bookId);
}

class NoOpSaleVoucherBookPort implements SaleVoucherBookPort {
  const NoOpSaleVoucherBookPort();

  @override
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks() async => const [];

  @override
  Future<SaleVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<String> allocateSaleNumber(String bookId) async {
    throw StateError('No sales voucher book available');
  }
}
