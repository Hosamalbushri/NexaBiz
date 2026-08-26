import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/settings_repository.dart';
import '../../../../core/database/tenant_database_name.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../../../core/tenancy/session_company.dart';
import '../../../../core/tenancy/tenant_context.dart';
import '../../data/database/inventory_database.dart';
import '../../data/datasources/pdf_barcode_label_printer.dart';
import '../../data/datasources/product_excel_import_datasource.dart';
import '../../data/datasources/thermal_barcode_label_printer.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/models/catalog_search_field.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/product_barcode_generator.dart';
import '../../domain/models/product_item_code_generator.dart';
import '../../domain/repositories/barcode_label_printer.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/services/product_scan_resolver.dart';
import '../../domain/services/product_stock_service.dart';
import '../../domain/usecases/product_usecases.dart';
import '../models/products_view_mode.dart';

final inventoryDatabaseProvider = Provider<InventoryDatabase>((ref) {
  // Keep the DB alive for the process; autoDispose list streams must not
  // close it mid-open or the UI stays on AsyncLoading forever.
  final db = InventoryDatabase(
    name: tenantScopedName(
      'inventory_products',
      ref.watch(sessionCompanyIdProvider),
    ),
  );
  ref.onDispose(db.close);
  ref.keepAlive();
  return db;
});

final productRepositoryImplProvider = Provider<ProductRepositoryImpl>((ref) {
  return ProductRepositoryImpl(
    ref.watch(inventoryDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ref.watch(productRepositoryImplProvider);
});

final productStockServiceProvider = Provider<ProductStockService>((ref) {
  return ProductStockService(ref.watch(productRepositoryProvider));
});

final watchProductsUseCaseProvider = Provider<WatchProducts>((ref) {
  return WatchProducts(ref.watch(productRepositoryProvider));
});

final searchProductsUseCaseProvider = Provider<SearchProducts>((ref) {
  return SearchProducts(ref.watch(productRepositoryProvider));
});

final getProductByIdUseCaseProvider = Provider<GetProductById>((ref) {
  return GetProductById(ref.watch(productRepositoryProvider));
});

final getProductByBarcodeUseCaseProvider = Provider<GetProductByBarcode>((ref) {
  return GetProductByBarcode(ref.watch(productRepositoryProvider));
});

final productScanResolverProvider = Provider<ProductScanResolver>((ref) {
  return ProductScanResolver(ref.watch(productRepositoryProvider));
});

final productBarcodeGeneratorProvider = Provider<ProductBarcodeGenerator>((
  ref,
) {
  return ProductBarcodeGenerator(ref.watch(productRepositoryProvider));
});

final productItemCodeGeneratorProvider = Provider<ProductItemCodeGenerator>((
  ref,
) {
  return ProductItemCodeGenerator(ref.watch(productRepositoryProvider));
});

final barcodeLabelPrinterProvider = Provider<BarcodeLabelPrinter>((ref) {
  return const PdfBarcodeLabelPrinter();
});

/// Future thermal backend — UI reads [BarcodeLabelPrinter.supportsThermal].
final thermalBarcodeLabelPrinterProvider = Provider<BarcodeLabelPrinter>((ref) {
  return const ThermalBarcodeLabelPrinter();
});

final createProductUseCaseProvider = Provider<CreateProduct>((ref) {
  return CreateProduct(ref.watch(productRepositoryProvider));
});

final updateProductUseCaseProvider = Provider<UpdateProduct>((ref) {
  return UpdateProduct(ref.watch(productRepositoryProvider));
});

final deleteProductUseCaseProvider = Provider<DeleteProduct>((ref) {
  return DeleteProduct(ref.watch(productRepositoryProvider));
});

final upsertProductsUseCaseProvider = Provider<UpsertProducts>((ref) {
  return UpsertProducts(ref.watch(productRepositoryProvider));
});

final productExcelImportDatasourceProvider =
    Provider<ProductExcelImportDatasource>((ref) {
      return const ProductExcelImportDatasource();
    });

/// Lightweight invalidation token — avoids reloading the full catalog stream
/// on every products list rebuild / scroll frame.
final productsRevisionProvider = StateProvider<int>((ref) => 0);

void bumpProductsRevision(Ref ref) {
  ref.read(productsRevisionProvider.notifier).state++;
}

void bumpProductsRevisionFromWidget(WidgetRef ref) {
  ref.read(productsRevisionProvider.notifier).state++;
}

/// Full catalog stream — use only where the entire list is needed.
final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(watchProductsUseCaseProvider).call();
});

const int kProductsPageSize = 20;

/// Allowed page sizes for the products catalog list.
const List<int> kProductsPageSizeOptions = [10, 20, 30, 50];

final productSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final productSearchFieldProvider =
    StateProvider.autoDispose<CatalogSearchField>(
      (ref) => CatalogSearchField.all,
    );

final productSearchPageIndexProvider = StateProvider.autoDispose<int>(
  (ref) => 0,
);

final productPageSizeProvider = StateProvider.autoDispose<int>(
  (ref) => kProductsPageSize,
);

/// One page of catalog results (SQL limit/offset).
final pagedProductsProvider = FutureProvider.autoDispose<PagedResult<Product>>((
  ref,
) async {
  ref.watch(productsRevisionProvider);

  final page = ref.watch(productSearchPageIndexProvider);
  final pageSize = ref.watch(productPageSizeProvider);
  final query = ref.watch(productSearchQueryProvider);
  final searchField = ref.watch(productSearchFieldProvider);

  return ref
      .read(productRepositoryProvider)
      .getPaged(
        page: page,
        pageSize: pageSize,
        query: query,
        searchField: searchField,
      );
});

final productByIdProvider = FutureProvider.autoDispose.family<Product?, int>((
  ref,
  id,
) {
  return ref.watch(getProductByIdUseCaseProvider).call(id);
});

final productsViewModeProvider =
    StateNotifierProvider<
      ProductsViewModeController,
      AsyncValue<ProductsViewMode>
    >((ref) {
      return ProductsViewModeController(
        repository: ref.watch(settingsRepositoryProvider),
      );
    });

class ProductsViewModeController
    extends StateNotifier<AsyncValue<ProductsViewMode>> {
  ProductsViewModeController({required SettingsRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    state = await AsyncValue.guard(() async {
      final stored = await _repository.loadProductsViewMode();
      return ProductsViewMode.fromStorage(stored);
    });
  }

  Future<void> setMode(ProductsViewMode mode) async {
    state = AsyncValue.data(mode);
    await _repository.saveProductsViewMode(mode.storageValue);
  }
}
