import 'package:flutter/material.dart';
import '../../core/domain/entities/account_role.dart';
import '../../core/domain/ports/setup_account_lookup_port.dart';
import '../../core/modules/module_setup_definition.dart';
import '../../core/setup/setup.dart';

/// Declarative account requirements for the Sales package.
const salesAccountRequirement = AccountRequirement(
  packageId: 'sales',
  requirementKey: 'sales_account',
  role: AccountRole.revenue,
  labelAr: 'حساب مبيعات البضائع (إيرادات)',
  labelEn: 'Sales Revenue Account',
  isRequired: true,
  expectedAccountType: SetupAccountType.revenue,
);

const salesDiscountAccountRequirement = AccountRequirement(
  packageId: 'sales',
  requirementKey: 'sales_discount_account',
  role: AccountRole.discount,
  labelAr: 'حساب خصم المبيعات (خصم إيرادات)',
  labelEn: 'Sales Discount Account',
  isRequired: false,
  expectedAccountType: SetupAccountType.revenue,
);

const salesCashAccountRequirement = AccountRequirement(
  packageId: 'sales',
  requirementKey: 'sales_cash_account',
  role: AccountRole.cash,
  labelAr: 'حساب الصندوق/النقدية للمبيعات النقدية',
  labelEn: 'Sales Cash Account',
  isRequired: false,
  bindingMode: AccountBindingMode.parent,
  expectedAccountType: SetupAccountType.asset,
);

/// Central setup definition contributed by the Sales business package.
final salesPackageSetupDefinition = PackageSetupDefinition(
  packageId: 'sales',
  displayNameAr: 'إعدادات المبيعات',
  displayNameEn: 'Sales Setup',
  sortOrder: 30,
  sections: const [
    SetupSection(
      id: 'policies',
      packageId: 'sales',
      titleAr: 'سياسات فواتير المبيعات',
      titleEn: 'Sales Invoice Policies',
      descriptionAr: 'نسبة الضريبة الافتراضية وصلاحيات الخصم والتعديل',
      descriptionEn: 'Default tax rate, discount rules, and price modification rules',
      fields: [
        SetupField(
          id: 'defaultTaxRate',
          sectionId: 'policies',
          key: 'defaultTaxRate',
          labelAr: 'نسبة الضريبة الافتراضية (%)',
          labelEn: 'Default Tax Rate (%)',
          fieldType: SetupFieldType.number,
          defaultValue: 0.15,
        ),
        SetupField(
          id: 'allowPriceOverride',
          sectionId: 'policies',
          key: 'allowPriceOverride',
          labelAr: 'السماح بتعديل أسعار البيع للفاتورة',
          labelEn: 'Allow Price Modification on Invoice',
          fieldType: SetupFieldType.boolean,
          defaultValue: true,
        ),
        SetupField(
          id: 'allowInvoiceDiscount',
          sectionId: 'policies',
          key: 'allowInvoiceDiscount',
          labelAr: 'السماح بالخصم على مستوى الفاتورة',
          labelEn: 'Allow Overall Invoice Discount',
          fieldType: SetupFieldType.boolean,
          defaultValue: true,
        ),
      ],
    ),
    SetupSection(
      id: 'account_requirements',
      packageId: 'sales',
      titleAr: 'ربط حسابات المبيعات',
      titleEn: 'Sales Account Bindings',
      descriptionAr: 'ربط حساب الإيرادات وخصم المبيعات من دليل الحسابات',
      descriptionEn: 'Bind sales revenue and sales discount accounts from Chart of Accounts',
      fields: [
        SetupField(
          id: 'sales_account',
          sectionId: 'account_requirements',
          key: 'sales_account',
          labelAr: 'حساب مبيعات البضائع (إيرادات)',
          labelEn: 'Sales Revenue Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
        SetupField(
          id: 'sales_discount_account',
          sectionId: 'account_requirements',
          key: 'sales_discount_account',
          labelAr: 'حساب خصم المبيعات',
          labelEn: 'Sales Discount Account',
          fieldType: SetupFieldType.reference,
          isRequired: false,
        ),
        SetupField(
          id: 'sales_cash_account',
          sectionId: 'account_requirements',
          key: 'sales_cash_account',
          labelAr: 'حساب المبيعات النقدية',
          labelEn: 'Sales Cash Account',
          fieldType: SetupFieldType.reference,
          isRequired: false,
        ),
      ],
    ),
  ],
);

/// Registers Sales setup definition into [registry].
void registerSalesSetup(CentralSetupRegistry registry) {
  registry.register(salesPackageSetupDefinition);
}

/// Legacy module setup step definitions preserved for backward compatibility.
final salesSetupSteps = [
  ModuleSetupStepDefinition(
    id: 'sales_defaults_setup_step',
    moduleId: 'sales',
    titleAr: 'إعدادات وسياسات المبيعات',
    titleEn: 'Sales Defaults & Policies',
    descriptionAr: 'سياسات الأسعار، نسبة الضريبة الافتراضية، وخصومات الفواتير',
    descriptionEn: 'Default tax rate, pricing policies, and discount rules',
    icon: Icons.point_of_sale_outlined,
    sortOrder: 50,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سياسات فواتير المبيعات:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'يتم ترحيل قيود المبيعات آلياً إلى الحسابات المحددة في دليل الحسابات.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    },
  ),
];
