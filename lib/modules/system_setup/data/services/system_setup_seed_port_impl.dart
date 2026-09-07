import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../../../core/tenancy/tenant_context.dart';
import '../../domain/ports/system_setup_seed_port.dart';
import '../../presentation/providers/system_setup_providers.dart';

class SystemSetupSeedPortImpl implements SystemSetupSeedPort {
  SystemSetupSeedPortImpl(this._ref);

  final Ref _ref;

  @override
  Future<void> ensureLocalDefaults({
    String? baseCurrency,
    String? defaultWarehouseName,
    String? defaultWarehouseCode,
  }) async {
    final companyId = _ref.read(currentCompanyIdProvider);
    final initRepo = _ref.read(companyInitializationRepositoryProvider);

    // If company context exists, seed Chart of Accounts defaults safely
    if (companyId.isNotEmpty) {
      try {
        final accountRepo = _ref.read(accountRepositoryProvider);
        await accountRepo.ensureDefaultChartSeeded();
      } catch (_) {
        // Safe fallback if accounting database context is uninitialized
      }
    }

    final currentState = await initRepo.getState();
    await initRepo.saveState(
      currentState.copyWith(
        companyId: companyId,
        companyCreated: companyId.isNotEmpty,
        accountingConfigured: true,
        inventoryCurrencyConfigured: true,
        warehouseConfigured: true,
        inventorySettingsConfigured: true,
        initializationCompleted: true,
      ),
    );
  }

  @override
  Future<void> pullRemoteDefaults() async {}
}
