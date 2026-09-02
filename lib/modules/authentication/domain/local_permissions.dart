import '../../../core/database/tenant_database_name.dart';

/// Permission codes for local offline RBAC (aligned with backend catalog).
///
/// Organized by domain and granular business actions:
/// - view
/// - create
/// - edit (update)
/// - delete
/// - post
/// - reverse
/// - approve
/// - manage users
/// - manage company
/// - manage accounting configuration
/// - manage system configuration
class LocalPermissions {
  LocalPermissions._();

  // --- Granular Action Categories ---

  // Platform & User Management
  static const platformCompaniesManage = 'platform.companies.manage';
  static const platformUsersManage = 'platform.users.manage';
  static const usersView = 'users.view';
  static const usersCreate = 'users.create';
  static const usersUpdate = 'users.update';
  static const usersDelete = 'users.delete';
  static const usersManage = 'users.manage';

  // Role & Permission Management
  static const rolesView = 'roles.view';
  static const rolesCreate = 'roles.create';
  static const rolesUpdate = 'roles.update';
  static const rolesDelete = 'roles.delete';
  static const rolesManage = 'roles.manage';
  static const permissionsManage = 'permissions.manage';

  // Company Management
  static const companiesView = 'companies.view';
  static const companiesUpdate = 'companies.update';

  // Inventory — General & Products
  static const productsView = 'products.view';
  static const productsCreate = 'products.create';
  static const productsUpdate = 'products.update';
  static const productsDelete = 'products.delete';
  static const inventoryView = 'inventory.view';
  static const inventoryCreate = 'inventory.create';
  static const inventoryUpdate = 'inventory.update';
  static const inventoryDelete = 'inventory.delete';
  static const inventoryAdjust = 'inventory.adjust';
  static const inventoryPost = 'inventory.post';

  // Stock Count
  static const inventoryStockCountView = 'inventory.stock_count.view';
  static const inventoryStockCountAdjust = 'inventory.stock_count.adjust';
  static const inventoryStockCountImport = 'inventory.stock_count.import';
  static const inventoryStockCountExport = 'inventory.stock_count.export';
  static const inventoryStockCountClear = 'inventory.stock_count.clear';

  // Customers
  static const customersView = 'customers.view';
  static const customersCreate = 'customers.create';
  static const customersUpdate = 'customers.update';
  static const customersDelete = 'customers.delete';
  static const customersMasterView = 'customers.master.view';
  static const customersMasterCreate = 'customers.master.create';
  static const customersMasterUpdate = 'customers.master.update';
  static const customersMasterDelete = 'customers.master.delete';

  // Sales & Documents
  static const salesView = 'sales.view';
  static const salesCreate = 'sales.create';
  static const salesUpdate = 'sales.update';
  static const salesDelete = 'sales.delete';
  static const salesPost = 'sales.post';
  static const salesCancel = 'sales.cancel';
  static const salesReverse = 'sales.reverse';
  static const salesApprove = 'sales.approve';

  // Accounting — Accounts & Journals
  static const accountingView = 'accounting.view';
  static const accountingAccountsView = 'accounting.accounts.view';
  static const accountingAccountsCreate = 'accounting.accounts.create';
  static const accountingAccountsUpdate = 'accounting.accounts.update';
  static const accountingAccountsDelete = 'accounting.accounts.delete';

  static const accountingJournalsView = 'accounting.journals.view';
  static const accountingJournalsCreate = 'accounting.journals.create';
  static const accountingJournalsUpdate = 'accounting.journals.update';
  static const accountingJournalsDelete = 'accounting.journals.delete';
  static const accountingJournalsPost = 'accounting.journals.post';
  static const accountingJournalsReverse = 'accounting.journals.reverse';
  static const accountingJournalsApprove = 'accounting.journals.approve';

  // Accounting — Configuration & Fiscal Years
  static const accountingConfigManage = 'accounting.config.manage';
  static const accountingFiscalYearsView = 'accounting.fiscal_years.view';
  static const accountingFiscalYearsCreate = 'accounting.fiscal_years.create';
  static const accountingFiscalYearsUpdate = 'accounting.fiscal_years.update';
  static const accountingFiscalYearsOpenPeriod = 'accounting.fiscal_years.open_period';
  static const accountingFiscalYearsClosePeriod = 'accounting.fiscal_years.close_period';
  static const accountingFiscalYearsReopenPeriod = 'accounting.fiscal_years.reopen_period';
  static const accountingFiscalYearsConfigureFx = 'accounting.fiscal_years.configure_fx';

  // Receipts & Payments
  static const receiptsView = 'receipts.view';
  static const receiptsCreate = 'receipts.create';
  static const receiptsUpdate = 'receipts.update';
  static const receiptsPost = 'receipts.post';
  static const receiptsCancel = 'receipts.cancel';
  static const receiptsReverse = 'receipts.reverse';

  static const paymentsView = 'payments.view';
  static const paymentsCreate = 'payments.create';
  static const paymentsUpdate = 'payments.update';
  static const paymentsPost = 'payments.post';
  static const paymentsCancel = 'payments.cancel';
  static const paymentsReverse = 'payments.reverse';

  static const transfersView = 'transfers.view';
  static const transfersCreate = 'transfers.create';
  static const transfersUpdate = 'transfers.update';
  static const transfersPost = 'transfers.post';
  static const transfersCancel = 'transfers.cancel';
  static const transfersApprove = 'transfers.approve';

  // Reports
  static const reportsView = 'reports.view';
  static const reportsSalesPeriodView = 'reports.sales_period.view';
  static const reportsSalesPeriodExport = 'reports.sales_period.export';
  static const reportsAccountStatementView = 'reports.account_statement.view';
  static const reportsAccountStatementExport = 'reports.account_statement.export';
  static const reportsTrialBalanceView = 'reports.trial_balance.view';
  static const reportsTrialBalanceExport = 'reports.trial_balance.export';
  static const reportsJournalBookView = 'reports.journal_book.view';
  static const reportsJournalBookExport = 'reports.journal_book.export';

  // System & Settings Configuration
  static const settingsView = 'settings.view';
  static const settingsUpdate = 'settings.update';
  static const systemConfigManage = 'system.config.manage';
  static const syncView = 'sync.view';
  static const syncExecute = 'sync.execute';
}

/// Comprehensive catalog of all local permission strings.
const List<String> kAllLocalPermissions = [
  LocalPermissions.platformCompaniesManage,
  LocalPermissions.platformUsersManage,
  LocalPermissions.usersView,
  LocalPermissions.usersCreate,
  LocalPermissions.usersUpdate,
  LocalPermissions.usersDelete,
  LocalPermissions.usersManage,
  LocalPermissions.rolesView,
  LocalPermissions.rolesCreate,
  LocalPermissions.rolesUpdate,
  LocalPermissions.rolesDelete,
  LocalPermissions.rolesManage,
  LocalPermissions.permissionsManage,
  LocalPermissions.companiesView,
  LocalPermissions.companiesUpdate,
  LocalPermissions.productsView,
  LocalPermissions.productsCreate,
  LocalPermissions.productsUpdate,
  LocalPermissions.productsDelete,
  LocalPermissions.inventoryView,
  LocalPermissions.inventoryCreate,
  LocalPermissions.inventoryUpdate,
  LocalPermissions.inventoryDelete,
  LocalPermissions.inventoryAdjust,
  LocalPermissions.inventoryPost,
  LocalPermissions.inventoryStockCountView,
  LocalPermissions.inventoryStockCountAdjust,
  LocalPermissions.inventoryStockCountImport,
  LocalPermissions.inventoryStockCountExport,
  LocalPermissions.inventoryStockCountClear,
  LocalPermissions.customersView,
  LocalPermissions.customersCreate,
  LocalPermissions.customersUpdate,
  LocalPermissions.customersDelete,
  LocalPermissions.customersMasterView,
  LocalPermissions.customersMasterCreate,
  LocalPermissions.customersMasterUpdate,
  LocalPermissions.customersMasterDelete,
  LocalPermissions.salesView,
  LocalPermissions.salesCreate,
  LocalPermissions.salesUpdate,
  LocalPermissions.salesDelete,
  LocalPermissions.salesPost,
  LocalPermissions.salesCancel,
  LocalPermissions.salesReverse,
  LocalPermissions.salesApprove,
  LocalPermissions.accountingView,
  LocalPermissions.accountingAccountsView,
  LocalPermissions.accountingAccountsCreate,
  LocalPermissions.accountingAccountsUpdate,
  LocalPermissions.accountingAccountsDelete,
  LocalPermissions.accountingJournalsView,
  LocalPermissions.accountingJournalsCreate,
  LocalPermissions.accountingJournalsUpdate,
  LocalPermissions.accountingJournalsDelete,
  LocalPermissions.accountingJournalsPost,
  LocalPermissions.accountingJournalsReverse,
  LocalPermissions.accountingJournalsApprove,
  LocalPermissions.accountingConfigManage,
  LocalPermissions.accountingFiscalYearsView,
  LocalPermissions.accountingFiscalYearsCreate,
  LocalPermissions.accountingFiscalYearsUpdate,
  LocalPermissions.accountingFiscalYearsOpenPeriod,
  LocalPermissions.accountingFiscalYearsClosePeriod,
  LocalPermissions.accountingFiscalYearsReopenPeriod,
  LocalPermissions.accountingFiscalYearsConfigureFx,
  LocalPermissions.receiptsView,
  LocalPermissions.receiptsCreate,
  LocalPermissions.receiptsUpdate,
  LocalPermissions.receiptsPost,
  LocalPermissions.receiptsCancel,
  LocalPermissions.receiptsReverse,
  LocalPermissions.paymentsView,
  LocalPermissions.paymentsCreate,
  LocalPermissions.paymentsUpdate,
  LocalPermissions.paymentsPost,
  LocalPermissions.paymentsCancel,
  LocalPermissions.paymentsReverse,
  LocalPermissions.transfersView,
  LocalPermissions.transfersCreate,
  LocalPermissions.transfersUpdate,
  LocalPermissions.transfersPost,
  LocalPermissions.transfersCancel,
  LocalPermissions.transfersApprove,
  LocalPermissions.reportsView,
  LocalPermissions.reportsSalesPeriodView,
  LocalPermissions.reportsSalesPeriodExport,
  LocalPermissions.reportsAccountStatementView,
  LocalPermissions.reportsAccountStatementExport,
  LocalPermissions.reportsTrialBalanceView,
  LocalPermissions.reportsTrialBalanceExport,
  LocalPermissions.reportsJournalBookView,
  LocalPermissions.reportsJournalBookExport,
  LocalPermissions.settingsView,
  LocalPermissions.settingsUpdate,
  LocalPermissions.systemConfigManage,
  LocalPermissions.syncView,
  LocalPermissions.syncExecute,
];

/// System-level authority permission codes (belonging strictly to System Scope).
const Set<String> kSystemLevelPermissions = {
  LocalPermissions.platformCompaniesManage,
  LocalPermissions.platformUsersManage,
  LocalPermissions.usersView,
  LocalPermissions.usersCreate,
  LocalPermissions.usersUpdate,
  LocalPermissions.usersDelete,
  LocalPermissions.usersManage,
  LocalPermissions.rolesView,
  LocalPermissions.rolesCreate,
  LocalPermissions.rolesUpdate,
  LocalPermissions.rolesDelete,
  LocalPermissions.rolesManage,
  LocalPermissions.permissionsManage,
  LocalPermissions.companiesView,
  LocalPermissions.companiesUpdate,
  LocalPermissions.settingsView,
  LocalPermissions.settingsUpdate,
  LocalPermissions.systemConfigManage,
  LocalPermissions.syncView,
  LocalPermissions.syncExecute,
};

/// Helper to test whether a permission code belongs to system scope vs company scope.
bool isSystemLevelPermission(String code) {
  return kSystemLevelPermissions.contains(code) ||
      code.startsWith('platform.') ||
      code.startsWith('system.');
}

/// Default offline identity constants.
class LocalAuthDefaults {
  const LocalAuthDefaults._();

  static const adminEmail = 'admin@local';
  static const adminName = 'System Admin';
  static const adminUserId = '00000000-0000-4000-8000-0000000000a1';

  static const companyId = kLegacyLocalCompanyId;
  static const companyName = 'Local Company';
  static const companyCode = 'LOCAL';

  static const ownerRole = 'Owner';
  static const adminRole = 'Super Admin';
}
