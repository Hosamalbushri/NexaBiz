import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../presentation/providers/customer_providers.dart';
import 'customers_sync_handlers.dart';

/// Registers Customers sync adapters with the shared [SyncManager].
void registerCustomersSyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  final remote = ref.read(remoteSyncApiProvider);
  manager.registerHandler(
    CustomerSyncHandler(
      repository: ref.read(customerRepositoryImplProvider),
      remote: remote,
    ),
  );
}
