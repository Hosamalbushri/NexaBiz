import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';

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
                        Text(
                          wh.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    final isEditing = warehouse != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(
              isEditing
                  ? (l10n.localeName == 'ar' ? 'تعديل المستودع' : 'Edit Warehouse')
                  : (l10n.localeName == 'ar' ? 'إضافة مستودع جديد' : 'Add New Warehouse'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.localeName == 'ar' ? 'كود المستودع' : 'Warehouse Code',
                      hintText: 'WH-01',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.localeName == 'ar' ? 'اسم المستودع' : 'Warehouse Name',
                      hintText: 'المستودع الرئيسي',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: managerCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.localeName == 'ar' ? 'أمين / مدير المستودع' : 'Warehouse Manager',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.localeName == 'ar' ? 'رقم الهاتف' : 'Phone Number',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.localeName == 'ar' ? 'العنوان / الموقع' : 'Address / Location',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (val) => setStateDialog(() => isDefault = val ?? false),
                    title: Text(l10n.localeName == 'ar' ? 'تعيين كمستودع افتراضي' : 'Set as Default Warehouse'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.localeName == 'ar' ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                    showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'يرجى إدخال كود واسم المستودع' : 'Please enter code and name', isSuccess: false);
                    return;
                  }

                  final newWh = Warehouse(
                    id: warehouse?.id ?? generateUuidV4(),
                    code: codeCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    isDefault: isDefault,
                    address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    managerName: managerCtrl.text.trim().isEmpty ? null : managerCtrl.text.trim(),
                    version: warehouse?.version ?? 1,
                  );

                  Navigator.of(ctx).pop();
                  final success = await ref.read(warehouseControllerProvider.notifier).saveWarehouse(newWh);
                  if (context.mounted && success) {
                    showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'تم حفظ المستودع بنجاح' : 'Warehouse saved successfully', isSuccess: true);
                  }
                },
                child: Text(l10n.localeName == 'ar' ? 'حفظ' : 'Save'),
              ),
            ],
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
