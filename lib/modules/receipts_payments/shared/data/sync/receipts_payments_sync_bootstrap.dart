import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/providers/rp_providers.dart';
import 'receipts_payments_sync_handlers.dart';

void registerReceiptsPaymentsSyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  manager.registerHandler(
    FinancialTransactionSyncHandler(
      repository: ref.read(financialTransactionRepositoryImplProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
}
