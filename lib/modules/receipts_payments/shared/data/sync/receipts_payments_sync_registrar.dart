import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/providers/rp_providers.dart';
import 'receipts_payments_sync_handlers.dart';

class ReceiptsPaymentsSyncRegistrar implements SyncModuleRegistrar {
  const ReceiptsPaymentsSyncRegistrar();

  @override
  String get moduleId => 'receipts_payments';

  @override
  SyncScope get scope => SyncScope.companyOnly;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    return [
      FinancialTransactionSyncHandler(
        repository: ref.read(financialTransactionRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
    ];
  }
}
