import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../presentation/providers/account_providers.dart';
import 'accounting_sync_handlers.dart';

/// Registers Accounting sync adapters with the shared [SyncManager].
void registerAccountingSyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  final remote = ref.read(remoteSyncApiProvider);
  manager.registerHandler(
    AccountSyncHandler(
      repository: ref.read(accountRepositoryImplProvider),
      remote: remote,
    ),
  );
}
