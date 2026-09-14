import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
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

  group('Phase 3H — Canonical Purchases & Payables Baseline Tests', () {
    test('NexabizDatabase schemaVersion is 8 and purchases & suppliers tables exist', () async {
      expect(db.schemaVersion, equals(8));

      final suppliersCount = await db.select(db.suppliers).get();
      final purchasesCount = await db.select(db.purchases).get();
      final itemsCount = await db.select(db.purchaseItems).get();
      final paymentsCount = await db.select(db.purchasePayments).get();

      expect(suppliersCount, isEmpty);
      expect(purchasesCount, isEmpty);
      expect(itemsCount, isEmpty);
      expect(paymentsCount, isEmpty);
    });

    test('Canonical UUID identity and tenant isolation on suppliers and purchases', () async {
      final companyA = 'comp-purch-aaa-3h';
      final companyB = 'comp-purch-bbb-3h';

      final supplierUuidA = generateUuidV4();
      final supplierUuidB = generateUuidV4();
      final purchaseUuidA = generateUuidV4();
      final purchaseUuidB = generateUuidV4();

      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      // Insert Supplier & Purchase for Company A
      await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              id: Value(supplierUuidA),
              supplierCode: 'SUPP-A-01',
              name: 'Supplier Alpha',
              companyId: companyA,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await db.into(db.purchases).insert(
            PurchasesCompanion.insert(
              id: purchaseUuidA,
              purchaseNumber: 'PO-A-001',
              supplierId: Value(supplierUuidA),
              supplierName: const Value('Supplier Alpha'),
              subtotal: 1000.0,
              itemDiscountTotal: 0.0,
              total: 1000.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: nowMs,
              updatedAt: nowMs,
              companyId: Value(companyA),
            ),
          );

      // Insert Supplier & Purchase for Company B
      await db.into(db.suppliers).insert(
            SuppliersCompanion.insert(
              id: Value(supplierUuidB),
              supplierCode: 'SUPP-B-01',
              name: 'Supplier Beta',
              companyId: companyB,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await db.into(db.purchases).insert(
            PurchasesCompanion.insert(
              id: purchaseUuidB,
              purchaseNumber: 'PO-B-001',
              supplierId: Value(supplierUuidB),
              supplierName: const Value('Supplier Beta'),
              subtotal: 500.0,
              itemDiscountTotal: 0.0,
              total: 500.0,
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: nowMs,
              updatedAt: nowMs,
              companyId: Value(companyB),
            ),
          );

      // Query Company A suppliers & purchases
      final suppA = await (db.select(db.suppliers)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();
      final purchA = await (db.select(db.purchases)
            ..where((tbl) => tbl.companyId.equals(companyA)))
          .get();

      expect(suppA.length, equals(1));
      expect(suppA.first.uuid, equals(supplierUuidA));
      expect(purchA.length, equals(1));
      expect(purchA.first.uuid, equals(purchaseUuidA));
      expect(purchA.first.companyId, equals(companyA));

      // Query Company B suppliers & purchases
      final suppB = await (db.select(db.suppliers)
            ..where((tbl) => tbl.companyId.equals(companyB)))
          .get();
      final purchB = await (db.select(db.purchases)
            ..where((tbl) => tbl.companyId.equals(companyB)))
          .get();

      expect(suppB.length, equals(1));
      expect(suppB.first.uuid, equals(supplierUuidB));
      expect(purchB.length, equals(1));
      expect(purchB.first.uuid, equals(purchaseUuidB));
      expect(purchB.first.companyId, equals(companyB));
    });

    test('Purchase document line calculation and payment status tracking', () async {
      final companyId = 'comp-purch-calc-3h';
      final purchaseUuid = generateUuidV4();
      final productId = generateUuidV4();
      final supplierId = generateUuidV4();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Create Purchase Header
      await db.into(db.purchases).insert(
            PurchasesCompanion.insert(
              id: purchaseUuid,
              purchaseNumber: 'PO-2026-001',
              supplierId: Value(supplierId),
              subtotal: 250.0,
              itemDiscountTotal: 0.0,
              discountAmount: const Value(10.0),
              taxAmount: const Value(15.0),
              total: 255.0,
              paidAmount: const Value(255.0),
              remainingAmount: const Value(0.0),
              paymentStatus: const Value('paid'),
              currencyCode: 'USD',
              baseCurrencyCode: 'USD',
              createdAt: nowMs,
              updatedAt: nowMs,
              companyId: Value(companyId),
            ),
          );

      // Create Line Item
      final lineUuid = generateUuidV4();
      await db.into(db.purchaseItems).insert(
            PurchaseItemsCompanion.insert(
              uuid: lineUuid,
              purchaseUuid: purchaseUuid,
              productId: productId,
              productName: 'Raw Materials Widget',
              productCode: 'RAW-001',
              quantity: 10.0,
              unitPrice: 25.0,
              subtotal: 250.0,
              total: 250.0,
            ),
          );

      final row = await (db.select(db.purchases)
            ..where((tbl) => tbl.id.equals(purchaseUuid)))
          .getSingle();

      final lines = await (db.select(db.purchaseItems)
            ..where((tbl) => tbl.purchaseUuid.equals(purchaseUuid)))
          .get();

      expect(row.uuid, equals(purchaseUuid));
      expect(row.total, equals(255.0));
      expect(row.paymentStatus, equals('paid'));
      expect(lines.length, equals(1));
      expect(lines.first.productId, equals(productId));
      expect(lines.first.quantity, equals(10.0));
    });

    test('Transactional rollback on failed purchase insertion', () async {
      final companyId = 'comp-rollback-purch-3h';
      final purchaseUuid = generateUuidV4();
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      try {
        await db.transaction(() async {
          await db.into(db.purchases).insert(
                PurchasesCompanion.insert(
                  id: purchaseUuid,
                  purchaseNumber: 'PO-FAIL-01',
                  subtotal: 100.0,
                  itemDiscountTotal: 0.0,
                  total: 100.0,
                  currencyCode: 'USD',
                  baseCurrencyCode: 'USD',
                  createdAt: nowMs,
                  updatedAt: nowMs,
                  companyId: Value(companyId),
                ),
              );

          await db.into(db.purchaseItems).insert(
                PurchaseItemsCompanion.insert(
                  uuid: generateUuidV4(),
                  purchaseUuid: purchaseUuid,
                  productId: generateUuidV4(),
                  productName: 'Sample Product',
                  productCode: 'SMP-01',
                  quantity: 1.0,
                  unitPrice: 100.0,
                  subtotal: 100.0,
                  total: 100.0,
                ),
              );

          throw Exception('Forced purchase transaction failure');
        });
      } catch (_) {}

      final rows = await (db.select(db.purchases)
            ..where((tbl) => tbl.id.equals(purchaseUuid)))
          .get();

      final lines = await (db.select(db.purchaseItems)
            ..where((tbl) => tbl.purchaseUuid.equals(purchaseUuid)))
          .get();

      expect(rows, isEmpty);
      expect(lines, isEmpty);
    });
  });
}
