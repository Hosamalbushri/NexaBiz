import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/sales/perpetual_sale_inventory_effect_adapter.dart';
import 'package:stock_count/modules/inventory/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/domain/models/product_exception.dart';
import 'package:stock_count/modules/inventory/domain/models/stock_quantity_line.dart';
import 'package:stock_count/modules/inventory/domain/services/product_stock_service.dart';
import 'package:stock_count/modules/sales/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_data_source.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/domain/services/sale_inventory_effect_port.dart';

Sale _sale({
  required String productUuid,
  required double quantity,
  SaleStatus status = SaleStatus.posted,
}) {
  final now = DateTime.utc(2026, 1, 15);
  return Sale(
    id: 1,
    uuid: 'sale-1',
    saleNumber: 'S-1',
    saleDate: now,
    settlementType: SaleSettlementType.cash,
    currencyCode: 'USD',
    baseCurrencyCode: 'USD',
    exchangeRate: 1,
    items: [
      SaleItem(
        id: 1,
        uuid: 'line-1',
        saleUuid: 'sale-1',
        productId: productUuid,
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
    late InventoryDatabase db;
    late ProductRepositoryImpl products;
    late ProductStockService stock;

    setUp(() {
      db = InventoryDatabase.memory();
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
      await products.adjustOnHandByUuid(uuid: product.uuid, delta: 5);

      await stock.issueLines([
        StockQuantityLine(productUuid: product.uuid, quantity: 2),
      ]);

      final reloaded = await products.getByUuid(product.uuid);
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
        products.adjustOnHandByUuid(uuid: product.uuid, delta: -1),
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
    late InventoryDatabase db;
    late ProductRepositoryImpl products;
    late ProductStockService stock;

    setUp(() {
      db = InventoryDatabase.memory();
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
      await products.adjustOnHandByUuid(uuid: product.uuid, delta: 10);

      final adapter = PerpetualSaleInventoryEffectAdapter(
        stock: stock,
        cogs: _NoOpCogs(),
      );
      final sale = _sale(productUuid: product.uuid, quantity: 4);

      await adapter.onConfirmed(sale);
      expect((await products.getByUuid(product.uuid))?.onHandQty, 6);

      await adapter.onCancelled(sale);
      expect((await products.getByUuid(product.uuid))?.onHandQty, 10);
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
      await products.adjustOnHandByUuid(uuid: product.uuid, delta: 1);

      final adapter = PerpetualSaleInventoryEffectAdapter(
        stock: stock,
        cogs: _NoOpCogs(),
      );

      await expectLater(
        adapter.onConfirmed(_sale(productUuid: product.uuid, quantity: 5)),
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
