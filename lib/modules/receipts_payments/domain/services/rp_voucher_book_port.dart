import '../entities/transaction_type.dart';

class RpVoucherBookRef {
  const RpVoucherBookRef({
    required this.bookId,
    required this.name,
    required this.nextNumber,
    required this.canAllocate,
    required this.transactionType,
    this.formattedPreview,
  });

  final String bookId;
  final String name;
  final int nextNumber;
  final bool canAllocate;
  final TransactionType transactionType;
  final String? formattedPreview;

  String get previewNumber => formattedPreview ?? '$nextNumber';

  /// Identity is [bookId] so dropdowns match across list reloads.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RpVoucherBookRef && other.bookId == bookId;

  @override
  int get hashCode => bookId.hashCode;
}

/// App wires to Accounting voucher books (receipts / payments sections).
abstract class RpVoucherBookPort {
  Future<List<RpVoucherBookRef>> listActiveBooks(TransactionType type);

  Future<RpVoucherBookRef?> findById(String bookId);

  Future<String> allocateNumber({
    required String bookId,
    required TransactionType type,
  });
}

class NoOpRpVoucherBookPort implements RpVoucherBookPort {
  const NoOpRpVoucherBookPort();

  @override
  Future<List<RpVoucherBookRef>> listActiveBooks(TransactionType type) async =>
      const [];

  @override
  Future<RpVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<String> allocateNumber({
    required String bookId,
    required TransactionType type,
  }) async {
    throw StateError('No receipts/payments voucher book available');
  }
}
