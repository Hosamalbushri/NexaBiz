import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/providers/warehouse_providers.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';

import '../../domain/entities/category.dart';
import '../../domain/services/category_code_generator.dart';
import '../providers/category_providers.dart';

/// Professional, canonical NexaBizForm aligned Category Add/Edit Dialog.
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
  String? _errorMessage;

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

    return NexaBizFormDialog<void>(
      formKey: _formKey,
      title: isEditing
          ? (isAr ? 'تعديل التصنيف' : 'Edit Category')
          : (isAr ? 'إضافة تصنيف جديد' : 'Add New Category'),
      subtitle: isAr
          ? 'حدد المستودع والأب لإنشاء شجرة هرمية ووراثة أسلوب التكلفة'
          : 'Set warehouse & parent for hierarchy',
      icon: isEditing
          ? Icons.edit_note_rounded
          : Icons.create_new_folder_rounded,
      errorMessage: _errorMessage,
      isSubmitting: _saving,
      submitLabel: isAr ? 'حفظ' : 'Save',
      cancelLabel: isAr ? 'إلغاء' : 'Cancel',
      onSubmit: _saving ? null : _save,
      onCancel: _saving ? null : () => Navigator.of(context).pop(),
      size: NexaBizDialogSize.medium,
      children: [
            // Section 1: Category Classification
            NexaBizFormSection(
              title: isAr ? 'نوع التصنيف' : 'Category Type',
              icon: Icons.tune_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_special_outlined, size: 18),
                              const SizedBox(width: 6),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sell_outlined, size: 18),
                              const SizedBox(width: 6),
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
              ],
            ),

            // Section 2: Hierarchy & Location
            NexaBizFormSection(
              title: isAr ? 'الموقع والشجرة الهرمية' : 'Warehouse & Hierarchy',
              icon: Icons.account_tree_outlined,
              children: [
                warehousesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text(
                    isAr ? 'خطأ في تحميل المستودعات' : 'Error loading warehouses',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  data: (warehouses) {
                    if (warehouses.isEmpty) return const SizedBox.shrink();

                    final uniqueWarehouses = warehouses.fold<List<Warehouse>>(
                      [],
                      (acc, wh) {
                        if (!acc.any((x) => x.id == wh.id)) acc.add(wh);
                        return acc;
                      },
                    );

                    final validWarehouseId = uniqueWarehouses.any((w) => w.id == _selectedWarehouseId)
                        ? _selectedWarehouseId
                        : (uniqueWarehouses.firstWhere((w) => w.isDefault, orElse: () => uniqueWarehouses.first).id);

                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: validWarehouseId,
                      decoration: InputDecoration(
                        labelText: isAr ? 'المستودع الرئيسي (الجذر)' : 'Root Warehouse',
                        prefixIcon: const Icon(Icons.warehouse_outlined),
                      ),
                      items: uniqueWarehouses.map((wh) {
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
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (categories) {
                    final uniqueCategories = categories.fold<List<Category>>(
                      [],
                      (acc, cat) {
                        if (!acc.any((x) => x.id == cat.id)) acc.add(cat);
                        return acc;
                      },
                    );

                    final availableParents = uniqueCategories
                        .where((c) => c.id != widget.category?.id && c.isGroup)
                        .toList();

                    final validParentId = availableParents.any((c) => c.id == _selectedParentId)
                        ? _selectedParentId
                        : null;

                    return DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: validParentId,
                      decoration: InputDecoration(
                        labelText: isAr ? 'التصنيف الأب (اختياري)' : 'Parent Category (Optional)',
                        prefixIcon: const Icon(Icons.account_tree_outlined),
                        helperText: isAr
                            ? 'اتركه فارغاً ليصبح تصنيفاً رئيسياً تحت المستودع'
                            : 'Leave empty for root warehouse category',
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            isAr ? '-- بدون (تصنيف رئيسي) --' : '-- None (Root Category) --',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
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
              ],
            ),

            // Section 3: Basic Identification
            NexaBizFormSection(
              title: isAr ? 'البيانات الأساسية' : 'Basic Identification',
              icon: Icons.info_outline,
              children: [
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
              ],
            ),

            // Section 4: Valuation Method
            NexaBizFormSection(
              title: isAr ? 'طريقة التكلفة والتقييم' : 'Cost Valuation',
              icon: Icons.calculate_outlined,
              children: [
                DropdownButtonFormField<CostValuationMethod?>(
                  isExpanded: true,
                  initialValue: _costValuationMethod,
                  decoration: InputDecoration(
                    labelText: isAr ? 'طريقة احتساب التكلفة (تجاوز)' : 'Cost Valuation Method',
                    prefixIcon: const Icon(Icons.calculate_outlined),
                    helperText: isAr
                        ? 'وراثة الإعداد تلقائياً من التصنيف الأب أو المستودع عند اختيار افتراضي'
                        : 'Inherits setting from Parent Category or Warehouse',
                  ),
                  items: [
                    DropdownMenuItem<CostValuationMethod?>(
                      value: null,
                      child: Text(
                        isAr ? 'افتراضي (وراثة من الأب / المستودع)' : 'Inherit from Parent / Warehouse',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    DropdownMenuItem<CostValuationMethod?>(
                      value: CostValuationMethod.fifo,
                      child: Text(
                        isAr ? 'FIFO - الوارد أولاً يصدر أولاً' : 'FIFO (First-In, First-Out)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<CostValuationMethod?>(
                      value: CostValuationMethod.lifo,
                      child: Text(
                        isAr ? 'LIFO - الوارد أخيراً يصدر أولاً' : 'LIFO (Last-In, First-Out)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem<CostValuationMethod?>(
                      value: CostValuationMethod.weightedAverage,
                      child: Text(
                        isAr ? 'Weighted Average - المتوسط المرجح' : 'Weighted Average',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _costValuationMethod = val),
                ),
              ],
            ),
          ],
        );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedWarehouseId == null) {
      setState(() {
        _errorMessage = isAr ? 'يرجى اختيار المستودع' : 'Please select warehouse';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

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
        final ctrlState = ref.read(categoryControllerProvider);
        String errorMsg = isAr
            ? 'حدث خطأ أثناء حفظ التصنيف'
            : 'Failed to save category';
        if (ctrlState is AsyncError) {
          final err = ctrlState.error;
          if (err is JournalException) {
            errorMsg = err.message;
          } else {
            errorMsg = err.toString();
          }
        }

        setState(() {
          _errorMessage = errorMsg;
        });
      }
    }
  }
}

