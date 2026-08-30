import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/modules/inventory/categories/data/repositories/category_repository_impl.dart';
import 'package:stock_count/modules/inventory/categories/domain/entities/category.dart';

void main() {
  late InventoryDatabase db;
  late String currentTenant;

  WarehouseRepositoryImpl createRepo() {
    return WarehouseRepositoryImpl(db, null, () => currentTenant);
  }

  CategoryRepositoryImpl createCategoryRepo() {
    return CategoryRepositoryImpl(db, readCompanyId: () => currentTenant);
  }

  setUp(() {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    currentTenant = 'company_alpha';
  });

  tearDown(() async {
    await db.close();
  });

  group('ROOT FIX 06 — Warehouse Multi-Tenant Isolation & Default Integrity', () {
    test('1. Company A Default Warehouse: Auto-creates default scoped to Company A', () async {
      currentTenant = 'company_alpha';
      final repoA = createRepo();

      final defaultWh = await repoA.ensureDefaultWarehouse();
      expect(defaultWh.isDefault, isTrue);
      expect(defaultWh.companyId, equals('company_alpha'));
      expect(defaultWh.code, equals('WH-MAIN'));

      final retrieved = await repoA.getDefaultWarehouse();
      expect(retrieved?.id, equals(defaultWh.id));
      expect(retrieved?.companyId, equals('company_alpha'));
    });

    test('2. Cross-Tenant Modification Rejection: Company B cannot save or delete Company A warehouse', () async {
      currentTenant = 'company_alpha';
      final repoA = createRepo();
      final whA = await repoA.ensureDefaultWarehouse();

      // Switch to Company B
      currentTenant = 'company_beta';
      final repoB = createRepo();

      // Company B trying to update Company A's warehouse
      final hackedWhA = whA.copyWith(name: 'Hacked Name', companyId: 'company_beta');
      expect(
        () => repoB.saveWarehouse(hackedWhA),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );

      // Company B trying to delete Company A's warehouse
      expect(
        () => repoB.deleteWarehouse(whA.id),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );
    });

    test('3. Company-Scoped Default Update: Setting Company A second warehouse default does NOT clear Company B default', () async {
      // Company A setup
      currentTenant = 'company_alpha';
      final repoA = createRepo();
      final whA1 = await repoA.ensureDefaultWarehouse();

      final whA2 = Warehouse(
        id: 'wh-alpha-2',
        code: 'WH-ALPHA-2',
        name: 'Alpha Wh 2',
        isDefault: false,
        companyId: 'company_alpha',
      );
      await repoA.saveWarehouse(whA2);

      // Company B setup
      currentTenant = 'company_beta';
      final repoB = createRepo();
      final whB1 = await repoB.ensureDefaultWarehouse();

      expect(whA1.isDefault, isTrue);
      expect(whB1.isDefault, isTrue);

      // Switch back to Company A and set WhA2 as default
      currentTenant = 'company_alpha';
      await repoA.saveWarehouse(whA2.copyWith(isDefault: true));

      // Verify Company A's WhA1 is no longer default, WhA2 IS default
      final updatedWhA1 = await repoA.getWarehouseById(whA1.id);
      final updatedWhA2 = await repoA.getWarehouseById(whA2.id);

      expect(updatedWhA1?.isDefault, isFalse);
      expect(updatedWhA2?.isDefault, isTrue);

      // CRITICAL SECURITY CHECK: Verify Company B's whB1 IS STILL DEFAULT!
      currentTenant = 'company_beta';
      final updatedWhB1 = await repoB.getWarehouseById(whB1.id);
      expect(updatedWhB1?.isDefault, isTrue);
    });

    test('4. Multi-Tenant Same Code Support: Company A and B can create identical warehouse codes', () async {
      currentTenant = 'company_alpha';
      final repoA = createRepo();
      final whA = Warehouse(
        id: 'wh-alpha-main',
        code: 'WH-MAIN',
        name: 'Main Wh Alpha',
        companyId: 'company_alpha',
      );
      await repoA.saveWarehouse(whA);

      currentTenant = 'company_beta';
      final repoB = createRepo();
      final whB = Warehouse(
        id: 'wh-beta-main',
        code: 'WH-MAIN',
        name: 'Main Wh Beta',
        companyId: 'company_beta',
      );

      // Should succeed without unique constraint collision
      await repoB.saveWarehouse(whB);

      currentTenant = 'company_alpha';
      final retrievedA = await repoA.getWarehouseById('wh-alpha-main');
      currentTenant = 'company_beta';
      final retrievedB = await repoB.getWarehouseById('wh-beta-main');

      expect(retrievedA?.code, equals('WH-MAIN'));
      expect(retrievedB?.code, equals('WH-MAIN'));
    });

    test('5. Default Warehouse Deletion Safeguard: Deleting default warehouse is blocked', () async {
      currentTenant = 'company_alpha';
      final repoA = createRepo();
      final defaultWh = await repoA.ensureDefaultWarehouse();

      expect(
        () => repoA.deleteWarehouse(defaultWh.id),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', 'warehouse_in_use')),
      );
    });

    test('6. Referenced Warehouse Deletion Safeguard: Deleting warehouse referenced by active categories is blocked', () async {
      currentTenant = 'company_alpha';
      final repoA = createRepo();
      final categoryRepo = createCategoryRepo();

      final wh = Warehouse(
        id: 'wh-ref-cat',
        code: 'WH-REF-CAT',
        name: 'Warehouse Referenced by Category',
        isDefault: false,
        companyId: 'company_alpha',
      );
      await repoA.saveWarehouse(wh);

      final category = Category(
        id: 'cat-ref-wh',
        code: 'CAT-01',
        name: 'Category Ref WH',
        warehouseId: wh.id,
        companyId: 'company_alpha',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(category);

      expect(
        () => repoA.deleteWarehouse(wh.id),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', 'warehouse_in_use')),
      );
    });

    test('7. Clean Warehouse Deletion: Unreferenced non-default warehouse deletes successfully', () async {
      currentTenant = 'company_alpha';
      final repoA = createRepo();
      await repoA.ensureDefaultWarehouse();

      final wh = Warehouse(
        id: 'wh-clean-delete',
        code: 'WH-CLEAN',
        name: 'Clean Warehouse',
        isDefault: false,
        companyId: 'company_alpha',
      );
      await repoA.saveWarehouse(wh);

      // Deleting clean warehouse
      await repoA.deleteWarehouse(wh.id);

      final retrieved = await repoA.getWarehouseById(wh.id);
      expect(retrieved, isNull);
    });
  });
}
