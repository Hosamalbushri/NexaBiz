import '../../../../../core/import_engine/import_engine.dart';

/// Factory and definition helper for Product entity import profiles.
class ProductImportProfile {
  ProductImportProfile._();

  static const String profileId = 'PROF-INVENTORY-PRODUCT';
  static const String entityType = 'Product';
  static const String label = 'Products Import Catalog';

  /// Creates a standard, fully configured [ImportProfile] for Products.
  static ImportProfile createProfile({
    ImportPolicy? defaultPolicy,
    String? requiredPermission,
    List<ImportRelation>? customRelations,
  }) {
    return ImportProfile(
      profileId: profileId,
      entityType: entityType,
      label: label,
      requiredPermission: requiredPermission ?? 'inventory.products.import',
      defaultPolicy: defaultPolicy ??
          const ImportPolicy(
            duplicateResolution: DuplicateResolutionStrategy.overwrite,
            createMissingRelations: true,
          ),
      fields: const [
        // Product Name (Required)
        ImportField(
          key: 'name',
          label: 'Product Name',
          dataType: ImportDataType.text,
          isRequired: true,
          aliases: ['Product Name', 'Name', 'Item Name', 'Description', 'اسم المنتج', 'الاسم'],
        ),
        // Item Code / SKU (Required & Unique)
        ImportField(
          key: 'itemCode',
          label: 'Item Code / SKU',
          dataType: ImportDataType.text,
          isRequired: true,
          isUnique: true,
          aliases: ['Item Code', 'SKU', 'Product Code', 'Code', 'كود المنتج', 'رمز المنتج', 'الرمز'],
        ),
        // Barcode (Optional)
        ImportField(
          key: 'barcode',
          label: 'Barcode',
          dataType: ImportDataType.text,
          aliases: ['Barcode', 'EAN', 'UPC', 'الباركود', 'باركود'],
        ),
        // Unit Cost (Optional, default 0)
        ImportField(
          key: 'unitCost',
          label: 'Unit Cost',
          dataType: ImportDataType.number,
          aliases: ['Unit Cost', 'Cost', 'Purchase Price', 'Cost Price', 'التكلفة', 'سعر التكلفة'],
        ),
        // Selling Price (Required)
        ImportField(
          key: 'price',
          label: 'Selling Price',
          dataType: ImportDataType.number,
          isRequired: true,
          aliases: ['Selling Price', 'Price', 'Retail Price', 'Sale Price', 'السعر', 'سعر البيع'],
        ),
        // On Hand Quantity (Optional, default 0)
        ImportField(
          key: 'onHandQty',
          label: 'On-Hand Quantity',
          dataType: ImportDataType.number,
          aliases: ['On-Hand Quantity', 'Quantity', 'Qty', 'Stock Qty', 'Initial Qty', 'الكمية', 'الكمية الحالية'],
        ),
        // Pack Size / Unit (Optional, default 1)
        ImportField(
          key: 'packSize',
          label: 'Pack Size / Unit',
          dataType: ImportDataType.number,
          aliases: ['Pack Size', 'Unit', 'Box Size', 'Unit Qty', 'حجم العبوة', 'الوحدة'],
        ),
        // Brand (Optional)
        ImportField(
          key: 'brand',
          label: 'Brand',
          dataType: ImportDataType.text,
          aliases: ['Brand', 'Manufacturer', 'Make', 'العلامة التجارية', 'الماركة'],
        ),
        // Tax Rate / Code (Optional)
        ImportField(
          key: 'tax',
          label: 'Tax',
          dataType: ImportDataType.text,
          aliases: ['Tax', 'Tax Rate', 'VAT', 'Tax Code', 'الضريبة', 'نسبة الضريبة'],
        ),
        // Category Name / Code (Optional)
        ImportField(
          key: 'category',
          label: 'Category',
          dataType: ImportDataType.text,
          aliases: ['Category', 'Category Name', 'Category Code', 'Filing Category', 'التصنيف', 'الفئة'],
        ),
        // Warehouse (Optional)
        ImportField(
          key: 'warehouse',
          label: 'Warehouse',
          dataType: ImportDataType.text,
          aliases: ['Warehouse', 'Warehouse Name', 'Warehouse Code', 'Store', 'المستودع', 'المخزن'],
        ),
        // Supplier (Optional)
        ImportField(
          key: 'supplier',
          label: 'Supplier',
          dataType: ImportDataType.text,
          aliases: ['Supplier', 'Vendor', 'Supplier Name', 'المورد'],
        ),
        // Asset Account Reference
        ImportField(
          key: 'accountingAssetAccount',
          label: 'Asset Account',
          dataType: ImportDataType.text,
          aliases: ['Asset Account', 'Inventory Account', 'حساب الأصول'],
        ),
        // Income Account Reference
        ImportField(
          key: 'accountingIncomeAccount',
          label: 'Income Account',
          dataType: ImportDataType.text,
          aliases: ['Income Account', 'Sales Account', 'Revenue Account', 'حساب المبيعات'],
        ),
        // Expense Account Reference
        ImportField(
          key: 'accountingExpenseAccount',
          label: 'Expense Account',
          dataType: ImportDataType.text,
          aliases: ['Expense Account', 'COGS Account', 'Cost Account', 'حساب المصروفات'],
        ),
      ],
      relations: customRelations ??
          const [
            ImportRelation(
              relationKey: 'category',
              targetEntityType: 'Category',
              lookupFieldKey: 'name',
              isRequired: false,
            ),
            ImportRelation(
              relationKey: 'warehouse',
              targetEntityType: 'Warehouse',
              lookupFieldKey: 'name',
              isRequired: false,
            ),
            ImportRelation(
              relationKey: 'supplier',
              targetEntityType: 'Supplier',
              lookupFieldKey: 'name',
              isRequired: false,
            ),
            ImportRelation(
              relationKey: 'accountingAssetAccount',
              targetEntityType: 'Account',
              lookupFieldKey: 'code',
              isRequired: false,
            ),
            ImportRelation(
              relationKey: 'accountingIncomeAccount',
              targetEntityType: 'Account',
              lookupFieldKey: 'code',
              isRequired: false,
            ),
            ImportRelation(
              relationKey: 'accountingExpenseAccount',
              targetEntityType: 'Account',
              lookupFieldKey: 'code',
              isRequired: false,
            ),
          ],
    );
  }
}
