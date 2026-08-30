import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/domain/models/product_exception.dart';

void main() {
  late InventoryDatabase db;
  late ProductRepositoryImpl repoCompanyA;
  late ProductRepositoryImpl repoCompanyB;

  setUp(() async {
    db = InventoryDatabase.memory();
    repoCompanyA = ProductRepositoryImpl(db, readCompanyId: () => 'COMP-A');
    repoCompanyB = ProductRepositoryImpl(db, readCompanyId: () => 'COMP-A-OTHER-B');
  });

  tearDown(() async {
    await db.close();
  });

  group('Product Repository — Multi-Tenant Stock Isolation Security Tests', () {
    test('1. Company A can adjust Company A product stock successfully', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final uuidA = generateUuidV4();

      await db.into(db.products).insert(
        ProductsCompanion(
          id: const Value(1),
          uuid: Value(uuidA),
          itemCode: const Value('PROD-A-01'),
          name: const Value('Company A Product'),
          packSize: const Value(1),
          price: const Value(100.0),
          onHandQty: const Value(50.0),
          unitCost: const Value(10.0),
          companyId: const Value('COMP-A'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final updated = await repoCompanyA.adjustOnHandByUuid(
        uuid: uuidA,
        delta: 25.0,
      );

      expect(updated.onHandQty, 75.0);

      final dbRow = await (db.select(db.products)
            ..where((t) => t.uuid.equals(uuidA)))
          .getSingle();
      expect(dbRow.onHandQty, 75.0);
    });

    test('2. Company A cannot adjust Company B product (stock remains unchanged)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final uuidB = generateUuidV4();

      await db.into(db.products).insert(
        ProductsCompanion(
          id: const Value(2),
          uuid: Value(uuidB),
          itemCode: const Value('PROD-B-01'),
          name: const Value('Company B Product'),
          packSize: const Value(1),
          price: const Value(200.0),
          onHandQty: const Value(100.0),
          unitCost: const Value(20.0),
          companyId: const Value('COMP-A-OTHER-B'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Company A attempts to adjust Company B product
      expect(
        () => repoCompanyA.adjustOnHandByUuid(
          uuid: uuidB,
          delta: -30.0,
        ),
        throwsA(isA<ProductException>().having(
          (e) => e.code,
          'code',
          ProductException.notFound,
        )),
      );

      // Verify Company B product stock was NOT modified in the database
      final dbRow = await (db.select(db.products)
            ..where((t) => t.uuid.equals(uuidB)))
          .getSingle();
      expect(dbRow.onHandQty, 100.0);
    });

    test('3. Company B cannot adjust Company A product (stock remains unchanged)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final uuidA = generateUuidV4();

      await db.into(db.products).insert(
        ProductsCompanion(
          id: const Value(3),
          uuid: Value(uuidA),
          itemCode: const Value('PROD-A-02'),
          name: const Value('Company A Product 2'),
          packSize: const Value(1),
          price: const Value(50.0),
          onHandQty: const Value(40.0),
          unitCost: const Value(5.0),
          companyId: const Value('COMP-A'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Company B attempts to adjust Company A product
      expect(
        () => repoCompanyB.adjustOnHandByUuid(
          uuid: uuidA,
          delta: 10.0,
        ),
        throwsA(isA<ProductException>().having(
          (e) => e.code,
          'code',
          ProductException.notFound,
        )),
      );

      // Verify Company A product stock was NOT modified
      final dbRow = await (db.select(db.products)
            ..where((t) => t.uuid.equals(uuidA)))
          .getSingle();
      expect(dbRow.onHandQty, 40.0);
    });

    test('4. Unknown product UUID yields notFound exception', () async {
      final unknownUuid = generateUuidV4();

      expect(
        () => repoCompanyA.adjustOnHandByUuid(
          uuid: unknownUuid,
          delta: 10.0,
        ),
        throwsA(isA<ProductException>().having(
          (e) => e.code,
          'code',
          ProductException.notFound,
        )),
      );
    });

    test('5. Product with null companyId cannot be modified through company context', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final nullCompanyUuid = generateUuidV4();

      await db.into(db.products).insert(
        ProductsCompanion(
          id: const Value(5),
          uuid: Value(nullCompanyUuid),
          itemCode: const Value('PROD-NULL-01'),
          name: const Value('Unassigned Company Product'),
          packSize: const Value(1),
          price: const Value(10.0),
          onHandQty: const Value(20.0),
          unitCost: const Value(2.0),
          companyId: const Value(null),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Company A attempts to adjust product with null companyId
      expect(
        () => repoCompanyA.adjustOnHandByUuid(
          uuid: nullCompanyUuid,
          delta: 5.0,
        ),
        throwsA(isA<ProductException>().having(
          (e) => e.code,
          'code',
          ProductException.notFound,
        )),
      );

      // Verify null-company product stock was NOT modified
      final dbRow = await (db.select(db.products)
            ..where((t) => t.uuid.equals(nullCompanyUuid)))
          .getSingle();
      expect(dbRow.onHandQty, 20.0);
    });

    test('6. Database UPDATE contains strict tenant scoping in query predicate', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final uuid = generateUuidV4();

      await db.into(db.products).insert(
        ProductsCompanion(
          id: const Value(6),
          uuid: Value(uuid),
          itemCode: const Value('PROD-A-03'),
          name: const Value('Company A Product 3'),
          packSize: const Value(1),
          price: const Value(15.0),
          onHandQty: const Value(10.0),
          unitCost: const Value(3.0),
          companyId: const Value('COMP-A'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Fetch with repoCompanyA
      final productA = await repoCompanyA.getByUuid(uuid);
      expect(productA, isNotNull);

      // Attempt to fetch with repoCompanyB (should return null)
      final productB = await repoCompanyB.getByUuid(uuid);
      expect(productB, isNull);
    });
  });
}
