import '../../modules/accounting/domain/entities/voucher_book_type.dart';
import '../../modules/accounting/domain/repositories/voucher_book_repository.dart';
import '../../modules/sales/domain/services/sale_voucher_book_port.dart';

/// App adapter: Sales voucher books → Accounting [VoucherBookRepository].
class AccountingSaleVoucherBookAdapter implements SaleVoucherBookPort {
  const AccountingSaleVoucherBookAdapter(this._repository);

  final VoucherBookRepository _repository;

  @override
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks() async {
    await _repository.ensureDefaultSections();
    final books = await _repository.getByType(VoucherBookType.sales);
    return books
        .where((b) => !b.isGroup && b.isActive)
        .map(
          (b) => SaleVoucherBookRef(
            bookId: b.uuid,
            name: b.name,
            nextNumber: b.currentNumber,
            canAllocate: b.canAllocate,
          ),
        )
        .toList(growable: false);
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
    return SaleVoucherBookRef(
      bookId: book.uuid,
      name: book.name,
      nextNumber: book.currentNumber,
      canAllocate: book.canAllocate,
    );
  }

  @override
  Future<String> allocateSaleNumber(String bookId) async {
    final book = await _repository.getByUuid(bookId);
    if (book == null || !book.canAllocate) {
      throw StateError('Sales voucher book unavailable: $bookId');
    }
    final number = await _repository.allocateNextNumber(book.id);
    return number.toString();
  }
}
