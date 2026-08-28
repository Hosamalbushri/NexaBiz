import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import '../../domain/entities/warehouse.dart';
import '../providers/warehouse_providers.dart';

class WarehousesSettingsPage extends ConsumerWidget {
  const WarehousesSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final warehousesAsync = ref.watch(warehousesListStreamProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.localeName == 'ar' ? 'إدارة المستودعات' : 'Warehouse Management',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWarehouseDialog(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.localeName == 'ar' ? 'مستودع جديد' : 'New Warehouse'),
      ),
      body: warehousesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            l10n.localeName == 'ar' ? 'حدث خطأ أثناء تحميل المستودعات' : 'Error loading warehouses',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (warehouses) {
          if (warehouses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.localeName == 'ar' ? 'لا توجد مستودعات مضافة' : 'No warehouses found',
                    style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () => _openWarehouseDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.localeName == 'ar' ? 'إضافة المستودع الأول' : 'Add First Warehouse'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: AppConstants.pageInsets(context),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l10n.localeName == 'ar'
                      ? 'قم بتهيئة وتحديد المستودعات الرئيسية والفروع وتعيين المستودع الافتراضي للنظام'
                      : 'Configure main warehouses, branches, and set default operational location',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SettingsGroupLabel(
                l10n.localeName == 'ar' ? 'المستودعات المسجلة' : 'Registered Warehouses',
              ),
              SettingsGroup(
                children: warehouses.map((wh) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: wh.isDefault ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
                      child: Icon(
                        wh.isDefault ? Icons.warehouse_rounded : Icons.store_outlined,
                        color: wh.isDefault ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            wh.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (wh.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.localeName == 'ar' ? 'افتراضي' : 'Default',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${l10n.localeName == 'ar' ? 'الكود' : 'Code'}: ${wh.code}'
                      '${wh.managerName != null && wh.managerName!.isNotEmpty ? ' • ${l10n.localeName == 'ar' ? 'المسؤول' : 'Manager'}: ${wh.managerName}' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          _openWarehouseDialog(context, ref, warehouse: wh);
                        } else if (val == 'set_default') {
                          _setDefaultWarehouse(context, ref, wh);
                        } else if (val == 'delete') {
                          _confirmDeleteWarehouse(context, ref, wh);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.localeName == 'ar' ? 'تعديل' : 'Edit'),
                            ],
                          ),
                        ),
                        if (!wh.isDefault)
                          PopupMenuItem(
                            value: 'set_default',
                            child: Row(
                              children: [
                                const Icon(Icons.star_outline, size: 20),
                                const SizedBox(width: 8),
                                Text(l10n.localeName == 'ar' ? 'تعيين كافتراضي' : 'Set as Default'),
                              ],
                            ),
                          ),
                        if (!wh.isDefault)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.localeName == 'ar' ? 'حذف' : 'Delete',
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openWarehouseDialog(BuildContext context, WidgetRef ref, {Warehouse? warehouse}) {
    final codeCtrl = TextEditingController(text: warehouse?.code ?? '');
    final nameCtrl = TextEditingController(text: warehouse?.name ?? '');
    final addressCtrl = TextEditingController(text: warehouse?.address ?? '');
    final phoneCtrl = TextEditingController(text: warehouse?.phone ?? '');
    final managerCtrl = TextEditingController(text: warehouse?.managerName ?? '');
    bool isDefault = warehouse?.isDefault ?? false;
    CostValuationMethod? costValuationMethod = warehouse?.costValuationMethod;
    final isEditing = warehouse != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final l10n = AppLocalizations.of(context);
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isAr = l10n.localeName == 'ar';

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modern Header Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isEditing ? Icons.warehouse_rounded : Icons.add_business_rounded,
                            color: colorScheme.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? (isAr ? 'تعديل بيانات المستودع' : 'Edit Warehouse Details')
                                    : (isAr ? 'إضافة مستودع جديد' : 'Add New Warehouse'),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAr
                                    ? 'أدخل بيانات وإعدادات التكلفة للمستودع'
                                    : 'Specify details and cost valuation rules',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: isAr ? 'إغلاق' : 'Close',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Form Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Info Section Header
                          Text(
                            isAr ? 'البيانات الأساسية' : 'Basic Information',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: codeCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'كود المستودع *' : 'Code *',
                                    hintText: 'WH-01',
                                    prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: isAr ? 'اسم المستودع *' : 'Warehouse Name *',
                                    hintText: 'المستودع الرئيسي',
                                    prefixIcon: const Icon(Icons.store_rounded, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: managerCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? 'أمين / مدير المستودع' : 'Warehouse Manager',
                              hintText: isAr ? 'اسم المسؤول عن المستودع' : 'Manager Name',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),
                          // Contact & Location Section
                          Text(
                            isAr ? 'بيانات التواصل والموقع' : 'Contact & Location',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: isAr ? 'رقم الهاتف' : 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: addressCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? 'العنوان / الموقع' : 'Address / Location',
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),
                          // Valuation & Policy Section
                          Text(
                            isAr ? 'سياسة احتساب التكلفة' : 'Cost Valuation Policy',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          DropdownButtonFormField<CostValuationMethod?>(
                            isExpanded: true,
                            initialValue: costValuationMethod,
                            decoration: InputDecoration(
                              labelText: isAr ? 'طريقة احتساب التكلفة الافتراضية' : 'Default Valuation Method',
                              prefixIcon: const Icon(Icons.calculate_outlined, size: 20),
                              helperText: isAr ? 'تطبق على جميع المنتجات ما لم يُحدد خلاف ذلك' : 'Applies to products unless overridden',
                            ),
                            items: [
                              DropdownMenuItem<CostValuationMethod?>(
                                value: null,
                                child: Text(
                                  isAr ? 'افتراضي للنظام (المتوسط المرجح)' : 'System Default (Weighted Average)',
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
                            onChanged: (val) => setStateDialog(() => costValuationMethod = val),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isDefault,
                              onChanged: (val) => setStateDialog(() => isDefault = val ?? false),
                              title: Text(
                                isAr ? 'تعيين كمستودع افتراضي للنظام' : 'Set as Default Warehouse',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                isAr ? 'سيتم اعتماد هذا المستودع تلقائياً في العمليات' : 'Auto-selected for default transactions',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1),
                  // Actions Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isAr ? 'إلغاء' : 'Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () async {
                            if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                              showAppSnackBar(
                                context,
                                message: isAr ? 'يرجى إدخال كود واسم المستودع' : 'Please enter code and name',
                                isSuccess: false,
                              );
                              return;
                            }

                            final newWh = Warehouse(
                              id: warehouse?.id ?? generateUuidV4(),
                              code: codeCtrl.text.trim(),
                              name: nameCtrl.text.trim(),
                              isDefault: isDefault,
                              costValuationMethod: costValuationMethod,
                              address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              managerName: managerCtrl.text.trim().isEmpty ? null : managerCtrl.text.trim(),
                              version: warehouse?.version ?? 1,
                            );

                            Navigator.of(ctx).pop();
                            final success = await ref.read(warehouseControllerProvider.notifier).saveWarehouse(newWh);
                            if (context.mounted && success) {
                              showAppSnackBar(
                                context,
                                message: isAr ? 'تم حفظ المستودع بنجاح' : 'Warehouse saved successfully',
                                isSuccess: true,
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: Text(isAr ? 'حفظ البيانات' : 'Save Details'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _setDefaultWarehouse(BuildContext context, WidgetRef ref, Warehouse wh) async {
    final updated = wh.copyWith(isDefault: true);
    final success = await ref.read(warehouseControllerProvider.notifier).saveWarehouse(updated);
    if (context.mounted && success) {
      final l10n = AppLocalizations.of(context);
      showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'تم تعيين المستودع كافتراضي' : 'Set as default warehouse', isSuccess: true);
    }
  }

  void _confirmDeleteWarehouse(BuildContext context, WidgetRef ref, Warehouse wh) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.localeName == 'ar' ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(
          l10n.localeName == 'ar'
              ? 'هل أنت تأكد من رغبتك في حذف المستودع "${wh.name}"؟'
              : 'Are you sure you want to delete warehouse "${wh.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.localeName == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(warehouseControllerProvider.notifier).deleteWarehouse(wh.id);
              if (context.mounted && success) {
                showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'تم حذف المستودع بنجاح' : 'Warehouse deleted successfully', isSuccess: true);
              }
            },
            child: Text(l10n.localeName == 'ar' ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
