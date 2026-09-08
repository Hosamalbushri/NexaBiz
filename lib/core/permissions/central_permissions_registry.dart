import '../../modules/accounting/permissions/accounting_permission_package.dart';
import '../../modules/administration/permissions/administration_permission_package.dart';
import '../../modules/customers/permissions/customers_permission_package.dart';
import '../../modules/inventory/permissions/inventory_permission_package.dart';
import '../../modules/purchases/permissions/purchases_permission_package.dart';
import '../../modules/receipts_payments/permissions/receipts_payments_permission_package.dart';
import '../../modules/reports/permissions/reports_permission_package.dart';
import '../../modules/sales/permissions/sales_permission_package.dart';
import '../../modules/system_setup/permissions/platform_permission_package.dart';
import 'permission_defs.dart';

/// Single authoritative registry aggregating all module permission packages in NexaBiz ERP.
class CentralPermissionsRegistry {
  static final List<PermissionPackageDef> allPackages = [
    accountingPermissionPackage(),
    administrationPermissionPackage(),
    customersPermissionPackage(),
    inventoryPermissionPackage(),
    purchasesPermissionPackage(),
    receiptsPaymentsPermissionPackage(),
    reportsPermissionPackage(),
    salesPermissionPackage(),
    platformPermissionPackage(),
  ];

  /// Returns a consolidated list of all unique permission keys system-wide.
  static List<String> getAllPermissionKeys() {
    final keys = <String>{};
    for (final package in allPackages) {
      for (final code in package.allCodes) {
        keys.add(code);
      }
    }
    return keys.toList();
  }
}
