import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/settings_repository.dart';
import '../../domain/entities/accounting_mode.dart';
import '../../domain/services/accounting_integration_port.dart';
import '../../domain/services/accounting_mode_policy.dart';

/// Current accounting operating mode (standalone / integrated).
final accountingModeProvider =
    StateNotifierProvider<AccountingModeController, AsyncValue<AccountingMode>>(
      (ref) {
        return AccountingModeController(
          repository: ref.watch(settingsRepositoryProvider),
        );
      },
    );

final accountingModePolicyProvider = Provider<AccountingModePolicy>((ref) {
  final mode =
      ref.watch(accountingModeProvider).valueOrNull ??
      AccountingMode.standalone;
  return AccountingModePolicy(mode);
});

/// Integration gateway — swap implementation when a real connector is wired.
final accountingIntegrationPortProvider = Provider<AccountingIntegrationPort>((
  ref,
) {
  final mode =
      ref.watch(accountingModeProvider).valueOrNull ??
      AccountingMode.standalone;
  if (mode.isIntegrated) {
    // Placeholder until a vendor connector is registered via DI override.
    return const NoOpAccountingIntegrationPort();
  }
  return const NoOpAccountingIntegrationPort();
});

class AccountingModeController
    extends StateNotifier<AsyncValue<AccountingMode>> {
  AccountingModeController({required SettingsRepository repository})
    : _repository = repository,
      super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final raw = await _repository.loadAccountingMode();
      return AccountingMode.fromStorage(raw);
    });
  }

  Future<void> setMode(AccountingMode mode) async {
    await _repository.saveAccountingMode(mode.storageValue);
    state = AsyncValue.data(mode);
  }

  Future<void> reload() => _load();
}
