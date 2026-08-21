import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/bootstrap/module_bootstrap.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/router/app_navigator_keys.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/theme/app_theme.dart';
import 'package:stock_count/modules/inventory/domain/entities/inventory_item.dart';
import 'package:stock_count/modules/inventory/domain/entities/item_status.dart';
import 'package:stock_count/modules/inventory/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/domain/entities/report_summary.dart';
import 'package:stock_count/modules/inventory/domain/models/paged_result.dart';
import 'package:stock_count/modules/inventory/domain/models/catalog_search_field.dart';
import 'package:stock_count/modules/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_count/modules/inventory/domain/repositories/product_repository.dart';
import 'package:stock_count/modules/inventory/inventory_module.dart';
import 'package:stock_count/modules/inventory/presentation/pages/inventory_home_page.dart';
import 'package:stock_count/modules/inventory/presentation/pages/inventory_routes.dart';
import 'package:stock_count/modules/inventory/presentation/pages/products_barcode_page.dart';
import 'package:stock_count/modules/inventory/presentation/pages/products_home_page.dart';
import 'package:stock_count/modules/inventory/presentation/pages/products_list_page.dart';
import 'package:stock_count/modules/inventory/presentation/providers/inventory_providers.dart';
import 'package:stock_count/modules/inventory/presentation/providers/product_providers.dart';

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<List<InventoryItem>> getAll() async => const [];

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(const []);

  @override
  Future<InventoryItem?> getByCode(String itemCode) async => null;

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
  Future<List<InventoryItem>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async => const [];

  @override
  Future<List<InventoryItem>> filterByStatus(ItemStatus? status) async =>
      const [];

  @override
  Future<int> countAll() async => 0;

  @override
  Future<ReportSummary> getReportSummary() async => const ReportSummary.empty();

  @override
  Future<PagedResult<InventoryItem>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    ItemStatus? status,
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async {
    return PagedResult<InventoryItem>(
      items: const [],
      totalCount: 0,
      page: page,
      pageSize: pageSize,
    );
  }
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getAll() async => const [];

  @override
  Stream<List<Product>> watchAll() => Stream.value(const []);

  @override
  Future<Product?> getById(int id) async => null;

  @override
  Future<Product?> getByItemCode(String itemCode) async => null;

  @override
  Future<Product?> getByUuid(String uuid) async => null;

  @override
  Future<Product?> getByBarcode(String barcode) async => null;

  @override
  Future<List<Product>> search(
    String query, {
    CatalogSearchField searchField = CatalogSearchField.all,
    int? limit,
  }) async => const [];

  @override
  Future<PagedResult<Product>> getPaged({
    required int page,
    required int pageSize,
    String query = '',
    CatalogSearchField searchField = CatalogSearchField.all,
  }) async {
    return PagedResult<Product>(
      items: const [],
      totalCount: 0,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Product> insert(ProductDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<Product> update(int id, ProductDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(int id) async {}

  @override
  Future<ProductUpsertResult> upsertAll(
    List<ProductDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) async {
    return const ProductUpsertResult(insertedCount: 0, updatedCount: 0);
  }

  @override
  Future<Product> adjustOnHandByUuid({
    required String uuid,
    required double delta,
  }) =>
      throw UnimplementedError();
}

class _FakeSettingsRepository extends SettingsRepository {
  List<String>? inventoryIds;
  String productsViewMode = 'list';

  @override
  Future<List<String>?> loadInventoryServiceIds() async => inventoryIds;

  @override
  Future<void> saveInventoryServiceIds(List<String> ids) async {
    inventoryIds = ids;
  }

  @override
  Future<List<String>?> loadDashboardServiceIds() async => const [];

  @override
  Future<void> saveDashboardServiceIds(List<String> ids) async {}

  @override
  Future<String> loadProductsViewMode() async => productsViewMode;

  @override
  Future<void> saveProductsViewMode(String mode) async {
    productsViewMode = mode;
  }

  @override
  Future<List<String>?> loadQuickActionIds() async => null;

  @override
  Future<void> saveQuickActionIds(List<String> ids) async {}
}

void main() {
  GoRouter buildRouter({String initialLocation = InventoryRoutes.root}) {
    const module = InventoryModule();
    return GoRouter(
      navigatorKey: appRootNavigatorKey,
      initialLocation: initialLocation,
      routes: module.routes,
    );
  }

  Widget wrap(GoRouter router) {
    return ProviderScope(
      overrides: [
        ...moduleRegistryOverrides(),
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        inventoryRepositoryProvider.overrideWithValue(
          _FakeInventoryRepository(),
        ),
        inventoryItemsProvider.overrideWith((ref) => Stream.value(const [])),
        productRepositoryProvider.overrideWithValue(_FakeProductRepository()),
        productsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(hours: 1));
  }

  testWidgets('inventory hub shows products service card', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    expect(find.byType(InventoryHomePage), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Stock count'), findsOneWidget);
  });

  testWidgets('opening products hub shows list import and barcode cards', (
    tester,
  ) async {
    final router = buildRouter(initialLocation: InventoryRoutes.products);
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    expect(find.byType(ProductsHomePage), findsOneWidget);
    expect(find.text('Product list'), findsOneWidget);
    expect(find.text('Barcodes'), findsOneWidget);
    expect(find.text('Import products'), findsOneWidget);
  });

  testWidgets('products barcode route opens barcode page', (tester) async {
    final router = buildRouter(
      initialLocation: InventoryRoutes.productsBarcode,
    );
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    expect(find.byType(ProductsBarcodePage), findsOneWidget);
    expect(find.text('Search or scan to select a product.'), findsOneWidget);
  });

  testWidgets('products list route opens list page', (tester) async {
    final router = buildRouter(initialLocation: InventoryRoutes.productsList);
    await tester.pumpWidget(wrap(router));
    await settle(tester);

    expect(find.byType(ProductsListPage), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);
  });
}
