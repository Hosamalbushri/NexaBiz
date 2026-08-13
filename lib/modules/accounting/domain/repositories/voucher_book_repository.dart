import '../entities/voucher_book.dart';
import '../entities/voucher_book_type.dart';

/// Persistence for voucher numbering books (section groups + children).
abstract class VoucherBookRepository {
  Future<List<VoucherBook>> getAll();

  Stream<List<VoucherBook>> watchAll();

  Future<VoucherBook?> getById(int id);

  Future<VoucherBook?> getByUuid(String uuid);

  Future<List<VoucherBook>> getByType(VoucherBookType type);

  Future<List<VoucherBook>> getChildren(String parentUuid);

  /// Ensures default section folders exist and orphans are attached.
  Future<void> ensureDefaultSections();

  /// Section groups with their child books (after [ensureDefaultSections]).
  Future<List<VoucherBookSectionNode>> getSectionTree();

  Stream<List<VoucherBookSectionNode>> watchSectionTree();

  Future<VoucherBook> create(VoucherBookDraft draft);

  Future<VoucherBook> update(int id, VoucherBookDraft draft);

  Future<void> delete(int id);

  /// Atomically returns the current [VoucherBook.currentNumber] then increments it.
  /// Only valid for active leaf books (not section groups).
  /// Fails when the book is exhausted (`currentNumber` > `endNumber`).
  Future<int> allocateNextNumber(int id);
}
