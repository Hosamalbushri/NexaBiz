import 'package:stock_count/core/sync/sync_core.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/presentation/providers/cash_register_providers.dart';
import 'cash_registers_sync_handlers.dart';

class CashRegistersSyncRegistrar implements SyncModuleRegistrar {
  const CashRegistersSyncRegistrar();

  @override
  String get moduleId => 'cash_registers';

  @override
  SyncScope get scope => SyncScope.companyOnly;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    final repo = ref.read(cashRegisterRepositoryProvider);
    if (repo is CashRegisterRepositoryImpl) {
      return [
        CashRegisterSyncHandler(
          repository: repo,
          remoteProvider: () => ref.read(remoteSyncApiProvider),
        ),
      ];
    }
    return [];
  }
}
