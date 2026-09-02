import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/inventory/stock_count/presentation/providers/inventory_providers.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/providers/stock_movements_providers.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_context_providers.dart';
import 'inventory_sync_handlers.dart';

class InventorySyncRegistrar implements SyncModuleRegistrar {
  const InventorySyncRegistrar();

  @override
  String get moduleId => 'inventory';

  @override
  SyncScope get scope => SyncScope.companyOnly;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    final db = ref.read(inventoryDatabaseProvider);
    final coordinator = ref.read(postingCoordinatorProvider);
    final engine = ref.read(postingEngineProvider);
    String companyIdReader() => ref.read(authorizationContextProvider).companyId;

    final handlers = <SyncEntityHandler>[
      ProductSyncHandler(
        repository: ref.read(productRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
      InventoryItemSyncHandler(
        repository: ref.read(inventoryRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
    ];

    for (final docType in [
      'stock_receipt',
      'stock_issue',
      'stock_transfer',
      'stock_return',
      'inventory_reversal',
    ]) {
      handlers.add(
        InventoryDocumentSyncHandler(
          entityType: docType,
          remoteProvider: () => ref.read(remoteSyncApiProvider),
          db: db,
          postingCoordinator: coordinator,
          postingEngine: engine,
          readCompanyId: companyIdReader,
        ),
      );
    }

    return handlers;
  }
}
