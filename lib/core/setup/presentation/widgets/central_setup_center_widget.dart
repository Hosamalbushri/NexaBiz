import 'dart:async';
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
import 'package:stock_count/modules/accounting/shared/domain/services/account_binding_safety_gate.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/account_mapping_providers.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';

import 'package:stock_count/core/setup/presentation/widgets/package_setup_view.dart';
import 'package:stock_count/core/setup/presentation/widgets/setup_field_renderer.dart';

/// Central Setup Center master widget for rendering and orchestrating setup definitions.
class CentralSetupCenterWidget extends ConsumerStatefulWidget {
  const CentralSetupCenterWidget({
    super.key,
    this.onSaved,
    this.filterPackageId,
  });

  final VoidCallback? onSaved;
  final String? filterPackageId;

  @override
  ConsumerState<CentralSetupCenterWidget> createState() =>
      _CentralSetupCenterWidgetState();
}

class _CentralSetupCenterWidgetState
    extends ConsumerState<CentralSetupCenterWidget> {
  int _selectedPackageIndex = 0;
  final Map<String, Map<String, dynamic>> _packageFieldValues = {};
  bool _saving = false;
  bool _initialized = false;

  final Map<String, AccountRole> _knownAccountRoles = {
    // Inventory
    'inventory_account': AccountRole.inventory,
    'inventory_asset_account': AccountRole.inventory,
    'cogs_account': AccountRole.cogs,
    'inventory_adjustment_account': AccountRole.adjustment,
    'inventory_variance_account': AccountRole.adjustment,
    // Sales
    'sales_account': AccountRole.revenue,
    'sales_discount_account': AccountRole.discount,
    'sales_cash_account': AccountRole.cash,
    // Purchases
    'payable_account': AccountRole.payable,
    'purchase_inventory_account': AccountRole.inventory,
    'purchase_discount_account': AccountRole.discount,
    'purchase_cash_account': AccountRole.cash,
    'purchase_bank_account': AccountRole.cash,
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

  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    runZonedGuarded(
      () async {
        final repo = ref.read(companyInitializationRepositoryProvider);

        CompanyInitializationState? state;
        try {
          state = await repo.getState();
        } catch (_) {}
        final companyId = state?.companyId ?? '';

        CompanyAccountingConfig? accountingConfig;
        try {
          accountingConfig = await repo.getAccountingConfig();
        } catch (_) {}

        CompanyInventoryConfig? inventoryConfig;
        try {
          inventoryConfig = await repo.getInventoryConfig();
        } catch (_) {}

        AccountBindingRepository? bindingRepo;
        try {
          bindingRepo = ref.read(accountBindingRepositoryProvider);
        } catch (_) {}

        final rawSetups = ref.read(registeredPackageSetupsProvider);

        for (final pkg in rawSetups) {
          final fieldMap = _packageFieldValues.putIfAbsent(
            pkg.packageId,
            () => {},
          );

          List<AccountBinding> packageBindings = [];
          if (bindingRepo != null) {
            try {
              packageBindings = await bindingRepo.getBindingsForPackage(
                companyId: companyId,
                packageId: pkg.packageId,
              );
            } catch (_) {}
          }

          for (final section in pkg.sections) {
            for (final field in section.fields) {
              // 1. Known account roles mapping
              if (_knownAccountRoles.containsKey(field.key)) {
                final role = _knownAccountRoles[field.key]!;
                final savedUuid = accountingConfig?.accountMappings[role];
                if (savedUuid != null && savedUuid.isNotEmpty) {
                  fieldMap[field.key] = savedUuid;
                  continue;
                }
              }

              // 2. Declarative bindings check
              AccountBinding? matchingBinding;
              for (final b in packageBindings) {
                if (b.requirementKey == field.key ||
                    b.requirementKey == field.id) {
                  matchingBinding = b;
                  break;
                }
              }
              if (matchingBinding != null &&
                  matchingBinding.accountUuid.isNotEmpty) {
                fieldMap[field.key] = matchingBinding.accountUuid;
                continue;
              }

              // 3. Inventory config settings
              if (pkg.packageId == 'inventory' && inventoryConfig != null) {
                if (field.key == 'costing_method') {
                  fieldMap[field.key] = inventoryConfig.defaultCostingMethod;
                  continue;
                }
                if (field.key == 'allow_negative_stock') {
                  fieldMap[field.key] = inventoryConfig.allowNegativeStock;
                  continue;
                }
                if (field.key == 'inventoryValuationCurrencyId') {
                  fieldMap[field.key] = inventoryConfig.inventoryBaseCurrencyId;
                  continue;
                }
              }

              // 4. Default fallback
              fieldMap.putIfAbsent(field.key, () => field.defaultValue);
            }
          }
        }

        if (mounted) {
          setState(() {
            _dataLoaded = true;
          });
        }
      },
      (error, stack) {
        // Gracefully swallow unhandled repository errors (e.g. uninitialized Hive in widget tests)
      },
    );
  }

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

  Future<void> _savePackage(PackageSetupDefinition pkg) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(companyInitializationRepositoryProvider);
      final state = await repo.getState();
      final companyId = state.companyId;

      final fields = _packageFieldValues[pkg.packageId] ?? {};

      // 1. Extract account role mappings for this package
      final Map<AccountRole, String> accountMappings = {};
      fields.forEach((key, val) {
        if (val is String &&
            val.isNotEmpty &&
            _knownAccountRoles.containsKey(key)) {
          accountMappings[_knownAccountRoles[key]!] = val;
        }
      });

      if (accountMappings.isNotEmpty) {
        final existingAccounting = await repo.getAccountingConfig();
        final existingMappings = existingAccounting?.accountMappings ?? {};

        // Atomic Safety Gate Pre-Validation
        final safetyGate = ref.read(accountBindingSafetyGateProvider);
        for (final entry in accountMappings.entries) {
          final role = entry.key;
          final candidateUuid = entry.value;
          final currentUuid = existingMappings[role];

          await safetyGate.validateBindingChange(
            companyId: companyId,
            role: role,
            currentAccountUuid: currentUuid,
            candidateAccountUuid: candidateUuid,
          );
        }

        final updatedAccountMappings = Map<AccountRole, String>.from(
          existingMappings,
        )..addAll(accountMappings);
        await repo.saveAccountingConfig(
          CompanyAccountingConfig(
            companyId: companyId,
            accountMappings: updatedAccountMappings,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }

      // 2. Persist declarative bindings for package requirements into AccountBindingRepository
      final bindingRepo = ref.read(accountBindingRepositoryProvider);
      for (final entry in fields.entries) {
        final fieldKey = entry.key;
        final val = entry.value;
        if (val is String && val.isNotEmpty) {
          await bindingRepo.saveBinding(
            AccountBinding(
              companyId: companyId,
              packageId: pkg.packageId,
              requirementKey: fieldKey,
              accountUuid: val,
              status: AccountBindingStatus.bound,
              boundAt: DateTime.now().toUtc(),
            ),
          );
        }
      }

      // 3. Extract inventory config if saving inventory package
      if (pkg.packageId == 'inventory') {
        final existingInv = await repo.getInventoryConfig();
        final costingMethod =
            fields['costing_method']?.toString() ??
            existingInv?.defaultCostingMethod ??
            'FIFO';
        final allowNegative =
            (fields['allow_negative_stock'] as bool?) ??
            existingInv?.allowNegativeStock ??
            false;
        final baseCurrency =
            fields['inventoryValuationCurrencyId']?.toString() ??
            existingInv?.inventoryBaseCurrencyId ??
            'YER';

        await repo.saveInventoryConfig(
          CompanyInventoryConfig(
            companyId: companyId,
            inventoryBaseCurrencyId: baseCurrency,
            defaultCostingMethod: costingMethod,
            allowNegativeStock: allowNegative,
            autoPostAccountingEntries: true,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }

      ref.invalidate(companyAccountingConfigProvider);
      ref.invalidate(companyInventoryConfigProvider);

      if (widget.onSaved != null) {
        widget.onSaved!();
      }

      if (mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final pkgName = pkg.displayName(isArabic ? 'ar' : 'en');
        showAppSnackBar(
          context,
          message: isArabic
              ? 'تم حفظ إعدادات حزمة ($pkgName) بنجاح'
              : 'Package ($pkgName) saved successfully',
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

  Future<void> _saveAll(List<PackageSetupDefinition> setups) async {
    for (final pkg in setups) {
      await _savePackage(pkg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rawSetups = ref.watch(registeredPackageSetupsProvider);
    final registeredSetups = widget.filterPackageId != null
        ? rawSetups.where((s) => s.packageId == widget.filterPackageId).toList()
        : rawSetups;
    final accountsAsync = ref.watch(accountsProvider);

    _hydrateDefaults(registeredSetups);

    final availableAccounts = accountsAsync.when(
      data: (accounts) => accounts
          .where((a) => a.isPostingAccount && a.isActive && !a.isDeleted)
          .map(
            (a) => SetupAccountOption(
              uuid: a.uuid,
              code: a.accountCode,
              name: a.name,
            ),
          )
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

    final int safeIndex = _selectedPackageIndex
        .clamp(0, registeredSetups.length - 1)
        .toInt();
    final currentPackage = registeredSetups[safeIndex];
    final currentPackageFields = _packageFieldValues.putIfAbsent(
      currentPackage.packageId,
      () => {},
    );

    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    if (widget.filterPackageId != null) {
      return PackageSetupView(
        definition: currentPackage,
        fieldValues: currentPackageFields,
        isArabic: isArabic,
        availableAccounts: availableAccounts,
        accountRoles: _knownAccountRoles,
        status: _calculatePackageStatus(currentPackage, currentPackageFields),
        onFieldValueChanged: (key, val) {
          setState(() {
            currentPackageFields[key] = val;
          });
        },
        onSavePackage: () => _savePackage(currentPackage),
        isSaving: _saving,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      );
    }

    return Column(
      children: [
        // Show package tabs header if displaying all packages
        if (widget.filterPackageId == null && registeredSetups.length > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: registeredSetups.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pkg = entry.value;
                  final isSelected = idx == safeIndex;
                  final pkgName = pkg.displayName(isArabic ? 'ar' : 'en');
                  final icon = _getPackageIcon(pkg.packageId);

                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: CircleAvatar(
                        backgroundColor: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      label: Text(
                        pkgName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selectedColor: theme.colorScheme.primaryContainer,
                      onSelected: (_) {
                        setState(() => _selectedPackageIndex = idx);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
        ],

        Expanded(
          child: !isWideScreen
              ? PackageSetupView(
                  definition: currentPackage,
                  fieldValues: currentPackageFields,
                  isArabic: isArabic,
                  availableAccounts: availableAccounts,
                  accountRoles: _knownAccountRoles,
                  status: _calculatePackageStatus(
                    currentPackage,
                    currentPackageFields,
                  ),
                  onFieldValueChanged: (key, val) {
                    setState(() {
                      currentPackageFields[key] = val;
                    });
                  },
                  onSavePackage: () => _savePackage(currentPackage),
                  isSaving: _saving,
                )
              : _buildDesktopLayout(
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

  SetupStatus _calculatePackageStatus(
    PackageSetupDefinition pkg,
    Map<String, dynamic> fieldValues,
  ) {
    final fields = pkg.sections.expand((s) => s.fields).toList();
    if (fields.isEmpty) return SetupStatus.configured;

    int totalCount = fields.length;
    int populatedCount = 0;

    for (final field in fields) {
      final val = fieldValues[field.key];
      if (val != null && val.toString().trim().isNotEmpty) {
        populatedCount++;
      }
    }

    if (populatedCount == 0) {
      return SetupStatus.notConfigured;
    } else if (populatedCount >= totalCount) {
      return SetupStatus.configured;
    } else {
      return SetupStatus.partiallyConfigured;
    }
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
                final pkgFields = _packageFieldValues[pkg.packageId] ?? {};
                final pkgStatus = _calculatePackageStatus(pkg, pkgFields);

                return ListTile(
                  selected: isSelected,
                  leading: Icon(
                    _getPackageIcon(pkg.packageId),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    pkgName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    pkg.packageId,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pkgStatus == SetupStatus.configured
                          ? Colors.green
                          : (pkgStatus == SetupStatus.partiallyConfigured
                                ? Colors.amber
                                : Colors.grey.shade400),
                    ),
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
            status: _calculatePackageStatus(activePackage, activePackageFields),
            onFieldValueChanged: (key, val) {
              setState(() {
                activePackageFields[key] = val;
              });
            },
            onSavePackage: () => _savePackage(activePackage),
            isSaving: _saving,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          child: DropdownButtonFormField<int>(
            initialValue: activeIndex,
            decoration: InputDecoration(
              labelText: isArabic ? 'اختر حزمة النظام' : 'Select Package',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
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
            status: _calculatePackageStatus(activePackage, activePackageFields),
            onFieldValueChanged: (key, val) {
              setState(() {
                activePackageFields[key] = val;
              });
            },
            onSavePackage: () => _savePackage(activePackage),
            isSaving: _saving,
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
