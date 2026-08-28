import 'package:stock_count/modules/accounting/voucher_books/domain/entities/voucher_book_type.dart';
import 'package:stock_count/modules/accounting/voucher_books/domain/repositories/voucher_book_repository.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_voucher_book_port.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_number_block_store.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/device_sale_number.dart';

/// App adapter: Inventory voucher books → Accounting [VoucherBookRepository].
///
/// Allocates plain integer document numbers from exclusive offline blocks.
/// A silent per-device numeric lane avoids collisions across devices
/// without displaying a device prefix.
class AccountingInventoryVoucherBookAdapter implements InventoryVoucherBookPort {
  AccountingInventoryVoucherBookAdapter(
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
  Future<List<InventoryVoucherBookRef>> listActiveIssueBooks() async {
    await _repository.seedDefaultBooks();
    final books = await _repository.getByType(VoucherBookType.stockIssues);
    final refs = <InventoryVoucherBookRef>[];
    for (final b in books) {
      if (b.isGroup || !b.isActive) continue;
      refs.add(await _toRef(b.uuid, b.name, b.currentNumber, b.canAllocate));
    }
    return refs;
  }

  @override
  Future<List<InventoryVoucherBookRef>> listActiveReceiptBooks() async {
    await _repository.seedDefaultBooks();
    final books = await _repository.getByType(VoucherBookType.stockReceipts);
    final refs = <InventoryVoucherBookRef>[];
    for (final b in books) {
      if (b.isGroup || !b.isActive) continue;
      refs.add(await _toRef(b.uuid, b.name, b.currentNumber, b.canAllocate));
    }
    return refs;
  }

  @override
  Future<InventoryVoucherBookRef?> findById(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) return null;
    return _toRef(book.uuid, book.name, book.currentNumber, book.canAllocate);
  }

  Future<InventoryVoucherBookRef> _toRef(
    String bookId,
    String name,
    int bookCurrent,
    bool canAllocate,
  ) async {
    final peek = await _blocks.peekNext(bookId);
    final sequence = peek ?? bookCurrent;
    final absolute = _base + sequence;
    return InventoryVoucherBookRef(
      bookId: bookId,
      name: name,
      nextNumber: absolute,
      canAllocate: canAllocate || (peek != null),
      formattedPreview: formatSaleNumberPrimary(formatSaleNumber(absolute)),
    );
  }

  @override
  Future<String> allocateIssueNumber(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) {
      throw StateError('Stock issue voucher book unavailable: $bookId');
    }

    var sequence = await _blocks.takeNext(bookId);
    if (sequence == null) {
      if (!book.canAllocate) {
        throw StateError('Stock issue voucher book exhausted: $bookId');
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

  @override
  Future<String> allocateReceiptNumber(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) {
      throw StateError('Stock receipt voucher book unavailable: $bookId');
    }

    var sequence = await _blocks.takeNext(bookId);
    if (sequence == null) {
      if (!book.canAllocate) {
        throw StateError('Stock receipt voucher book exhausted: $bookId');
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
