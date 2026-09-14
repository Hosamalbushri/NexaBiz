import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_list_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_keyset_paged_result.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_list_filter.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_paged_result.dart';
import 'package:stock_count/modules/sales/invoices/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_money.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_validator.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_voucher_book_port.dart';

class FakeVoucherBookPort implements SaleVoucherBookPort {
  const FakeVoucherBookPort();

  @override
  Future<String> allocateSaleNumber(String voucherBookId) async => 'INV-9999';

  @override
  Future<SaleVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks() async => [];
}

class InMemorySaleRepository implements SaleRepository {
  final Map<int, Sale> _sales = {};
  int _nextId = 1;
  int _sequence = 1;

  @override
  Future<Sale?> getById(int id) async => _sales[id];

  @override
  Future<Sale?> getByUuid(String uuid) async {
    for (final s in _sales.values) {
      if (s.uuid == uuid) return s;
    }
    return null;
  }

  @override
  Future<Sale?> getBySaleNumber(String saleNumber) async {
    for (final s in _sales.values) {
      if (s.saleNumber == saleNumber) return s;
    }
    return null;
  }

  @override
  Future<List<Sale>> getAll() async =>
      _sales.values.where((s) => !s.isDeleted).toList();

  @override
  Stream<List<Sale>> watchAll() async* {
    yield await getAll();
  }

  @override
  Stream<List<Sale>> watchFiltered(SaleListFilter filter) async* {
    yield await getAll();
  }

  @override
  Future<List<Sale>> search(SaleListFilter filter) async => getAll();

  @override
  Future<Sale> insert(SaleDraft draft, {required String saleNumber}) async {
    const calculator = SaleCalculationService();
    final summary = calculator.calculate(
      items: draft.items,
      saleDiscountType: draft.discountType,
      saleDiscountValue: draft.discountValue,
      taxRatePercent: draft.taxRate,
      paidAmount: draft.paidAmount,
    );

    final id = _nextId++;
    final now = DateTime.now().toUtc();
    final sale = Sale(
      id: id,
      uuid: 'uuid_$id',
      companyId: draft.companyId ?? 'company_1',
      saleNumber: saleNumber,
      saleDate: draft.saleDate,
      settlementType: draft.settlementType,
      voucherBookId: draft.voucherBookId,
      warehouseId: draft.warehouseId,
      customerId: draft.customerId,
      customerCode: draft.customerCode,
      customerName: draft.customerName,
      customerAccountId: draft.customerAccountId,
      cashAccountId: draft.cashAccountId,
      currencyCode: draft.currencyCode,
      baseCurrencyCode: draft.baseCurrencyCode,
      exchangeRate: draft.exchangeRate,
      dataSource: SaleDataSource.local,
      items: [
        for (int i = 0; i < draft.items.length; i++)
          SaleItem(
            id: i + 1,
            uuid: 'item_${id}_$i',
            saleUuid: 'uuid_$id',
            productId: draft.items[i].productId,
            productName: draft.items[i].productName,
            productCode: draft.items[i].productCode,
            quantity: draft.items[i].quantity,
            mainQuantity: draft.items[i].mainQuantity,
            subQuantity: draft.items[i].subQuantity,
            packSize: draft.items[i].packSize,
            unitPrice: draft.items[i].unitPrice,
            baseUnitPrice: draft.items[i].baseUnitPrice,
            discountType: draft.items[i].discountType,
            discountValue: draft.items[i].discountValue,
            discountAmount: SaleMoney.applyDiscount(
              base: SaleMoney.round(
                draft.items[i].quantity * draft.items[i].unitPrice,
              ),
              isPercentage:
                  draft.items[i].discountType == DiscountType.percentage,
              discountValue: draft.items[i].discountValue,
            ),
            taxAmount: 0,
            subtotal: SaleMoney.round(
              draft.items[i].quantity * draft.items[i].unitPrice,
            ),
            total: SaleMoney.clampNonNegative(
              SaleMoney.round(
                    draft.items[i].quantity * draft.items[i].unitPrice,
                  ) -
                  SaleMoney.applyDiscount(
                    base: SaleMoney.round(
                      draft.items[i].quantity * draft.items[i].unitPrice,
                    ),
                    isPercentage:
                        draft.items[i].discountType == DiscountType.percentage,
                    discountValue: draft.items[i].discountValue,
                  ),
            ),
            lineOrder: i,
          ),
      ],
      payments: [],
      subtotal: summary.subtotal,
      itemDiscountTotal: summary.itemDiscountTotal,
      discountType: draft.discountType,
      discountValue: draft.discountValue,
      discountAmount: summary.saleDiscount,
      taxRate: draft.taxRate,
      taxAmount: summary.tax,
      total: summary.total,
      paidAmount: summary.paidAmount,
      remainingAmount: summary.remainingAmount,
      paymentStatus: summary.paymentStatus,
      paymentMethod: draft.paymentMethod,
      saleStatus: draft.saleStatus,
      notes: draft.notes,
      createdAt: now,
      updatedAt: now,
    );
    _sales[id] = sale;
    return sale;
  }

  @override
  Future<Sale> update(int id, SaleDraft draft) async {
    final existing = _sales[id];
    if (existing == null) throw const SaleException(SaleException.notFound);
    final now = DateTime.now().toUtc();
    final updated = existing.copyWith(
      companyId: draft.companyId ?? existing.companyId,
      warehouseId: draft.warehouseId ?? existing.warehouseId,
      saleDate: draft.saleDate,
      settlementType: draft.settlementType,
      paidAmount: draft.paidAmount,
      updatedAt: now,
    );
    _sales[id] = updated;
    return updated;
  }

  @override
  Future<Sale> updateStatus(int id, SaleStatusUpdate update) async {
    final existing = _sales[id];
    if (existing == null) throw const SaleException(SaleException.notFound);
    final updated = existing.copyWith(
      saleStatus: update.saleStatus,
      submittedAt: update.submittedAt,
      clearSubmittedAt: update.clearSubmittedAt,
      confirmedAt: update.confirmedAt,
      clearConfirmedAt: update.clearConfirmedAt,
      completedAt: update.completedAt,
      clearCompletedAt: update.clearCompletedAt,
      cancelledAt: update.cancelledAt,
      clearCancelledAt: update.clearCancelledAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _sales[id] = updated;
    return updated;
  }

  @override
  Future<void> softDelete(int id) async {
    final existing = _sales[id];
    if (existing != null) {
      _sales[id] = existing.copyWith(deletedAt: DateTime.now().toUtc());
    }
  }

  @override
  Future<int> nextLocalSequence({int? minExclusive}) async {
    return _sequence++;
  }

  @override
  Future<CustomerSaleTotals> totalsForCustomer(String customerId) async {
    return const CustomerSaleTotals(
      totalSales: 0,
      paidAmount: 0,
      outstandingAmount: 0,
      saleCount: 0,
    );
  }

  @override
  Future<List<Sale>> listByAccountLink(String accountId) async => [];

  @override
  Future<SaleKeysetPagedResult<SaleListItem>> searchKeysetPaged(
    SaleListFilter filter, {
    SaleCursor? cursor,
    int pageSize = 30,
  }) async =>
      const SaleKeysetPagedResult(items: [], nextCursor: null, hasMore: false);

  @override
  Future<SalePagedResult<SaleListItem>> searchListPaged(
    SaleListFilter filter, {
    int page = 0,
    int pageSize = 30,
  }) async =>
      const SalePagedResult(items: [], page: 0, pageSize: 30, totalCount: 0);

  @override
  Future<List<SaleListItem>> listRecent({int limit = 20}) async => [];

  @override
  Stream<void> watchListChanges() async* {}
}

void main() {
  group(
    'SA-03 — Sales Lines, Pricing, Discounts & Deterministic Totals Tests',
    () {
      const calculator = SaleCalculationService();
      const validator = SaleValidator();

      test('1. Normal price calculation without discount', () {
        const item = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Product 1',
          productCode: 'P01',
          mainQuantity: 2,
          unitPrice: 50.0,
          baseUnitPrice: 50.0,
        );

        final line = calculator.calculateLine(item);
        expect(line.subtotal, equals(100.0));
        expect(line.discountAmount, equals(0.0));
        expect(line.total, equals(100.0));
      });

      test('2. Zero discount handling (fixed 0 and percentage 0)', () {
        const itemFixed = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Product 1',
          productCode: 'P01',
          mainQuantity: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.fixed,
          discountValue: 0.0,
        );

        const itemPercent = SaleItemDraft(
          productId: 'prod_02',
          productName: 'Product 2',
          productCode: 'P02',
          mainQuantity: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.percentage,
          discountValue: 0.0,
        );

        expect(calculator.calculateLine(itemFixed).discountAmount, equals(0.0));
        expect(
          calculator.calculateLine(itemPercent).discountAmount,
          equals(0.0),
        );
      });

      test('3. Percentage discount calculation (15% discount)', () {
        const item = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Product 1',
          productCode: 'P01',
          mainQuantity: 1,
          unitPrice: 200.0,
          baseUnitPrice: 200.0,
          discountType: DiscountType.percentage,
          discountValue: 15.0,
        );

        final line = calculator.calculateLine(item);
        expect(line.subtotal, equals(200.0));
        expect(line.discountAmount, equals(30.0));
        expect(line.total, equals(170.0));
      });

      test('4. Fixed amount discount calculation', () {
        const item = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Product 1',
          productCode: 'P01',
          mainQuantity: 1,
          unitPrice: 150.0,
          baseUnitPrice: 150.0,
          discountType: DiscountType.fixed,
          discountValue: 25.0,
        );

        final line = calculator.calculateLine(item);
        expect(line.subtotal, equals(150.0));
        expect(line.discountAmount, equals(25.0));
        expect(line.total, equals(125.0));
      });

      test('5. 100% discount producing zero net line total', () {
        const item100Percent = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Free Product',
          productCode: 'P01',
          mainQuantity: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.percentage,
          discountValue: 100.0,
        );

        const itemFixedOver = SaleItemDraft(
          productId: 'prod_02',
          productName: 'Capped Product',
          productCode: 'P02',
          mainQuantity: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.fixed,
          discountValue: 150.0, // Exceeds subtotal
        );

        final line1 = calculator.calculateLine(item100Percent);
        expect(line1.discountAmount, equals(100.0));
        expect(line1.total, equals(0.0));

        final line2 = calculator.calculateLine(itemFixedOver);
        expect(line2.discountAmount, equals(100.0)); // Capped at subtotal
        expect(line2.total, equals(0.0));
      });

      test('6. Invalid discount validation rejection (>100% or <0%)', () {
        const itemInvalidPercent = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Product 1',
          productCode: 'P01',
          mainQuantity: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.percentage,
          discountValue: 105.0, // Invalid > 100%
        );

        const itemNegativeDiscount = SaleItemDraft(
          productId: 'prod_02',
          productName: 'Product 2',
          productCode: 'P02',
          mainQuantity: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.fixed,
          discountValue: -10.0, // Invalid negative
        );

        expect(
          () => validator.validateItem(itemInvalidPercent),
          throwsA(
            isA<SaleException>().having(
              (e) => e.code,
              'code',
              SaleException.invalidDiscount,
            ),
          ),
        );

        expect(
          () => validator.validateItem(itemNegativeDiscount),
          throwsA(
            isA<SaleException>().having(
              (e) => e.code,
              'code',
              SaleException.invalidDiscount,
            ),
          ),
        );
      });

      test(
        '7. Fractional quantities & prices with exact 2-decimal rounding',
        () {
          const item = SaleItemDraft(
            productId: 'prod_01',
            productName: 'Bulk Item',
            productCode: 'BULK',
            mainQuantity: 2.33,
            unitPrice: 17.85,
            baseUnitPrice: 17.85,
          );

          final line = calculator.calculateLine(item);
          // 2.33 * 17.85 = 41.5905 -> rounded to 2 decimals = 41.59
          expect(line.subtotal, equals(41.59));
          expect(line.total, equals(41.59));
        },
      );

      test('8. Multiple lines & duplicate products aggregation', () {
        const item1 = SaleItemDraft(
          productId: 'prod_A',
          productName: 'Product A - Line 1',
          productCode: 'PA',
          mainQuantity: 2,
          unitPrice: 50.0,
          baseUnitPrice: 50.0,
        );

        const item2 = SaleItemDraft(
          productId: 'prod_A',
          productName: 'Product A - Line 2',
          productCode: 'PA',
          mainQuantity: 3,
          unitPrice: 50.0,
          baseUnitPrice: 50.0,
          discountType: DiscountType.fixed,
          discountValue: 10.0,
        );

        final summary = calculator.calculate(items: const [item1, item2]);
        // Line 1 subtotal: 100, disc: 0 -> total: 100
        // Line 2 subtotal: 150, disc: 10 -> total: 140
        expect(summary.subtotal, equals(250.0));
        expect(summary.itemDiscountTotal, equals(10.0));
        expect(summary.total, equals(240.0));
      });

      test('9. Document-level discount combined with item-level discounts', () {
        const item1 = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Product 1',
          productCode: 'P01',
          mainQuantity: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.fixed,
          discountValue: 10.0, // Line subtotal 100 - 10 = 90
        );

        const item2 = SaleItemDraft(
          productId: 'prod_02',
          productName: 'Product 2',
          productCode: 'P02',
          mainQuantity: 1,
          unitPrice: 120.0,
          baseUnitPrice: 120.0,
          discountType: DiscountType.fixed,
          discountValue: 10.0, // Line subtotal 120 - 10 = 110
        );

        // Subtotal = 220, itemDiscountTotal = 20, afterItems = 200
        // Document 10% discount on 200 = 20
        final summary = calculator.calculate(
          items: const [item1, item2],
          saleDiscountType: DiscountType.percentage,
          saleDiscountValue: 10.0,
        );

        expect(summary.subtotal, equals(220.0));
        expect(summary.itemDiscountTotal, equals(20.0));
        expect(summary.saleDiscount, equals(20.0));
        expect(summary.total, equals(180.0));
      });

      test('10. Tax calculation on post-discount net amount', () {
        const item = SaleItemDraft(
          productId: 'prod_01',
          productName: 'Product 1',
          productCode: 'P01',
          mainQuantity: 1,
          unitPrice: 200.0,
          baseUnitPrice: 200.0,
          discountType: DiscountType.fixed,
          discountValue: 20.0, // Net line = 180
        );

        // Tax rate = 15% on 180 net = 27.0 -> grand total = 207.0
        final summary = calculator.calculate(
          items: const [item],
          taxRatePercent: 15.0,
        );

        expect(summary.subtotal, equals(200.0));
        expect(summary.itemDiscountTotal, equals(20.0));
        expect(summary.tax, equals(27.0));
        expect(summary.total, equals(207.0));
      });

      test('11. Non-negative clamping & rounding guarantees', () {
        expect(SaleMoney.round(12.3456), equals(12.35));
        expect(SaleMoney.round(12.3444), equals(12.34));
        expect(SaleMoney.clampNonNegative(-5.50), equals(0.0));
        expect(SaleMoney.toCents(10.50), equals(1050));
        expect(SaleMoney.fromCents(1050), equals(10.50));
      });

      test('12. Immutable posted values snapshot verification', () async {
        final repository = InMemorySaleRepository();

        final draft = SaleDraft(
          companyId: 'company_A',
          warehouseId: 'wh_01',
          voucherBookId: 'vb_01',
          cashAccountId: 'acc_cash_01',
          saleDate: DateTime.now(),
          settlementType: SaleSettlementType.cash,
          currencyCode: 'SAR',
          baseCurrencyCode: 'SAR',
          exchangeRate: 1.0,
          paidAmount: 100,
          items: const [
            SaleItemDraft(
              productId: 'prod_01',
              productName: 'Product 01',
              productCode: 'P01',
              mainQuantity: 1,
              unitPrice: 100,
              baseUnitPrice: 100,
              discountType: DiscountType.fixed,
              discountValue: 10,
            ),
          ],
        );

        final sale = await repository.insert(draft, saleNumber: 'INV-1001');

        expect(sale.items.first.subtotal, equals(100.0));
        expect(sale.items.first.discountAmount, equals(10.0));
        expect(sale.items.first.total, equals(90.0));
        expect(sale.subtotal, equals(100.0));
        expect(sale.itemDiscountTotal, equals(10.0));

        // Retrieve sale later
        final fetched = await repository.getById(sale.id);
        expect(fetched!.items.first.unitPrice, equals(100.0));
        expect(fetched.items.first.total, equals(90.0));
      });
    },
  );
}
