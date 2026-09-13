import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

/// Single canonical repository interface for Master Data persistence in `nexabiz.sqlite`.
abstract class CanonicalMasterDataRepository {
  // Currencies
  Future<CurrencyData> createCurrency(CurrenciesCompanion currency);
  Future<List<CurrencyData>> getCurrencies(String? companyId);
  Future<CurrencyData?> getCurrencyByCode(String code, {String? companyId});

  // Product Categories
  Future<ProductCategoryData> createCategory(ProductCategoriesCompanion category);
  Future<List<ProductCategoryData>> getCategories(String companyId);
  Future<ProductCategoryData?> getCategoryByUuid(String uuid, String companyId);

  // Warehouses
  Future<WarehouseData> createWarehouse(WarehousesCompanion warehouse);
  Future<List<WarehouseData>> getWarehouses(String companyId);
  Future<WarehouseData?> getWarehouseByUuid(String uuid, String companyId);

  // Accounts (Chart of Accounts)
  Future<AccountData> createAccount(AccountsCompanion account);
  Future<List<AccountData>> getAccounts(String companyId);
  Future<AccountData?> getAccountByUuid(String uuid, String companyId);

  // Products
  Future<ProductData> createProduct(ProductsCompanion product);
  Future<List<ProductData>> getProducts(String companyId);
  Future<ProductData?> getProductByUuid(String uuid, String companyId);

  // Customers
  Future<CustomerData> createCustomer(CustomersCompanion customer);
  Future<List<CustomerData>> getCustomers(String companyId);
  Future<CustomerData?> getCustomerByUuid(String uuid, String companyId);

  // Cash Registers
  Future<CashRegisterData> createCashRegister(CashRegistersCompanion cashRegister);
  Future<List<CashRegisterData>> getCashRegisters(String companyId);
  Future<CashRegisterData?> getCashRegisterByUuid(String uuid, String companyId);

  // Voucher Books
  Future<VoucherBookData> createVoucherBook(VoucherBooksCompanion voucherBook);
  Future<List<VoucherBookData>> getVoucherBooks(String companyId);
  Future<VoucherBookData?> getVoucherBookByUuid(String uuid, String companyId);
}

/// Drift implementation of [CanonicalMasterDataRepository] operating on [NexabizDatabase].
class CanonicalMasterDataRepositoryImpl implements CanonicalMasterDataRepository {
  CanonicalMasterDataRepositoryImpl(this._db);

  final NexabizDatabase _db;

  void _verifyCompanyId(String? companyId, String entityName) {
    if (companyId == null || companyId.trim().isEmpty) {
      throw ArgumentError('$entityName operations require an explicit non-empty companyId.');
    }
  }

  // --- Currencies ---
  @override
  Future<CurrencyData> createCurrency(CurrenciesCompanion currency) async {
    final id = currency.id.present ? currency.id.value : generateUuidV7();
    final companion = currency.copyWith(id: Value(id));
    return _db.into(_db.currencies).insertReturning(companion);
  }

  @override
  Future<List<CurrencyData>> getCurrencies(String? companyId) {
    if (companyId == null || companyId.isEmpty) {
      return (_db.select(_db.currencies)..where((tbl) => tbl.companyId.isNull())).get();
    }
    return (_db.select(_db.currencies)
          ..where((tbl) => tbl.companyId.equals(companyId) | tbl.companyId.isNull()))
        .get();
  }

  @override
  Future<CurrencyData?> getCurrencyByCode(String code, {String? companyId}) {
    final query = _db.select(_db.currencies)..where((tbl) => tbl.currencyCode.equals(code));
    if (companyId != null && companyId.isNotEmpty) {
      query.where((tbl) => tbl.companyId.equals(companyId) | tbl.companyId.isNull());
    }
    return query.getSingleOrNull();
  }

  // --- Product Categories ---
  @override
  Future<ProductCategoryData> createCategory(ProductCategoriesCompanion category) async {
    final companyId = category.companyId.value;
    _verifyCompanyId(companyId, 'ProductCategory');

    final parentUuid = category.parentCategoryId.present ? category.parentCategoryId.value : null;
    final id = category.id.present ? category.id.value : generateUuidV7();

    if (parentUuid != null) {
      if (parentUuid == id) {
        throw ArgumentError('Self-parenting is prohibited for category $id.');
      }
      final parent = await getCategoryByUuid(parentUuid, companyId);
      if (parent == null) {
        throw ArgumentError('Parent category $parentUuid does not exist for company $companyId.');
      }
    }

    final companion = category.copyWith(id: Value(id));
    return _db.into(_db.productCategories).insertReturning(companion);
  }

  @override
  Future<List<ProductCategoryData>> getCategories(String companyId) {
    _verifyCompanyId(companyId, 'ProductCategory');
    return (_db.select(_db.productCategories)
          ..where((tbl) => tbl.companyId.equals(companyId) & tbl.isActive.equals(true)))
        .get();
  }

  @override
  Future<ProductCategoryData?> getCategoryByUuid(String uuid, String companyId) {
    _verifyCompanyId(companyId, 'ProductCategory');
    return (_db.select(_db.productCategories)
          ..where((tbl) => tbl.id.equals(uuid) & tbl.companyId.equals(companyId)))
        .getSingleOrNull();
  }

  // --- Warehouses ---
  @override
  Future<WarehouseData> createWarehouse(WarehousesCompanion warehouse) async {
    final companyId = warehouse.companyId.value;
    _verifyCompanyId(companyId, 'Warehouse');

    final id = warehouse.id.present ? warehouse.id.value : generateUuidV7();
    final companion = warehouse.copyWith(id: Value(id));
    return _db.into(_db.warehouses).insertReturning(companion);
  }

  @override
  Future<List<WarehouseData>> getWarehouses(String companyId) {
    _verifyCompanyId(companyId, 'Warehouse');
    return (_db.select(_db.warehouses)
          ..where((tbl) => tbl.companyId.equals(companyId) & tbl.isActive.equals(true)))
        .get();
  }

  @override
  Future<WarehouseData?> getWarehouseByUuid(String uuid, String companyId) {
    _verifyCompanyId(companyId, 'Warehouse');
    return (_db.select(_db.warehouses)
          ..where((tbl) => tbl.id.equals(uuid) & tbl.companyId.equals(companyId)))
        .getSingleOrNull();
  }

  // --- Accounts (Chart of Accounts) ---
  @override
  Future<AccountData> createAccount(AccountsCompanion account) async {
    final companyId = account.companyId.value;
    _verifyCompanyId(companyId, 'Account');

    final parentUuid = account.parentAccountId.present ? account.parentAccountId.value : null;
    final id = account.id.present ? account.id.value : generateUuidV7();

    if (parentUuid != null) {
      if (parentUuid == id) {
        throw ArgumentError('Self-parenting is prohibited for account $id.');
      }
      final parent = await getAccountByUuid(parentUuid, companyId);
      if (parent == null) {
        throw ArgumentError('Parent account $parentUuid does not exist for company $companyId.');
      }
    }

    final companion = account.copyWith(id: Value(id));
    return _db.into(_db.accounts).insertReturning(companion);
  }

  @override
  Future<List<AccountData>> getAccounts(String companyId) {
    _verifyCompanyId(companyId, 'Account');
    return (_db.select(_db.accounts)
          ..where((tbl) => tbl.companyId.equals(companyId) & tbl.isActive.equals(true)))
        .get();
  }

  @override
  Future<AccountData?> getAccountByUuid(String uuid, String companyId) {
    _verifyCompanyId(companyId, 'Account');
    return (_db.select(_db.accounts)
          ..where((tbl) => tbl.id.equals(uuid) & tbl.companyId.equals(companyId)))
        .getSingleOrNull();
  }

  // --- Products ---
  @override
  Future<ProductData> createProduct(ProductsCompanion product) async {
    final companyId = product.companyId.value;
    _verifyCompanyId(companyId, 'Product');

    final categoryUuid = product.categoryId.present ? product.categoryId.value : null;
    if (categoryUuid != null) {
      final category = await getCategoryByUuid(categoryUuid, companyId);
      if (category == null) {
        throw ArgumentError('Category $categoryUuid does not exist for company $companyId.');
      }
    }

    final id = product.id.present ? product.id.value : generateUuidV7();
    final companion = product.copyWith(id: Value(id));
    return _db.into(_db.products).insertReturning(companion);
  }

  @override
  Future<List<ProductData>> getProducts(String companyId) {
    _verifyCompanyId(companyId, 'Product');
    return (_db.select(_db.products)
          ..where((tbl) => tbl.companyId.equals(companyId) & tbl.isActive.equals(true)))
        .get();
  }

  @override
  Future<ProductData?> getProductByUuid(String uuid, String companyId) {
    _verifyCompanyId(companyId, 'Product');
    return (_db.select(_db.products)
          ..where((tbl) => tbl.id.equals(uuid) & tbl.companyId.equals(companyId)))
        .getSingleOrNull();
  }

  // --- Customers ---
  @override
  Future<CustomerData> createCustomer(CustomersCompanion customer) async {
    final companyId = customer.companyId.value;
    _verifyCompanyId(companyId, 'Customer');

    final accountUuid = customer.accountId.present ? customer.accountId.value : null;
    if (accountUuid != null) {
      final account = await getAccountByUuid(accountUuid, companyId);
      if (account == null) {
        throw ArgumentError('AR Account $accountUuid does not exist for company $companyId.');
      }
    }

    final id = customer.id.present ? customer.id.value : generateUuidV7();
    final companion = customer.copyWith(id: Value(id));
    return _db.into(_db.customers).insertReturning(companion);
  }

  @override
  Future<List<CustomerData>> getCustomers(String companyId) {
    _verifyCompanyId(companyId, 'Customer');
    return (_db.select(_db.customers)
          ..where((tbl) => tbl.companyId.equals(companyId) & tbl.status.equals('active')))
        .get();
  }

  @override
  Future<CustomerData?> getCustomerByUuid(String uuid, String companyId) {
    _verifyCompanyId(companyId, 'Customer');
    return (_db.select(_db.customers)
          ..where((tbl) => tbl.id.equals(uuid) & tbl.companyId.equals(companyId)))
        .getSingleOrNull();
  }

  // --- Cash Registers ---
  @override
  Future<CashRegisterData> createCashRegister(CashRegistersCompanion cashRegister) async {
    final companyId = cashRegister.companyId.value;
    _verifyCompanyId(companyId, 'CashRegister');

    final accountUuid = cashRegister.accountId.present ? cashRegister.accountId.value : null;
    if (accountUuid != null) {
      final account = await getAccountByUuid(accountUuid, companyId);
      if (account == null) {
        throw ArgumentError('Treasury Account $accountUuid does not exist for company $companyId.');
      }
    }

    final id = cashRegister.id.present ? cashRegister.id.value : generateUuidV7();
    final companion = cashRegister.copyWith(id: Value(id));
    return _db.into(_db.cashRegisters).insertReturning(companion);
  }

  @override
  Future<List<CashRegisterData>> getCashRegisters(String companyId) {
    _verifyCompanyId(companyId, 'CashRegister');
    return (_db.select(_db.cashRegisters)
          ..where((tbl) => tbl.companyId.equals(companyId) & tbl.isActive.equals(true)))
        .get();
  }

  @override
  Future<CashRegisterData?> getCashRegisterByUuid(String uuid, String companyId) {
    _verifyCompanyId(companyId, 'CashRegister');
    return (_db.select(_db.cashRegisters)
          ..where((tbl) => tbl.id.equals(uuid) & tbl.companyId.equals(companyId)))
        .getSingleOrNull();
  }

  // --- Voucher Books ---
  @override
  Future<VoucherBookData> createVoucherBook(VoucherBooksCompanion voucherBook) async {
    final companyId = voucherBook.companyId.value;
    _verifyCompanyId(companyId, 'VoucherBook');

    final parentUuid = voucherBook.parentBookId.present ? voucherBook.parentBookId.value : null;
    final id = voucherBook.id.present ? voucherBook.id.value : generateUuidV7();

    if (parentUuid != null) {
      if (parentUuid == id) {
        throw ArgumentError('Self-parenting is prohibited for voucher book $id.');
      }
      final parent = await getVoucherBookByUuid(parentUuid, companyId);
      if (parent == null) {
        throw ArgumentError('Parent voucher book $parentUuid does not exist for company $companyId.');
      }
    }

    final companion = voucherBook.copyWith(id: Value(id));
    return _db.into(_db.voucherBooks).insertReturning(companion);
  }

  @override
  Future<List<VoucherBookData>> getVoucherBooks(String companyId) {
    _verifyCompanyId(companyId, 'VoucherBook');
    return (_db.select(_db.voucherBooks)
          ..where((tbl) => tbl.companyId.equals(companyId) & tbl.isActive.equals(true)))
        .get();
  }

  @override
  Future<VoucherBookData?> getVoucherBookByUuid(String uuid, String companyId) {
    _verifyCompanyId(companyId, 'VoucherBook');
    return (_db.select(_db.voucherBooks)
          ..where((tbl) => tbl.id.equals(uuid) & tbl.companyId.equals(companyId)))
        .getSingleOrNull();
  }
}
