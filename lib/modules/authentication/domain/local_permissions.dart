/// Permission codes for local offline RBAC (aligned with backend catalog).
const List<String> kAllLocalPermissions = [
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
  'products.view',
  'products.create',
  'products.update',
  'products.delete',
  'inventory.view',
  'inventory.create',
  'inventory.update',
  'inventory.delete',
  'inventory.adjust',
  'customers.view',
  'customers.create',
  'customers.update',
  'customers.delete',
  'sales.view',
  'sales.create',
  'sales.update',
  'sales.delete',
  'sales.post',
  'sales.cancel',
  'accounting.view',
  'accounting.accounts.view',
  'accounting.accounts.create',
  'accounting.accounts.update',
  'accounting.journals.view',
  'accounting.journals.create',
  'reports.view',
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
