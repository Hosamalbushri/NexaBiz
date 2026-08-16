import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../presentation/providers/rp_providers.dart';
import 'receipts_payments_sync_handlers.dart';

void registerReceiptsPaymentsSyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  manager.registerHandler(
    FinancialTransactionSyncHandler(
      repository: ref.read(financialTransactionRepositoryImplProvider),
      remote: ref.read(remoteSyncApiProvider),
    ),
  );
}
