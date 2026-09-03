import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../domain/entities/account_role.dart';
import '../../setup.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';

import 'package:stock_count/core/setup/presentation/widgets/package_setup_view.dart';
import 'package:stock_count/core/setup/presentation/widgets/setup_field_renderer.dart';

/// Central Setup Center master widget for rendering and orchestrating setup definitions.
class CentralSetupCenterWidget extends ConsumerStatefulWidget {
  const CentralSetupCenterWidget({
    super.key,
    this.onSaved,
  });

  final VoidCallback? onSaved;

  @override
  ConsumerState<CentralSetupCenterWidget> createState() => _CentralSetupCenterWidgetState();
}

class _CentralSetupCenterWidgetState extends ConsumerState<CentralSetupCenterWidget> {
  int _selectedPackageIndex = 0;
  final Map<String, Map<String, dynamic>> _packageFieldValues = {};
  bool _saving = false;
  bool _initialized = false;

  final Map<String, AccountRole> _knownAccountRoles = {
    // Inventory
    'inventory_account': AccountRole.inventory,
    'cogs_account': AccountRole.cogs,
    'inventory_adjustment_account': AccountRole.adjustment,
    // Sales
    'sales_account': AccountRole.revenue,
    'sales_discount_account': AccountRole.discount,
    'sales_cash_account': AccountRole.cash,
    // Customers
    'ar_account': AccountRole.receivable,
    // Receipts & Payments
    'cash_account': AccountRole.cash,
    'bank_account': AccountRole.cash,
    // Accounting
    'default_cash_account': AccountRole.cash,
    'default_receivable_account': AccountRole.receivable,
    'default_payable_account': AccountRole.payable,
  };

  void _hydrateDefaults(List<PackageSetupDefinition> setups) {
    if (_initialized) return;
    _initialized = true;

    for (final pkg in setups) {
      final fieldMap = _packageFieldValues.putIfAbsent(pkg.packageId, () => {});
      for (final section in pkg.sections) {
        for (final field in section.fields) {
          if (!fieldMap.containsKey(field.key)) {
            fieldMap[field.key] = field.defaultValue;
          }
        }
      }
    }
  }

  Future<void> _saveAll(List<PackageSetupDefinition> setups) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(companyInitializationRepositoryProvider);
      final state = await repo.getState();
      final companyId = state.companyId;

      // Extract account role mappings from field values
      final Map<AccountRole, String> accountMappings = {};
      _packageFieldValues.forEach((pkgId, fields) {
        fields.forEach((key, val) {
          if (val is String && val.isNotEmpty && _knownAccountRoles.containsKey(key)) {
            accountMappings[_knownAccountRoles[key]!] = val;
          }
        });
      });

      if (accountMappings.isNotEmpty) {
        final existingAccounting = await repo.getAccountingConfig();
        final updatedAccountMappings = Map<AccountRole, String>.from(existingAccounting?.accountMappings ?? {})
          ..addAll(accountMappings);
        await repo.saveAccountingConfig(CompanyAccountingConfig(
          companyId: companyId,
          accountMappings: updatedAccountMappings,
          updatedAt: DateTime.now().toUtc(),
        ));
      }

      // Extract inventory config
      final invFields = _packageFieldValues['inventory'] ?? {};
      final existingInv = await repo.getInventoryConfig();
      final costingMethod = invFields['costing_method']?.toString() ?? existingInv?.defaultCostingMethod ?? 'FIFO';
      final allowNegative = (invFields['allow_negative_stock'] as bool?) ?? existingInv?.allowNegativeStock ?? false;
      final baseCurrency = invFields['inventoryValuationCurrencyId']?.toString() ?? existingInv?.inventoryBaseCurrencyId ?? 'YER';

      await repo.saveInventoryConfig(CompanyInventoryConfig(
        companyId: companyId,
        inventoryBaseCurrencyId: baseCurrency,
        defaultCostingMethod: costingMethod,
        allowNegativeStock: allowNegative,
        autoPostAccountingEntries: true,
        updatedAt: DateTime.now().toUtc(),
      ));

      ref.invalidate(companyAccountingConfigProvider);
      ref.invalidate(companyInventoryConfigProvider);

      if (widget.onSaved != null) {
        widget.onSaved!();
      }

      if (mounted) {
        showAppSnackBar(
          context,
          message: 'تم حفظ كافة إعدادات التهيئة بنجاح',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'خطأ أثناء حفظ الإعدادات: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final registeredSetups = ref.watch(registeredPackageSetupsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    _hydrateDefaults(registeredSetups);

    final availableAccounts = accountsAsync.when(
      data: (accounts) => accounts
          .where((a) => a.isPostingAccount && a.isActive && !a.isDeleted)
          .map((a) => SetupAccountOption(
                uuid: a.uuid,
                code: a.accountCode,
                name: a.name,
              ))
          .toList(),
      loading: () => <SetupAccountOption>[],
      error: (_, _) => <SetupAccountOption>[],
    );

    if (registeredSetups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isArabic
                      ? 'لا توجد حزم مسجلة في مركز الإعدادات المركزي'
                      : 'No registered business packages found in Central Setup Center.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int safeIndex = _selectedPackageIndex.clamp(0, registeredSetups.length - 1).toInt();
    final currentPackage = registeredSetups[safeIndex];
    final currentPackageFields = _packageFieldValues.putIfAbsent(currentPackage.packageId, () => {});

    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        Expanded(
          child: isWideScreen
              ? _buildDesktopLayout(
                  context,
                  theme,
                  isArabic,
                  registeredSetups,
                  safeIndex,
                  currentPackage,
                  currentPackageFields,
                  availableAccounts,
                )
              : _buildMobileLayout(
                  context,
                  theme,
                  isArabic,
                  registeredSetups,
                  safeIndex,
                  currentPackage,
                  currentPackageFields,
                  availableAccounts,
                ),
        ),

        // Global Action Footer
        Container(
          padding: AppConstants.pageInsets(context),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: isArabic
                      ? 'حفظ كافة إعدادات التهيئة للحزم'
                      : 'Save All Package Configurations',
                  icon: Icons.save_outlined,
                  isLoading: _saving,
                  onPressed: _saving ? null : () => _saveAll(registeredSetups),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    bool isArabic,
    List<PackageSetupDefinition> setups,
    int activeIndex,
    PackageSetupDefinition activePackage,
    Map<String, dynamic> activePackageFields,
    List<SetupAccountOption> availableAccounts,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Navigation
        SizedBox(
          width: 260,
          child: Card(
            margin: const EdgeInsets.all(AppSpacing.sm),
            child: ListView.separated(
              itemCount: setups.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final pkg = setups[idx];
                final isSelected = idx == activeIndex;
                final pkgName = pkg.displayName(isArabic ? 'ar' : 'en');

                return ListTile(
                  selected: isSelected,
                  leading: Icon(
                    _getPackageIcon(pkg.packageId),
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    pkgName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    pkg.packageId,
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () {
                    setState(() => _selectedPackageIndex = idx);
                  },
                );
              },
            ),
          ),
        ),

        // Dynamic Setup View
        Expanded(
          child: PackageSetupView(
            definition: activePackage,
            fieldValues: activePackageFields,
            isArabic: isArabic,
            availableAccounts: availableAccounts,
            accountRoles: _knownAccountRoles,
            onFieldValueChanged: (key, val) {
              setState(() {
                activePackageFields[key] = val;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    bool isArabic,
    List<PackageSetupDefinition> setups,
    int activeIndex,
    PackageSetupDefinition activePackage,
    Map<String, dynamic> activePackageFields,
    List<SetupAccountOption> availableAccounts,
  ) {
    return Column(
      children: [
        // Dropdown package selector for small screens
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: DropdownButtonFormField<int>(
            initialValue: activeIndex,
            decoration: InputDecoration(
              labelText: isArabic ? 'اختر حزمة النظام' : 'Select Package',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: setups.asMap().entries.map((entry) {
              final idx = entry.key;
              final pkg = entry.value;
              return DropdownMenuItem<int>(
                value: idx,
                child: Text(pkg.displayName(isArabic ? 'ar' : 'en')),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPackageIndex = val);
              }
            },
          ),
        ),

        // Package setup view
        Expanded(
          child: PackageSetupView(
            definition: activePackage,
            fieldValues: activePackageFields,
            isArabic: isArabic,
            availableAccounts: availableAccounts,
            accountRoles: _knownAccountRoles,
            onFieldValueChanged: (key, val) {
              setState(() {
                activePackageFields[key] = val;
              });
            },
          ),
        ),
      ],
    );
  }

  IconData _getPackageIcon(String packageId) {
    switch (packageId) {
      case 'accounting':
        return Icons.account_balance_outlined;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'sales':
        return Icons.point_of_sale_outlined;
      case 'customers':
        return Icons.people_outline;
      case 'receipts_payments':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.tune_outlined;
    }
  }
}
