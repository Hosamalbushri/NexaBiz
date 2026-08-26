import '../../modules/accounting/accounting_module.dart';
import '../../modules/administration/administration_module.dart';
import '../../modules/customers/customers_module.dart';
import '../../modules/inventory/inventory_module.dart';
import '../../modules/receipts_payments/receipts_payments_module.dart';
import '../../modules/reports/reports_module.dart';
import '../../modules/sales/sales_module.dart';
import '../../modules/sync/sync_module.dart';
import '../../modules/system_setup/system_setup_module.dart';

/// Module Self-Registration Manifest.
///
/// Triggers each module's own static `register()` method. Modules self-inject
/// into `ModuleRegistry` without `module_bootstrap.dart` hardcoding any module definitions.
void initializeModuleCatalog() {
  AccountingModule.register();
  AdministrationModule.register();
  CustomersModule.register();
  InventoryModule.register();
  ReceiptsPaymentsModule.register();
  ReportsModule.register();
  SalesModule.register();
  SyncModule.register();
  SystemSetupModule.register();
}
