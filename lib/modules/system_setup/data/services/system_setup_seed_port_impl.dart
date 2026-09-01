import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Complete setup initialization state only.
    // Specific module defaults (CoA, Warehouses, Currencies) are managed by each module package.
    final currentState = await initRepo.getState();
    await initRepo.saveState(
      currentState.copyWith(
        companyId: companyId,
        companyCreated: true,
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
