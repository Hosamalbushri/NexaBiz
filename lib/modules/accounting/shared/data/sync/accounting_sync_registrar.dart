import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../presentation/providers/currency_rate_providers.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'accounting_sync_handlers.dart';

class AccountingSyncRegistrar implements SyncModuleRegistrar {
  const AccountingSyncRegistrar();

  @override
  String get moduleId => 'accounting';

  @override
  SyncScope get scope => SyncScope.companyOnly;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    return [
      AccountSyncHandler(
        repository: ref.read(accountRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
      JournalSyncHandler(
        repository: ref.read(journalRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
      CurrencyRateSyncHandler(
        repository: ref.read(currencyRateRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
      FiscalYearSyncHandler(
        repository: ref.read(fiscalYearRepositoryImplProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
    ];
  }
}
