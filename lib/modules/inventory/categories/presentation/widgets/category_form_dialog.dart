import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/providers/warehouse_providers.dart';

import '../../domain/entities/category.dart';
import '../../domain/services/category_code_generator.dart';
import '../providers/category_providers.dart';

/// Professional, design-system aligned Category Add/Edit Dialog.
class CategoryFormDialog extends ConsumerStatefulWidget {
  const CategoryFormDialog({
    super.key,
    this.category,
    this.initialWarehouseId,
    this.initialParentId,
  });

  final Category? category;
  final String? initialWarehouseId;
  final String? initialParentId;

  static Future<void> show(
    BuildContext context, {
    Category? category,
    String? initialWarehouseId,
    String? initialParentId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(
        category: category,
        initialWarehouseId: initialWarehouseId,
        initialParentId: initialParentId,
      ),
    );
  }

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;

  String? _selectedWarehouseId;
  String? _selectedParentId;
  CostValuationMethod? _costValuationMethod;
  bool _isGroup = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _codeCtrl = TextEditingController(text: cat?.code ?? '');
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _selectedWarehouseId = cat?.warehouseId ?? widget.initialWarehouseId;
    _selectedParentId = cat?.parentId ?? widget.initialParentId;
    _costValuationMethod = cat?.costValuationMethod;
    _isGroup = cat?.isGroup ?? (widget.initialParentId == null);

    if (cat == null && _codeCtrl.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoGenerateCode();
      });
    }
  }

  Future<void> _autoGenerateCode() async {
    if (widget.category != null || _selectedWarehouseId == null) return;
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final generator = CategoryCodeGenerator(repo);
      Category? parentCat;
      if (_selectedParentId != null) {
        parentCat = await repo.getCategoryById(_selectedParentId!);
      }
      final code = await generator.generate(
        warehouseId: _selectedWarehouseId!,
        parentCategory: parentCat,
      );
      if (mounted && _codeCtrl.text.isEmpty) {
        setState(() {
          _codeCtrl.text = code;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.category != null;
    final isAr = l10n.localeName == 'ar';

    final warehousesAsync = ref.watch(warehousesListStreamProvider);
    final categoriesAsync = _selectedWarehouseId != null
        ? ref.watch(categoriesForWarehouseStreamProvider(_selectedWarehouseId!))
        : const AsyncValue<List<Category>>.data([]);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.surface),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.create_new_folder_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? (isAr ? 'تعديل التصنيف' : 'Edit Category')
                              : (isAr ? 'إضافة تصنيف جديد' : 'Add New Category'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isAr
                              ? 'حدد المستودع والأب لإنشاء شجرة هرمية ووراثة أسلوب التكلفة'
                              : 'Set warehouse & parent for hierarchy and cost valuation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: isAr ? 'إغلاق' : 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Group vs Leaf Category Switch / Segmented Button
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.folder_special_outlined, size: 18),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(isAr ? 'رئيسي (تجميعي)' : 'Group'),
                                    ],
                                  ),
                                ),
                                selected: _isGroup,
                                onSelected: (sel) {
                                  if (sel) setState(() => _isGroup = true);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: ChoiceChip(
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sell_outlined, size: 18),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(isAr ? 'فرعي (للمنتجات)' : 'Leaf'),
                                    ],
                                  ),
                                ),
                                selected: !_isGroup,
                                onSelected: (sel) {
                                  if (sel) setState(() => _isGroup = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 2. Root Warehouse Selector
                      warehousesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text(
                          isAr
                              ? 'خطأ في تحميل المستودعات'
                              : 'Error loading warehouses',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        data: (warehouses) {
                          if (_selectedWarehouseId == null &&
                              warehouses.isNotEmpty) {
                            final defaultWh = warehouses.firstWhere(
                              (w) => w.isDefault,
                              orElse: () => warehouses.first,
                            );
                            _selectedWarehouseId = defaultWh.id;
                          }
                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _selectedWarehouseId,
                            decoration: InputDecoration(
                              labelText: isAr
                                  ? 'المستودع الرئيسي (الجذر)'
                                  : 'Root Warehouse',
                              prefixIcon: const Icon(Icons.warehouse_outlined),
                            ),
                            items: warehouses.map((wh) {
                              return DropdownMenuItem(
                                value: wh.id,
                                child: Text(
                                  wh.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedWarehouseId = val;
                                _selectedParentId = null;
                                if (!isEditing) _codeCtrl.clear();
                              });
                              _autoGenerateCode();
                            },
                            validator: (val) => val == null
                                ? (isAr ? 'يرجى اختيار المستودع' : 'Select warehouse')
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3. Parent Category Selector (Hierarchy)
                      categoriesAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                        data: (categories) {
                          final availableParents = categories
                              .where((c) => c.id != widget.category?.id && c.isGroup)
                              .toList();

                          return DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _selectedParentId,
                            decoration: InputDecoration(
                              labelText: isAr
                                  ? 'التصنيف الأب (اختياري)'
                                  : 'Parent Category (Optional)',
                              prefixIcon:
                                  const Icon(Icons.account_tree_outlined),
                              helperText: isAr
                                  ? 'اتركه فارغاً ليصبح تصنيفاً رئيسياً تحت المستودع'
                                  : 'Leave empty for root warehouse category',
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  isAr
                                      ? '-- بدون (تصنيف رئيسي) --'
                                      : '-- None (Root Category) --',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              ...availableParents.map((cat) {
                                return DropdownMenuItem<String?>(
                                  value: cat.id,
                                  child: Text(
                                    '${cat.code} - ${cat.name}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedParentId = val);
                              if (!isEditing) _codeCtrl.clear();
                              _autoGenerateCode();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 4. Category Code
                      TextFormField(
                        controller: _codeCtrl,
                        decoration: InputDecoration(
                          labelText: isAr ? 'كود التصنيف' : 'Category Code',
                          hintText: 'e.g. 1000, 1001',
                          prefixIcon: const Icon(Icons.qr_code_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.auto_awesome_rounded),
                            tooltip: isAr ? 'توليد كود تلقائي' : 'Auto Generate Code',
                            onPressed: () {
                              _codeCtrl.clear();
                              _autoGenerateCode();
                            },
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? (isAr ? 'يرجى إدخال كود التصنيف' : 'Enter code')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 5. Category Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: isAr ? 'اسم التصنيف' : 'Category Name',
                          hintText: 'e.g. عصائر, مشروبات',
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? (isAr ? 'يرجى إدخال اسم التصنيف' : 'Enter name')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 6. Cost Valuation Method Override
                      DropdownButtonFormField<CostValuationMethod?>(
                        isExpanded: true,
                        initialValue: _costValuationMethod,
                        decoration: InputDecoration(
                          labelText: isAr
                              ? 'طريقة احتساب التكلفة (تجاوز)'
                              : 'Cost Valuation Method',
                          prefixIcon: const Icon(Icons.calculate_outlined),
                          helperText: isAr
                              ? 'وراثة الإعداد تلقائياً من التصنيف الأب أو المستودع عند اختيار افتراضي'
                              : 'Inherits setting from Parent Category or Warehouse',
                        ),
                        items: [
                          DropdownMenuItem<CostValuationMethod?>(
                            value: null,
                            child: Text(
                              isAr
                                  ? 'افتراضي (وراثة من الأب / المستودع)'
                                  : 'Inherit from Parent / Warehouse',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          DropdownMenuItem<CostValuationMethod?>(
                            value: CostValuationMethod.fifo,
                            child: Text(
                              isAr
                                  ? 'FIFO - الوارد أولاً يصدر أولاً'
                                  : 'FIFO (First-In, First-Out)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem<CostValuationMethod?>(
                            value: CostValuationMethod.lifo,
                            child: Text(
                              isAr
                                  ? 'LIFO - الوارد أخيراً يصدر أولاً'
                                  : 'LIFO (Last-In, First-Out)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem<CostValuationMethod?>(
                            value: CostValuationMethod.weightedAverage,
                            child: Text(
                              isAr
                                  ? 'Weighted Average - المتوسط المرجح'
                                  : 'Weighted Average',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _costValuationMethod = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: isAr ? 'إلغاء' : 'Cancel',
                      variant: AppButtonVariant.outlined,
                      expand: true,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: isAr ? 'حفظ' : 'Save',
                      variant: AppButtonVariant.filled,
                      expand: true,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedWarehouseId == null) {
      showAppSnackBar(
        context,
        message: isAr ? 'يرجى اختيار المستودع' : 'Please select warehouse',
        isSuccess: false,
      );
      return;
    }

    setState(() => _saving = true);

    // Compute level dynamically based on parent level
    int calculatedLevel = 0;
    if (_selectedParentId != null) {
      try {
        final parent = await ref
            .read(categoryRepositoryProvider)
            .getCategoryById(_selectedParentId!);
        if (parent != null) {
          calculatedLevel = parent.level + 1;
        }
      } catch (_) {}
    }

    final now = DateTime.now().toUtc();
    final cat = Category(
      id: widget.category?.id ?? generateUuidV4(),
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      warehouseId: _selectedWarehouseId!,
      parentId: _selectedParentId,
      level: calculatedLevel,
      isGroup: _isGroup,
      isActive: widget.category?.isActive ?? true,
      costValuationMethod: _costValuationMethod,
      createdAt: widget.category?.createdAt ?? now,
      updatedAt: now,
      version: widget.category?.version ?? 1,
    );

    final success = await ref
        .read(categoryControllerProvider.notifier)
        .saveCategory(cat);

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.of(context).pop();
        showAppSnackBar(
          context,
          message: isAr
              ? 'تم حفظ التصنيف بنجاح'
              : 'Category saved successfully',
          isSuccess: true,
        );
      } else {
        showAppSnackBar(
          context,
          message: isAr
              ? 'حدث خطأ أثناء حفظ التصنيف'
              : 'Failed to save category',
          isSuccess: false,
        );
      }
    }
  }
}
