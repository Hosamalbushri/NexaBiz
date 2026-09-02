import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/inventory/accounting_inventory_account_adapter.dart';
import 'package:stock_count/app/inventory/accounting_inventory_voucher_book_adapter.dart';
import 'package:stock_count/app/inventory/inventory_accounting_poster_adapter.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/accounting/voucher_books/presentation/providers/voucher_book_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_account_port.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_voucher_book_port.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';

import 'package:stock_count/core/domain/ports/period_validator_port.dart';

/// App-level provider that bridges InventoryVoucherBookPort to Accounting implementation.
final appInventoryVoucherBookPortProvider = Provider<InventoryVoucherBookPort>((ref) {
  final repo = ref.watch(voucherBookRepositoryProvider);
  final deviceId = ref.watch(syncApiConfigProvider).deviceId;
  return AccountingInventoryVoucherBookAdapter(repo, deviceId: deviceId);
});

/// App-level provider that bridges InventoryAccountPort to Accounting implementation.
final appInventoryAccountPortProvider = Provider<InventoryAccountPort>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return AccountingInventoryAccountAdapter(repo);
});

/// App-level provider that bridges InventoryAccountingPoster to Accounting implementation.
final appInventoryAccountingPosterProvider = Provider<InventoryAccountingPoster>((ref) {
  final db = ref.watch(accountingDatabaseProvider);
  final postingService = ref.watch(journalPostingServiceProvider);
  final initRepo = ref.watch(companyInitializationRepositoryProvider);
  return InventoryAccountingPosterAdapter(
    db,
    journalPostingService: postingService,
    readCompanyId: () => ref.read(currentCompanyIdProvider),
    initRepository: initRepo,
  );
});

/// App-level provider that bridges PeriodValidatorPort to AccountingPeriodValidator.
final appPeriodValidatorPortProvider = Provider<PeriodValidatorPort>((ref) {
  return ref.watch(accountingPeriodValidatorProvider);
});

