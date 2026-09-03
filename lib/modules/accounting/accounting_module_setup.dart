import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/modules/module_setup_definition.dart';
import '../../core/setup/setup.dart';
import 'shared/domain/services/account_mapping_resolver.dart';
import 'shared/presentation/providers/currency_providers.dart';
import 'shared/presentation/widgets/account_picker_dropdown.dart';

/// Declarative setup definition exposing Accounting setup requirements to the central orchestrator.
const accountingPackageSetupDefinition = PackageSetupDefinition(
  packageId: 'accounting',
  displayNameAr: 'إعدادات المحاسبة',
  displayNameEn: 'Accounting Setup',
  sortOrder: 10,
  sections: [
    SetupSection(
      id: 'currency',
      packageId: 'accounting',
      titleAr: 'دليل العملات والعملة الافتراضية',
      titleEn: 'Currencies & Default Currency',
      descriptionAr: 'تحديد العملات المعتمدة والعملة الأساسية للنظام',
      descriptionEn: 'Configure active currencies and primary system currency',
      sortOrder: 10,
      fields: [
        SetupField(
          id: 'default_currency_code',
          sectionId: 'currency',
          key: 'defaultCurrencyCode',
          labelAr: 'رمز العملة الافتراضية',
          labelEn: 'Default Currency Code',
          fieldType: SetupFieldType.text,
          isRequired: true,
          defaultValue: 'SAR',
        ),
      ],
    ),
    SetupSection(
      id: 'fiscal_period',
      packageId: 'accounting',
      titleAr: 'السنة المالية والافتتاح',
      titleEn: 'Fiscal Year & Period Opening',
      descriptionAr: 'تحديد الفترة المالية المغلقة وتاريخ الافتتاح',
      descriptionEn: 'Configure closed fiscal period date and opening setup',
      sortOrder: 20,
      fields: [
        SetupField(
          id: 'fiscal_closed_through',
          sectionId: 'fiscal_period',
          key: 'fiscalClosedThrough',
          labelAr: 'مغلق حتى تاريخ',
          labelEn: 'Closed Through Date',
          fieldType: SetupFieldType.text,
          isRequired: false,
        ),
      ],
    ),
    SetupSection(
      id: 'chart_of_accounts',
      packageId: 'accounting',
      titleAr: 'ربط الحسابات الافتراضية',
      titleEn: 'Chart of Accounts Mapping',
      descriptionAr: 'اختيار الحسابات التلقائية لعمليات النظام من شجرة الحسابات',
      descriptionEn: 'Map automatic operational accounts from CoA tree',
      sortOrder: 30,
      fields: [
        SetupField(
          id: 'inventory_account',
          sectionId: 'chart_of_accounts',
          key: 'account_role_inventory',
          labelAr: 'حساب المخزون (أصول متداولة)',
          labelEn: 'Inventory Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
        SetupField(
          id: 'revenue_account',
          sectionId: 'chart_of_accounts',
          key: 'account_role_revenue',
          labelAr: 'حساب إيراد المبيعات',
          labelEn: 'Revenue Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
      ],
    ),
    SetupSection(
      id: 'accounting_defaults',
      packageId: 'accounting',
      titleAr: 'الإعدادات المحاسبية الافتراضية',
      titleEn: 'Accounting Defaults & Settings',
      descriptionAr: 'إعدادات القيود والسندات الافتراضية',
      descriptionEn: 'General journal and voucher configuration defaults',
      sortOrder: 40,
      isOptional: true,
    ),
  ],
);

/// Registers the Accounting setup definition into [registry] if not already registered.
void registerAccountingSetup(CentralSetupRegistry registry) {
  if (!registry.isRegistered('accounting')) {
    registry.register(accountingPackageSetupDefinition);
  }
}

/// Legacy setup steps preserved for backward compatibility with existing UI wizard pages.
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
