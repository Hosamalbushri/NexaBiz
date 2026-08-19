import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../presentation/providers/inventory_providers.dart';
import '../../presentation/providers/product_providers.dart';
import 'inventory_sync_handlers.dart';

/// Registers Inventory sync adapters with the shared [SyncManager].
void registerInventorySyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  manager.registerHandler(
    ProductSyncHandler(
      repository: ref.read(productRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
  manager.registerHandler(
    InventoryItemSyncHandler(
      repository: ref.read(inventoryRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
}
