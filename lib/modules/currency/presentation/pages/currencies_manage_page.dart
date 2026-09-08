import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/errors/currency_exception.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/app_text_field.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/providers/inventory_valuation_currency_providers.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../../domain/entities/currency.dart';
import '../providers/currency_providers.dart';
import '../providers/functional_currency_providers.dart';

enum _CurrencyFilter { all, activeOnly, inactiveOnly }

/// Master Data UI page for Currencies (List, Search, Create, Edit, Toggle Active, View Details).
class CurrenciesManagePage extends ConsumerStatefulWidget {
  const CurrenciesManagePage({super.key});

  @override
  ConsumerState<CurrenciesManagePage> createState() => _CurrenciesManagePageState();
}

class _CurrenciesManagePageState extends ConsumerState<CurrenciesManagePage> {
  String _searchQuery = '';
  _CurrencyFilter _filter = _CurrencyFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currenciesAsync = ref.watch(allCurrenciesProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isArabic ? 'إدارة العملات' : 'Currencies Master Data',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCurrencyDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(isArabic ? 'إضافة عملة' : 'Add Currency'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              children: [
                AppTextField(
                  hint: isArabic ? 'بحث برمز العملة أو الاسم...' : 'Search code or name...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    FilterChip(
                      selected: _filter == _CurrencyFilter.all,
                      label: Text(isArabic ? 'الكل' : 'All'),
                      onSelected: (_) => setState(() => _filter = _CurrencyFilter.all),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      selected: _filter == _CurrencyFilter.activeOnly,
                      label: Text(isArabic ? 'نشط فقط' : 'Active Only'),
                      onSelected: (_) => setState(() => _filter = _CurrencyFilter.activeOnly),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      selected: _filter == _CurrencyFilter.inactiveOnly,
                      label: Text(isArabic ? 'غير نشط' : 'Inactive Only'),
                      onSelected: (_) => setState(() => _filter = _CurrencyFilter.inactiveOnly),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: currenciesAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (currencies) {
                final funcCode = ref.watch(functionalCurrencyStateInfoProvider).valueOrNull?.currencyCode.toUpperCase() ?? '';
                final valCode = ref.watch(inventoryValuationCurrencyStateProvider).valueOrNull?.currencyCode.toUpperCase() ?? '';

                final filtered = currencies.where((c) {
                  if (_filter == _CurrencyFilter.activeOnly && !c.isActive) return false;
                  if (_filter == _CurrencyFilter.inactiveOnly && c.isActive) return false;
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

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: isArabic ? 'لا توجد عملات' : 'No Currencies Found',
                    subtitle: isArabic
                        ? 'لم يتم العثور على عملات تطابق معايير البحث'
                        : 'No currencies match your filter criteria',
                    icon: Icons.monetization_on_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    0,
                    AppConstants.pagePadding,
                    80,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final currency = filtered[index];
                    final isFunc = funcCode.isNotEmpty && currency.code.toUpperCase() == funcCode;
                    final isVal = valCode.isNotEmpty && currency.code.toUpperCase() == valCode;

                    return AppCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: currency.isActive
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            currency.symbol.isNotEmpty ? currency.symbol : currency.code,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: currency.isActive
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              currency.code,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                '— ${currency.localizedName(isArabic)}',
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic
                                  ? 'الخانات العشرية: ${currency.decimalDigits}'
                                  : 'Decimals: ${currency.decimalDigits}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isFunc || isVal) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: [
                                  if (isFunc)
                                    AppStatusBadge(
                                      label: isArabic ? 'العملة الرئيسية' : 'Main Currency',
                                      tone: AppStatusTone.info,
                                      animate: false,
                                    ),
                                  if (isVal)
                                    AppStatusBadge(
                                      label: isArabic ? 'تقييم المخزون' : 'Inventory Valuation',
                                      tone: AppStatusTone.info,
                                      animate: false,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppStatusBadge(
                              label: currency.isActive
                                  ? (isArabic ? 'نشط' : 'Active')
                                  : (isArabic ? 'غير نشط' : 'Inactive'),
                              tone: currency.isActive ? AppStatusTone.success : AppStatusTone.neutral,
                              animate: false,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'details') {
                                  _showCurrencyDetails(context, currency, isArabic);
                                } else if (val == 'edit') {
                                  _showEditCurrencyDialog(context, currency);
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
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        currency.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        currency.isActive
                                            ? (isArabic ? 'تعطيل' : 'Deactivate')
                                            : (isArabic ? 'تفعيل' : 'Activate'),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        isArabic ? 'حذف' : 'Delete',
                                        style: TextStyle(color: theme.colorScheme.error),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateCurrencyDialog(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currencies = ref.read(allCurrenciesProvider).valueOrNull ?? [];
    final existingCodes = currencies.map((c) => c.code.toUpperCase()).toList();

    final result = await showDialog<_CurrencyFormResult>(
      context: context,
      builder: (_) => _CurrencyFormDialog(
        existingCodes: existingCodes,
        isCurrentlyFunctionalCurrency: false,
        isCurrentlyInventoryValuationCurrency: false,
      ),
    );
    if (result == null || !mounted) return;
    try {
      // 1. Save Currency Master Record FIRST
      await ref.read(currencyRepositoryProvider).upsert(result.draft);

      // 2. Assign Functional Currency role if requested
      if (result.isFunctionalCurrency) {
        await ref
            .read(functionalCurrencyServiceProvider)
            .setFunctionalCurrency(result.draft.code);
      }

      // 3. Assign Inventory Valuation Currency role if requested
      if (result.isInventoryValuationCurrency) {
        final initRepo = ref.read(companyInitializationRepositoryProvider);
        final state = await initRepo.getState();
        final currentConfig = await initRepo.getInventoryConfig();
        final updatedConfig = (currentConfig ??
                CompanyInventoryConfig(
                  companyId: state.companyId,
                  inventoryBaseCurrencyId: result.draft.code,
                ))
            .copyWith(inventoryBaseCurrencyId: result.draft.code);
        await initRepo.saveInventoryConfig(updatedConfig);
      }

      ref.invalidate(functionalCurrencyStateInfoProvider);
      ref.invalidate(inventoryValuationCurrencyStateProvider);
      ref.invalidate(companyInventoryConfigProvider);
      ref.invalidate(allCurrenciesProvider);
      ref.invalidate(activeCurrenciesProvider);

      if (!mounted) return;
      showAppSnackBar(
        this.context,
        message: isArabic ? 'تم حفظ العملة وتعيين الأدوار بنجاح' : 'Currency saved and roles updated successfully',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is CurrencyValidationException ? e.message : e.toString();
      showAppSnackBar(this.context, message: msg, isSuccess: false);
    }
  }

  Future<void> _showEditCurrencyDialog(BuildContext context, Currency currency) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final funcInfo = ref.read(functionalCurrencyStateInfoProvider).valueOrNull;
    final valInfo = ref.read(inventoryValuationCurrencyStateProvider).valueOrNull;

    final isFunctional = funcInfo?.currencyCode.toUpperCase() == currency.code.toUpperCase();
    final isValuation = valInfo?.currencyCode.toUpperCase() == currency.code.toUpperCase();

    final isFunctionalLocked = isFunctional && (funcInfo?.isLocked ?? false);
    final isValuationLocked = isValuation && (valInfo?.isLocked ?? false);

    final result = await showDialog<_CurrencyFormResult>(
      context: context,
      builder: (_) => _CurrencyFormDialog(
        initialCurrency: currency,
        isCurrentlyFunctionalCurrency: isFunctional,
        isCurrentlyInventoryValuationCurrency: isValuation,
        isFunctionalLocked: isFunctionalLocked,
        isValuationLocked: isValuationLocked,
      ),
    );
    if (result == null || !mounted) return;
    try {
      // 1. Update Currency Master Record FIRST
      await ref.read(currencyRepositoryProvider).upsert(result.draft);

      // 2. Assign or clear Functional Currency role independently
      if (result.isFunctionalCurrency && !isFunctional) {
        await ref
            .read(functionalCurrencyServiceProvider)
            .setFunctionalCurrency(result.draft.code);
      } else if (!result.isFunctionalCurrency && isFunctional) {
        if (!isFunctionalLocked) {
          await ref.read(currencyRepositoryProvider).setDefaultCurrency('');
        }
      }

      // 3. Assign or clear Inventory Valuation Currency role independently
      if (result.isInventoryValuationCurrency && !isValuation) {
        final initRepo = ref.read(companyInitializationRepositoryProvider);
        final state = await initRepo.getState();
        final currentConfig = await initRepo.getInventoryConfig();
        final updatedConfig = (currentConfig ??
                CompanyInventoryConfig(
                  companyId: state.companyId,
                  inventoryBaseCurrencyId: result.draft.code,
                ))
            .copyWith(inventoryBaseCurrencyId: result.draft.code);
        await initRepo.saveInventoryConfig(updatedConfig);
      } else if (!result.isInventoryValuationCurrency && isValuation) {
        if (!isValuationLocked) {
          final initRepo = ref.read(companyInitializationRepositoryProvider);
          final currentConfig = await initRepo.getInventoryConfig();
          if (currentConfig != null) {
            await initRepo.saveInventoryConfig(
              currentConfig.copyWith(inventoryBaseCurrencyId: ''),
            );
          }
        }
      }

      ref.invalidate(functionalCurrencyStateInfoProvider);
      ref.invalidate(inventoryValuationCurrencyStateProvider);
      ref.invalidate(companyInventoryConfigProvider);
      ref.invalidate(allCurrenciesProvider);
      ref.invalidate(activeCurrenciesProvider);

      if (!mounted) return;
      showAppSnackBar(
        this.context,
        message: isArabic ? 'تم تحديث العملة وتحديث الأدوار بنجاح' : 'Currency and role assignments updated successfully',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is CurrencyValidationException ? e.message : e.toString();
      showAppSnackBar(this.context, message: msg, isSuccess: false);
    }
  }

  Future<void> _toggleActive(Currency currency) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final willDeactivate = currency.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(willDeactivate
            ? (isArabic ? 'تأكيد التعطيل' : 'Confirm Deactivation')
            : (isArabic ? 'تأكيد التفعيل' : 'Confirm Activation')),
        content: Text(willDeactivate
            ? (isArabic
                ? 'هل أنت تأكد من تعطيل العملة (${currency.code})؟ لن تظهر العملة المعطلة في المعاملات الجديدة.'
                : 'Are you sure you want to deactivate currency (${currency.code})? Inactive currencies will not appear in new transactions.')
            : (isArabic
                ? 'هل أنت تأكد من تفعيل العملة (${currency.code})؟'
                : 'Are you sure you want to activate currency (${currency.code})?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(willDeactivate
                ? (isArabic ? 'تعطيل' : 'Deactivate')
                : (isArabic ? 'تفعيل' : 'Activate')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(currencyRepositoryProvider)
          .toggleActive(currency.code, !currency.isActive);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: currency.isActive
            ? (isArabic ? 'تم تعطيل العملة' : 'Currency deactivated')
            : (isArabic ? 'تم تفعيل العملة' : 'Currency activated'),
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Currency currency) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Deletion'),
        content: Text(
          isArabic
              ? 'هل أنت تأكد من حذف العملة (${currency.code})؟ لن يؤثر الحذف على المعاملات التاريخية.'
              : 'Are you sure you want to delete currency (${currency.code})? Historical transactions will remain preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
            ),
            child: Text(isArabic ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref.read(currencyRepositoryProvider).deleteByCode(currency.code);
      if (!mounted) return;
      showAppSnackBar(
        this.context,
        message: isArabic ? 'تم حذف العملة' : 'Currency deleted',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(this.context, message: e.toString(), isSuccess: false);
    }
  }

  void _showCurrencyDetails(BuildContext context, Currency currency, bool isArabic) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${currency.code} — ${currency.localizedName(isArabic)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(isArabic ? 'معرف UUID:' : 'UUID:', currency.uuid),
              _detailRow(isArabic ? 'الرمز:' : 'Symbol:', currency.symbol),
              _detailRow(isArabic ? 'الاسم بالعربية:' : 'Arabic Name:', currency.nameAr),
              _detailRow(isArabic ? 'الاسم بالإنجليزية:' : 'English Name:', currency.nameEn),
              _detailRow(isArabic ? 'الخانات العشرية:' : 'Decimal Digits:', currency.decimalDigits.toString()),
              _detailRow(
                isArabic ? 'الحالة:' : 'Status:',
                currency.isActive ? (isArabic ? 'نشط' : 'Active') : (isArabic ? 'غير نشط' : 'Inactive'),
              ),
              _detailRow(
                isArabic ? 'تاريخ الإنشاء:' : 'Created At:',
                dateFormat.format(currency.createdAt.toLocal()),
              ),
              _detailRow(
                isArabic ? 'تاريخ التعديل:' : 'Updated At:',
                dateFormat.format(currency.updatedAt.toLocal()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}

class _CurrencyFormResult {
  const _CurrencyFormResult({
    required this.draft,
    required this.isFunctionalCurrency,
    required this.isInventoryValuationCurrency,
  });

  final CurrencyDraft draft;
  final bool isFunctionalCurrency;
  final bool isInventoryValuationCurrency;
}

class _CurrencyFormDialog extends StatefulWidget {
  const _CurrencyFormDialog({
    this.initialCurrency,
    this.existingCodes = const [],
    this.isCurrentlyFunctionalCurrency = false,
    this.isCurrentlyInventoryValuationCurrency = false,
    this.isFunctionalLocked = false,
    this.isValuationLocked = false,
  });

  final Currency? initialCurrency;
  final List<String> existingCodes;
  final bool isCurrentlyFunctionalCurrency;
  final bool isCurrentlyInventoryValuationCurrency;
  final bool isFunctionalLocked;
  final bool isValuationLocked;

  @override
  State<_CurrencyFormDialog> createState() => _CurrencyFormDialogState();
}

class _CurrencyFormDialogState extends State<_CurrencyFormDialog> {
  late TextEditingController _codeController;
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _symbolController;
  late TextEditingController _decimalsController;
  late bool _isActive;
  late bool _isFunctionalCurrency;
  late bool _isInventoryValuationCurrency;
  String? _codeError;
  String? _decimalsError;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCurrency;
    _codeController = TextEditingController(text: c?.code ?? '');
    _nameArController = TextEditingController(text: c?.nameAr ?? '');
    _nameEnController = TextEditingController(text: c?.nameEn ?? '');
    _symbolController = TextEditingController(text: c?.symbol ?? '');
    _decimalsController = TextEditingController(text: (c?.decimalDigits ?? 2).toString());
    _isActive = c?.isActive ?? true;
    _isFunctionalCurrency = widget.isCurrentlyFunctionalCurrency;
    _isInventoryValuationCurrency = widget.isCurrentlyInventoryValuationCurrency;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _symbolController.dispose();
    _decimalsController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _codeError = null;
      _decimalsError = null;
    });

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final code = _codeController.text.trim().toUpperCase();
    final nameAr = _nameArController.text.trim();
    final nameEn = _nameEnController.text.trim();
    final symbol = _symbolController.text.trim();
    final decimalsParsed = int.tryParse(_decimalsController.text.trim());

    if (code.isEmpty) {
      setState(() => _codeError = isArabic ? 'رمز العملة مطلوب' : 'Currency code is required');
      return;
    }

    if (code.length < 2 || code.length > 5) {
      setState(() => _codeError = isArabic ? 'رمز العملة يجب أن يكون بين 2 و 5 أحرف' : 'Currency code must be 2 to 5 characters');
      return;
    }

    if (widget.initialCurrency == null && widget.existingCodes.contains(code)) {
      setState(() => _codeError = isArabic ? 'رمز العملة مستخدم بالفعل' : 'Currency code already in use');
      return;
    }

    if (decimalsParsed == null || decimalsParsed < 0 || decimalsParsed > 6) {
      setState(() => _decimalsError = isArabic ? 'الخانات العشرية يجب أن تكون بين 0 و 6' : 'Decimal precision must be between 0 and 6');
      return;
    }

    final draft = CurrencyDraft(
      uuid: widget.initialCurrency?.uuid,
      code: code,
      nameAr: nameAr,
      nameEn: nameEn,
      symbol: symbol,
      decimalDigits: decimalsParsed,
      isActive: _isActive,
    );

    try {
      draft.validate();
      Navigator.of(context).pop(
        _CurrencyFormResult(
          draft: draft,
          isFunctionalCurrency: _isFunctionalCurrency,
          isInventoryValuationCurrency: _isInventoryValuationCurrency,
        ),
      );
    } on CurrencyValidationException catch (e) {
      showAppSnackBar(context, message: e.message, isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isEdit = widget.initialCurrency != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? (isArabic ? 'تعديل عملة' : 'Edit Currency')
            : (isArabic ? 'إضافة عملة جديدة' : 'Add New Currency'),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _codeController,
                label: isArabic ? 'رمز العملة (ISO)' : 'Currency Code (ISO)',
                hint: 'e.g. USD, SAR, YER',
                enabled: !isEdit,
                errorText: _codeError,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _nameArController,
                label: isArabic ? 'الاسم بالعربية' : 'Arabic Name',
                hint: 'مثال: دولار أمريكي',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _nameEnController,
                label: isArabic ? 'الاسم بالإنجليزية' : 'English Name',
                hint: 'e.g. US Dollar',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _symbolController,
                label: isArabic ? 'الرمز' : 'Symbol',
                hint: r'e.g. $, ر.س, €',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _decimalsController,
                label: isArabic ? 'الخانات العشرية (0-6)' : 'Decimal Precision (0-6)',
                keyboardType: TextInputType.number,
                errorText: _decimalsError,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                title: Text(isArabic ? 'عملة نشطة' : 'Active Currency'),
                subtitle: Text(
                  isArabic
                      ? 'العملات النشطة تظهر في خيارات المعاملات وسعر الصرف.'
                      : 'Active currencies appear in transaction and rate selectors.',
                ),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  isArabic ? 'أدوار العملة للشركة (Company Roles)' : 'Company Currency Roles',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              CheckboxListTile(
                title: Text(isArabic ? 'استخدام كعملة وظيفية (رئيسية) للشركة' : 'Use as company main/functional currency'),
                subtitle: Text(
                  widget.isFunctionalLocked
                      ? (isArabic
                          ? 'مقفلة: توجد قيود محاسبية مرحلة كُتبت بهذه العملة'
                          : 'Locked: Posted accounting transactions exist')
                      : (isArabic
                          ? 'العملة الأساسية للدفاتر والمستندات المحاسبية'
                          : 'Base accounting & ledger currency'),
                  style: TextStyle(
                    color: widget.isFunctionalLocked ? Colors.red.shade700 : null,
                  ),
                ),
                value: _isFunctionalCurrency,
                onChanged: widget.isFunctionalLocked
                    ? null
                    : (val) => setState(() => _isFunctionalCurrency = val ?? false),
              ),
              CheckboxListTile(
                title: Text(isArabic ? 'استخدام كعملة تقييم المخزون' : 'Use as inventory valuation currency'),
                subtitle: Text(
                  widget.isValuationLocked
                      ? (isArabic
                          ? 'مقفلة: توجد طبقات تكلفة أو سندات مخزنية مسجلة بهذه العملة'
                          : 'Locked: Inventory transactions or cost layers exist')
                      : (isArabic
                          ? 'عملة تقييم التكلفة وطبقات المخزون'
                          : 'Base currency for inventory cost layers'),
                  style: TextStyle(
                    color: widget.isValuationLocked ? Colors.red.shade700 : null,
                  ),
                ),
                value: _isInventoryValuationCurrency,
                onChanged: widget.isValuationLocked
                    ? null
                    : (val) => setState(() => _isInventoryValuationCurrency = val ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        AppButton(
          label: isEdit ? (isArabic ? 'تحديث' : 'Update') : (isArabic ? 'حفظ' : 'Save'),
          onPressed: _submit,
        ),
      ],
    );
  }
}
