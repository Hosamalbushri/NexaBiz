import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/customers/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/domain/entities/customer_data_source.dart';
import 'package:stock_count/modules/customers/domain/models/import_session.dart';
import 'package:stock_count/modules/customers/domain/repositories/customer_repository.dart';
import 'package:stock_count/modules/customers/domain/usecases/customer_usecases.dart';
import 'package:stock_count/modules/customers/permissions/customers_permission_package.dart';
import 'package:stock_count/modules/inventory/domain/entities/inventory_item.dart';
import 'package:stock_count/modules/inventory/domain/entities/item_status.dart';
import 'package:stock_count/modules/inventory/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/domain/entities/report_summary.dart';
import 'package:stock_count/modules/inventory/domain/models/catalog_search_field.dart';
import 'package:stock_count/modules/inventory/domain/models/paged_result.dart';
import 'package:stock_count/modules/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_count/modules/inventory/domain/repositories/product_repository.dart';
import 'package:stock_count/modules/inventory/domain/usecases/inventory_usecases.dart';
import 'package:stock_count/modules/inventory/domain/usecases/product_usecases.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';

class _FakeProductRepository implements ProductRepository {
  @override
  Future<Product> insert(ProductDraft draft) async {
    return Product(
      id: 1,
      uuid: '00000000-0000-4000-8000-000000000001',
      itemCode: draft.itemCode,
      name: draft.name,
      packSize: draft.packSize,
      price: draft.price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Product> update(int id, ProductDraft draft) async {
    return Product(
      id: id,
      uuid: '00000000-0000-4000-8000-000000000001',
      itemCode: draft.itemCode,
      name: draft.name,
      packSize: draft.packSize,
      price: draft.price,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> delete(int id) async {}

  @override
  Future<ProductUpsertResult> upsertAll(
    List<ProductDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) async =>
      const ProductUpsertResult(insertedCount: 1, updatedCount: 0);

  @override
  Future<Product> adjustOnHandByUuid({required String uuid, required double delta}) =>
      throw UnimplementedError();

  @override
  Future<List<Product>> getAll() async => const [];
  @override
  Future<Product?> getByBarcode(String barcode) async => null;
  @override
  Future<Product?> getById(int id) async => null;
  @override
  Future<Product?> getByItemCode(String itemCode) async => null;
  @override
  Future<Product?> getByUuid(String uuid) async => null;
  @override
  Future<PagedResult<Product>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async => PagedResult(items: const [], totalCount: 0, page: page, pageSize: pageSize);
  @override
  Future<List<Product>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
    int? limit,
  }) async => const [];
  @override
  Stream<List<Product>> watchAll() => Stream.value(const []);
}

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<void> save(InventoryItem item) async {}
  @override
  Future<void> replaceAll(
    List<InventoryItem> items, {
    void Function(int processed, int total)? onProgress,
  }) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<int> countAll() async => 0;
  @override
  Future<List<InventoryItem>> filterByStatus(ItemStatus? status) async => const [];
  @override
  Future<List<InventoryItem>> getAll() async => const [];
  @override
  Future<InventoryItem?> getByCode(String itemCode) async => null;
  @override
  Future<PagedResult<InventoryItem>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    ItemStatus? status,
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async => PagedResult(items: const [], totalCount: 0, page: page, pageSize: pageSize);
  @override
  Future<ReportSummary> getReportSummary() async => const ReportSummary.empty();
  @override
  Future<List<InventoryItem>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async => const [];
  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(const []);
}

class _FakeCustomerRepository implements CustomerRepository {
  @override
  Future<Customer> insert(CustomerDraft draft) async {
    return Customer(
      id: 1,
      uuid: '00000000-0000-4000-8000-000000000002',
      customerCode: draft.customerCode,
      name: draft.name,
      isActive: true,
      dataSource: CustomerDataSource.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Customer> update(int id, CustomerDraft draft) async {
    return Customer(
      id: id,
      uuid: '00000000-0000-4000-8000-000000000002',
      customerCode: draft.customerCode,
      name: draft.name,
      isActive: true,
      dataSource: CustomerDataSource.local,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<Customer> upsertFromExternal(CustomerDraft draft) async => insert(draft);

  @override
  Future<CustomerUpsertResult> upsertAll(
    List<CustomerDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) async => const CustomerUpsertResult(insertedCount: 1, updatedCount: 0);

  @override
  Future<List<Customer>> getAll({bool includeInactive = false}) async => const [];
  @override
  Future<Customer?> getByCustomerCode(String customerCode) async => null;
  @override
  Future<Customer?> getByExternalId(String externalId) async => null;
  @override
  Future<Customer?> getById(int id) async => null;
  @override
  Future<Customer?> getByUuid(String uuid) async => null;
  @override
  Future<PagedResult<Customer>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    bool includeInactive = false,
  }) async => PagedResult(items: const [], totalCount: 0, page: page, pageSize: pageSize);
  @override
  Future<List<Customer>> search(String query, {bool includeInactive = false, int? limit}) async => const [];
  @override
  Stream<List<Customer>> watchAll({bool includeInactive = false}) => Stream.value(const []);
}

void main() {
  final denyAllGuard = CallbackPermissionGuard((codes) => false);
  final allowProductCreateGuard = CallbackPermissionGuard(
    (codes) => codes.any((c) => InventoryPermissions.productsCreate.contains(c)),
  );
  final allowCustomerCreateGuard = CallbackPermissionGuard(
    (codes) => codes.any((c) => CustomersPermissions.create.contains(c)),
  );

  final productRepo = _FakeProductRepository();
  final inventoryRepo = _FakeInventoryRepository();
  final customerRepo = _FakeCustomerRepository();

  group('Inventory Domain Permission Enforcement', () {
    test('CreateProduct throws PermissionDeniedException when permission missing', () async {
      final create = CreateProduct(productRepo, permissionGuard: denyAllGuard);
      await expectLater(
        create(const ProductDraft(itemCode: 'ITEM-1', name: 'Product 1', packSize: 1, price: 10.0)),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('CreateProduct succeeds when permission granted', () async {
      final create = CreateProduct(productRepo, permissionGuard: allowProductCreateGuard);
      final result = await create(const ProductDraft(itemCode: 'ITEM-1', name: 'Product 1', packSize: 1, price: 10.0));
      expect(result.itemCode, 'ITEM-1');
    });

    test('SaveInventoryCount throws PermissionDeniedException when permission missing', () async {
      final save = SaveInventoryCount(inventoryRepo, permissionGuard: denyAllGuard);
      await expectLater(
        save(InventoryItem(itemCode: 'ITEM-1', itemName: 'Product 1', systemQuantity: 10)),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('Customers Domain Permission Enforcement', () {
    test('CreateCustomer throws PermissionDeniedException when permission missing', () async {
      final create = CreateCustomer(customerRepo, permissionGuard: denyAllGuard);
      await expectLater(
        create(const CustomerDraft(customerCode: 'CUST-1', name: 'Customer 1')),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('CreateCustomer succeeds when permission granted', () async {
      final create = CreateCustomer(customerRepo, permissionGuard: allowCustomerCreateGuard);
      final result = await create(const CustomerDraft(customerCode: 'CUST-1', name: 'Customer 1'));
      expect(result.customerCode, 'CUST-1');
    });
  });
}
