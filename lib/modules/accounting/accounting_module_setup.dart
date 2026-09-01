import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/modules/module_setup_definition.dart';
import 'shared/presentation/providers/currency_providers.dart';
import 'shared/presentation/widgets/account_picker_dropdown.dart';
import 'shared/domain/services/account_mapping_resolver.dart';

final accountingSetupSteps = [
  ModuleSetupStepDefinition(
    id: 'accounting_currencies_setup_step',
    moduleId: 'accounting',
    titleAr: 'دليل العملات والعملة الافتراضية',
    titleEn: 'Currencies & Default Currency',
    descriptionAr: 'تحديد العملات المعتمدة والعملة الأساسية للنظام',
    descriptionEn: 'Configure active currencies and primary system currency',
    icon: Icons.currency_exchange,
    sortOrder: 10,
    builder: (context, ref) {
      final currenciesAsync = ref.watch(allCurrenciesProvider);
      return currenciesAsync.when(
        data: (currencies) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'العملات المعرفة في النظام:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final c in currencies)
              ListTile(
                dense: true,
                leading: CircleAvatar(child: Text(c.symbol)),
                title: Text('${c.nameAr} (${c.code})'),
                trailing: c.isDefault
                    ? const Chip(label: Text('العملة الافتراضية'))
                    : null,
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Error: $err'),
      );
    },
  ),
  ModuleSetupStepDefinition(
    id: 'accounting_role_mapping_setup_step',
    moduleId: 'accounting',
    titleAr: 'ربط الحسابات الافتراضية',
    titleEn: 'Chart of Accounts Mapping',
    descriptionAr: 'اختيار الحسابات التلقائية لعمليات النظام من شجرة الحسابات',
    descriptionEn: 'Map automatic operational accounts from CoA tree',
    icon: Icons.account_tree_outlined,
    sortOrder: 20,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تخصيص الحسابات المحاسبية:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          AccountPickerDropdown(
            label: 'حساب المخزون (أصول متداولة)',
            role: AccountRole.inventory,
          ),
          SizedBox(height: 12),
          AccountPickerDropdown(
            label: 'حساب إيراد المبيعات',
            role: AccountRole.revenue,
          ),
        ],
      );
    },
  ),
];
