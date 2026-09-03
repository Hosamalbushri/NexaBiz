import 'package:flutter/material.dart';
import '../../core/domain/entities/account_role.dart';
import '../../core/domain/ports/setup_account_lookup_port.dart';
import '../../core/modules/module_setup_definition.dart';
import '../../core/setup/setup.dart';

/// Declarative account requirements for the Inventory package.
const inventoryAccountRequirement = AccountRequirement(
  packageId: 'inventory',
  requirementKey: 'inventory_asset_account',
  role: AccountRole.inventory,
  labelAr: 'حساب تقييم المخزون (أصول)',
  labelEn: 'Inventory Asset Account',
  isRequired: true,
  expectedAccountType: SetupAccountType.asset,
);

const cogsAccountRequirement = AccountRequirement(
  packageId: 'inventory',
  requirementKey: 'cogs_account',
  role: AccountRole.cogs,
  labelAr: 'حساب تكلفة البضاعة المباعة (مصروفات)',
  labelEn: 'Cost of Goods Sold (COGS) Account',
  isRequired: true,
  expectedAccountType: SetupAccountType.expense,
);

const inventoryVarianceAccountRequirement = AccountRequirement(
  packageId: 'inventory',
  requirementKey: 'inventory_variance_account',
  role: AccountRole.adjustment,
  labelAr: 'حساب تسويات وانحرافات المخزون',
  labelEn: 'Inventory Variance & Adjustment Account',
  isRequired: false,
  expectedAccountType: SetupAccountType.expense,
);

/// Central setup definition contributed by the Inventory business package.
final inventoryPackageSetupDefinition = PackageSetupDefinition(
  packageId: 'inventory',
  displayNameAr: 'إعدادات المخزون',
  displayNameEn: 'Inventory Setup',
  sortOrder: 20,
  sections: const [
    SetupSection(
      id: 'currency',
      packageId: 'inventory',
      titleAr: 'عملة تقييم المخزون',
      titleEn: 'Inventory Valuation Currency',
      descriptionAr: 'تحديد العملة الأساسية لاحتساب تكلفة وتقييم المخزون',
      descriptionEn: 'Select base currency for inventory cost calculation and valuation',
      fields: [
        SetupField(
          id: 'inventoryValuationCurrencyId',
          sectionId: 'currency',
          key: 'inventoryValuationCurrencyId',
          labelAr: 'عملة تقييم المخزون الوحيدة',
          labelEn: 'Inventory Base Valuation Currency',
          fieldType: SetupFieldType.select,
          isRequired: true,
          defaultValue: 'SAR',
        ),
      ],
    ),
    SetupSection(
      id: 'costing_policy',
      packageId: 'inventory',
      titleAr: 'سياسات تقييم التكلفة والكميات',
      titleEn: 'Costing & Quantity Policies',
      descriptionAr: 'طريقة احتساب التكلفة وسياسة المنع عند نفاذ الرصيد ودقة الأرقام',
      descriptionEn: 'Costing method (FIFO / WAC), negative stock policy, and decimal precision',
      fields: [
        SetupField(
          id: 'defaultCostingMethod',
          sectionId: 'costing_policy',
          key: 'defaultCostingMethod',
          labelAr: 'طريقة احتساب التكلفة',
          labelEn: 'Costing Method',
          fieldType: SetupFieldType.select,
          allowedValues: ['FIFO', 'WAC'],
          defaultValue: 'FIFO',
        ),
        SetupField(
          id: 'allowNegativeStock',
          sectionId: 'costing_policy',
          key: 'allowNegativeStock',
          labelAr: 'السماح بالسحب بالسالب',
          labelEn: 'Allow Negative Stock',
          fieldType: SetupFieldType.boolean,
          defaultValue: false,
        ),
        SetupField(
          id: 'quantityPrecision',
          sectionId: 'costing_policy',
          key: 'quantityPrecision',
          labelAr: 'دقة أرقام الكمية',
          labelEn: 'Quantity Precision',
          fieldType: SetupFieldType.number,
          defaultValue: 2,
        ),
        SetupField(
          id: 'costPrecision',
          sectionId: 'costing_policy',
          key: 'costPrecision',
          labelAr: 'دقة أرقام التكلفة',
          labelEn: 'Cost Precision',
          fieldType: SetupFieldType.number,
          defaultValue: 2,
        ),
      ],
    ),
    SetupSection(
      id: 'warehouse',
      packageId: 'inventory',
      titleAr: 'المستودع الافتراضي',
      titleEn: 'Default Warehouse',
      descriptionAr: 'تحديد المستودع الافتراضي لحركات المخزون الرئيسية',
      descriptionEn: 'Select default primary warehouse location for stock movements',
      fields: [
        SetupField(
          id: 'defaultWarehouseId',
          sectionId: 'warehouse',
          key: 'defaultWarehouseId',
          labelAr: 'المستودع الرئيسي',
          labelEn: 'Default Primary Warehouse',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
      ],
    ),
    SetupSection(
      id: 'account_requirements',
      packageId: 'inventory',
      titleAr: 'ربط حسابات المخزون',
      titleEn: 'Inventory Account Bindings',
      descriptionAr: 'ربط الحسابات المطلوبة للعمليات المالية الخاصة بالمخزون',
      descriptionEn: 'Bind required financial accounts for inventory operations',
      fields: [
        SetupField(
          id: 'inventory_asset_account',
          sectionId: 'account_requirements',
          key: 'inventory_asset_account',
          labelAr: 'حساب تقييم المخزون (أصول)',
          labelEn: 'Inventory Asset Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
        SetupField(
          id: 'cogs_account',
          sectionId: 'account_requirements',
          key: 'cogs_account',
          labelAr: 'حساب تكلفة البضاعة المباعة (مصروفات)',
          labelEn: 'Cost of Goods Sold (COGS) Account',
          fieldType: SetupFieldType.reference,
          isRequired: true,
        ),
        SetupField(
          id: 'inventory_variance_account',
          sectionId: 'account_requirements',
          key: 'inventory_variance_account',
          labelAr: 'حساب تسويات المخزون',
          labelEn: 'Inventory Variance Account',
          fieldType: SetupFieldType.reference,
          isRequired: false,
        ),
      ],
    ),
  ],
);

/// Registers Inventory's setup definition into [registry].
void registerInventorySetup(CentralSetupRegistry registry) {
  registry.register(inventoryPackageSetupDefinition);
}

/// Legacy module setup step definitions preserved for backward compatibility.
final inventorySetupSteps = [
  ModuleSetupStepDefinition(
    id: 'inventory_base_currency_warehouse_step',
    moduleId: 'inventory',
    titleAr: 'عملة المخزون والمستودع الافتراضي',
    titleEn: 'Inventory Base Currency & Warehouse',
    descriptionAr: 'تحديد عملة وحيدة لاحتساب تكلفة الأصناف والمستودع الرئيسي',
    descriptionEn: 'Select single base currency for inventory costing and default warehouse',
    icon: Icons.warehouse_outlined,
    sortOrder: 30,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عملة المخزون الأساسية (Single-Choice):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'تعتمد جميع حركات تقييم المخزون وتكلفة الأصناف (WAC / FIFO) على عملة وحيدة ثابتة.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    },
  ),
  ModuleSetupStepDefinition(
    id: 'inventory_costing_policy_step',
    moduleId: 'inventory',
    titleAr: 'سياسات تقييم المخزون',
    titleEn: 'Inventory Valuation Policies',
    descriptionAr: 'طريقة احتساب التكلفة وسياسة المنع عند نفاذ الرصيد',
    descriptionEn: 'Costing method (FIFO / WAC) and negative stock prevention',
    icon: Icons.inventory_2_outlined,
    sortOrder: 40,
    builder: (context, ref) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سياسة تقييم التكلفة: المتوسط المرجح (WAC)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    },
  ),
];
