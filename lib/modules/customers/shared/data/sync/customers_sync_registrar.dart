import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/customers/directory/presentation/providers/customer_providers.dart';
import 'customers_sync_handlers.dart';

class CustomersSyncRegistrar implements SyncModuleRegistrar {
  const CustomersSyncRegistrar({
    this.ensureLinkedAccount,
  });

  final Future<void> Function(Map<String, dynamic> payload)? ensureLinkedAccount;

  @override
  String get moduleId => 'customers';

  @override
  SyncScope get scope => SyncScope.companyOnly;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    return [
      CustomerSyncHandler(
        repository: ref.read(customerRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
        ensureLinkedAccount: ensureLinkedAccount,
      ),
    ];
  }
}
