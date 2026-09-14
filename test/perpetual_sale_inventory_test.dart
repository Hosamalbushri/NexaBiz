import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/sales/perpetual_sale_inventory_effect_adapter.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/products/domain/models/product_exception.dart';
import 'package:stock_count/modules/inventory/stock_count/domain/models/stock_quantity_line.dart';
import 'package:stock_count/modules/inventory/stock_count/domain/services/product_stock_service.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';

Sale _sale({
  required String productId,
  required double quantity,
  SaleStatus status = SaleStatus.posted,
}) {
  final now = DateTime.utc(2026, 1, 15);
  return Sale(
    id: 'sale-1',
    saleNumber: 'S-1',
    saleDate: now,
    settlementType: SaleSettlementType.cash,
    currencyCode: 'USD',
    baseCurrencyCode: 'USD',
    exchangeRate: 1,
    items: [
      SaleItem(
        id: 'line-1',
        saleUuid: 'sale-1',
        productId: productId,
        productName: 'Widget',
        productCode: 'W1',
        quantity: quantity,
        mainQuantity: quantity,
        subQuantity: 0,
        packSize: 1,
        unitPrice: 10,
        baseUnitPrice: 10,
        discountType: DiscountType.fixed,
        discountValue: 0,
        discountAmount: 0,
        taxAmount: 0,
        subtotal: 10,
        total: 10,
        lineOrder: 0,
      ),
    ],
    payments: const [],
    subtotal: 10,
    itemDiscountTotal: 0,
    discountType: DiscountType.fixed,
    discountValue: 0,
    discountAmount: 0,
    taxRate: 0,
    taxAmount: 0,
    total: 10,
    paidAmount: 10,
    remainingAmount: 0,
    paymentMethod: PaymentMethod.cash,
    paymentStatus: PaymentStatus.paid,
    saleStatus: status,
    dataSource: SaleDataSource.local,
    createdAt: now,
    updatedAt: now,
    confirmedAt: status.isPosted ? now : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductStockService', () {
    late NexabizDatabase db;
    late ProductRepositoryImpl products;
    late ProductStockService stock;

    setUp(() {
      db = NexabizDatabase.memory();
      products = ProductRepositoryImpl(db);
      stock = ProductStockService(products);
    });

    tearDown(() async {
      await db.close();
    });

    test('issueLines reduces on-hand qty', () async {
      final product = await products.insert(
        const ProductDraft(
          itemCode: 'W1',
          name: 'Widget',
          packSize: 1,
          price: 10,
          unitCost: 4,
        ),
      );
      await products.adjustOnHandByUuid(uuid: product.id, delta: 5);

      await stock.issueLines([
        StockQuantityLine(productId: product.id, quantity: 2),
      ]);

      final reloaded = await products.getByUuid(product.id);
      expect(reloaded?.onHandQty, 3);
    });

    test('adjustOnHandByUuid rejects negative balance', () async {
      final product = await products.insert(
        const ProductDraft(
          itemCode: 'W2',
          name: 'Widget',
          packSize: 1,
          price: 10,
        ),
      );

      await expectLater(
        products.adjustOnHandByUuid(uuid: product.id, delta: -1),
        throwsA(
          isA<ProductException>().having(
            (e) => e.code,
            'code',
            ProductException.insufficientStock,
          ),
        ),
      );
    });
  });

  group('PerpetualSaleInventoryEffectAdapter', () {
    late NexabizDatabase db;
    late ProductRepositoryImpl products;
    late ProductStockService stock;

    setUp(() {
      db = NexabizDatabase.memory();
      products = ProductRepositoryImpl(db);
      stock = ProductStockService(products);
    });

    tearDown(() async {
      await db.close();
    });

    test('unlocks sale posting gate', () {
      final adapter = PerpetualSaleInventoryEffectAdapter(
        stock: stock,
        cogs: _NoOpCogs(),
      );
      expect(isSalePostingEnabled(adapter), isTrue);
    });

    test('onConfirmed issues stock and onCancelled restores it', () async {
      final product = await products.insert(
        const ProductDraft(
          itemCode: 'W3',
          name: 'Widget',
          packSize: 1,
          price: 10,
          unitCost: 3,
        ),
      );
      await products.adjustOnHandByUuid(uuid: product.id, delta: 10);

      final adapter = PerpetualSaleInventoryEffectAdapter(
        stock: stock,
        cogs: _NoOpCogs(),
      );
      final sale = _sale(productId: product.id, quantity: 4);

      await adapter.onConfirmed(sale);
      expect((await products.getByUuid(product.id))?.onHandQty, 6);

      await adapter.onCancelled(sale);
      expect((await products.getByUuid(product.id))?.onHandQty, 10);
    });

    test('maps insufficient stock to SaleException', () async {
      final product = await products.insert(
        const ProductDraft(
          itemCode: 'W4',
          name: 'Widget',
          packSize: 1,
          price: 10,
        ),
      );
      await products.adjustOnHandByUuid(uuid: product.id, delta: 1);

      final adapter = PerpetualSaleInventoryEffectAdapter(
        stock: stock,
        cogs: _NoOpCogs(),
      );

      await expectLater(
        adapter.onConfirmed(_sale(productId: product.id, quantity: 5)),
        throwsA(
          isA<SaleException>().having(
            (e) => e.code,
            'code',
            SaleException.insufficientStock,
          ),
        ),
      );
    });
  });
}

class _NoOpCogs implements SaleCogsEffectPort {
  @override
  Future<void> syncSale(Sale sale) async {}

  @override
  Future<void> voidSale(Sale sale) async {}
}
