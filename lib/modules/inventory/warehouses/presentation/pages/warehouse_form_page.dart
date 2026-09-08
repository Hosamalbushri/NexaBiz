import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/widgets/app_account_search_picker.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';

import '../../domain/entities/warehouse.dart';
import '../../domain/entities/warehouse_accounting_binding.dart';
import '../../domain/services/warehouse_validator.dart';
import '../providers/warehouse_providers.dart';

class WarehouseFormPage extends ConsumerStatefulWidget {
  const WarehouseFormPage({super.key, this.warehouse});

  final Warehouse? warehouse;

  @override
  ConsumerState<WarehouseFormPage> createState() => _WarehouseFormPageState();
}

class _WarehouseFormPageState extends ConsumerState<WarehouseFormPage> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _managerCtrl;

  late bool _isDefault;
  CostValuationMethod? _costValuationMethod;
  bool _isLoadingBinding = true;
  bool _isSaving = false;

  String? _inventoryAssetAccountId;
  String? _cogsAccountId;
  String? _adjustmentAccountId;
  String? _salesRevenueAccountId;
  String? _salesReturnAccountId;
  String? _salesDiscountAccountId;

  bool get isEditing => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    final wh = widget.warehouse;
    _codeCtrl = TextEditingController(text: wh?.code ?? '');
    _nameCtrl = TextEditingController(text: wh?.name ?? '');
    _addressCtrl = TextEditingController(text: wh?.address ?? '');
    _phoneCtrl = TextEditingController(text: wh?.phone ?? '');
    _managerCtrl = TextEditingController(text: wh?.managerName ?? '');
    _isDefault = wh?.isDefault ?? false;
    _costValuationMethod = wh?.costValuationMethod;

    _loadExistingBinding();
  }

  Future<void> _loadExistingBinding() async {
    final wh = widget.warehouse;
    if (wh != null) {
      final bindingRepo = ref.read(
        warehouseAccountingBindingRepositoryProvider,
      );
      final binding = await bindingRepo.getBindingForWarehouse(wh.id);
      if (mounted && binding != null) {
        setState(() {
          _inventoryAssetAccountId = binding.inventoryAssetAccountId;
          _cogsAccountId = binding.cogsAccountId;
          _adjustmentAccountId = binding.inventoryAdjustmentAccountId;
          _salesRevenueAccountId = binding.salesRevenueAccountId;
          _salesReturnAccountId = binding.salesReturnAccountId;
          _salesDiscountAccountId = binding.salesDiscountAccountId;
        });
      }
    }
    if (mounted) {
      setState(() => _isLoadingBinding = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _managerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = l10n.localeName == 'ar';

    final accountsAsync = ref.watch(allAccountsProvider);
    final accounts = accountsAsync.valueOrNull ?? [];

    String resolveAccountName(String? uuid) {
      if (uuid == null || uuid.isEmpty) return '';
      for (final acc in accounts) {
        if (acc.uuid == uuid || acc.accountCode == uuid) {
          return '${acc.accountCode} - ${acc.name}';
        }
      }
      return uuid;
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isEditing
            ? (isAr ? 'تعديل بيانات المستودع' : 'Edit Warehouse Details')
            : (isAr ? 'إضافة مستودع جديد' : 'New Warehouse Entry'),
        showBackButton: true,
      ),
      body: _isLoadingBinding
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    100, // Space for bottom action bar
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Executive Hero Header Card
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isEditing
                                        ? Icons.warehouse_rounded
                                        : Icons.add_business_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEditing
                                            ? (isAr
                                                ? 'تعديل بيانات المستودع والربط'
                                                : 'Edit Warehouse Configuration')
                                            : (isAr
                                                ? 'تهيئة مستودع جديد'
                                                : 'Setup New Warehouse'),
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isAr
                                            ? 'قم بتنظيم البيانات الأساسية، سياسة التكلفة المعتمدة، وربط حسابات المخزون بالدليل'
                                            : 'Configure core details, costing methodology, and chart of accounts mapping',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 1: Basic Information
                          _FormSectionCard(
                            stepNumber: '1',
                            title: isAr
                                ? 'البيانات الأساسية'
                                : 'Basic Information',
                            subtitle: isAr
                                ? 'كود المستودع والاسم والمسؤول المباشر'
                                : 'Warehouse code, name and assigned manager',
                            icon: Icons.store_rounded,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _codeCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr
                                        ? 'كود المستودع *'
                                        : 'Warehouse Code *',
                                    hintText: 'WH-01',
                                    prefixIcon: const Icon(
                                      Icons.qr_code_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr
                                        ? 'اسم المستودع *'
                                        : 'Warehouse Name *',
                                    hintText: isAr
                                        ? 'المستودع الرئيسي'
                                        : 'Main Warehouse',
                                    prefixIcon: const Icon(
                                      Icons.storefront_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _managerCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr
                                        ? 'أمين / مدير المستودع'
                                        : 'Warehouse Manager',
                                    hintText: isAr
                                        ? 'اسم المسؤول عن المستودع'
                                        : 'Manager Name',
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 20,
                                    ),
                                   ),
                                 ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 2: Contact & Location
                          _FormSectionCard(
                            stepNumber: '2',
                            title: isAr
                                ? 'التواصل والموقع الجغرافي'
                                : 'Contact & Location',
                            subtitle: isAr
                                ? 'رقم الهاتف وعنوان الموقع الفيزيائي'
                                : 'Contact numbers and physical address',
                            icon: Icons.location_on_outlined,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: isAr
                                        ? 'رقم الهاتف'
                                        : 'Phone Number',
                                    prefixIcon: const Icon(
                                      Icons.phone_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextField(
                                  controller: _addressCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr
                                        ? 'العنوان / الموقع'
                                        : 'Physical Address',
                                    prefixIcon: const Icon(
                                      Icons.map_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 3: Cost Valuation Method
                          _FormSectionCard(
                            stepNumber: '3',
                            title: isAr
                                ? 'سياسة احتساب التكلفة'
                                : 'Cost Valuation Policy',
                            subtitle: isAr
                                ? 'طريقة تتبع واحتساب تكلفة البضاعة في المستودع'
                                : 'Costing method used for valuation layers',
                            icon: Icons.calculate_outlined,
                            child: DropdownButtonFormField<CostValuationMethod?>(
                              isExpanded: true,
                              initialValue: _costValuationMethod,
                              decoration: InputDecoration(
                                labelText: isAr
                                    ? 'طريقة احتساب التكلفة'
                                    : 'Valuation Methodology',
                                prefixIcon: const Icon(
                                  Icons.account_tree_outlined,
                                  size: 20,
                                ),
                                helperText: isAr
                                    ? 'تحدد كيفية احتساب تكلفة البضاعة المباعة والمنصرفة'
                                    : 'Determines COGS and stock movement issue costs',
                              ),
                              items: [
                                DropdownMenuItem<CostValuationMethod?>(
                                  value: null,
                                  child: Text(
                                    isAr
                                        ? 'افتراضي النظام (المتوسط المرجح - Weighted Average)'
                                        : 'System Default (Weighted Average)',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem<CostValuationMethod?>(
                                  value: CostValuationMethod.fifo,
                                  child: Text(
                                    isAr
                                        ? 'FIFO - الوارد أولاً يصدر أولاً (First-In, First-Out)'
                                        : 'FIFO (First-In, First-Out)',
                                  ),
                                ),
                                DropdownMenuItem<CostValuationMethod?>(
                                  value: CostValuationMethod.lifo,
                                  child: Text(
                                    isAr
                                        ? 'LIFO - الوارد أخيراً يصدر أولاً (Last-In, First-Out)'
                                        : 'LIFO (Last-In, First-Out)',
                                  ),
                                ),
                                DropdownMenuItem<CostValuationMethod?>(
                                  value: CostValuationMethod.weightedAverage,
                                  child: Text(
                                    isAr
                                        ? 'Weighted Average - المتوسط المرجح'
                                        : 'Weighted Average',
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _costValuationMethod = val),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 4: Chart of Accounts Binding
                          _FormSectionCard(
                            stepNumber: '4',
                            title: isAr
                                ? 'التهيئة والربط المحاسبي للمخزون والمبيعات'
                                : 'Inventory & Sales Accounting Binding',
                            subtitle: isAr
                                ? 'تحديد وتخصيص الحسابات المحاسبية لأصل المخزون، تكلفة المبيعات، وتسويات هذا المستودع'
                                : 'Assign explicit accounts for asset, COGS, adjustments, and revenue',
                            icon: Icons.account_balance_outlined,
                            child: Column(
                              children: [
                                _AccountBindingTile(
                                  icon: Icons.inventory_2_outlined,
                                  title: isAr
                                      ? 'حساب أصل المخزون'
                                      : 'Inventory Asset Account',
                                  subtitle: isAr
                                      ? 'الحساب المحاسبي لقيمة المخزون في هذا المستودع'
                                      : 'Ledger account for warehouse stock value',
                                  accountUuid: _inventoryAssetAccountId,
                                  resolvedName: resolveAccountName(
                                    _inventoryAssetAccountId,
                                  ),
                                  onSelect: () async {
                                    final acc = await showAppAccountPicker(
                                      context,
                                      title: isAr
                                          ? 'اختر حساب أصل المخزون'
                                          : 'Select Inventory Asset Account',
                                      initialTypeFilter: AccountType.asset,
                                      selectedUuid: _inventoryAssetAccountId,
                                    );
                                    if (acc != null) {
                                      setState(
                                        () => _inventoryAssetAccountId =
                                            acc.uuid,
                                      );
                                    }
                                  },
                                  onClear: () => setState(
                                    () => _inventoryAssetAccountId = null,
                                  ),
                                ),
                                const Divider(height: 24),
                                _AccountBindingTile(
                                  icon: Icons.shopping_cart_outlined,
                                  title: isAr
                                      ? 'حساب تكلفة البضاعة المباعة (COGS)'
                                      : 'Cost of Goods Sold Account',
                                  subtitle: isAr
                                      ? 'حساب مصروف تكلفة مبيعات هذا المستودع'
                                      : 'Expense account for warehouse COGS',
                                  accountUuid: _cogsAccountId,
                                  resolvedName: resolveAccountName(
                                    _cogsAccountId,
                                  ),
                                  onSelect: () async {
                                    final acc = await showAppAccountPicker(
                                      context,
                                      title: isAr
                                          ? 'اختر حساب تكلفة المبيعات'
                                          : 'Select COGS Account',
                                      initialTypeFilter: AccountType.expense,
                                      selectedUuid: _cogsAccountId,
                                    );
                                    if (acc != null) {
                                      setState(() => _cogsAccountId = acc.uuid);
                                    }
                                  },
                                  onClear: () =>
                                      setState(() => _cogsAccountId = null),
                                ),
                                const Divider(height: 24),
                                _AccountBindingTile(
                                  icon: Icons.tune_outlined,
                                  title: isAr
                                      ? 'حساب تسوية وجرد المخزون'
                                      : 'Inventory Adjustment Account',
                                  subtitle: isAr
                                      ? 'حساب فوارق الجرد والتسويات الاستثنائية'
                                      : 'Account for stock variances and adjustments',
                                  accountUuid: _adjustmentAccountId,
                                  resolvedName: resolveAccountName(
                                    _adjustmentAccountId,
                                  ),
                                  onSelect: () async {
                                    final acc = await showAppAccountPicker(
                                      context,
                                      title: isAr
                                          ? 'اختر حساب تسوية المخزون'
                                          : 'Select Adjustment Account',
                                      selectedUuid: _adjustmentAccountId,
                                    );
                                    if (acc != null) {
                                      setState(
                                        () => _adjustmentAccountId = acc.uuid,
                                      );
                                    }
                                  },
                                  onClear: () => setState(
                                    () => _adjustmentAccountId = null,
                                  ),
                                ),
                                const Divider(height: 24),
                                _AccountBindingTile(
                                  icon: Icons.point_of_sale_outlined,
                                  title: isAr
                                      ? 'حساب إيرادات المبيعات'
                                      : 'Sales Revenue Account',
                                  subtitle: isAr
                                      ? 'حساب إيراد مبيعات بضاعة هذا المستودع'
                                      : 'Revenue account for warehouse sales',
                                  accountUuid: _salesRevenueAccountId,
                                  resolvedName: resolveAccountName(
                                    _salesRevenueAccountId,
                                  ),
                                  onSelect: () async {
                                    final acc = await showAppAccountPicker(
                                      context,
                                      title: isAr
                                          ? 'اختر حساب إيرادات المبيعات'
                                          : 'Select Sales Revenue Account',
                                      initialTypeFilter: AccountType.revenue,
                                      selectedUuid: _salesRevenueAccountId,
                                    );
                                    if (acc != null) {
                                      setState(
                                        () => _salesRevenueAccountId = acc.uuid,
                                      );
                                    }
                                  },
                                  onClear: () => setState(
                                    () => _salesRevenueAccountId = null,
                                  ),
                                ),
                                const Divider(height: 24),
                                _AccountBindingTile(
                                  icon: Icons.assignment_return_outlined,
                                  title: isAr
                                      ? 'حساب مردودات المبيعات'
                                      : 'Sales Return Account',
                                  subtitle: isAr
                                      ? 'حساب مردودات مبيعات هذا المستودع'
                                      : 'Account for warehouse sales returns',
                                  accountUuid: _salesReturnAccountId,
                                  resolvedName: resolveAccountName(
                                    _salesReturnAccountId,
                                  ),
                                  onSelect: () async {
                                    final acc = await showAppAccountPicker(
                                      context,
                                      title: isAr
                                          ? 'اختر حساب مردودات المبيعات'
                                          : 'Select Sales Return Account',
                                      selectedUuid: _salesReturnAccountId,
                                    );
                                    if (acc != null) {
                                      setState(
                                        () => _salesReturnAccountId = acc.uuid,
                                      );
                                    }
                                  },
                                  onClear: () => setState(
                                    () => _salesReturnAccountId = null,
                                  ),
                                ),
                                const Divider(height: 24),
                                _AccountBindingTile(
                                  icon: Icons.discount_outlined,
                                  title: isAr
                                      ? 'حساب الخصم المسموح به'
                                      : 'Sales Discount Account',
                                  subtitle: isAr
                                      ? 'حساب خصم المبيعات المسموح به لعملاء هذا المستودع'
                                      : 'Discount account for warehouse sales',
                                  accountUuid: _salesDiscountAccountId,
                                  resolvedName: resolveAccountName(
                                    _salesDiscountAccountId,
                                  ),
                                  onSelect: () async {
                                    final acc = await showAppAccountPicker(
                                      context,
                                      title: isAr
                                          ? 'اختر حساب الخصم المسموح به'
                                          : 'Select Sales Discount Account',
                                      selectedUuid: _salesDiscountAccountId,
                                    );
                                    if (acc != null) {
                                      setState(
                                        () => _salesDiscountAccountId = acc.uuid,
                                      );
                                    }
                                  },
                                  onClear: () => setState(
                                    () => _salesDiscountAccountId = null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Section 5: Operational Options
                          _FormSectionCard(
                            stepNumber: '5',
                            title: isAr
                                ? 'خيارات التشغيل'
                                : 'Operational Options',
                            subtitle: isAr
                                ? 'تحديد حالة الاعتماد الافتراضي في حركات النظام'
                                : 'Default behavior for new system transactions',
                            icon: Icons.toggle_on_outlined,
                            child: Material(
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SwitchListTile(
                                value: _isDefault,
                                onChanged: (val) =>
                                    setState(() => _isDefault = val),
                                secondary: Icon(
                                  Icons.star_rounded,
                                  color: _isDefault
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  isAr
                                      ? 'اعتماد كمستودع افتراضي رئيسي'
                                      : 'Set as Main Default Warehouse',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  isAr
                                      ? 'يتم اختياره تلقائياً في فاتورة المبيعات وفواتير الشراء وسندات التوريد والصرف'
                                      : 'Automatically pre-selected for sales, purchases, and stock slips',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Bottom Action Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: Text(isAr ? 'إلغاء' : 'Cancel'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _onSave,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  isAr
                                      ? 'حفظ البيانات والربط'
                                      : 'Save Warehouse & Bindings',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    if (_codeCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      showAppSnackBar(
        context,
        message: isAr
            ? 'يرجى إدخال كود واسم المستودع'
            : 'Please enter warehouse code and name',
        isSuccess: false,
      );
      return;
    }

    final targetWarehouseId = widget.warehouse?.id ?? generateUuidV4();
    final newWh = Warehouse(
      id: targetWarehouseId,
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      isDefault: _isDefault,
      costValuationMethod: _costValuationMethod,
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      managerName: _managerCtrl.text.trim().isEmpty
          ? null
          : _managerCtrl.text.trim(),
      version: widget.warehouse?.version ?? 1,
    );

    final companyId = ref.read(currentCompanyIdProvider);
    final binding = WarehouseAccountingBinding(
      id: targetWarehouseId,
      warehouseId: targetWarehouseId,
      inventoryAssetAccountId: _inventoryAssetAccountId,
      cogsAccountId: _cogsAccountId,
      inventoryAdjustmentAccountId: _adjustmentAccountId,
      salesRevenueAccountId: _salesRevenueAccountId,
      salesReturnAccountId: _salesReturnAccountId,
      salesDiscountAccountId: _salesDiscountAccountId,
      companyId: companyId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final validationResult = WarehouseValidator.validate(
      warehouse: newWh,
      binding: binding,
    );

    if (!validationResult.isValid) {
      showAppSnackBar(
        context,
        message: validationResult.errors.join(' • '),
        isSuccess: false,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {

      final success = await ref
          .read(warehouseControllerProvider.notifier)
          .saveWarehouse(newWh, binding: binding);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          showAppSnackBar(
            context,
            message: isAr
                ? 'تم حفظ بيانات المستودع والربط المحاسبي بنجاح'
                : 'Warehouse and accounting configuration saved successfully',
            isSuccess: true,
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showAppSnackBar(
          context,
          message: isAr ? 'حدث خطأ أثناء الحفظ: $e' : 'Save failed: $e',
          isSuccess: false,
        );
      }
    }
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    stepNumber,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _AccountBindingTile extends StatelessWidget {
  const _AccountBindingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accountUuid,
    required this.resolvedName,
    required this.onSelect,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? accountUuid;
  final String resolvedName;
  final VoidCallback onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isLinked = accountUuid != null && accountUuid!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLinked
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            color: isLinked
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isLinked
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isLinked
                          ? (isAr ? 'مربوط' : 'Linked')
                          : (isAr ? 'افتراضي الشركة' : 'Default'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isLinked
                            ? const Color(0xFF047857)
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isLinked
                      ? colorScheme.primary.withValues(alpha: 0.06)
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isLinked
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  isLinked
                      ? resolvedName
                      : (isAr
                          ? 'غير معين (سيتم استخدام حساب الشركة الافتراضي)'
                          : 'Not assigned (Company default account will be used)'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLinked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight:
                        isLinked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          children: [
            OutlinedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.search_rounded, size: 16),
              label: Text(
                isLinked
                    ? (isAr ? 'تغيير' : 'Change')
                    : (isAr ? 'اختيار' : 'Select'),
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            if (isLinked) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colorScheme.error,
                ),
                child: Text(
                  isAr ? 'إلغاء الربط' : 'Clear',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
