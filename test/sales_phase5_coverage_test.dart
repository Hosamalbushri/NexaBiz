import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/modules/sales/data/database/sales_database.dart';
import 'package:stock_count/modules/sales/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/modules/sales/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/domain/models/sale_list_filter.dart';
import 'package:stock_count/modules/sales/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sales/domain/services/sale_accounting_bridge_port.dart';
import 'package:stock_count/modules/sales/domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/domain/services/sale_inventory_effect_port.dart';
import 'package:stock_count/modules/sales/domain/services/sale_number_allocator_port.dart';
import 'package:stock_count/modules/sales/domain/services/sale_product_catalog_port.dart';
import 'package:stock_count/modules/sales/domain/services/sale_voucher_book_port.dart';
import 'package:stock_count/modules/sales/domain/usecases/sale_usecases.dart';
import 'package:stock_count/modules/sales/presentation/providers/sale_composer_provider.dart';

SaleDraft _draft({
  required List<SaleItemDraft> items,
  String? customerId,
  String? customerName,
  double paidAmount = 0,
  SaleSettlementType settlement = SaleSettlementType.cash,
}) {
  return SaleDraft(
    saleDate: DateTime.utc(2026, 8, 13),
    settlementType: settlement,
    voucherBookId: 'book-1',
    customerId: customerId,
    customerName: customerName,
    customerAccountId: settlement.isCredit ? 'cust-acc' : null,
    cashAccountId: settlement.isCash ? 'cash-1' : null,
    currencyCode: 'SAR',
    baseCurrencyCode: 'SAR',
    exchangeRate: 1,
    items: items,
    paidAmount: paidAmount,
    paymentMethod: settlement.isCredit
        ? PaymentMethod.credit
        : PaymentMethod.cash,
  );
}

Sale _percentDiscountSale() {
  final now = DateTime.utc(2026, 8, 13, 12);
  return Sale(
    id: 1,
    uuid: 'sale-uuid-1',
    saleNumber: 'INV-100',
    saleDate: DateTime.utc(2026, 8, 10),
    settlementType: SaleSettlementType.credit,
    voucherBookId: 'book-1',
    customerId: 'cust-1',
    customerName: 'Acme Co',
    customerAccountId: 'acc-1',
    currencyCode: 'SAR',
    baseCurrencyCode: 'SAR',
    exchangeRate: 1,
    items: const [
      SaleItem(
        id: 1,
        uuid: 'item-1',
        saleUuid: 'sale-uuid-1',
        productId: 'p1',
        productName: 'Widget',
        productCode: 'W-1',
        quantity: 2,
        mainQuantity: 2,
        subQuantity: 0,
        packSize: 1,
        unitPrice: 100,
        baseUnitPrice: 100,
        discountType: DiscountType.fixed,
        discountValue: 0,
        discountAmount: 0,
        taxAmount: 0,
        subtotal: 200,
        total: 200,
        lineOrder: 0,
      ),
    ],
    payments: const [],
    subtotal: 200,
    itemDiscountTotal: 0,
    discountType: DiscountType.percentage,
    discountValue: 10,
    discountAmount: 20,
    taxRate: 15,
    taxAmount: 27,
    total: 207,
    paidAmount: 0,
    remainingAmount: 207,
    paymentStatus: PaymentStatus.unpaid,
    paymentMethod: PaymentMethod.credit,
    saleStatus: SaleStatus.unposted,
    dataSource: SaleDataSource.local,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeVoucherBookPort implements SaleVoucherBookPort {
  var _seq = 41;

  @override
  Future<String> allocateSaleNumber(String bookId) async {
    _seq += 1;
    return '$_seq';
  }

  @override
  Future<SaleVoucherBookRef?> findById(String bookId) async {
    return SaleVoucherBookRef(
      bookId: bookId,
      name: 'Main',
      nextNumber: _seq + 1,
      canAllocate: true,
    );
  }

  @override
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks() async {
    return [
      SaleVoucherBookRef(
        bookId: 'book-1',
        name: 'Main',
        nextNumber: _seq + 1,
        canAllocate: true,
      ),
    ];
  }
}

class _RecordingAccounting implements SaleAccountingBridgePort {
  int submitCalls = 0;
  Sale? lastSale;

  @override
  Future<bool> get isIntegratedMode async => true;

  @override
  Future<void> submitOperationalSale(Sale sale) async {
    submitCalls++;
    lastSale = sale;
  }

  @override
  Future<void> attachExternalReference({
    required String saleUuid,
    required String externalId,
    String? externalDocumentNumber,
    String? externalStatus,
  }) async {}
}

class _RecordingInventory implements SaleInventoryEffectPort {
  int confirmCalls = 0;

  @override
  Future<void> onConfirmed(Sale sale) async {
    confirmCalls++;
  }

  @override
  Future<void> onCancelled(Sale sale) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  group('SaleComposerController', () {
    late SaleComposerController composer;

    setUp(() {
      composer = SaleComposerController(
        calculator: const SaleCalculationService(),
        catalog: const NoOpSaleProductCatalogPort(),
        baseCurrencyCode: 'SAR',
      );
    });

    tearDown(() => composer.dispose());

    test('loadFromSale keeps percentage discount type and value', () {
      composer.loadFromSale(_percentDiscountSale());

      expect(composer.state.discountType, DiscountType.percentage);
      expect(composer.state.discountValue, 10);
      expect(composer.state.taxRate, 15);
      expect(composer.state.customer?.customerId, 'cust-1');
      expect(composer.state.items, hasLength(1));
      expect(composer.state.items.single.productCode, 'W-1');
    });

    test('setDiscount preserves type when value changes', () {
      composer.setDiscount(type: DiscountType.percentage, value: 12);
      expect(composer.state.discountType, DiscountType.percentage);
      expect(composer.state.discountValue, 12);

      composer.setDiscount(type: DiscountType.percentage, value: 5);
      expect(composer.state.discountType, DiscountType.percentage);
      expect(composer.state.discountValue, 5);

      composer.setDiscount(type: DiscountType.fixed, value: 20);
      expect(composer.state.discountType, DiscountType.fixed);
      expect(composer.state.discountValue, 20);
    });

    test('cash summary treats invoice as fully paid', () {
      composer.addProduct(
        const SaleProductRef(
          productId: 'p1',
          itemCode: 'SKU',
          name: 'Item',
          unitPrice: 50,
        ),
        mainQuantity: 2,
      );
      expect(composer.summary.total, 100);
      expect(composer.summary.paidAmount, 100);
      expect(composer.summary.remainingAmount, 0);
      expect(composer.buildDraft().paidAmount, 100);
    });
  });

  group('ConfirmSale success path + repository SQL helpers', () {
    late Directory tempDir;
    late SalesDatabase db;
    late SaleRepositoryImpl repository;
    late SyncQueue syncQueue;
    late _FakeVoucherBookPort voucherBooks;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sales_p5_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
      syncQueue = SyncQueue(box: syncBox);
      db = SalesDatabase.memory();
      repository = SaleRepositoryImpl(db, syncQueue: syncQueue);
      voucherBooks = _FakeVoucherBookPort();
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<Sale> createSale(SaleDraft draft) {
      return CreateSale(
        repository: repository,
        numberAllocator: LocalSaleNumberAllocator(
          nextSequence: repository.nextLocalSequence,
        ),
        voucherBookPort: voucherBooks,
      )(draft);
    }

    test('post submits accounting then inventory in integrated mode', () async {
      final accounting = _RecordingAccounting();
      final inventory = _RecordingInventory();
      final sale = await createSale(
        _draft(
          paidAmount: 40,
          items: const [
            SaleItemDraft(
              productId: 'p',
              productName: 'P',
              productCode: 'P',
              mainQuantity: 2,
              unitPrice: 20,
              baseUnitPrice: 20,
            ),
          ],
        ),
      );

      final posted = await ConfirmSale(
        repository: repository,
        accountingBridge: accounting,
        inventoryEffect: inventory,
      )(sale.id);

      expect(accounting.submitCalls, 1);
      expect(accounting.lastSale?.uuid, sale.uuid);
      expect(inventory.confirmCalls, 1);
      expect(posted.saleStatus, SaleStatus.posted);
      expect(posted.confirmedAt, isNotNull);
      expect(posted.submittedAt, isNotNull);
      expect(posted.syncStatus, SyncStatus.pending);
    });

    test('searchListPaged matches sale number and customer name in SQL', () async {
      await createSale(
        _draft(
          customerId: 'c-alpha',
          customerName: 'Alpha Trading',
          paidAmount: 10,
          items: const [
            SaleItemDraft(
              productId: 'p1',
              productName: 'Nail',
              productCode: 'N-1',
              mainQuantity: 1,
              unitPrice: 10,
              baseUnitPrice: 10,
            ),
          ],
        ),
      );
      await createSale(
        _draft(
          customerId: 'c-beta',
          customerName: 'Beta Motors',
          paidAmount: 15,
          items: const [
            SaleItemDraft(
              productId: 'p2',
              productName: 'Bolt',
              productCode: 'B-1',
              mainQuantity: 1,
              unitPrice: 15,
              baseUnitPrice: 15,
            ),
          ],
        ),
      );

      final byCustomer = await repository.searchListPaged(
        const SaleListFilter(query: 'alpha'),
        page: 0,
        pageSize: 10,
      );
      expect(byCustomer.totalCount, 1);
      expect(byCustomer.items.single.customerName, 'Alpha Trading');

      final saleNumber = byCustomer.items.single.saleNumber;
      final byNumber = await repository.searchListPaged(
        SaleListFilter(query: saleNumber),
        page: 0,
        pageSize: 10,
      );
      expect(byNumber.totalCount, 1);
      expect(byNumber.items.single.saleNumber, saleNumber);
    });

    test('totalsForCustomer aggregates and excludes soft-deleted', () async {
      final s1 = await createSale(
        _draft(
          customerId: 'cust-t',
          customerName: 'Totals Cust',
          paidAmount: 100,
          items: const [
            SaleItemDraft(
              productId: 'p',
              productName: 'P',
              productCode: 'P',
              mainQuantity: 1,
              unitPrice: 100,
              baseUnitPrice: 100,
            ),
          ],
        ),
      );
      final s2 = await createSale(
        _draft(
          customerId: 'cust-t',
          customerName: 'Totals Cust',
          paidAmount: 50,
          items: const [
            SaleItemDraft(
              productId: 'p',
              productName: 'P',
              productCode: 'P',
              mainQuantity: 1,
              unitPrice: 50,
              baseUnitPrice: 50,
            ),
          ],
        ),
      );
      await createSale(
        _draft(
          customerId: 'other',
          customerName: 'Other',
          paidAmount: 999,
          items: const [
            SaleItemDraft(
              productId: 'p',
              productName: 'P',
              productCode: 'P',
              mainQuantity: 1,
              unitPrice: 999,
              baseUnitPrice: 999,
            ),
          ],
        ),
      );

      await ConfirmSale(
        repository: repository,
        accountingBridge: const NoOpSaleAccountingBridgePort(),
        inventoryEffect: _RecordingInventory(),
      )(s1.id);

      await ConfirmSale(
        repository: repository,
        accountingBridge: const NoOpSaleAccountingBridgePort(),
        inventoryEffect: _RecordingInventory(),
      )(s2.id);

      await CancelSale(
        repository: repository,
        inventoryEffect: const NoOpSaleInventoryEffectPort(),
      )(s2.id);

      final totals = await repository.totalsForCustomer('cust-t');
      expect(totals.saleCount, 1);
      expect(totals.totalSales, 100);
      expect(totals.paidAmount, 100);
      expect(totals.outstandingAmount, 0);
    });

    test('watchListChanges emits when a sale is inserted', () async {
      final events = <Object?>[];
      final sub = repository.watchListChanges().listen(events.add);

      await createSale(
        _draft(
          paidAmount: 5,
          items: const [
            SaleItemDraft(
              productId: 'p',
              productName: 'P',
              productCode: 'P',
              mainQuantity: 1,
              unitPrice: 5,
              baseUnitPrice: 5,
            ),
          ],
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(events, isNotEmpty);
      await sub.cancel();
    });
  });
}
