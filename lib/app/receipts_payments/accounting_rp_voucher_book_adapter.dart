import '../../modules/accounting/domain/entities/voucher_book_type.dart';
import '../../modules/accounting/domain/repositories/voucher_book_repository.dart';
import '../../modules/receipts_payments/domain/entities/transaction_type.dart';
import '../../modules/receipts_payments/domain/services/rp_voucher_book_port.dart';
import '../../modules/sales/data/sale_number_block_store.dart';
import '../../modules/sales/domain/services/device_sale_number.dart';

/// App adapter: receipts/payments numbering → Accounting voucher books.
///
/// Reuses the Sales device-lane + offline block store pattern.
class AccountingRpVoucherBookAdapter implements RpVoucherBookPort {
  AccountingRpVoucherBookAdapter(
    this._repository, {
    required this.deviceId,
    SaleNumberBlockStore? blockStore,
    this.blockSize = SaleNumberBlockStore.defaultBlockSize,
  }) : _blocks = blockStore ?? SaleNumberBlockStore();

  final VoucherBookRepository _repository;
  final SaleNumberBlockStore _blocks;
  final String deviceId;
  final int blockSize;

  int get _base => deviceSaleNumberBase(deviceId);

  VoucherBookType _sectionFor(TransactionType type) => type.isReceipt
      ? VoucherBookType.receipts
      : VoucherBookType.payments;

  @override
  Future<List<RpVoucherBookRef>> listActiveBooks(TransactionType type) async {
    await _repository.ensureDefaultSections();
    final books = await _repository.getByType(_sectionFor(type));
    final refs = <RpVoucherBookRef>[];
    for (final b in books) {
      if (b.isGroup || !b.isActive) continue;
      refs.add(
        await _toRef(
          b.uuid,
          b.name,
          b.currentNumber,
          b.canAllocate,
          type,
        ),
      );
    }
    return refs;
  }

  @override
  Future<RpVoucherBookRef?> findById(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) return null;
    final section = book.bookType.section;
    if (section != VoucherBookType.receipts &&
        section != VoucherBookType.payments) {
      return null;
    }
    final type = section == VoucherBookType.receipts
        ? TransactionType.receipt
        : TransactionType.payment;
    return _toRef(
      book.uuid,
      book.name,
      book.currentNumber,
      book.canAllocate,
      type,
    );
  }

  Future<RpVoucherBookRef> _toRef(
    String bookId,
    String name,
    int bookCurrent,
    bool canAllocate,
    TransactionType type,
  ) async {
    final peek = await _blocks.peekNext(bookId);
    final sequence = peek ?? bookCurrent;
    final absolute = _base + sequence;
    return RpVoucherBookRef(
      bookId: bookId,
      name: name,
      nextNumber: absolute,
      canAllocate: canAllocate || (peek != null),
      transactionType: type,
      formattedPreview: formatSaleNumberPrimary(formatSaleNumber(absolute)),
    );
  }

  @override
  Future<String> allocateNumber({
    required String bookId,
    required TransactionType type,
  }) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) {
      throw StateError('Voucher book unavailable: $bookId');
    }
    final expected = _sectionFor(type);
    if (book.bookType.section != expected) {
      throw StateError('Voucher book type mismatch for $bookId');
    }

    var sequence = await _blocks.takeNext(bookId);
    if (sequence == null) {
      if (!book.canAllocate) {
        throw StateError('Voucher book exhausted: $bookId');
      }
      final reserved = await _repository.reserveNumberBlock(book.id, blockSize);
      sequence = await _blocks.installBlock(
        bookId: bookId,
        start: reserved.start,
        end: reserved.end,
      );
    }

    return formatSaleNumber(_base + sequence);
  }
}
