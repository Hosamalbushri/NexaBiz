import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/providers/inventory_valuation_currency_providers.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

import '../../domain/entities/app_currency.dart';
import '../../domain/entities/currency.dart';
import '../providers/currency_providers.dart';
import '../providers/currency_rate_providers.dart';
import '../providers/functional_currency_providers.dart';
import '../widgets/app_searchable_currency_picker.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

enum _CurrencyFilter { all, activeOnly, inactiveOnly }

/// Standardized Master Data UI page for Currencies built with [ModuleListScaffold].
class CurrenciesManagePage extends ConsumerStatefulWidget {
  const CurrenciesManagePage({super.key});

  @override
  ConsumerState<CurrenciesManagePage> createState() =>
      _CurrenciesManagePageState();
}

class _CurrenciesManagePageState extends ConsumerState<CurrenciesManagePage> {
  String _searchQuery = '';
  _CurrencyFilter _filter = _CurrencyFilter.all;

  void _invalidateAllCurrencyProviders() {
    ref.invalidate(allCurrenciesProvider);
    ref.invalidate(activeCurrenciesProvider);
    ref.invalidate(defaultCurrencyProvider);
    ref.invalidate(functionalCurrencyProvider);
    ref.invalidate(functionalCurrencyStateInfoProvider);
    ref.invalidate(accountingBaseCurrencyProvider);
    ref.invalidate(currencyRateListProvider);
    ref.invalidate(availableCurrenciesToAddProvider);
    ref.invalidate(inventoryValuationCurrencyStateProvider);
    ref.invalidate(companyInventoryConfigProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currenciesAsync = ref.watch(allCurrenciesProvider);

    final funcCode =
        ref
            .watch(functionalCurrencyStateInfoProvider)
            .valueOrNull
            ?.currencyCode
            .toUpperCase() ??
        '';
    final valCode =
        ref
            .watch(inventoryValuationCurrencyStateProvider)
            .valueOrNull
            ?.currencyCode
            .toUpperCase() ??
        '';

    final currenciesList = currenciesAsync.valueOrNull ?? const [];

    // Filter currencies by query and status filter chip
    final filteredCurrencies = currenciesList.where((c) {
      if (_filter == _CurrencyFilter.activeOnly && !c.isActive) {
        return false;
      }
      if (_filter == _CurrencyFilter.inactiveOnly && c.isActive) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = c.code.toLowerCase().contains(q);
        final matchAr = c.nameAr.toLowerCase().contains(q);
        final matchEn = c.nameEn.toLowerCase().contains(q);
        final matchSymbol = c.symbol.toLowerCase().contains(q);
        return matchCode || matchAr || matchEn || matchSymbol;
      }
      return true;
    }).toList();

    return ModuleListScaffold<Currency>(
      title: isArabic ? 'قائمة العملات' : 'Currencies List',
      searchQuery: _searchQuery,
      searchHint: isArabic ? 'بحث برمز العملة أو الاسم...' : 'Search code or name...',
      onSearchChanged: (val) {
        setState(() => _searchQuery = val.trim());
      },
      isLoading: currenciesAsync.isLoading && !currenciesAsync.hasValue,
      error: currenciesAsync.error,
      onRetry: () {
        _invalidateAllCurrencyProviders();
      },
      onRefresh: () async {
        _invalidateAllCurrencyProviders();
      },
      emptyTitle: isArabic ? 'لا توجد عملات' : 'No Currencies Found',
      emptyMessage: isArabic
          ? 'لم يتم العثور على عملات تطابق معايير البحث'
          : 'No currencies match your filter criteria',
      emptyIcon: Icons.monetization_on_outlined,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCurrencyDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(isArabic ? 'إضافة عملة' : 'Add Currency'),
      ),
      actions: [
        PopupMenuButton<_CurrencyFilter>(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: isArabic ? 'تصفية' : 'Filter',
          initialValue: _filter,
          onSelected: (filter) => setState(() => _filter = filter),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _CurrencyFilter.all,
              child: Row(
                children: [
                  if (_filter == _CurrencyFilter.all)
                    const Icon(Icons.check_rounded, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(isArabic ? 'عرض الكل' : 'All Currencies'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _CurrencyFilter.activeOnly,
              child: Row(
                children: [
                  if (_filter == _CurrencyFilter.activeOnly)
                    const Icon(Icons.check_rounded, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(isArabic ? 'العملات النشطة فقط' : 'Active Only'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _CurrencyFilter.inactiveOnly,
              child: Row(
                children: [
                  if (_filter == _CurrencyFilter.inactiveOnly)
                    const Icon(Icons.check_rounded, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(isArabic ? 'العملات غير النشطة' : 'Inactive Only'),
                ],
              ),
            ),
          ],
        ),
      ],
      items: filteredCurrencies,
      itemBuilder: (context, currency) {
        return _buildCurrencyItemCard(
          context,
          currency,
          funcCode,
          valCode,
          isArabic,
          theme,
        );
      },
    );
  }

  Widget _buildCurrencyItemCard(
    BuildContext context,
    Currency currency,
    String funcCode,
    String valCode,
    bool isArabic,
    ThemeData theme,
  ) {
    final isFunc =
        funcCode.isNotEmpty && currency.code.toUpperCase() == funcCode;
    final isVal =
        valCode.isNotEmpty && currency.code.toUpperCase() == valCode;

    final hasTxns = ref
            .watch(currencyHasTransactionsProvider(currency.code))
            .valueOrNull ??
        false;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showCurrencyDetails(context, currency, isArabic),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isFunc
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: currency.isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      child: Text(
                        currency.symbol.isNotEmpty
                            ? currency.symbol
                            : currency.code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: currency.isActive
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  currency.code,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  currency.localizedName(isArabic),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currency.nameEn,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'details') {
                          _showCurrencyDetails(context, currency, isArabic);
                        } else if (val == 'edit') {
                          _showEditCurrencyDialog(context, currency);
                        } else if (val == 'set_base') {
                          _showSetAsFunctionalCurrencyDialog(context, currency);
                        } else if (val == 'toggle') {
                          _toggleActive(currency);
                        } else if (val == 'delete') {
                          _confirmDelete(context, currency);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text(isArabic ? 'التفاصيل' : 'Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text(isArabic ? 'تعديل' : 'Edit'),
                            ],
                          ),
                        ),
                        if (!isFunc)
                          PopupMenuItem(
                            value: 'set_base',
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_outlined, size: 20),
                                const SizedBox(width: AppSpacing.xs),
                                Text(isArabic ? 'تعيين كعملة رئيسية' : 'Set as Base'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                (currency.isActive && hasTxns)
                                    ? Icons.lock_outline_rounded
                                    : (currency.isActive
                                        ? Icons.block_rounded
                                        : Icons.check_circle_outline_rounded),
                                size: 20,
                                color: (currency.isActive && hasTxns)
                                    ? theme.colorScheme.outline
                                    : null,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                currency.isActive
                                    ? (hasTxns
                                        ? (isArabic
                                            ? 'تعطيل (مقفلة لوجود حركات)'
                                            : 'Deactivate (Locked)')
                                        : (isArabic ? 'تعطيل' : 'Deactivate'))
                                    : (isArabic ? 'تفعيل' : 'Activate'),
                                style: (currency.isActive && hasTxns)
                                    ? TextStyle(color: theme.colorScheme.outline)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                hasTxns
                                    ? Icons.lock_outline_rounded
                                    : Icons.delete_outline_rounded,
                                size: 20,
                                color: hasTxns
                                    ? theme.colorScheme.outline
                                    : theme.colorScheme.error,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                hasTxns
                                    ? (isArabic
                                        ? 'حذف (مقفلة لوجود حركات)'
                                        : 'Delete (Locked)')
                                    : (isArabic ? 'حذف' : 'Delete'),
                                style: TextStyle(
                                  color: hasTxns
                                      ? theme.colorScheme.outline
                                      : theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppStatusBadge(
                      label: currency.isActive
                          ? (isArabic ? 'نشط' : 'Active')
                          : (isArabic ? 'غير نشط' : 'Inactive'),
                      tone: currency.isActive
                          ? AppStatusTone.success
                          : AppStatusTone.neutral,
                      animate: false,
                    ),
                    if (isFunc)
                      AppStatusBadge(
                        label: isArabic
                            ? 'العملة الرئيسية للشركة'
                            : 'Main Functional Base',
                        tone: AppStatusTone.info,
                        animate: false,
                      ),
                    if (isVal)
                      AppStatusBadge(
                        label: isArabic
                            ? 'تقييم المخزون'
                            : 'Inventory Valuation',
                        tone: AppStatusTone.warning,
                        animate: false,
                      ),
                    if (hasTxns)
                      AppStatusBadge(
                        label: isArabic
                            ? 'مقفلة (توجد حركات)'
                            : 'Locked (Has Txns)',
                        tone: AppStatusTone.neutral,
                        animate: false,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencyDetails(
    BuildContext context,
    Currency currency,
    bool isArabic,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      currency.symbol.isNotEmpty ? currency.symbol : currency.code,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currency.localizedName(isArabic),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currency.code,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              _detailRow(isArabic ? 'الاسم بالإنجليزي' : 'English Name', currency.nameEn),
              _detailRow(isArabic ? 'الاسم بالعربي' : 'Arabic Name', currency.nameAr),
              _detailRow(isArabic ? 'الرمز' : 'Symbol', currency.symbol),
              _detailRow(isArabic ? 'الخانات العشرية' : 'Decimals', '${currency.decimalDigits}'),
              _detailRow(
                isArabic ? 'الحالة' : 'Status',
                currency.isActive
                    ? (isArabic ? 'نشط' : 'Active')
                    : (isArabic ? 'غير نشط' : 'Inactive'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showCreateCurrencyDialog(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    AppCurrency? selectedAppCurrency;
    int decimalDigits = 2;
    bool isDefault = false;
    bool isInventoryValuation = false;

    final existingCurrencies =
        ref.read(allCurrenciesProvider).valueOrNull ?? [];
    final existingCodes =
        existingCurrencies.map((c) => c.code.toUpperCase()).toSet();

    final funcInfo = ref.read(functionalCurrencyStateInfoProvider).valueOrNull;
    final valInfo = ref.read(inventoryValuationCurrencyStateProvider).valueOrNull;
    final isFuncLocked = funcInfo?.isLocked ?? false;
    final isValLocked = valInfo?.isLocked ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isArabic ? 'إضافة عملة جديدة' : 'Add New Currency'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSearchableCurrencyPickerField(
                      selectedPreset: selectedAppCurrency,
                      excludedCodes: existingCodes,
                      onPresetSelected: (appCurrency) {
                        setDialogState(() {
                          selectedAppCurrency = appCurrency;
                          decimalDigits = appCurrency.decimalDigits;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      initialValue: decimalDigits.toString(),
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الخانات العشرية' : 'Decimals',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 0 && parsed <= 6) {
                          setDialogState(() {
                            decimalDigits = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isArabic ? 'العملة الرئيسية للنظام' : 'System Base Currency',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isFuncLocked
                            ? (isArabic
                                ? 'مقفلة: لا يمكن تعيين عملة رئيسية لوجود قيود محاسبية بالمنشأة'
                                : 'Locked: Accounting entries exist for company')
                            : (isArabic
                                ? 'تعيين كعملة محددة للحسابات والقوائم المالية'
                                : 'Set as system functional base currency'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isFuncLocked ? Theme.of(context).colorScheme.error : null,
                        ),
                      ),
                      value: isDefault,
                      onChanged: isFuncLocked
                          ? null
                          : (val) {
                              setDialogState(() {
                                isDefault = val;
                              });
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isArabic
                            ? 'عملة تقييم المخزون'
                            : 'Inventory Valuation Currency',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isValLocked
                            ? (isArabic
                                ? 'مقفلة: لا يمكن تعيين عملة مخزون لوجود حركات مخزون بالمنشأة'
                                : 'Locked: Inventory movements exist for company')
                            : (isArabic
                                ? 'تعيين كعملة معتمدة لحساب تكلفة المخزون'
                                : 'Set as company inventory valuation currency'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isValLocked ? Theme.of(context).colorScheme.error : null,
                        ),
                      ),
                      value: isInventoryValuation,
                      onChanged: isValLocked
                          ? null
                          : (val) {
                              setDialogState(() {
                                isInventoryValuation = val;
                              });
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedAppCurrency == null
                      ? null
                      : () async {
                          final selected = selectedAppCurrency!;
                          final draft = CurrencyDraft(
                            code: selected.code,
                            nameAr: selected.nameAr,
                            nameEn: selected.nameEn,
                            symbol: selected.symbol,
                            decimalDigits: decimalDigits,
                            isDefault: isDefault,
                            isActive: true,
                          );
                          try {
                            await ref
                                .read(currencyRepositoryProvider)
                                .upsert(draft);

                            if (isDefault) {
                              await ref
                                  .read(currencyRepositoryProvider)
                                  .setDefaultCurrency(selected.code);
                            }

                            if (isInventoryValuation) {
                              final initRepo = ref.read(
                                companyInitializationRepositoryProvider,
                              );
                              final existingConfig =
                                  await initRepo.getInventoryConfig();
                              final state = await initRepo.getState();
                              await initRepo.saveInventoryConfig(
                                CompanyInventoryConfig(
                                  companyId: state.companyId,
                                  inventoryBaseCurrencyId: selected.code,
                                  defaultCostingMethod:
                                      existingConfig?.defaultCostingMethod ??
                                      'FIFO',
                                  allowNegativeStock:
                                      existingConfig?.allowNegativeStock ??
                                      false,
                                  autoPostAccountingEntries:
                                      existingConfig
                                          ?.autoPostAccountingEntries ??
                                      true,
                                  updatedAt: DateTime.now().toUtc(),
                                ),
                              );
                            }

                            _invalidateAllCurrencyProviders();

                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            if (mounted) {
                              showAppSnackBar(
                                this.context,
                                message: isArabic
                                    ? 'تمت إضافة العملة بنجاح'
                                    : 'Currency added successfully',
                                isSuccess: true,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showAppSnackBar(
                                this.context,
                                message: e.toString(),
                                isSuccess: false,
                              );
                            }
                          }
                        },
                  child: Text(isArabic ? 'حفظ' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditCurrencyDialog(
    BuildContext context,
    Currency currency,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final nameArCtrl = TextEditingController(text: currency.nameAr);
    final nameEnCtrl = TextEditingController(text: currency.nameEn);
    final symbolCtrl = TextEditingController(text: currency.symbol);
    int decimalDigits = currency.decimalDigits;

    final funcInfo = ref.read(functionalCurrencyStateInfoProvider).valueOrNull;
    final valInfo = ref.read(inventoryValuationCurrencyStateProvider).valueOrNull;
    final isFuncLocked = funcInfo?.isLocked ?? false;
    final isValLocked = valInfo?.isLocked ?? false;

    final currentFuncCode = funcInfo?.currencyCode.toUpperCase() ?? '';
    final currentValCode = valInfo?.currencyCode.toUpperCase() ?? '';

    bool isDefault =
        currency.isDefault ||
        currentFuncCode == currency.code.toUpperCase();
    bool isInventoryValuation =
        currentValCode == currency.code.toUpperCase();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isArabic
                    ? 'تعديل العملة (${currency.code})'
                    : 'Edit Currency (${currency.code})',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameArCtrl,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الاسم بالعربي' : 'Arabic Name',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        labelText:
                            isArabic ? 'الاسم بالإنجليزي' : 'English Name',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: symbolCtrl,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الرمز' : 'Symbol',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      initialValue: decimalDigits.toString(),
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الخانات العشرية' : 'Decimals',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 0 && parsed <= 6) {
                          setDialogState(() {
                            decimalDigits = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isArabic ? 'العملة الرئيسية للنظام' : 'System Base Currency',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isFuncLocked
                            ? (isArabic
                                ? 'مقفلة: توجد قيود محاسبية مسجلة ولا يمكن تغيير العملة الرئيسية'
                                : 'Locked: Accounting entries exist; base currency locked')
                            : (isArabic
                                ? 'تعيين كعملة محددة للحسابات والقوائم المالية'
                                : 'Set as system functional base currency'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isFuncLocked ? Theme.of(context).colorScheme.error : null,
                        ),
                      ),
                      value: isDefault,
                      onChanged: isFuncLocked
                          ? null
                          : (val) {
                              setDialogState(() {
                                isDefault = val;
                              });
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isArabic
                            ? 'عملة تقييم المخزون'
                            : 'Inventory Valuation Currency',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isValLocked
                            ? (isArabic
                                ? 'مقفلة: توجد حركات مخزون مسجلة ولا يمكن تغيير عملة التقييم'
                                : 'Locked: Inventory movements exist; valuation currency locked')
                            : (isArabic
                                ? 'تعيين كعملة معتمدة لحساب تكلفة المخزون'
                                : 'Set as company inventory valuation currency'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isValLocked ? Theme.of(context).colorScheme.error : null,
                        ),
                      ),
                      value: isInventoryValuation,
                      onChanged: isValLocked
                          ? null
                          : (val) {
                              setDialogState(() {
                                isInventoryValuation = val;
                              });
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final draft = CurrencyDraft(
                      uuid: currency.uuid,
                      code: currency.code,
                      nameAr: nameArCtrl.text.trim(),
                      nameEn: nameEnCtrl.text.trim(),
                      symbol: symbolCtrl.text.trim(),
                      decimalDigits: decimalDigits,
                      isDefault: isDefault,
                      isActive: currency.isActive,
                    );
                    try {
                      await ref
                          .read(currencyRepositoryProvider)
                          .upsert(draft);

                      if (isDefault && !isFuncLocked) {
                        await ref
                            .read(currencyRepositoryProvider)
                            .setDefaultCurrency(currency.code);
                      }

                      if (isInventoryValuation && !isValLocked) {
                        final initRepo = ref.read(
                          companyInitializationRepositoryProvider,
                        );
                        final existingConfig =
                            await initRepo.getInventoryConfig();
                        final state = await initRepo.getState();
                        await initRepo.saveInventoryConfig(
                          CompanyInventoryConfig(
                            companyId: state.companyId,
                            inventoryBaseCurrencyId: currency.code,
                            defaultCostingMethod:
                                existingConfig?.defaultCostingMethod ??
                                'FIFO',
                            allowNegativeStock:
                                existingConfig?.allowNegativeStock ??
                                false,
                            autoPostAccountingEntries:
                                existingConfig?.autoPostAccountingEntries ??
                                true,
                            updatedAt: DateTime.now().toUtc(),
                          ),
                        );
                      }

                      _invalidateAllCurrencyProviders();

                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                      if (mounted) {
                        showAppSnackBar(
                          this.context,
                          message: isArabic
                              ? 'تم تحديث العملة بنجاح'
                              : 'Currency updated successfully',
                          isSuccess: true,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        showAppSnackBar(
                          this.context,
                          message: e.toString(),
                          isSuccess: false,
                        );
                      }
                    }
                  },
                  child: Text(isArabic ? 'حفظ' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSetAsFunctionalCurrencyDialog(
    BuildContext context,
    Currency currency,
  ) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final funcInfo = ref.read(functionalCurrencyStateInfoProvider).valueOrNull;
    if (funcInfo?.isLocked == true) {
      showAppSnackBar(
        context,
        message: isArabic
            ? 'مقفلة: لا يمكن تغيير العملة الرئيسية للنظام لوجود قيود محاسبية مسجلة بالمنشأة'
            : 'Cannot change system base currency because accounting entries exist',
        isSuccess: false,
      );
      return;
    }

    final confirmed = await showAppDialog(
      context: context,
      title: isArabic
          ? 'تعيين العملة الرئيسية'
          : 'Set Main Base Currency',
      message: isArabic
          ? 'هل انت متأكد من تعيين ${currency.nameAr} (${currency.code}) كعملة أساسية للنظام؟'
          : 'Are you sure you want to set ${currency.code} as the functional base currency?',
      confirmLabel: isArabic ? 'تأكيد' : 'Confirm',
      cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
    );
    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(currencyRepositoryProvider);
      await repo.setDefaultCurrency(currency.code);
      _invalidateAllCurrencyProviders();
      if (mounted) {
        showAppSnackBar(
          this.context,
          message: isArabic
              ? 'تم تعيين العملة الرئيسية بنجاح'
              : 'Base currency set successfully',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          this.context,
          message: e.toString(),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _toggleActive(Currency currency) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currentFuncCode =
        ref.read(functionalCurrencyStateInfoProvider).valueOrNull?.currencyCode.toUpperCase() ?? '';
    final currentValCode =
        ref.read(inventoryValuationCurrencyStateProvider).valueOrNull?.currencyCode.toUpperCase() ?? '';
    final code = currency.code.toUpperCase();

    if (currency.isActive && (code == currentFuncCode || code == currentValCode)) {
      showAppSnackBar(
        context,
        message: isArabic
            ? 'لا يمكن تعطيل العملة الرئيسية للنظام أو عملة تقييم المخزون الحالية'
            : 'Cannot deactivate active system base currency or inventory valuation currency',
        isSuccess: false,
      );
      return;
    }

    try {
      await ref
          .read(currencyRepositoryProvider)
          .toggleActive(currency.code, !currency.isActive);
      _invalidateAllCurrencyProviders();
      if (mounted) {
        showAppSnackBar(
          context,
          message: currency.isActive
              ? (isArabic ? 'تم تعطيل العملة' : 'Currency deactivated')
              : (isArabic ? 'تم تفعيل العملة' : 'Currency activated'),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          message: e.toString(),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Currency currency) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currentFuncCode =
        ref.read(functionalCurrencyStateInfoProvider).valueOrNull?.currencyCode.toUpperCase() ?? '';
    final currentValCode =
        ref.read(inventoryValuationCurrencyStateProvider).valueOrNull?.currencyCode.toUpperCase() ?? '';
    final code = currency.code.toUpperCase();

    if (code == currentFuncCode || code == currentValCode) {
      showAppSnackBar(
        context,
        message: isArabic
            ? 'لا يمكن حذف العملة الرئيسية للنظام أو عملة تقييم المخزون الحالية'
            : 'Cannot delete active system base currency or inventory valuation currency',
        isSuccess: false,
      );
      return;
    }

    final confirmed = await showAppDialog(
      context: context,
      title: isArabic ? 'حذف العملة' : 'Delete Currency',
      message: isArabic
          ? 'هل أنت تأكد من حذف العملة ${currency.nameAr} (${currency.code})؟'
          : 'Are you sure you want to delete ${currency.code}?',
      confirmLabel: isArabic ? 'حذف' : 'Delete',
      cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(currencyRepositoryProvider)
          .deleteByCode(currency.code);
      _invalidateAllCurrencyProviders();
      if (mounted) {
        showAppSnackBar(
          this.context,
          message: isArabic
              ? 'تم حذف العملة بنجاح'
              : 'Currency deleted successfully',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          this.context,
          message: e.toString(),
          isSuccess: false,
        );
      }
    }
  }
}
