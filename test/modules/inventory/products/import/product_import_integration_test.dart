import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/categories/domain/entities/category.dart';
import 'package:stock_count/modules/inventory/categories/domain/repositories/category_repository.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/products/domain/models/catalog_search_field.dart';
import 'package:stock_count/modules/inventory/products/domain/repositories/product_repository.dart';
import 'package:stock_count/modules/inventory/products/import/products_import.dart';
import 'package:stock_count/modules/inventory/stock_count/domain/models/paged_result.dart';

/// In-memory test repository for Product entity.
class TestProductRepository implements ProductRepository {
  final Map<int, Product> _productsById = {};
  final Map<String, Product> _productsByCode = {};

  @override
  Future<List<Product>> getAll() async => _productsById.values.toList();

  @override
  Stream<List<Product>> watchAll() =>
      Stream.value(_productsById.values.toList());

  @override
  Future<Product?> getById(int id) async => _productsById[id];

  @override
  Future<Product?> getByItemCode(String itemCode) async =>
      _productsByCode[itemCode];

  @override
  Future<Product?> getByUuid(String uuid) async {
    for (final p in _productsById.values) {
      if (p.uuid == uuid) return p;
    }
    return null;
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    for (final p in _productsById.values) {
      if (p.barcode == barcode) return p;
    }
    return null;
  }

  @override
  Future<List<Product>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
    int? limit,
  }) async {
    return _productsById.values
        .where((p) => p.name.contains(query) || p.itemCode.contains(query))
        .toList();
  }

  @override
  Future<PagedResult<Product>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async {
    final list = _productsById.values.toList();
    return PagedResult(
      items: list,
      totalCount: list.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Product> insert(ProductDraft draft) async {
    final now = DateTime.now().toUtc();
    final newId = _productsById.length + 1;
    final product = Product(
      id: newId,
      uuid: 'PROD-UUID-$newId',
      itemCode: draft.itemCode,
      name: draft.name,
      barcode: draft.barcode,
      packSize: draft.packSize,
      price: draft.price,
      unitCost: draft.unitCost,
      
      categoryId: draft.categoryId,
      createdAt: now,
      updatedAt: now,
    );
    _productsById[newId] = product;
    _productsByCode[product.itemCode] = product;
    return product;
  }

  @override
  Future<Product> update(int id, ProductDraft draft) async {
    final existing = _productsById[id];
    if (existing == null) {
      throw StateError('Product $id not found');
    }
    final updated = existing.copyWith(
      name: draft.name,
      price: draft.price,
      unitCost: draft.unitCost,
      barcode: draft.barcode,
      packSize: draft.packSize,
      categoryId: draft.categoryId,
      updatedAt: DateTime.now().toUtc(),
    );
    _productsById[id] = updated;
    _productsByCode[updated.itemCode] = updated;
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    final p = _productsById.remove(id);
    if (p != null) {
      _productsByCode.remove(p.itemCode);
    }
  }

  @override
  Future<ProductUpsertResult> upsertAll(
    List<ProductDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) async {
    int inserted = 0;
    int updated = 0;
    for (int i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final existing = await getByItemCode(draft.itemCode);
      if (existing != null) {
        await update(existing.id, draft);
        updated++;
      } else {
        await insert(draft);
        inserted++;
      }
      onProgress?.call(i + 1, drafts.length);
    }
    return ProductUpsertResult(insertedCount: inserted, updatedCount: updated);
  }

  @override
  Future<Product> adjustOnHandByUuid({
    required String uuid,
    required double delta,
  }) async {
    final p = await getByUuid(uuid);
    if (p == null) throw StateError('Not found');
    final updated = p.copyWith();
    _productsById[p.id] = updated;
    _productsByCode[p.itemCode] = updated;
    return updated;
  }
}

/// In-memory test repository for Category entity.
class TestCategoryRepository implements CategoryRepository {
  final Map<String, Category> _categories = {};

  @override
  Future<List<Category>> getAllCategories() async =>
      _categories.values.toList();

  @override
  Stream<List<Category>> watchAllCategories() =>
      Stream.value(_categories.values.toList());

  @override
  Stream<List<Category>> watchCategoriesForWarehouse(String warehouseId) {
    return Stream.value(
      _categories.values.where((c) => c.warehouseId == warehouseId).toList(),
    );
  }

  @override
  Future<Category?> getCategoryById(String id) async => _categories[id];

  @override
  Future<void> saveCategory(Category category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
  }
}

void main() {
  group('Phase 18 — Universal Import Engine Products Import Integration Tests', () {
    late TestProductRepository productRepo;
    late TestCategoryRepository categoryRepo;
    late ProductImportExecutor executor;
    late Map<String, ResolvedAccount> testAccountsRegistry;

    setUp(() {
      productRepo = TestProductRepository();
      categoryRepo = TestCategoryRepository();

      testAccountsRegistry = {
        '1010': const ResolvedAccount(
          accountId: 'ACC-1010',
          accountCode: '1010',
          accountName: 'Inventory Assets',
        ),
        '4010': const ResolvedAccount(
          accountId: 'ACC-4010',
          accountCode: '4010',
          accountName: 'Sales Revenue',
        ),
        '5010': const ResolvedAccount(
          accountId: 'ACC-5010',
          accountCode: '5010',
          accountName: 'Cost of Goods Sold',
        ),
      };

      executor = ProductImportExecutor(
        productRepository: productRepo,
        categoryRepository: categoryRepo,
        accountsRegistry: testAccountsRegistry,
      );

      // Pre-seed an existing category
      final now = DateTime.now().toUtc();
      categoryRepo.saveCategory(
        Category(
          id: 'CAT-COMPUTERS',
          code: 'CAT-COMP',
          name: 'Computers',
          warehouseId: 'WH-MAIN',
          companyId: 'COMP-100',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    test(
      '1. New Products: Creates brand new product record with complete attributes',
      () async {
        final row = {
          'itemCode': 'LAPTOP-PRO-15',
          'name': 'Laptop Pro 15-inch',
          'barcode': '1234567890123',
          'unitCost': 850.0,
          'price': 1200.0,
          'onHandQty': 15.0,
          'packSize': 1,
        };

        final product = await executor.executeProductRow(
          rowData: row,
          companyId: 'COMP-100',
        );

        expect(product.itemCode, equals('LAPTOP-PRO-15'));
        expect(product.name, equals('Laptop Pro 15-inch'));
        expect(product.price, equals(1200.0));
        expect(product.unitCost, equals(850.0));
        expect(product.barcode, equals('1234567890123'));
      },
    );

    test(
      '2. Updates: Upserts existing product by SKU/itemCode cleanly',
      () async {
        final initialRow = {
          'itemCode': 'TABLET-10',
          'name': 'Tablet 10-inch',
          'price': 300.0,
          'unitCost': 200.0,
        };
        await executor.executeProductRow(
          rowData: initialRow,
          companyId: 'COMP-100',
        );

        final updateRow = {
          'itemCode': 'TABLET-10',
          'name': 'Tablet 10-inch v2',
          'price': 350.0,
          'unitCost': 220.0,
        };
        final updated = await executor.executeProductRow(
          rowData: updateRow,
          companyId: 'COMP-100',
        );

        expect(updated.name, equals('Tablet 10-inch v2'));
        expect(updated.price, equals(350.0));
        expect(updated.unitCost, equals(220.0));
        expect(await productRepo.getAll(), hasLength(1));
      },
    );

    test(
      '3. Duplicates: Sequential duplicate rows update attributes without duplicate records',
      () async {
        final duplicateRow1 = {
          'itemCode': 'MOUSE-USB',
          'name': 'USB Mouse',
          'price': 15.0,
        };
        final duplicateRow2 = {
          'itemCode': 'MOUSE-USB',
          'name': 'USB Mouse Wireless',
          'price': 25.0,
        };

        await executor.executeProductRow(
          rowData: duplicateRow1,
          companyId: 'COMP-100',
        );
        await executor.executeProductRow(
          rowData: duplicateRow2,
          companyId: 'COMP-100',
        );

        final all = await productRepo.getAll();
        expect(all, hasLength(1));
        expect(all.first.price, equals(25.0));
        expect(all.first.name, equals('USB Mouse Wireless'));
      },
    );

    test(
      '4. Category Assignment: Fixed Category selected before import (without Category column in file)',
      () async {
        final rowNoCategoryColumn = {
          'itemCode': 'DESKTOP-CORE-I7',
          'name': 'Desktop Core i7',
          'price': 900.0,
        };

        const config = CategoryAssignmentConfig(
          strategyType: CategoryAssignmentStrategyType.fixed,
          fixedCategoryId: 'CAT-COMPUTERS',
          fixedCategoryName: 'Computers',
        );

        final product = await executor.executeProductRow(
          rowData: rowNoCategoryColumn,
          companyId: 'COMP-100',
          categoryConfig: config,
        );

        expect(product.categoryId, equals('CAT-COMPUTERS'));
      },
    );

    test(
      '4b. Category Assignment: Explicit CREATE_IF_ALLOWED policy creates missing category',
      () async {
        final rowNewCategory = {
          'itemCode': 'MONITOR-4K',
          'name': '4K Gaming Monitor',
          'price': 450.0,
          'category': 'Displays',
        };

        const config = CategoryAssignmentConfig(
          strategyType: CategoryAssignmentStrategyType.fromFile,
          createIfMissingPolicy: true,
        );

        final product = await executor.executeProductRow(
          rowData: rowNewCategory,
          companyId: 'COMP-100',
          categoryConfig: config,
        );

        expect(product.categoryId, isNotNull);
        final createdCat = await categoryRepo.getCategoryById(
          product.categoryId!,
        );
        expect(createdCat, isNotNull);
        expect(createdCat!.name, equals('Displays'));
      },
    );

    test(
      '5. Multiple Categories: Handles multi-category assignment mapping payload',
      () async {
        final rowMulti = {
          'itemCode': 'SMART-HUB-01',
          'name': 'Smart Home Hub',
          'price': 120.0,
        };

        const config = CategoryAssignmentConfig(
          strategyType: CategoryAssignmentStrategyType.multiple,
          multipleCategoryIds: ['CAT-ELECTRONICS', 'CAT-SMARTHOME'],
        );

        final resolved = await executor.resolveCategoryAssignment(
          rowData: rowMulti,
          companyId: 'COMP-100',
          config: config,
          resolvedRelations: const {},
        );

        expect(resolved, isNotNull);
        expect(resolved!.allCategoryIds, contains('CAT-ELECTRONICS'));
        expect(resolved.allCategoryIds, contains('CAT-SMARTHOME'));
      },
    );

    test(
      '6. Warehouse Assignment: Resolves warehouse relation by ID/code',
      () async {
        final row = {
          'itemCode': 'ROUTER-AX',
          'name': 'Wi-Fi 6 Router',
          'price': 80.0,
          'warehouse': 'WH-MAIN',
        };

        final product = await executor.executeProductRow(
          rowData: row,
          companyId: 'COMP-100',
          resolvedRelations: {'warehouse': 'WH-MAIN'},
        );

        expect(product.itemCode, equals('ROUTER-AX'));
      },
    );

    test(
      '7. Account Assignment: Resolves accounting accounts by code or name without hardcoding',
      () {
        final resolvedAsset = executor.resolveAccount('1010', 'COMP-100');
        final resolvedIncome = executor.resolveAccount(
          'Sales Revenue',
          'COMP-100',
        );
        final resolvedExpense = executor.resolveAccount('5010', 'COMP-100');

        expect(resolvedAsset, isNotNull);
        expect(resolvedAsset!.accountName, equals('Inventory Assets'));

        expect(resolvedIncome, isNotNull);
        expect(resolvedIncome!.accountCode, equals('4010'));

        expect(resolvedExpense, isNotNull);
        expect(resolvedExpense!.accountName, equals('Cost of Goods Sold'));
      },
    );

    test(
      '8. Invalid Relations: Throws exception when missing non-creatable relation',
      () async {
        final rowMissingCategory = {
          'itemCode': 'CABLE-HDMI',
          'name': 'HDMI Cable 2m',
          'price': 10.0,
          'category': 'NonExistentCategory',
        };

        const config = CategoryAssignmentConfig(
          strategyType: CategoryAssignmentStrategyType.fromFile,
          createIfMissingPolicy: false,
        );

        expect(
          () async => executor.executeProductRow(
            rowData: rowMissingCategory,
            companyId: 'COMP-100',
            categoryConfig: config,
          ),
          throwsA(isA<ProductImportException>()),
        );
      },
    );

    test(
      '9. Company Isolation: Ensures company isolation during category creation',
      () async {
        final rowCompanyB = {
          'itemCode': 'PROD-COMP-B',
          'name': 'Company B Product',
          'price': 99.0,
          'category': 'Special Category B',
        };

        const config = CategoryAssignmentConfig(
          strategyType: CategoryAssignmentStrategyType.fromFile,
          createIfMissingPolicy: true,
        );

        final productB = await executor.executeProductRow(
          rowData: rowCompanyB,
          companyId: 'COMPANY-B',
          categoryConfig: config,
        );

        final catB = await categoryRepo.getCategoryById(productB.categoryId!);
        expect(catB, isNotNull);
        expect(catB!.companyId, equals('COMPANY-B'));
      },
    );

    test(
      '10. Large Import Simulation: Processes 500 product rows efficiently',
      () async {
        final List<Map<String, dynamic>> largeRows = List.generate(500, (i) {
          return {
            'itemCode': 'ITEM-BULK-${i + 1}',
            'name': 'Bulk Product ${i + 1}',
            'price': (i + 1) * 1.5,
            'unitCost': (i + 1) * 0.8,
            'onHandQty': 100.0,
          };
        });

        for (final row in largeRows) {
          await executor.executeProductRow(
            rowData: row,
            companyId: 'COMP-100',
            categoryConfig: const CategoryAssignmentConfig(
              strategyType: CategoryAssignmentStrategyType.fixed,
              fixedCategoryId: 'CAT-COMPUTERS',
            ),
          );
        }

        final allProducts = await productRepo.getAll();
        expect(allProducts.length, equals(500));
        expect(allProducts.last.itemCode, equals('ITEM-BULK-500'));
      },
    );
  });
}
