import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/categories/domain/entities/category.dart';
import 'package:stock_count/modules/inventory/categories/data/repositories/category_repository_impl.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';

void main() {
  late InventoryDatabase invDb;
  late CategoryRepositoryImpl categoryRepo;
  late ProductRepositoryImpl productRepo;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  setUp(() async {
    invDb = InventoryDatabase(executor: NativeDatabase.memory());
    companyA = 'company_alpha';
    companyB = 'company_beta';
    activeCompanyId = companyA;

    categoryRepo = CategoryRepositoryImpl(
      invDb,
      readCompanyId: () => activeCompanyId,
    );

    productRepo = ProductRepositoryImpl(
      invDb,
      readCompanyId: () => activeCompanyId,
    );
  });

  tearDown(() async {
    await invDb.close();
  });

  group('ROOT FIX 05 — Category Multi-Tenant Isolation & Reference Safeguards', () {
    test('1. Cross-Tenant Read Isolation: Company B cannot read Company A category', () async {
      activeCompanyId = companyA;
      final categoryAId = generateUuidV4();
      final categoryA = Category(
        id: categoryAId,
        code: 'CAT-A-01',
        name: 'Electronics Company A',
        warehouseId: 'WH-MAIN',
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await categoryRepo.saveCategory(categoryA);

      // Switch context to Company B
      activeCompanyId = companyB;

      final checkById = await categoryRepo.getCategoryById(categoryAId);
      expect(checkById, isNull);

      final allCategoriesB = await categoryRepo.getAllCategories();
      expect(allCategoriesB.any((c) => c.id == categoryAId), isFalse);

      final whCategoriesB = await categoryRepo.watchCategoriesForWarehouse('WH-MAIN').first;
      expect(whCategoriesB.any((c) => c.id == categoryAId), isFalse);
    });

    test('2. Cross-Tenant Update Rejection: Company B saving Company A category throws notFound', () async {
      activeCompanyId = companyA;
      final categoryAId = generateUuidV4();
      final categoryA = Category(
        id: categoryAId,
        code: 'CAT-A-02',
        name: 'Furniture Company A',
        warehouseId: 'WH-MAIN',
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await categoryRepo.saveCategory(categoryA);

      // Switch context to Company B
      activeCompanyId = companyB;

      final tamperedCategory = categoryA.copyWith(
        name: 'Tampered Furniture by Company B',
        companyId: companyB,
      );

      await expectLater(
        () async => categoryRepo.saveCategory(tamperedCategory),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );

      // Switch back to Company A and verify it was NOT modified
      activeCompanyId = companyA;
      final originalCheck = await categoryRepo.getCategoryById(categoryAId);
      expect(originalCheck!.name, equals('Furniture Company A'));
    });

    test('3. Cross-Tenant Delete Rejection: Company B deleting Company A category throws notFound', () async {
      activeCompanyId = companyA;
      final categoryAId = generateUuidV4();
      final categoryA = Category(
        id: categoryAId,
        code: 'CAT-A-03',
        name: 'Office Supplies Company A',
        warehouseId: 'WH-MAIN',
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await categoryRepo.saveCategory(categoryA);

      // Switch context to Company B
      activeCompanyId = companyB;

      await expectLater(
        () async => categoryRepo.deleteCategory(categoryAId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );

      // Switch back to Company A and verify category is intact
      activeCompanyId = companyA;
      final checkA = await categoryRepo.getCategoryById(categoryAId);
      expect(checkA, isNotNull);
      expect(checkA!.deletedAt, isNull);
    });

    test('4. Multi-Tenant Same Code Support: Company A and B can create identical category codes', () async {
      activeCompanyId = companyA;
      final catAId = generateUuidV4();
      final catA = Category(
        id: catAId,
        code: 'SHARED-CODE-01',
        name: 'Shared Category Name',
        warehouseId: 'WH-01',
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(catA);

      // Switch context to Company B and create category with same code and name
      activeCompanyId = companyB;
      final catBId = generateUuidV4();
      final catB = Category(
        id: catBId,
        code: 'SHARED-CODE-01',
        name: 'Shared Category Name',
        warehouseId: 'WH-01',
        companyId: companyB,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(catB);

      // Verify Company B reads catB
      final fetchedB = await categoryRepo.getCategoryById(catBId);
      expect(fetchedB, isNotNull);
      expect(fetchedB!.id, equals(catBId));

      // Switch to Company A and verify catA
      activeCompanyId = companyA;
      final fetchedA = await categoryRepo.getCategoryById(catAId);
      expect(fetchedA, isNotNull);
      expect(fetchedA!.id, equals(catAId));
    });

    test('5. Deletion Protection (Subcategories): Cannot delete category with subcategories', () async {
      activeCompanyId = companyA;
      final parentCatId = generateUuidV4();
      final childCatId = generateUuidV4();

      final parentCat = Category(
        id: parentCatId,
        code: 'PARENT-01',
        name: 'Parent Hardware',
        warehouseId: 'WH-MAIN',
        isGroup: true,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(parentCat);

      final childCat = Category(
        id: childCatId,
        code: 'CHILD-01',
        name: 'Child Power Tools',
        warehouseId: 'WH-MAIN',
        parentId: parentCatId,
        isGroup: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(childCat);

      // Attempting to delete parent category must fail
      await expectLater(
        () async => categoryRepo.deleteCategory(parentCatId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', 'category_in_use')),
      );

      final checkParent = await categoryRepo.getCategoryById(parentCatId);
      expect(checkParent, isNotNull);
      expect(checkParent!.deletedAt, isNull);
    });

    test('6. Deletion Protection (Products): Cannot delete category referenced by active products', () async {
      activeCompanyId = companyA;
      final catId = generateUuidV4();

      final category = Category(
        id: catId,
        code: 'CAT-PROD-REF',
        name: 'Product Category',
        warehouseId: 'WH-MAIN',
        isGroup: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(category);

      // Create product referencing this category
      await productRepo.insert(
        ProductDraft(
          itemCode: 'ITEM-CAT-REF-01',
          name: 'Category Referenced Product',
          packSize: 1,
          price: 100,
          unitCost: 60,
          categoryId: catId,
        ),
      );

      // Attempting to delete category must fail
      await expectLater(
        () async => categoryRepo.deleteCategory(catId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', 'category_in_use')),
      );

      final checkCat = await categoryRepo.getCategoryById(catId);
      expect(checkCat, isNotNull);
      expect(checkCat!.deletedAt, isNull);
    });

    test('7. Unreferenced Category Deletion: Category without references deletes successfully', () async {
      activeCompanyId = companyA;
      final catId = generateUuidV4();

      final category = Category(
        id: catId,
        code: 'CAT-CLEAN-DELETE',
        name: 'Clean Delete Category',
        warehouseId: 'WH-MAIN',
        isGroup: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryRepo.saveCategory(category);

      await categoryRepo.deleteCategory(catId);

      final checkCat = await categoryRepo.getCategoryById(catId);
      expect(checkCat, isNull);
    });
  });
}
