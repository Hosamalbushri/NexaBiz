import 'dart:async';

import '../../app/settings/settings_repository.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/voucher_books/domain/repositories/voucher_book_repository.dart';
import '../../modules/system_setup/domain/ports/system_setup_seed_exception.dart';
import '../../modules/system_setup/domain/ports/system_setup_seed_port.dart';

/// App adapter: System Setup → Accounting defaults (local seed or remote pull).
class AccountingSystemSetupSeedAdapter implements SystemSetupSeedPort {
  AccountingSystemSetupSeedAdapter({
    required AccountRepository accounts,
    required VoucherBookRepository voucherBooks,
    required SyncManager syncManager,
    required SettingsRepository settings,
  }) : _accounts = accounts,
       _voucherBooks = voucherBooks,
       _syncManager = syncManager,
       _settings = settings;

  final AccountRepository _accounts;
  final VoucherBookRepository _voucherBooks;
  final SyncManager _syncManager;
  final SettingsRepository _settings;

  @override
  Future<void> ensureLocalDefaults() async {
    await _settings.saveChartBootstrapPreferRemote(false);
  }

  @override
  Future<void> pullRemoteDefaults() async {
    if (!_syncManager.isEnabled) {
      throw const SystemSetupSeedException(SystemSetupSeedError.syncRequired);
    }

    await _settings.saveChartBootstrapPreferRemote(true);

    try {
      final result = await _syncManager.syncNow(
        notify: true,
        upload: false,
        download: true,
        trigger: SyncPassTrigger.auto,
      ).timeout(const Duration(seconds: 15));

      if (result.outcome == SyncPassOutcome.authRequired) {
        throw const SystemSetupSeedException(SystemSetupSeedError.authRequired);
      }
      if (result.outcome == SyncPassOutcome.skippedDisabled) {
        throw const SystemSetupSeedException(SystemSetupSeedError.syncRequired);
      }
    } catch (e) {
      if (e is SystemSetupSeedException) rethrow;
    }

    await _settings.saveChartBootstrapPreferRemote(false);
  }
}
