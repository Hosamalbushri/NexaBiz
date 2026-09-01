import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/modules/accounting/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/data/repositories/voucher_book_repository_impl.dart';
import 'package:stock_count/modules/accounting/domain/entities/voucher_book.dart';
import 'package:stock_count/modules/accounting/domain/entities/voucher_book_type.dart';
import 'package:stock_count/modules/accounting/domain/models/voucher_book_exception.dart';
import 'package:stock_count/modules/accounting/domain/services/default_voucher_books.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase db;
  late VoucherBookRepositoryImpl repo;

  setUp(() async {
    db = AccountingDatabase.memory();
    repo = VoucherBookRepositoryImpl(db);
    await repo.ensureDefaultSections();
  });

  tearDown(() async {
    await db.close();
  });

  test('seeds default section groups and one leaf book per kind', () async {
    final tree = await repo.getSectionTree();
    expect(tree.length, VoucherBookType.sections.length);

    final sales = tree.firstWhere(
      (n) => n.group.bookType == VoucherBookType.sales,
    );
    expect(
      sales.children.map((c) => c.bookType),
      containsAll([VoucherBookType.sales, VoucherBookType.salesReturns]),
    );
    expect(
      sales.children.where((c) => c.bookType == VoucherBookType.sales).length,
      1,
    );

    final rp = tree.firstWhere(
      (n) => n.group.bookType == VoucherBookType.receiptsPayments,
    );
    expect(
      rp.children.map((c) => c.bookType),
      containsAll([
        VoucherBookType.receipts,
        VoucherBookType.payments,
        VoucherBookType.transfers,
        VoucherBookType.exchanges,
      ]),
    );

    final allLeaves = tree.expand((n) => n.children).toList(growable: false);
    expect(allLeaves.length, DefaultVoucherBooks.seeds.length);
    for (final seed in DefaultVoucherBooks.seeds) {
      expect(
        allLeaves.any(
          (b) => b.bookType == seed.bookType && b.name == seed.nameAr,
        ),
        isTrue,
      );
    }
  });

  test('does not duplicate default leaves on second ensure', () async {
    await repo.ensureDefaultSections();
    final tree = await repo.getSectionTree();
    final leafCount = tree.fold<int>(0, (sum, n) => sum + n.children.length);
    expect(leafCount, DefaultVoucherBooks.seeds.length);
  });

  test('allocate advances currentNumber until end', () async {
    final salesBook = (await repo.getSectionTree())
        .firstWhere((n) => n.group.bookType == VoucherBookType.sales)
        .children
        .firstWhere((b) => b.bookType == VoucherBookType.sales);

    await repo.update(
      salesBook.id,
      VoucherBookDraft(
        name: salesBook.name,
        bookType: salesBook.bookType,
        parentId: salesBook.parentId,
        currentNumber: 7,
        endNumber: 8,
      ),
    );

    expect(await repo.allocateNextNumber(salesBook.id), 7);
    expect(await repo.allocateNextNumber(salesBook.id), 8);
    expect(
      () => repo.allocateNextNumber(salesBook.id),
      throwsA(isA<VoucherBookException>()),
    );
  });

  test('reserveNumberBlock claims exclusive range', () async {
    final salesBook = (await repo.getSectionTree())
        .firstWhere((n) => n.group.bookType == VoucherBookType.sales)
        .children
        .firstWhere((b) => b.bookType == VoucherBookType.sales);

    await repo.update(
      salesBook.id,
      VoucherBookDraft(
        name: salesBook.name,
        bookType: salesBook.bookType,
        parentId: salesBook.parentId,
        currentNumber: 10,
        endNumber: 100,
      ),
    );

    final block = await repo.reserveNumberBlock(salesBook.id, 50);
    expect(block.start, 10);
    expect(block.end, 59);
    final again = await repo.reserveNumberBlock(salesBook.id, 10);
    expect(again.start, 60);
    expect(again.end, 69);
  });

  test('validator rejects end before current', () async {
    final salesUuid = (await repo.getSectionTree())
        .firstWhere((n) => n.group.bookType == VoucherBookType.sales)
        .group
        .uuid;
    expect(
      () => repo.create(
        VoucherBookDraft(
          name: 'Bad range',
          bookType: VoucherBookType.sales,
          parentId: salesUuid,
          currentNumber: 10,
          endNumber: 5,
        ),
      ),
      throwsA(isA<VoucherBookException>()),
    );
  });
}
