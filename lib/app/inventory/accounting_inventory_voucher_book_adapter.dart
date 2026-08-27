import 'package:stock_count/modules/accounting/voucher_books/domain/entities/voucher_book_type.dart';
import 'package:stock_count/modules/accounting/voucher_books/domain/repositories/voucher_book_repository.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_voucher_book_port.dart';

/// App adapter: Inventory voucher books → Accounting [VoucherBookRepository].
class AccountingInventoryVoucherBookAdapter implements InventoryVoucherBookPort {
  AccountingInventoryVoucherBookAdapter(this._repository);

  final VoucherBookRepository _repository;

  @override
  Future<List<InventoryVoucherBookRef>> listActiveIssueBooks() async {
    await _repository.ensureDefaultSections();
    final books = await _repository.getByType(VoucherBookType.stockIssues);
    final refs = <InventoryVoucherBookRef>[];
    for (final b in books) {
      if (b.isGroup || !b.isActive) continue;
      refs.add(_toRef(b.uuid, b.name, b.currentNumber, b.canAllocate));
    }
    return refs;
  }

  @override
  Future<List<InventoryVoucherBookRef>> listActiveReceiptBooks() async {
    await _repository.ensureDefaultSections();
    final books = await _repository.getByType(VoucherBookType.stockReceipts);
    final refs = <InventoryVoucherBookRef>[];
    for (final b in books) {
      if (b.isGroup || !b.isActive) continue;
      refs.add(_toRef(b.uuid, b.name, b.currentNumber, b.canAllocate));
    }
    return refs;
  }

  @override
  Future<InventoryVoucherBookRef?> findById(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) return null;
    return _toRef(book.uuid, book.name, book.currentNumber, book.canAllocate);
  }

  InventoryVoucherBookRef _toRef(
    String bookId,
    String name,
    int currentNumber,
    bool canAllocate,
  ) {
    final formatted = 'ISS-${currentNumber.toString().padLeft(5, '0')}';
    return InventoryVoucherBookRef(
      bookId: bookId,
      name: name,
      nextNumber: currentNumber,
      canAllocate: canAllocate,
      formattedPreview: formatted,
    );
  }

  @override
  Future<String> allocateIssueNumber(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) {
      return 'ISS-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    final nextNum = await _repository.allocateNextNumber(book.id);
    return 'ISS-${nextNum.toString().padLeft(5, '0')}';
  }

  @override
  Future<String> allocateReceiptNumber(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || book.isGroup || !book.isActive) {
      return 'REC-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    final nextNum = await _repository.allocateNextNumber(book.id);
    return 'REC-${nextNum.toString().padLeft(5, '0')}';
  }
}
