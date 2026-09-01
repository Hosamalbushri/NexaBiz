import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_ledger_posting_port.dart';

import 'accounting_rp_ledger_adapter.dart';

/// App-level ledger posting port for Receipts & Payments.
final appRpLedgerPostingPortProvider = Provider<RpLedgerPostingPort>((ref) {
  final journalPostingService = ref.watch(journalPostingServiceProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  final fiscalYearRepo = ref.watch(fiscalYearRepositoryProvider);

  return AccountingRpLedgerAdapter(
    posting: journalPostingService,
    accounts: accountRepo,
    fiscalYears: fiscalYearRepo,
  );
});
