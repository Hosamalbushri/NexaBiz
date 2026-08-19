import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../presentation/providers/account_providers.dart';
import '../../presentation/providers/currency_rate_providers.dart';
import '../../presentation/providers/journal_providers.dart';
import 'accounting_sync_handlers.dart';

/// Registers Accounting sync adapters with the shared [SyncManager].
void registerAccountingSyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  manager.registerHandler(
    AccountSyncHandler(
      repository: ref.read(accountRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
  manager.registerHandler(
    JournalSyncHandler(
      repository: ref.read(journalRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
  manager.registerHandler(
    CurrencyRateSyncHandler(
      repository: ref.read(currencyRateRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
  manager.registerHandler(
    FiscalYearSyncHandler(
      repository: ref.read(fiscalYearRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
}
