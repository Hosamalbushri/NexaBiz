/// Permission codes for local offline RBAC (aligned with backend catalog).
///
/// Prefer service-level codes: `module.service.operation`
/// Legacy flat codes remain for compatibility.
const List<String> kAllLocalPermissions = [
  // Platform / admin
  'platform.companies.manage',
  'platform.users.manage',
  'users.view',
  'users.create',
  'users.update',
  'users.delete',
  'users.manage',
  'roles.view',
  'roles.create',
  'roles.update',
  'roles.delete',
  'roles.manage',
  'permissions.manage',
  'companies.view',
  'companies.update',
  // Inventory — legacy
  'products.view',
  'products.create',
  'products.update',
  'products.delete',
  'inventory.view',
  'inventory.create',
  'inventory.update',
  'inventory.delete',
  'inventory.adjust',
  // Inventory — stock count
  'inventory.stock_count.view',
  'inventory.stock_count.adjust',
  'inventory.stock_count.import',
  'inventory.stock_count.export',
  'inventory.stock_count.clear',
  // Inventory — products
  'inventory.products.view',
  'inventory.products.create',
  'inventory.products.update',
  'inventory.products.delete',
  'inventory.products.import',
  'inventory.products.barcode',
  // Customers — legacy + services
  'customers.view',
  'customers.create',
  'customers.update',
  'customers.delete',
  'customers.master.view',
  'customers.master.create',
  'customers.master.update',
  'customers.master.delete',
  'customers.master.import',
  'customers.accounts.view',
  'customers.settings.view',
  'customers.settings.update',
  // Sales — legacy + documents
  'sales.view',
  'sales.create',
  'sales.update',
  'sales.delete',
  'sales.post',
  'sales.cancel',
  'sales.documents.view',
  'sales.documents.create',
  'sales.documents.update',
  'sales.documents.delete',
  'sales.documents.post',
  'sales.documents.cancel',
  'sales.documents.duplicate',
  'sales.documents.export',
  // Accounting
  'accounting.view',
  'accounting.accounts.view',
  'accounting.accounts.create',
  'accounting.accounts.update',
  'accounting.accounts.delete',
  'accounting.journals.view',
  'accounting.journals.create',
  'accounting.journals.update',
  'accounting.journals.delete',
  'accounting.currency_rates.view',
  'accounting.currency_rates.create',
  'accounting.currency_rates.update',
  'accounting.currency_rates.delete',
  'accounting.voucher_books.view',
  'accounting.voucher_books.create',
  'accounting.voucher_books.update',
  'accounting.voucher_books.delete',
  'accounting.fiscal_years.view',
  'accounting.fiscal_years.create',
  'accounting.fiscal_years.update',
  'accounting.fiscal_years.open_period',
  'accounting.fiscal_years.close_period',
  'accounting.fiscal_years.reopen_period',
  'accounting.fiscal_years.configure_fx',
  'accounting.reports.view',
  // Receipts & Payments
  'receipts.view',
  'receipts.create',
  'receipts.update',
  'receipts.post',
  'receipts.cancel',
  'payments.view',
  'payments.create',
  'payments.update',
  'payments.post',
  'payments.cancel',
  'transfers.view',
  'transfers.create',
  'transfers.update',
  'transfers.post',
  'transfers.cancel',
  'exchanges.view',
  'exchanges.create',
  'exchanges.update',
  'exchanges.post',
  'exchanges.cancel',
  'receipts_payments.reports.view',
  'receipts_payments.reports.export',
  'receipts_payments.sync',
  // Reports
  'reports.view',
  'reports.sales_period.view',
  'reports.sales_period.export',
  'reports.account_statement.view',
  'reports.account_statement.export',
  // Settings / sync / devices
  'settings.view',
  'settings.update',
  'sync.view',
  'sync.execute',
  'devices.view',
  'devices.revoke',
];

/// Default offline admin (created on first launch).
class LocalAuthDefaults {
  const LocalAuthDefaults._();

  static const adminEmail = 'admin@local';
  static const adminPassword = 'admin123';
  static const adminName = 'System Admin';
  static const adminUserId = '00000000-0000-4000-8000-0000000000a1';

  static const companyId = '00000000-0000-4000-8000-000000000001';
  static const companyName = 'Local Company';
  static const companyCode = 'LOCAL';

  static const adminRole = 'Super Admin';
}
