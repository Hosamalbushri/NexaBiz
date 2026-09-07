import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import '../../domain/entities/account_binding.dart';
import '../../domain/entities/account_binding_status.dart';
import '../../domain/repositories/account_binding_repository.dart';

/// Legacy setup migration & default account discovery service.
///
/// Hydrates legacy [CompanyAccountingConfig] and [CompanyInventoryConfig]
/// account UUIDs into declarative [AccountBindingRepository] entries,
/// and discovers default accounts using stable system metadata.
///
/// Guarantees:
/// 1. Data Preservation: Never deletes or resets existing persisted data.
/// 2. Idempotency: Running migration multiple times yields the exact same state without duplicate records.
/// 3. Company Isolation: All migrated bindings maintain strict [companyId] tenant scoping.
class SetupMigrationAdapter {
  const SetupMigrationAdapter();

  /// Migrates legacy account configuration settings for [companyId] if not already bound,
  /// and performs default account discovery when [accountLookupPort] is provided.
  Future<int> migrateIfNeeded({
    required String companyId,
    required CompanyInitializationRepository companyInitRepo,
    required AccountBindingRepository bindingRepo,
    SetupAccountLookupPort? accountLookupPort,
  }) async {
    int migratedCount = 0;
    final trimmedCompanyId = companyId.trim();

    // 1. Migrate Accounting Configuration Accounts
    final accountingConfig = await companyInitRepo.getAccountingConfig();
    if (accountingConfig != null) {
      final roleToPkgReqs = <AccountRole, List<(String, String)>>{
        AccountRole.cash: [('accounting', 'cash_account')],
        AccountRole.receivable: [('accounting', 'receivable_account')],
        AccountRole.payable: [('accounting', 'payable_account')],
        AccountRole.revenue: [
          ('sales', 'sales_account'),
          ('accounting', 'sales_account'),
        ],
        AccountRole.cogs: [
          ('inventory', 'cogs_account'),
          ('accounting', 'cogs_account'),
        ],
        AccountRole.inventory: [
          ('inventory', 'inventory_asset_account'),
          ('inventory', 'inventory_account'),
        ],
        AccountRole.adjustment: [
          ('inventory', 'inventory_variance_account'),
          ('inventory', 'adjustment_account'),
        ],
        AccountRole.discount: [('sales', 'sales_discount_account')],
        AccountRole.tax: [('sales', 'sales_tax_account')],
      };

      for (final entry in accountingConfig.accountMappings.entries) {
        final role = entry.key;
        final uuid = entry.value.trim();
        final targets = roleToPkgReqs[role] ?? [];

        if (uuid.isNotEmpty && targets.isNotEmpty) {
          bool roleMigrated = false;
          for (final target in targets) {
            final packageId = target.$1;
            final requirementKey = target.$2;

            final existing = await bindingRepo.getBinding(
              companyId: trimmedCompanyId,
              packageId: packageId,
              requirementKey: requirementKey,
            );

            if (existing == null) {
              await bindingRepo.saveBinding(
                AccountBinding(
                  companyId: trimmedCompanyId,
                  packageId: packageId,
                  requirementKey: requirementKey,
                  accountUuid: uuid,
                  status: AccountBindingStatus.bound,
                  boundAt: DateTime.now().toUtc(),
                ),
              );
              roleMigrated = true;
            }
          }
          if (roleMigrated) {
            migratedCount++;
          }
        }
      }
    }

    // 2. Discover Default Account Bindings via system metadata if lookup port provided
    if (accountLookupPort != null) {
      final defaultSystemKeys =
          <
            AccountRole,
            (
              String packageId,
              String reqKey,
              String systemKey,
              String fallbackCode,
            )
          >{
            AccountRole.cash: ('accounting', 'cash_account', 'cash', '1211'),
            AccountRole.receivable: (
              'accounting',
              'receivable_account',
              'customers',
              '1221',
            ),
            AccountRole.payable: (
              'accounting',
              'payable_account',
              'accounts_payable',
              '2110',
            ),
            AccountRole.revenue: (
              'sales',
              'sales_account',
              'sales_revenue',
              '4100',
            ),
            AccountRole.cogs: (
              'inventory',
              'cogs_account',
              'cost_of_goods_sold',
              '5100',
            ),
            AccountRole.inventory: (
              'inventory',
              'inventory_asset_account',
              'inventory',
              '1230',
            ),
            AccountRole.adjustment: (
              'inventory',
              'inventory_variance_account',
              'inventory_adjustments',
              '5150',
            ),
            AccountRole.discount: (
              'sales',
              'sales_discount_account',
              'sales_discounts',
              '5170',
            ),
            AccountRole.tax: (
              'sales',
              'sales_tax_account',
              'vat_output',
              '2130',
            ),
          };

      final legacyMappings = Map<AccountRole, String>.from(
        accountingConfig?.accountMappings ?? {},
      );

      for (final entry in defaultSystemKeys.entries) {
        final role = entry.key;
        final (packageId, requirementKey, systemKey, fallbackCode) =
            entry.value;

        final existing = await bindingRepo.getBinding(
          companyId: trimmedCompanyId,
          packageId: packageId,
          requirementKey: requirementKey,
        );

        if (existing != null && existing.status == AccountBindingStatus.bound) {
          continue;
        }

        final account =
            await accountLookupPort.findAccount('system:$systemKey') ??
            await accountLookupPort.findAccount(systemKey) ??
            await accountLookupPort.findAccount(fallbackCode);

        if (account != null && account.isActive && !account.isDeleted) {
          await bindingRepo.saveBinding(
            AccountBinding(
              companyId: trimmedCompanyId,
              packageId: packageId,
              requirementKey: requirementKey,
              accountUuid: account.uuid,
              status: AccountBindingStatus.bound,
              boundAt: DateTime.now().toUtc(),
            ),
          );
          legacyMappings[role] = account.uuid;
          migratedCount++;
        }
      }

      if (legacyMappings.isNotEmpty) {
        await companyInitRepo.saveAccountingConfig(
          CompanyAccountingConfig(
            companyId: trimmedCompanyId,
            accountMappings: legacyMappings,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
    }

    return migratedCount;
  }
}
