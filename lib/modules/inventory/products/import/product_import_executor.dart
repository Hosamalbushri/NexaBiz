import '../../categories/domain/entities/category.dart';
import '../../categories/domain/repositories/category_repository.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';
import '../../../../../core/import_engine/import_engine.dart';

/// Exception thrown during Product import validation or relation failure.
class ProductImportException extends ImportEngineException {
  const ProductImportException(super.message, [super.code = 'PRODUCT_IMPORT_ERROR']);
}

/// Resolved Category assignment payload for a product record.
class ResolvedProductCategory {
  const ResolvedProductCategory({
    required this.categoryId,
    required this.categoryName,
    this.allCategoryIds = const [],
  });

  final String categoryId;
  final String categoryName;
  final List<String> allCategoryIds;
}

/// Execution result for a single imported product row.
class ProductImportRowResult {
  const ProductImportRowResult({
    required this.product,
    this.category,
    this.assetAccount,
    this.incomeAccount,
    this.expenseAccount,
  });

  final Product product;
  final ResolvedProductCategory? category;
  final ResolvedAccount? assetAccount;
  final ResolvedAccount? incomeAccount;
  final ResolvedAccount? expenseAccount;
}

/// Category assignment strategy configuration options for Product import.
enum CategoryAssignmentStrategyType {
  fromFile,
  fixed,
  multiple,
  hybrid,
}

/// Category assignment configuration passed to Product import engine execution.
class CategoryAssignmentConfig {
  const CategoryAssignmentConfig({
    this.strategyType = CategoryAssignmentStrategyType.fromFile,
    this.fixedCategoryId,
    this.fixedCategoryName,
    this.multipleCategoryIds = const [],
    this.createIfMissingPolicy = false,
    this.defaultWarehouseId = 'WH-MAIN',
  });

  final CategoryAssignmentStrategyType strategyType;
  final String? fixedCategoryId;
  final String? fixedCategoryName;
  final List<String> multipleCategoryIds;
  final bool createIfMissingPolicy;
  final String defaultWarehouseId;
}

/// Account resolution model for product accounting relations.
class ResolvedAccount {
  const ResolvedAccount({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.companyId,
  });

  final String accountId;
  final String accountCode;
  final String accountName;
  final String? companyId;
}

/// Domain import executor for Products enforcing multi-company tenant isolation.
class ProductImportExecutor {
  ProductImportExecutor({
    required this.productRepository,
    required this.categoryRepository,
    this.accountsRegistry = const {},
  });

  final ProductRepository productRepository;
  final CategoryRepository categoryRepository;

  /// In-memory accounting lookup registry (accountCode / accountId / accountName -> ResolvedAccount).
  final Map<String, ResolvedAccount> accountsRegistry;

  /// Executes import of a single product row record.
  Future<ProductImportRowResult> executeProductRowResult({
    required Map<String, dynamic> rowData,
    required String companyId,
    CategoryAssignmentConfig categoryConfig = const CategoryAssignmentConfig(),
    Map<String, String> resolvedRelations = const {},
  }) async {
    final name = rowData['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const ProductImportException('Product Name cannot be empty.', 'EMPTY_NAME');
    }

    final itemCode = rowData['itemCode']?.toString().trim() ?? '';
    if (itemCode.isEmpty) {
      throw const ProductImportException('Item Code / SKU cannot be empty.', 'EMPTY_ITEM_CODE');
    }

    final price = double.tryParse(rowData['price']?.toString() ?? '') ?? 0.0;
    final unitCost = double.tryParse(rowData['unitCost']?.toString() ?? '') ?? 0.0;
    final packSize = int.tryParse(rowData['packSize']?.toString() ?? '') ?? 1;
    final barcode = rowData['barcode']?.toString().trim();

    // 1. Resolve Category Assignment with Tenant Isolation
    final resolvedCategory = await resolveCategoryAssignment(
      rowData: rowData,
      companyId: companyId,
      config: categoryConfig,
      resolvedRelations: resolvedRelations,
    );

    // 2. Resolve Accounting Relations with Tenant Isolation
    final assetAccount = resolveAccount(rowData['accountingAssetAccount'] ?? resolvedRelations['accountingAssetAccount'], companyId);
    final incomeAccount = resolveAccount(rowData['accountingIncomeAccount'] ?? resolvedRelations['accountingIncomeAccount'], companyId);
    final expenseAccount = resolveAccount(rowData['accountingExpenseAccount'] ?? resolvedRelations['accountingExpenseAccount'], companyId);

    // 3. Upsert or Create Product via ProductRepository
    final existing = await productRepository.getByItemCode(itemCode);

    final draft = ProductDraft(
      itemCode: itemCode,
      name: name,
      barcode: barcode != null && barcode.isNotEmpty ? barcode : (existing?.barcode),
      packSize: packSize,
      price: price,
      unitCost: unitCost,
      categoryId: resolvedCategory?.categoryId ?? existing?.categoryId,
    );

    final Product product;
    if (existing != null) {
      product = await productRepository.update(existing.id, draft);
    } else {
      product = await productRepository.insert(draft);
    }

    return ProductImportRowResult(
      product: product,
      category: resolvedCategory,
      assetAccount: assetAccount,
      incomeAccount: incomeAccount,
      expenseAccount: expenseAccount,
    );
  }

  /// Convenience wrapper returning imported [Product].
  Future<Product> executeProductRow({
    required Map<String, dynamic> rowData,
    required String companyId,
    CategoryAssignmentConfig categoryConfig = const CategoryAssignmentConfig(),
    Map<String, String> resolvedRelations = const {},
  }) async {
    final result = await executeProductRowResult(
      rowData: rowData,
      companyId: companyId,
      categoryConfig: categoryConfig,
      resolvedRelations: resolvedRelations,
    );
    return result.product;
  }

  /// Resolves category assignment strictly scoped to [companyId].
  Future<ResolvedProductCategory?> resolveCategoryAssignment({
    required Map<String, dynamic> rowData,
    required String companyId,
    required CategoryAssignmentConfig config,
    required Map<String, String> resolvedRelations,
  }) async {
    String? categoryValue = rowData['category']?.toString().trim() ?? resolvedRelations['category'];

    switch (config.strategyType) {
      case CategoryAssignmentStrategyType.fixed:
        if (config.fixedCategoryId != null && config.fixedCategoryId!.isNotEmpty) {
          final cat = await categoryRepository.getCategoryById(config.fixedCategoryId!);
          if (cat != null && cat.companyId != companyId) {
            throw TenantIsolationException(
              'Cross-company category assignment violation: Category "${cat.id}" belongs to company "${cat.companyId}", expected "$companyId"',
              expectedCompanyId: companyId,
              attemptedCompanyId: cat.companyId,
            );
          }
          return ResolvedProductCategory(
            categoryId: config.fixedCategoryId!,
            categoryName: config.fixedCategoryName ?? 'Fixed Category',
          );
        }
        break;

      case CategoryAssignmentStrategyType.multiple:
        if (config.multipleCategoryIds.isNotEmpty) {
          for (final catId in config.multipleCategoryIds) {
            final cat = await categoryRepository.getCategoryById(catId);
            if (cat != null && cat.companyId != companyId) {
              throw TenantIsolationException(
                'Cross-company category assignment violation: Category "$catId" belongs to company "${cat.companyId}", expected "$companyId"',
                expectedCompanyId: companyId,
                attemptedCompanyId: cat.companyId,
              );
            }
          }
          return ResolvedProductCategory(
            categoryId: config.multipleCategoryIds.first,
            categoryName: 'Multi-Category Product',
            allCategoryIds: config.multipleCategoryIds,
          );
        }
        break;

      case CategoryAssignmentStrategyType.hybrid:
        if (categoryValue != null && categoryValue.isNotEmpty) {
          final found = await _findOrCreateCategory(categoryValue, companyId, config);
          if (found != null) return found;
        }
        if (config.fixedCategoryId != null && config.fixedCategoryId!.isNotEmpty) {
          final cat = await categoryRepository.getCategoryById(config.fixedCategoryId!);
          if (cat != null && cat.companyId != companyId) {
            throw TenantIsolationException(
              'Cross-company category assignment violation: Category "${cat.id}" belongs to company "${cat.companyId}", expected "$companyId"',
              expectedCompanyId: companyId,
              attemptedCompanyId: cat.companyId,
            );
          }
          return ResolvedProductCategory(
            categoryId: config.fixedCategoryId!,
            categoryName: config.fixedCategoryName ?? 'Fixed Fallback Category',
          );
        }
        break;

      case CategoryAssignmentStrategyType.fromFile:
        if (categoryValue != null && categoryValue.isNotEmpty) {
          return await _findOrCreateCategory(categoryValue, companyId, config);
        }
        break;
    }

    return null;
  }

  /// Helper to lookup or create a category by name/code/id strictly scoped to [companyId].
  Future<ResolvedProductCategory?> _findOrCreateCategory(
    String term,
    String companyId,
    CategoryAssignmentConfig config,
  ) async {
    final existingCategories = await categoryRepository.getAllCategories();
    final clean = term.toLowerCase().trim();

    for (final cat in existingCategories) {
      if (cat.id.toLowerCase() == clean || cat.code.toLowerCase() == clean || cat.name.toLowerCase() == clean) {
        if (cat.companyId != companyId) {
          throw TenantIsolationException(
            'Cross-company category resolution violation: Category "$term" (${cat.id}) belongs to company "${cat.companyId}", attempted by company "$companyId"',
            expectedCompanyId: companyId,
            attemptedCompanyId: cat.companyId,
          );
        }
        return ResolvedProductCategory(categoryId: cat.id, categoryName: cat.name);
      }
    }

    // Explicit Create-if-missing policy check
    if (config.createIfMissingPolicy) {
      final now = DateTime.now().toUtc();
      final newId = 'CAT-${DateTime.now().microsecondsSinceEpoch}';
      final newCategory = Category(
        id: newId,
        code: 'CAT-${clean.replaceAll(' ', '-').toUpperCase()}',
        name: term,
        warehouseId: config.defaultWarehouseId,
        companyId: companyId,
        createdAt: now,
        updatedAt: now,
      );
      await categoryRepository.saveCategory(newCategory);
      return ResolvedProductCategory(categoryId: newId, categoryName: term);
    }

    throw ProductImportException(
      'Category "$term" not found and CREATE_IF_MISSING policy is disabled.',
      'CATEGORY_NOT_FOUND',
    );
  }

  /// Resolves an Account relation by ID, code, or name strictly scoped to [companyId].
  ResolvedAccount? resolveAccount(dynamic queryTerm, String companyId) {
    if (queryTerm == null) return null;
    final term = queryTerm.toString().trim();
    if (term.isEmpty) return null;

    final clean = term.toLowerCase();

    ResolvedAccount? match;
    if (accountsRegistry.containsKey(term)) {
      match = accountsRegistry[term];
    } else {
      for (final account in accountsRegistry.values) {
        if (account.accountId.toLowerCase() == clean ||
            account.accountCode.toLowerCase() == clean ||
            account.accountName.toLowerCase() == clean) {
          match = account;
          break;
        }
      }
    }

    if (match != null && match.companyId != null && match.companyId != companyId) {
      throw TenantIsolationException(
        'Cross-company account resolution violation: Account "${match.accountCode}" belongs to company "${match.companyId}", attempted by company "$companyId"',
        expectedCompanyId: companyId,
        attemptedCompanyId: match.companyId,
      );
    }

    return match;
  }
}
