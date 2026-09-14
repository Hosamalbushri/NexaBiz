import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_list_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_keyset_paged_result.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_list_filter.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_paged_result.dart';
import 'package:stock_count/modules/sales/invoices/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/sale_validator.dart';
import 'package:stock_count/modules/sales/invoices/domain/usecases/sale_usecases.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_accounting_bridge_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_number_allocator_port.dart';
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
            discountAmount: 0,
            taxAmount: 0,
            subtotal: draft.items[i].quantity * draft.items[i].unitPrice,
            total: draft.items[i].quantity * draft.items[i].unitPrice,
            lineOrder: i,
          ),
      ],
      payments: [],
      subtotal: 100,
      itemDiscountTotal: 0,
      discountType: draft.discountType,
      discountValue: draft.discountValue,
      discountAmount: 0,
      taxRate: draft.taxRate,
      taxAmount: 0,
      total: 100,
      paidAmount: draft.paidAmount,
      remainingAmount: 100 - draft.paidAmount,
      paymentStatus: draft.paidAmount >= 100
          ? PaymentStatus.paid
          : PaymentStatus.unpaid,
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

class FakeNumberAllocator implements SaleNumberAllocatorPort {
  int seq = 100;
  @override
  Future<String> allocateNext() async => 'INV-${seq++}';
}

class FakeInventoryEffect implements SaleInventoryEffectPort {
  bool isEnabled = true;
  bool shouldFailOnPost = false;
  int confirmedCount = 0;
  int cancelledCount = 0;

  @override
  Future<void> onConfirmed(Sale sale) async {
    if (shouldFailOnPost) {
      throw const SaleException(
        SaleException.insufficientStock,
        'Stock unavailable',
      );
    }
    confirmedCount++;
  }

  @override
  Future<void> onCancelled(Sale sale) async {
    cancelledCount++;
  }
}

void main() {
  group('SA-02 — Sales Domain Lifecycle & Posting Integrity Tests', () {
    late InMemorySaleRepository repository;
    late FakeNumberAllocator numberAllocator;
    late FakeInventoryEffect inventoryEffect;
    late PermissionGuard permissionGuard;
    late FakeVoucherBookPort voucherBookPort;

    setUp(() {
      repository = InMemorySaleRepository();
      numberAllocator = FakeNumberAllocator();
      inventoryEffect = FakeInventoryEffect();
      permissionGuard = const AllowAllPermissionGuard();
      voucherBookPort = const FakeVoucherBookPort();
    });

    SaleDraft validDraft({
      String companyId = 'company_A',
      String warehouseId = 'wh_01',
      String voucherBookId = 'vb_01',
      String cashAccountId = 'acc_cash_01',
    }) {
      return SaleDraft(
        companyId: companyId,
        warehouseId: warehouseId,
        voucherBookId: voucherBookId,
        cashAccountId: cashAccountId,
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
          ),
        ],
      );
    }

    test(
      '1. Draft creation preserves complete identity including companyId and warehouseId',
      () async {
        final createSale = CreateSale(
          repository: repository,
          numberAllocator: numberAllocator,
          permissionGuard: permissionGuard,
          voucherBookPort: voucherBookPort,
        );

        final draft = validDraft();
        final sale = await createSale(draft);

        expect(sale.companyId, equals('company_A'));
        expect(sale.warehouseId, equals('wh_01'));
        expect(sale.saleStatus, equals(SaleStatus.unposted));
        expect(sale.saleNumber, equals('INV-9999'));
      },
    );

    test(
      '2. Missing warehouse explicitly BLOCKS validation and draft creation',
      () async {
        const validator = SaleValidator();
        final draftWithoutWarehouse = SaleDraft(
          companyId: 'company_A',
          warehouseId: null,
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
            ),
          ],
        );

        expect(
          () => validator.validate(draftWithoutWarehouse),
          throwsA(
            isA<SaleException>().having(
              (e) => e.code,
              'code',
              SaleException.warehouseRequired,
            ),
          ),
        );
      },
    );

    test(
      '3. Posting an unposted sale changes status to posted and triggers inventory effect',
      () async {
        final createSale = CreateSale(
          repository: repository,
          numberAllocator: numberAllocator,
          permissionGuard: permissionGuard,
          voucherBookPort: voucherBookPort,
        );
        final confirmSale = ConfirmSale(
          repository: repository,
          accountingBridge: const NoOpSaleAccountingBridgePort(),
          inventoryEffect: inventoryEffect,
          permissionGuard: permissionGuard,
        );

        final sale = await createSale(validDraft());
        expect(sale.saleStatus, equals(SaleStatus.unposted));

        final posted = await confirmSale(sale.id);
        expect(posted.saleStatus, equals(SaleStatus.posted));
        expect(posted.confirmedAt, isNotNull);
        expect(inventoryEffect.confirmedCount, equals(1));
      },
    );

    test(
      '4. Idempotency — Posting an already posted sale returns existing posted sale without re-posting side-effects',
      () async {
        final createSale = CreateSale(
          repository: repository,
          numberAllocator: numberAllocator,
          permissionGuard: permissionGuard,
          voucherBookPort: voucherBookPort,
        );
        final confirmSale = ConfirmSale(
          repository: repository,
          accountingBridge: const NoOpSaleAccountingBridgePort(),
          inventoryEffect: inventoryEffect,
          permissionGuard: permissionGuard,
        );

        final sale = await createSale(validDraft());
        final postedFirst = await confirmSale(sale.id);
        expect(postedFirst.saleStatus, equals(SaleStatus.posted));
        expect(inventoryEffect.confirmedCount, equals(1));

        // Second post call (idempotent retry)
        final postedSecond = await confirmSale(sale.id);
        expect(postedSecond.saleStatus, equals(SaleStatus.posted));
        expect(postedSecond.id, equals(postedFirst.id));
        // Confirmed count should still be 1 (no double side-effects)
        expect(inventoryEffect.confirmedCount, equals(1));
      },
    );

    test(
      '5. Posted document immutability — Editing a posted sale throws postedImmutable',
      () async {
        final createSale = CreateSale(
          repository: repository,
          numberAllocator: numberAllocator,
          permissionGuard: permissionGuard,
          voucherBookPort: voucherBookPort,
        );
        final confirmSale = ConfirmSale(
          repository: repository,
          accountingBridge: const NoOpSaleAccountingBridgePort(),
          inventoryEffect: inventoryEffect,
          permissionGuard: permissionGuard,
        );
        final updateSale = UpdateSale(repository: repository);

        final sale = await createSale(validDraft());
        await confirmSale(sale.id);

        expect(
          () async => updateSale(sale.id, validDraft()),
          throwsA(
            isA<SaleException>().having(
              (e) => e.code,
              'code',
              SaleException.postedImmutable,
            ),
          ),
        );
      },
    );

    test(
      '6. Atomic posting rollback — If inventory effect fails, sale remains unposted',
      () async {
        inventoryEffect.shouldFailOnPost = true;

        final createSale = CreateSale(
          repository: repository,
          numberAllocator: numberAllocator,
          permissionGuard: permissionGuard,
          voucherBookPort: voucherBookPort,
        );
        final confirmSale = ConfirmSale(
          repository: repository,
          accountingBridge: const NoOpSaleAccountingBridgePort(),
          inventoryEffect: inventoryEffect,
          permissionGuard: permissionGuard,
        );

        final sale = await createSale(validDraft());

        expect(
          () async => confirmSale(sale.id),
          throwsA(
            isA<SaleException>().having(
              (e) => e.code,
              'code',
              SaleException.insufficientStock,
            ),
          ),
        );

        final current = await repository.getById(sale.id);
        expect(current!.saleStatus, equals(SaleStatus.unposted));
        expect(current.confirmedAt, isNull);
      },
    );

    test(
      '7. Cancellation records cancelledAt timestamp and triggers inventory reversal',
      () async {
        final createSale = CreateSale(
          repository: repository,
          numberAllocator: numberAllocator,
          permissionGuard: permissionGuard,
          voucherBookPort: voucherBookPort,
        );
        final confirmSale = ConfirmSale(
          repository: repository,
          accountingBridge: const NoOpSaleAccountingBridgePort(),
          inventoryEffect: inventoryEffect,
          permissionGuard: permissionGuard,
        );
        final cancelSale = CancelSale(
          repository: repository,
          inventoryEffect: inventoryEffect,
          permissionGuard: permissionGuard,
        );

        final sale = await createSale(validDraft());
        final posted = await confirmSale(sale.id);

        await cancelSale(posted.id);

        final cancelled = await repository.getById(posted.id);
        expect(cancelled!.isDeleted, isTrue);
        expect(cancelled.cancelledAt, isNotNull);
        expect(inventoryEffect.cancelledCount, equals(1));
      },
    );
  });
}
