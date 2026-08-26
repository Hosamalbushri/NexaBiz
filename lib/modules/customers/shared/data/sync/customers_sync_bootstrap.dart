import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/customers/directory/presentation/providers/customer_providers.dart';
import 'customers_sync_handlers.dart';

/// Registers Customers sync adapters with the shared [SyncManager].
///
/// [ensureLinkedAccount] is optional App wiring so remote customers get a
/// Chart of Accounts posting account under this device's customers parent.
void registerCustomersSyncHandlers(
  Ref ref, {
  Future<void> Function(Map<String, dynamic> payload)? ensureLinkedAccount,
}) {
  final manager = ref.read(syncManagerProvider);
  manager.registerHandler(
    CustomerSyncHandler(
      repository: ref.read(customerRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
      ensureLinkedAccount: ensureLinkedAccount,
    ),
  );
}
