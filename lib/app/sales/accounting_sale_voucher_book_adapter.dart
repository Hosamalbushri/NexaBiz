import '../../modules/accounting/domain/entities/voucher_book_type.dart';
import '../../modules/accounting/domain/repositories/voucher_book_repository.dart';
import '../../modules/sales/data/sale_number_block_store.dart';
import '../../modules/sales/domain/services/device_sale_number.dart';
import '../../modules/sales/domain/services/sale_voucher_book_port.dart';

/// App adapter: Sales voucher books → Accounting [VoucherBookRepository].
///
/// Allocates plain integer sale numbers from exclusive offline blocks.
/// A silent per-device numeric lane avoids collisions without showing a
/// device code next to the invoice number.
class AccountingSaleVoucherBookAdapter implements SaleVoucherBookPort {
  AccountingSaleVoucherBookAdapter(
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

  @override
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks() async {
    await _repository.ensureDefaultSections();
    final books = await _repository.getByType(VoucherBookType.sales);
    final refs = <SaleVoucherBookRef>[];
    for (final b in books) {
      if (b.isGroup || !b.isActive) {
        continue;
      }
      refs.add(await _toRef(b.uuid, b.name, b.currentNumber, b.canAllocate));
    }
    return refs;
  }

  @override
  Future<SaleVoucherBookRef?> findById(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) {
      return null;
    }
    if (book.bookType.section != VoucherBookType.sales) {
      return null;
    }
    return _toRef(
      book.uuid,
      book.name,
      book.currentNumber,
      book.canAllocate,
    );
  }

  Future<SaleVoucherBookRef> _toRef(
    String bookId,
    String name,
    int bookCurrent,
    bool canAllocate,
  ) async {
    final peek = await _blocks.peekNext(bookId);
    final sequence = peek ?? bookCurrent;
    final absolute = _base + sequence;
    return SaleVoucherBookRef(
      bookId: bookId,
      name: name,
      nextNumber: absolute,
      canAllocate: canAllocate || (peek != null),
      formattedPreview: formatSaleNumber(absolute),
    );
  }

  @override
  Future<String> allocateSaleNumber(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) {
      throw StateError('Sales voucher book unavailable: $bookId');
    }

    var sequence = await _blocks.takeNext(bookId);
    if (sequence == null) {
      if (!book.canAllocate) {
        throw StateError('Sales voucher book exhausted: $bookId');
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
