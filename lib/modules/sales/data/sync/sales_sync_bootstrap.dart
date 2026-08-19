import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../presentation/providers/sale_providers.dart';
import 'sales_sync_handlers.dart';

/// Registers Sales sync adapters with the shared [SyncManager].
void registerSalesSyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  manager.registerHandler(
    SaleSyncHandler(
      repository: ref.read(saleRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
}
