import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import '../../domain/entities/account_binding.dart';
import '../../domain/entities/account_binding_status.dart';
import '../../domain/repositories/account_binding_repository.dart';

/// Legacy setup migration service.
///
/// Automatically hydrates legacy [CompanyAccountingConfig] and [CompanyInventoryConfig]
/// account UUIDs into declarative [AccountBindingRepository] entries.
///
/// Guarantees:
/// 1. Data Preservation: Never deletes or resets existing persisted data.
/// 2. Idempotency: Running migration multiple times yields the exact same state without duplicate records.
/// 3. Company Isolation: All migrated bindings maintain strict [companyId] tenant scoping.
class SetupMigrationAdapter {
  const SetupMigrationAdapter();

  /// Migrates legacy account configuration settings for [companyId] if not already bound.
  Future<int> migrateIfNeeded({
    required String companyId,
    required CompanyInitializationRepository companyInitRepo,
    required AccountBindingRepository bindingRepo,
  }) async {
    int migratedCount = 0;
    final trimmedCompanyId = companyId.trim();

    // 1. Migrate Accounting Configuration Accounts
    final accountingConfig = await companyInitRepo.getAccountingConfig();
    if (accountingConfig != null) {
      final roleToPkgReq = <AccountRole, (String, String)>{
        AccountRole.cash: ('accounting', 'cash_account'),
        AccountRole.receivable: ('accounting', 'receivable_account'),
        AccountRole.payable: ('accounting', 'payable_account'),
        AccountRole.revenue: ('accounting', 'sales_account'),
        AccountRole.cogs: ('accounting', 'cogs_account'),
        AccountRole.inventory: ('inventory', 'inventory_account'),
        AccountRole.adjustment: ('inventory', 'adjustment_account'),
      };

      for (final entry in accountingConfig.accountMappings.entries) {
        final role = entry.key;
        final uuid = entry.value.trim();
        final target = roleToPkgReq[role];

        if (uuid.isNotEmpty && target != null) {
          final packageId = target.$1;
          final requirementKey = target.$2;

          final existing = await bindingRepo.getBinding(
            companyId: trimmedCompanyId,
            packageId: packageId,
            requirementKey: requirementKey,
          );

          if (existing == null) {
            await bindingRepo.saveBinding(AccountBinding(
              companyId: trimmedCompanyId,
              packageId: packageId,
              requirementKey: requirementKey,
              accountUuid: uuid,
              status: AccountBindingStatus.bound,
              boundAt: DateTime.now().toUtc(),
            ));
            migratedCount++;
          }
        }
      }
    }

    return migratedCount;
  }
}
