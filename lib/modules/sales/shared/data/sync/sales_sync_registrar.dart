import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/sales/invoices/presentation/providers/sale_providers.dart';
import 'sales_sync_handlers.dart';

class SalesSyncRegistrar implements SyncModuleRegistrar {
  const SalesSyncRegistrar();

  @override
  String get moduleId => 'sales';

  @override
  SyncScope get scope => SyncScope.companyOnly;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    return [
      SaleSyncHandler(
        repository: ref.read(saleRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
    ];
  }
}
