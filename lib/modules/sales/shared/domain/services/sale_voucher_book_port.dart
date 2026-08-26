/// Opaque voucher book reference for sales numbering.
class SaleVoucherBookRef {
  const SaleVoucherBookRef({
    required this.bookId,
    required this.name,
    required this.nextNumber,
    required this.canAllocate,
    this.formattedPreview,
  });

  /// VoucherBook.uuid
  final String bookId;
  final String name;

  /// Next numeric sequence that will be allocated (without device prefix).
  final int nextNumber;
  final bool canAllocate;

  /// Plain integer preview for the next sale number on this device lane.
  final String? formattedPreview;

  /// UI preview of the next invoice number.
  String get previewNumber => formattedPreview ?? '$nextNumber';
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
