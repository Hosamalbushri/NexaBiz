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
import 'package:stock_count/modules/sales/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/domain/repositories/sale_repository.dart';
import 'package:stock_count/modules/sales/domain/services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/domain/services/sale_currency_converter.dart';
import 'package:stock_count/modules/sales/domain/services/sale_inventory_effect_port.dart';
import 'package:stock_count/modules/sales/domain/services/sale_money.dart';
import 'package:stock_count/modules/sales/domain/services/sale_number_allocator_port.dart';
import 'package:stock_count/modules/sales/domain/services/sale_validator.dart';
import 'package:stock_count/modules/sales/domain/services/sale_voucher_book_port.dart';
import 'package:stock_count/modules/sales/domain/services/sale_workflow_service.dart';
import 'package:stock_count/modules/sales/domain/usecases/sale_usecases.dart';

SaleDraft _cashDraft({
  required List<SaleItemDraft> items,
  String voucherBookId = 'book-1',
  double paidAmount = 0,
  String? customerId,
  String? customerAccountId,
  String cashAccountId = 'cash-1',
  SaleSettlementType settlement = SaleSettlementType.cash,
  double exchangeRate = 1,
  String currencyCode = 'SAR',
}) {
  return SaleDraft(
    saleDate: DateTime.utc(2026, 8, 13),
    settlementType: settlement,
    voucherBookId: voucherBookId,
    customerId: customerId,
    customerAccountId: customerAccountId,
    cashAccountId: settlement.isCash ? cashAccountId : null,
    currencyCode: currencyCode,
    baseCurrencyCode: 'SAR',
    exchangeRate: exchangeRate,
    items: items,
    paidAmount: paidAmount,
    paymentMethod: settlement.isCredit
        ? PaymentMethod.credit
        : PaymentMethod.cash,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  group('SaleCurrencyConverter', () {
    const converter = SaleCurrencyConverter();

    test('converts base product price to foreign currency', () {
      // Product priced 375 SAR, USD rate 3.75 → 100 USD
      expect(converter.baseToSale(375, 3.75), 100);
      expect(converter.saleToBase(100, 3.75), 375);
    });

    test('base currency rate 1 keeps price', () {
      expect(converter.baseToSale(1500, 1), 1500);
    });
  });

  group('SaleMoney / SaleCalculationService', () {
    const calc = SaleCalculationService();

    test('calculates line totals with fixed discount', () {
      final line = calc.calculateLine(
        const SaleItemDraft(
          productId: 'p1',
          productName: 'A',
          productCode: 'SKU-A',
          mainQuantity: 2,
          unitPrice: 1500,
          baseUnitPrice: 1500,
          discountType: DiscountType.fixed,
          discountValue: 100,
        ),
      );
      expect(line.subtotal, 3000);
      expect(line.discountAmount, 100);
      expect(line.total, 2900);
    });

    test('sale-level discount, tax, paid, remaining, payment status', () {
      final summary = calc.calculate(
        items: const [
          SaleItemDraft(
            productId: 'p1',
            productName: 'A',
            productCode: 'SKU-A',
            mainQuantity: 2,
            unitPrice: 1500,
            baseUnitPrice: 1500,
          ),
          SaleItemDraft(
            productId: 'p2',
            productName: 'B',
            productCode: 'SKU-B',
            mainQuantity: 1,
            unitPrice: 2500,
            baseUnitPrice: 2500,
          ),
        ],
        saleDiscountType: DiscountType.fixed,
        saleDiscountValue: 500,
        taxRatePercent: 5,
        paidAmount: 3000,
      );

      expect(summary.subtotal, 5500);
      expect(summary.saleDiscount, 500);
      expect(summary.tax, 250);
      expect(summary.total, 5250);
      expect(summary.paymentStatus, PaymentStatus.partiallyPaid);
    });

    test('keeps duplicate products as separate lines', () {
      const a = SaleItemDraft(
        productId: 'p1',
        productName: 'A',
        productCode: 'SKU-A',
        mainQuantity: 1,
        unitPrice: 10,
        baseUnitPrice: 10,
      );
      const b = SaleItemDraft(
        productId: 'p1',
        productName: 'A',
        productCode: 'SKU-A',
        mainQuantity: 2,
        unitPrice: 10,
        baseUnitPrice: 10,
      );
      final summary = calc.calculate(items: const [a, b], paidAmount: 30);
      expect(summary.subtotal, 30);
      expect([a, b], hasLength(2));
    });

    test('clamps invalid discount overflow', () {
      expect(SaleMoney.clampNonNegative(-5), 0);
    });
  });

  group('SaleValidator', () {
    const validator = SaleValidator();

    test('requires voucher book and cash account for cash sales', () {
      expect(
        () => validator.validate(
          _cashDraft(
            items: const [
              SaleItemDraft(
                productId: 'p',
                productName: 'P',
                productCode: 'P',
                mainQuantity: 1,
                unitPrice: 1,
                baseUnitPrice: 1,
              ),
            ],
            voucherBookId: '',
          ),
        ),
        throwsA(
          isA<SaleException>().having(
            (e) => e.code,
            'code',
            SaleException.voucherBookRequired,
          ),
        ),
      );
    });

    test('credit requires customer account', () {
      expect(
        () => validator.validate(
          _cashDraft(
            settlement: SaleSettlementType.credit,
            customerId: 'c1',
            customerAccountId: null,
            cashAccountId: '',
            items: const [
              SaleItemDraft(
                productId: 'p',
                productName: 'P',
                productCode: 'P',
                mainQuantity: 1,
                unitPrice: 1,
                baseUnitPrice: 1,
              ),
            ],
          ),
        ),
        throwsA(
          isA<SaleException>().having(
            (e) => e.code,
            'code',
            SaleException.customerAccountRequired,
          ),
        ),
      );
    });

    test('rejects unit price below catalog default', () {
      expect(
        () => validator.validateItem(
          const SaleItemDraft(
            productId: 'p',
            productName: 'P',
            productCode: 'P',
            mainQuantity: 1,
            unitPrice: 9,
            baseUnitPrice: 10,
          ),
        ),
        throwsA(
          isA<SaleException>().having(
            (e) => e.code,
            'code',
            SaleException.priceBelowCatalog,
          ),
        ),
      );
    });

    test('allows unit price above catalog default', () {
      expect(
        () => validator.validateItem(
          const SaleItemDraft(
            productId: 'p',
            productName: 'P',
            productCode: 'P',
            mainQuantity: 1,
            unitPrice: 12,
            baseUnitPrice: 10,
          ),
        ),
        returnsNormally,
      );
    });
  });

  group('SaleRepository offline create', () {
    late SalesDatabase db;
    late SaleRepositoryImpl repository;
    late Directory tempDir;
    late Box<SyncOperation> syncBox;
    late SyncQueue syncQueue;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sales_mod_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      syncBox = await Hive.openBox<SyncOperation>('sync_queue');
      syncQueue = SyncQueue(box: syncBox);
      db = SalesDatabase.memory();
      repository = SaleRepositoryImpl(db, syncQueue: syncQueue);
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('creates cash sale with book number and currency snapshot', () async {
      final create = CreateSale(
        repository: repository,
        numberAllocator: LocalSaleNumberAllocator(
          nextSequence: repository.nextLocalSequence,
        ),
        voucherBookPort: _FakeVoucherBookPort(),
      );

      final sale = await create(
        _cashDraft(
          customerId: 'cust-uuid',
          paidAmount: 2000,
          items: const [
            SaleItemDraft(
              productId: 'prod-uuid',
              productName: 'Product A',
              productCode: 'SKU-A',
              mainQuantity: 2,
              unitPrice: 1500,
              baseUnitPrice: 1500,
            ),
          ],
        ).copyWithDiscount(100),
      );

      expect(sale.saleNumber, '42');
      expect(sale.settlementType, SaleSettlementType.cash);
      expect(sale.cashAccountId, 'cash-1');
      expect(sale.currencyCode, 'SAR');
      expect(sale.exchangeRate, 1);
      expect(sale.items.first.baseUnitPrice, 1500);
      expect(sale.syncStatus, SyncStatus.pending);
      expect(await syncQueue.countByStatus(SyncStatus.pending), greaterThan(0));
    });

    test('cancels a confirmed sale', () async {
      final create = CreateSale(
        repository: repository,
        numberAllocator: LocalSaleNumberAllocator(
          nextSequence: repository.nextLocalSequence,
        ),
        voucherBookPort: _FakeVoucherBookPort(),
      );
      final sale = await create(
        _cashDraft(
          paidAmount: 10,
          items: const [
            SaleItemDraft(
              productId: 'p',
              productName: 'P',
              productCode: 'P',
              mainQuantity: 1,
              unitPrice: 10,
              baseUnitPrice: 10,
            ),
          ],
        ),
      );

      await repository.updateStatus(
        sale.id,
        const SaleStatusUpdate(saleStatus: SaleStatus.confirmed),
      );
      final cancel = CancelSale(
        repository: repository,
        inventoryEffect: const NoOpSaleInventoryEffectPort(),
      );
      final cancelled = await cancel(sale.id);
      expect(cancelled.saleStatus, SaleStatus.cancelled);
    });
  });

  group('workflow', () {
    const workflow = SaleWorkflowService();
    test('confirm goes pending in integrated mode', () {
      expect(workflow.nextOnConfirm(integratedMode: true), SaleStatus.pending);
      expect(
        workflow.nextOnConfirm(integratedMode: false),
        SaleStatus.confirmed,
      );
    });
  });
}

class _FakeVoucherBookPort implements SaleVoucherBookPort {
  @override
  Future<String> allocateSaleNumber(String bookId) async => '42';

  @override
  Future<SaleVoucherBookRef?> findById(String bookId) async {
    return SaleVoucherBookRef(
      bookId: bookId,
      name: 'Main',
      nextNumber: 42,
      canAllocate: true,
    );
  }

  @override
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks() async {
    return [
      const SaleVoucherBookRef(
        bookId: 'book-1',
        name: 'Main',
        nextNumber: 42,
        canAllocate: true,
      ),
    ];
  }
}

extension on SaleDraft {
  SaleDraft copyWithDiscount(double value) {
    return SaleDraft(
      saleDate: saleDate,
      settlementType: settlementType,
      voucherBookId: voucherBookId,
      customerId: customerId,
      customerCode: customerCode,
      customerName: customerName,
      customerAccountId: customerAccountId,
      cashAccountId: cashAccountId,
      currencyCode: currencyCode,
      baseCurrencyCode: baseCurrencyCode,
      exchangeRate: exchangeRate,
      items: items,
      discountType: DiscountType.fixed,
      discountValue: value,
      taxRate: taxRate,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      notes: notes,
      saleStatus: saleStatus,
      dataSource: dataSource,
      externalId: externalId,
      externalDocumentNumber: externalDocumentNumber,
      externalStatus: externalStatus,
      payments: payments,
    );
  }
}
