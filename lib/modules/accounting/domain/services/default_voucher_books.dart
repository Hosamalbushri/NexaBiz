import '../entities/voucher_book_type.dart';

/// Default leaf voucher book to seed under a section.
class DefaultVoucherBookSeed {
  const DefaultVoucherBookSeed({
    required this.bookType,
    required this.nameEn,
    required this.nameAr,
    this.currentNumber = 1,
    this.endNumber = 9999,
  });

  final VoucherBookType bookType;
  final String nameEn;
  final String nameAr;
  final int currentNumber;
  final int endNumber;
}

/// Built-in setup data: one starter book per leaf kind under each section.
class DefaultVoucherBooks {
  const DefaultVoucherBooks._();

  static const List<DefaultVoucherBookSeed> seeds = [
    DefaultVoucherBookSeed(
      bookType: VoucherBookType.sales,
      nameEn: 'Main sales book',
      nameAr: 'دفتر المبيعات الرئيسي',
    ),
    DefaultVoucherBookSeed(
      bookType: VoucherBookType.salesReturns,
      nameEn: 'Main sales returns book',
      nameAr: 'دفتر مردود المبيعات الرئيسي',
    ),
    DefaultVoucherBookSeed(
      bookType: VoucherBookType.receipts,
      nameEn: 'Main receipts book',
      nameAr: 'دفتر المقبوضات الرئيسي',
    ),
    DefaultVoucherBookSeed(
      bookType: VoucherBookType.payments,
      nameEn: 'Main payments book',
      nameAr: 'دفتر المدفوعات الرئيسي',
    ),
    DefaultVoucherBookSeed(
      bookType: VoucherBookType.purchases,
      nameEn: 'Main purchases book',
      nameAr: 'دفتر المشتريات الرئيسي',
    ),
    DefaultVoucherBookSeed(
      bookType: VoucherBookType.purchaseReturns,
      nameEn: 'Main purchase returns book',
      nameAr: 'دفتر مردود المشتريات الرئيسي',
    ),
    DefaultVoucherBookSeed(
      bookType: VoucherBookType.journal,
      nameEn: 'Main journal book',
      nameAr: 'دفتر القيود الرئيسي',
    ),
  ];
}
