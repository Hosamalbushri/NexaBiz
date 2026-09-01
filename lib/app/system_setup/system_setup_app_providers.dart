import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/domain/ports/setup_warehouse_lookup_port.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/providers/warehouse_providers.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_warehouse_config_service.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

import 'accounting_setup_account_lookup_adapter.dart';
import 'inventory_setup_warehouse_lookup_adapter.dart';

final appSetupAccountLookupPortProvider = Provider<SetupAccountLookupPort>((ref) {
  return AccountingSetupAccountLookupAdapter(
    ref.watch(accountRepositoryProvider),
  );
});

final appSetupWarehouseLookupPortProvider = Provider<SetupWarehouseLookupPort>((ref) {
  return InventorySetupWarehouseLookupAdapter(
    ref.watch(warehouseRepositoryProvider),
  );
});

final companyAccountingConfigServiceProvider = Provider<CompanyAccountingConfigService>((ref) {
  return CompanyAccountingConfigService(
    accountLookupPort: ref.watch(appSetupAccountLookupPortProvider),
    initRepository: ref.watch(companyInitializationRepositoryProvider),
  );
});

final companyWarehouseConfigServiceProvider = Provider<CompanyWarehouseConfigService>((ref) {
  return CompanyWarehouseConfigService(
    warehouseLookupPort: ref.watch(appSetupWarehouseLookupPortProvider),
    initRepository: ref.watch(companyInitializationRepositoryProvider),
  );
});
