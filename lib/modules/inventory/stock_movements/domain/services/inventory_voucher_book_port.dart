/// Opaque voucher book reference for inventory stock movements numbering.
class InventoryVoucherBookRef {
  const InventoryVoucherBookRef({
    required this.bookId,
    required this.name,
    required this.nextNumber,
    required this.canAllocate,
    this.formattedPreview,
  });

  /// VoucherBook.uuid or int id as String
  final String bookId;
  final String name;

  /// Next numeric sequence
  final int nextNumber;
  final bool canAllocate;

  final String? formattedPreview;

  String get previewNumber => formattedPreview ?? '$nextNumber';
}

/// App wires to Accounting voucher books for stock issues / receipts.
abstract class InventoryVoucherBookPort {
  Future<List<InventoryVoucherBookRef>> listActiveIssueBooks();
  Future<List<InventoryVoucherBookRef>> listActiveReceiptBooks();

  Future<InventoryVoucherBookRef?> findById(String bookId);

  /// Atomically allocates the next number and returns a formatted document number.
  Future<String> allocateIssueNumber(String bookId);
  Future<String> allocateReceiptNumber(String bookId);
}

class NoOpInventoryVoucherBookPort implements InventoryVoucherBookPort {
  const NoOpInventoryVoucherBookPort();

  @override
  Future<List<InventoryVoucherBookRef>> listActiveIssueBooks() async => const [];

  @override
  Future<List<InventoryVoucherBookRef>> listActiveReceiptBooks() async => const [];

  @override
  Future<InventoryVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<String> allocateIssueNumber(String bookId) async {
    return 'ISS-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  @override
  Future<String> allocateReceiptNumber(String bookId) async {
    return 'REC-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }
}
