import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/shared/presentation/widgets/account_picker_dropdown.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/company_accounting_config.dart';
import '../../domain/entities/company_inventory_config.dart';
import '../providers/system_setup_providers.dart';

/// Comprehensive setup hub for configuring package default accounts & operational defaults.
class PackageInitializationSettingsHub extends ConsumerStatefulWidget {
  const PackageInitializationSettingsHub({super.key});

  @override
  ConsumerState<PackageInitializationSettingsHub> createState() =>
      _PackageInitializationSettingsHubState();
}

class _PackageInitializationSettingsHubState
    extends ConsumerState<PackageInitializationSettingsHub> {
  final Map<AccountRole, String> _mappings = {};
  String _costingMethod = 'FIFO';
  bool _allowNegativeStock = false;
  bool _autoPostEntries = true;
  bool _saving = false;
  bool _initialized = false;

  void _hydrate(
    CompanyAccountingConfig? accountingConfig,
    CompanyInventoryConfig? inventoryConfig,
  ) {
    if (_initialized) return;
    _initialized = true;

    if (accountingConfig != null) {
      _mappings.addAll(accountingConfig.accountMappings);
    }
    if (inventoryConfig != null) {
      _costingMethod = inventoryConfig.defaultCostingMethod;
      _allowNegativeStock = inventoryConfig.allowNegativeStock;
      _autoPostEntries = inventoryConfig.autoPostAccountingEntries;
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(companyInitializationRepositoryProvider);
      final state = await repo.getState();

      // Save accounting config (role mappings)
      final newAccountingConfig = CompanyAccountingConfig(
        companyId: state.companyId,
        accountMappings: Map.from(_mappings),
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.saveAccountingConfig(newAccountingConfig);

      // Save inventory config
      final existingInv = await repo.getInventoryConfig();
      final baseCurrency = existingInv?.inventoryBaseCurrencyId ?? 'YER';
      final newInventoryConfig = CompanyInventoryConfig(
        companyId: state.companyId,
        inventoryBaseCurrencyId: baseCurrency,
        defaultCostingMethod: _costingMethod,
        allowNegativeStock: _allowNegativeStock,
        autoPostAccountingEntries: _autoPostEntries,
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.saveInventoryConfig(newInventoryConfig);

      ref.invalidate(companyAccountingConfigProvider);
      ref.invalidate(companyInventoryConfigProvider);

      if (mounted) {
        showAppSnackBar(
          context,
          message: 'تم حفظ الحسابات الافتراضية وإعدادات التهيئة للحزم بنجاح',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'خطأ أثناء حفظ الحسابات الافتراضية: $e',
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
    final asyncAccounting = ref.watch(companyAccountingConfigProvider);
    final asyncInventory = ref.watch(companyInventoryConfigProvider);

    return asyncAccounting.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ في تحميل البيانات: $err')),
      data: (accountingConfig) {
        return asyncInventory.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('خطأ في تحميل البيانات: $err')),
          data: (inventoryConfig) {
            _hydrate(accountingConfig, inventoryConfig);

            return ListView(
              padding: AppConstants.pageInsets(context),
              children: [
                Text(
                  isArabic
                      ? 'اختر الحسابات المحاسبية الافتراضية وشروط تشغيل حزم النظام'
                      : 'Configure default GL accounts & package operational defaults',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // SECTION 1: INVENTORY SETUP & ACCOUNTS
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isArabic
                                ? 'تهيئة وحسابات المخزون'
                                : 'Inventory Accounts & Setup',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب أصل المخزون الافتراضي'
                            : 'Default Inventory Asset Account',
                        role: AccountRole.inventory,
                        selectedUuid: _mappings[AccountRole.inventory],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.inventory] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب تكلفة البضاعة المباعة (COGS)'
                            : 'COGS Expense Account',
                        role: AccountRole.cogs,
                        selectedUuid: _mappings[AccountRole.cogs],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.cogs] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب تسويات وفروقات المخزون'
                            : 'Inventory Adjustment Account',
                        role: AccountRole.adjustment,
                        selectedUuid: _mappings[AccountRole.adjustment],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.adjustment] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _costingMethod,
                        decoration: InputDecoration(
                          labelText: isArabic
                              ? 'طريقة تقييم المخزون'
                              : 'Costing Method',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'FIFO',
                            child: Text(
                              isArabic
                                  ? 'الوارد أولاً يصدر أولاً (FIFO)'
                                  : 'First-In, First-Out (FIFO)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'WAVG',
                            child: Text(
                              isArabic
                                  ? 'المتوسط المرجح (WAVG)'
                                  : 'Weighted Average (WAVG)',
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _costingMethod = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile(
                        title: Text(
                          isArabic
                              ? 'الترخيص بالرصيد بالسالب للمخزون'
                              : 'Allow Negative Stock',
                        ),
                        value: _allowNegativeStock,
                        onChanged: (val) {
                          setState(() => _allowNegativeStock = val);
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          isArabic
                              ? 'الترحيل التلقائي للقيود المحاسبية'
                              : 'Auto-Post Accounting Entries',
                        ),
                        value: _autoPostEntries,
                        onChanged: (val) {
                          setState(() => _autoPostEntries = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // SECTION 2: SALES & CUSTOMERS ACCOUNTS
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.point_of_sale_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isArabic
                                ? 'تهيئة وحسابات المبيعات والعملاء'
                                : 'Sales & Customers Accounts',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب إيرادات المبيعات'
                            : 'Sales Revenue Account',
                        role: AccountRole.revenue,
                        selectedUuid: _mappings[AccountRole.revenue],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.revenue] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب العملاء والذمم المدينة'
                            : 'Accounts Receivable Account',
                        role: AccountRole.receivable,
                        selectedUuid: _mappings[AccountRole.receivable],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.receivable] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب الخصم المسموح به للمبيعات'
                            : 'Sales Discount Account',
                        role: AccountRole.discount,
                        selectedUuid: _mappings[AccountRole.discount],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.discount] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب ضريبة المبيعات / القيمة المضافة'
                            : 'Sales Tax / VAT Account',
                        role: AccountRole.tax,
                        selectedUuid: _mappings[AccountRole.tax],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.tax] = uuid;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // SECTION 3: CASH REGISTERS, TREASURIES & PAYMENTS ACCOUNTS
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isArabic
                                ? 'تهيئة وحسابات الصناديق والموردين والمدفوعات'
                                : 'Cash Registers, Treasuries & Payables Accounts',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب صندوق النقدية الرئيسي / الخزينة'
                            : 'Default Cash Register / Treasury Account',
                        role: AccountRole.cash,
                        selectedUuid: _mappings[AccountRole.cash],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.cash] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب الموردين والذمم الدائنة'
                            : 'Accounts Payable Account',
                        role: AccountRole.payable,
                        selectedUuid: _mappings[AccountRole.payable],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.payable] = uuid;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AccountPickerDropdown(
                        label: isArabic
                            ? 'حساب أرباح وخسائر فروقات أسعار العملات'
                            : 'Foreign Exchange Gain/Loss Account',
                        role: AccountRole.fxGainLoss,
                        selectedUuid: _mappings[AccountRole.fxGainLoss],
                        onChanged: (uuid) {
                          setState(() {
                            if (uuid != null) {
                              _mappings[AccountRole.fxGainLoss] = uuid;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // SAVE BUTTON
                AppButton(
                  label: isArabic
                      ? 'حفظ إعدادات التهيئة للحزم والحسابات الافتراضية'
                      : 'Save Package Default Accounts & Settings',
                  expand: true,
                  icon: Icons.save_outlined,
                  isLoading: _saving,
                  onPressed: _saving ? null : _saveAll,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        );
      },
    );
  }
}
