import 'dart:async';

import '../../app/settings/settings_repository.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/sync_overview.dart';
import '../../core/sync/sync_request_context.dart';
import '../../modules/accounting/domain/repositories/account_repository.dart';
import '../../modules/accounting/domain/repositories/voucher_book_repository.dart';
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
    await _accounts.ensureDefaultChartSeeded();
    await _voucherBooks.ensureDefaultSections();
  }

  @override
  Future<void> pullRemoteDefaults() async {
    if (!_syncManager.isEnabled) {
      throw const SystemSetupSeedException(SystemSetupSeedError.syncRequired);
    }

    // Persist preference only — never block setup UI on network / DB seed.
    await _settings.saveChartBootstrapPreferRemote(true);
    unawaited(_bootstrapRemoteInBackground());
  }

  Future<void> _bootstrapRemoteInBackground() async {
    try {
      await _voucherBooks.ensureDefaultSections();
      final result = await _syncManager.syncNow(
        notify: true,
        upload: false,
        download: true,
        trigger: SyncPassTrigger.auto,
      );
      if (result.outcome == SyncPassOutcome.authRequired ||
          result.outcome == SyncPassOutcome.skippedDisabled ||
          result.outcome == SyncPassOutcome.skippedOffline) {
        return;
      }
      final accounts = await _accounts.getAll(includeInactive: true);
      if (accounts.isNotEmpty) {
        await _settings.saveChartBootstrapPreferRemote(false);
      }
    } catch (_) {
      // Preference stays set; a later manual/auto sync can retry.
    }
  }
}
