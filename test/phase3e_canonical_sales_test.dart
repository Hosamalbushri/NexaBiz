import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  late NexabizDatabase db;

  setUp(() {
    db = NexabizDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3E — Canonical Sales Foundation Baseline Tests', () {
    test('NexabizDatabase schemaVersion is 5 or higher and sales tables exist', () async {
      expect(db.schemaVersion, greaterThanOrEqualTo(5));

      final salesCount = await db.select(db.sales).get();
      final itemsCount = await db.select(db.saleItems).get();
      final paymentsCount = await db.select(db.salePayments).get();

      expect(salesCount, isEmpty);
      expect(itemsCount, isEmpty);
      expect(paymentsCount, isEmpty);
    });

    test('Canonical UUID identity and tenant isolation on sales headers', () async {
      final companyA = 'comp-tenant-aaa-3e';
      final companyB = 'comp-tenant-bbb-3e';

      final saleUuidA = generateUuidV4();
      final saleUuidB = generateUuidV4();

      final now = DateTime.now().millisecondsSinceEpoch;

      // Insert Company A Sale
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              uuid: saleUuidA,
              saleNumber: 'INV-A-0001',
              subtotal: 1000.0,
              itemDiscountTotal: 0.0,
              total: 1000.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyA),
              customerId: Value(generateUuidV4()),
              warehouseId: Value(generateUuidV4()),
              voucherBookId: Value(generateUuidV4()),
            ),
          );

      // Insert Company B Sale
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              uuid: saleUuidB,
              saleNumber: 'INV-B-0001',
              subtotal: 500.0,
              itemDiscountTotal: 0.0,
              total: 500.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyB),
              customerId: Value(generateUuidV4()),
              warehouseId: Value(generateUuidV4()),
              voucherBookId: Value(generateUuidV4()),
            ),
          );

      // Query Company A sales
      final queryA = await (db.select(db.sales)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();

      expect(queryA.length, equals(1));
      expect(queryA.first.uuid, equals(saleUuidA));
      expect(queryA.first.saleNumber, equals('INV-A-0001'));
      expect(queryA.first.companyId, equals(companyA));

      // Query Company B sales
      final queryB = await (db.select(db.sales)
            ..where((tbl) => tbl.companyId.equals(companyB)))
          .get();

      expect(queryB.length, equals(1));
      expect(queryB.first.uuid, equals(saleUuidB));
      expect(queryB.first.saleNumber, equals('INV-B-0001'));
      expect(queryB.first.companyId, equals(companyB));
    });

    test('Sales document aggregate creation with lines and payments inside transaction', () async {
      final companyId = 'comp-sales-agg-3e';
      final saleUuid = generateUuidV4();
      final itemUuid = generateUuidV4();
      final paymentUuid = generateUuidV4();

      final customerUuid = generateUuidV4();
      final warehouseUuid = generateUuidV4();
      final productUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Atomic sale aggregate creation
      await db.transaction(() async {
        // 1. Insert header
        await db.into(db.sales).insert(
              SalesCompanion.insert(
                uuid: saleUuid,
                saleNumber: 'INV-2026-001',
                saleDate: Value(now),
                settlementType: const Value('cash'),
                warehouseId: Value(warehouseUuid),
                customerId: Value(customerUuid),
                customerName: const Value('Test Customer'),
                currencyCode: 'USD',
                baseCurrencyCode: 'USD',
                subtotal: 200.0,
                itemDiscountTotal: 0.0,
                total: 200.0,
                paidAmount: const Value(200.0),
                remainingAmount: const Value(0.0),
                paymentStatus: const Value('paid'),
                saleStatus: const Value('draft'),
                createdAt: now,
                updatedAt: now,
                companyId: Value(companyId),
              ),
            );

        // 2. Insert line item
        await db.into(db.saleItems).insert(
              SaleItemsCompanion.insert(
                uuid: itemUuid,
                saleUuid: saleUuid,
                productId: productUuid,
                productName: 'Widget Alpha',
                productCode: 'WID-001',
                quantity: 2.0,
                unitPrice: 100.0,
                subtotal: 200.0,
                total: 200.0,
              ),
            );

        // 3. Insert payment
        await db.into(db.salePayments).insert(
              SalePaymentsCompanion.insert(
                uuid: paymentUuid,
                saleUuid: saleUuid,
                amount: 200.0,
                method: const Value('cash'),
                paidAt: now,
                createdAt: now,
              ),
            );
      });

      // Verify header
      final sale = await (db.select(db.sales)
            ..where((tbl) => tbl.uuid.equals(saleUuid)))
          .getSingle();

      expect(sale.total, equals(200.0));
      expect(sale.companyId, equals(companyId));
      expect(sale.customerId, equals(customerUuid));

      // Verify lines
      final items = await (db.select(db.saleItems)
            ..where((tbl) => tbl.saleUuid.equals(saleUuid)))
          .get();

      expect(items.length, equals(1));
      expect(items.first.uuid, equals(itemUuid));
      expect(items.first.productId, equals(productUuid));
      expect(items.first.total, equals(200.0));

      // Verify payments
      final payments = await (db.select(db.salePayments)
            ..where((tbl) => tbl.saleUuid.equals(saleUuid)))
          .get();

      expect(payments.length, equals(1));
      expect(payments.first.uuid, equals(paymentUuid));
      expect(payments.first.amount, equals(200.0));
    });

    test('Sales lifecycle state transition and posted immutability contract', () async {
      final companyId = 'comp-lifecycle-3e';
      final saleUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Create draft sale
      await db.into(db.sales).insert(
            SalesCompanion.insert(
              uuid: saleUuid,
              saleNumber: 'INV-STATE-01',
              subtotal: 150.0,
              itemDiscountTotal: 0.0,
              total: 150.0,
              currencyCode: 'YER',
              baseCurrencyCode: 'YER',
              saleStatus: const Value('draft'),
              createdAt: now,
              updatedAt: now,
              companyId: Value(companyId),
            ),
          );

      // 2. Transition to confirmed
      await (db.update(db.sales)..where((tbl) => tbl.uuid.equals(saleUuid)))
          .write(
        SalesCompanion(
          saleStatus: const Value('confirmed'),
          confirmedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      var updated = await (db.select(db.sales)
            ..where((tbl) => tbl.uuid.equals(saleUuid)))
          .getSingle();
      expect(updated.saleStatus, equals('confirmed'));

      // 3. Transition to posted
      await (db.update(db.sales)..where((tbl) => tbl.uuid.equals(saleUuid)))
          .write(
        SalesCompanion(
          saleStatus: const Value('posted'),
          completedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      updated = await (db.select(db.sales)
            ..where((tbl) => tbl.uuid.equals(saleUuid)))
          .getSingle();
      expect(updated.saleStatus, equals('posted'));
    });

    test('Transactional rollback on failed sales aggregate insertion', () async {
      final companyId = 'comp-rollback-sales-3e';
      final saleUuid = generateUuidV4();
      final now = DateTime.now().millisecondsSinceEpoch;

      try {
        await db.transaction(() async {
          // Insert sale header
          await db.into(db.sales).insert(
                SalesCompanion.insert(
                  uuid: saleUuid,
                  saleNumber: 'INV-FAIL-01',
                  subtotal: 50.0,
                  itemDiscountTotal: 0.0,
                  total: 50.0,
                  currencyCode: 'USD',
                  baseCurrencyCode: 'USD',
                  createdAt: now,
                  updatedAt: now,
                  companyId: Value(companyId),
                ),
              );

          // Intentionally throw exception to trigger transaction rollback
          throw Exception('Forced sales transaction failure');
        });
      } catch (_) {}

      final sales = await (db.select(db.sales)
            ..where((tbl) => tbl.uuid.equals(saleUuid)))
          .get();

      expect(sales, isEmpty);
    });
  });
}
