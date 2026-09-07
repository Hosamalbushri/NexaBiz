import 'package:flutter/material.dart';
import '../../core/domain/entities/account_role.dart';
import '../../core/domain/ports/setup_account_lookup_port.dart';
import '../../core/modules/module_setup_definition.dart';
import '../../core/setup/setup.dart';

/// Declarative account requirements for the Purchases package.
const payableAccountRequirement = AccountRequirement(
  packageId: 'purchases',
  requirementKey: 'payable_account',
  role: AccountRole.payable,
  labelAr: 'حساب الذمم الدائنة / الموردين (التزامات)',
  labelEn: 'Accounts Payable / Suppliers Account',
  isRequired: true,
  bindingMode: AccountBindingMode.parent,
  expectedAccountType: SetupAccountType.liability,
);

const purchaseInventoryAccountRequirement = AccountRequirement(
  packageId: 'purchases',
  requirementKey: 'purchase_inventory_account',
  role: AccountRole.inventory,
  labelAr: 'حساب تقييم استلام المشتريات (أصول)',
  labelEn: 'Purchases Inventory Asset Account',
  isRequired: true,
  expectedAccountType: SetupAccountType.asset,
);

const purchaseDiscountAccountRequirement = AccountRequirement(
  packageId: 'purchases',
  requirementKey: 'purchase_discount_account',
  role: AccountRole.discount,
  labelAr: 'حساب المكتسب / خصم المشتريات',
  labelEn: 'Purchase Discount / Earned Discount Account',
  isRequired: false,
  expectedAccountType: SetupAccountType.revenue,
);

const purchaseCashAccountRequirement = AccountRequirement(
  packageId: 'purchases',
  requirementKey: 'purchase_cash_account',
  role: AccountRole.cash,
  labelAr: 'حساب السداد النقدي للمشتريات',
  labelEn: 'Purchase Cash Account',
  isRequired: false,
  bindingMode: AccountBindingMode.parent,
  expectedAccountType: SetupAccountType.asset,
);

const purchaseBankAccountRequirement = AccountRequirement(
  packageId: 'purchases',
  requirementKey: 'purchase_bank_account',
  role: AccountRole.cash,
  labelAr: 'حساب السداد البنكي للمشتريات',
  labelEn: 'Purchase Bank Account',
  isRequired: false,
  bindingMode: AccountBindingMode.parent,
  expectedAccountType: SetupAccountType.asset,
);

/// Central setup definition contributed by the Purchases business package.
final purchasesPackageSetupDefinition = PackageSetupDefinition(
  packageId: 'purchases',
  displayNameAr: 'إعدادات المشتريات',
  displayNameEn: 'Purchases Setup',
  sortOrder: 35,
  sections: const [
    SetupSection(
      id: 'purchases_policies',
      packageId: 'purchases',
      titleAr: 'سياسات فواتير واستلام المشتريات',
      titleEn: 'Purchases & Receiving Controls',
      descriptionAr:
          'اشتراط مطابقة أمر الشراء، السماح بالاستلام الجزئي، والتحكم بالفروقات',
      descriptionEn:
          'Purchase Order matching rules, partial receiving policy, and variance tolerances',
      fields: [
        SetupField(
          id: 'requirePurchaseOrderMatching',
          sectionId: 'purchases_policies',
          key: 'requirePurchaseOrderMatching',
          labelAr: 'اشتراط مطابقة الفاتورة مع أمر الشراء',
          labelEn: 'Require Invoice to PO Matching',
          fieldType: SetupFieldType.boolean,
          defaultValue: false,
        ),
        SetupField(
          id: 'allowPartialReceiving',
          sectionId: 'purchases_policies',
          key: 'allowPartialReceiving',
          labelAr: 'السماح بالاستلام الجزئي للشحنة',
          labelEn: 'Allow Partial Shipment Receiving',
          fieldType: SetupFieldType.boolean,
          defaultValue: true,
        ),
      ],
    ),
    SetupSection(
      id: 'account_requirements',
      packageId: 'purchases',
      titleAr: 'ربط حسابات المشتريات والموردين',
      titleEn: 'Purchases Account Bindings',
      descriptionAr:
          'ربط حسابات الموردين والاستلام النقدي والخصم المكتسب من دليل الحسابات',
      descriptionEn:
          'Bind Accounts Payable, inventory valuation, cash, and discount accounts from Chart of Accounts',
      fields: [
        SetupField(
          id: 'payable_account',
          sectionId: 'account_requirements',
          key: 'payable_account',
          labelAr: 'حساب الذمم الدائنة / الموردين',
          labelEn: 'Accounts Payable Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
        SetupField(
          id: 'purchase_inventory_account',
          sectionId: 'account_requirements',
          key: 'purchase_inventory_account',
          labelAr: 'حساب تقييم المخزون المستلم',
          labelEn: 'Purchases Inventory Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
        SetupField(
          id: 'purchase_discount_account',
          sectionId: 'account_requirements',
          key: 'purchase_discount_account',
          labelAr: 'حساب الخصم المكتسب',
          labelEn: 'Purchase Discount Account',
          fieldType: SetupFieldType.reference,
          isRequired: false,
        ),
        SetupField(
          id: 'purchase_cash_account',
          sectionId: 'account_requirements',
          key: 'purchase_cash_account',
          labelAr: 'حساب السداد النقدي للمشتريات',
          labelEn: 'Purchase Cash Account',
          fieldType: SetupFieldType.reference,
          isRequired: false,
        ),
      ],
    ),
  ],
);

/// Registers Purchases setup definition into [registry].
void registerPurchasesSetup(CentralSetupRegistry registry) {
  registry.register(purchasesPackageSetupDefinition);
}

/// Module setup step definitions preserved for backward compatibility.
final purchasesSetupSteps = [
  ModuleSetupStepDefinition(
    id: 'purchases_defaults_setup_step',
    moduleId: 'purchases',
    titleAr: 'إعدادات وسياسات المشتريات',
    titleEn: 'Purchases Defaults & Policies',
    descriptionAr: 'سياسات الاستلام، الخصومات المكتسبة، وقواعد الموردين',
    descriptionEn:
        'Receiving policies, earned discounts, and supplier controls',
    icon: Icons.shopping_bag_outlined,
    sortOrder: 45,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سياسات فواتير المشتريات:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'يتم ترحيل قيود المشتريات والموردين آلياً إلى الحسابات المحددة في دليل الحسابات.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    },
  ),
];
