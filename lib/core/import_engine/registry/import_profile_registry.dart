import '../import_engine.dart';
import '../../../modules/accounting/chart_of_accounts/import/account_import_profile.dart';
import '../../../modules/inventory/products/import/product_import_profile.dart';

/// Registry holding all available [ImportProfile] definitions across NexaBiz.
class ImportProfileRegistry {
  ImportProfileRegistry._();

  static final Map<String, ImportProfile> _profiles = {
    AccountImportProfile.profileId: AccountImportProfile.createProfile(),
    ProductImportProfile.profileId: ProductImportProfile.createProfile(),
    _customersProfile.profileId: _customersProfile,
    _suppliersProfile.profileId: _suppliersProfile,
    _employeesProfile.profileId: _employeesProfile,
    _warehousesProfile.profileId: _warehousesProfile,
    _inventoryOpeningProfile.profileId: _inventoryOpeningProfile,
  };

  /// Registers or overrides a profile definition.
  static void registerProfile(ImportProfile profile) {
    _profiles[profile.profileId] = profile;
  }

  /// Returns all registered profiles.
  static List<ImportProfile> get allProfiles => _profiles.values.toList();

  /// Returns a profile by its ID, or null if not registered.
  static ImportProfile? getProfile(String profileId) => _profiles[profileId];

  /// Returns profiles matching an entity type.
  static List<ImportProfile> getProfilesForEntity(String entityType) {
    return _profiles.values
        .where((p) => p.entityType.toLowerCase() == entityType.toLowerCase())
        .toList();
  }

  // --- Static Supplementary Profiles for Complete ERP Scope ---

  static final ImportProfile _customersProfile = ImportProfile(
    profileId: 'PROF-CUSTOMERS',
    entityType: 'Customer',
    label: 'Customers Directory Import',
    requiredPermission: 'customers.import',
    defaultPolicy: const ImportPolicy(
      duplicateResolution: DuplicateResolutionStrategy.overwrite,
      createMissingRelations: true,
    ),
    fields: const [
      ImportField(
        key: 'name',
        label: 'Customer Name',
        dataType: ImportDataType.text,
        isRequired: true,
        aliases: [
          'Customer Name',
          'Name',
          'Company Name',
          'اسم العميل',
          'العميل',
        ],
      ),
      ImportField(
        key: 'code',
        label: 'Customer Code',
        dataType: ImportDataType.text,
        isUnique: true,
        aliases: [
          'Customer Code',
          'Code',
          'Account No',
          'كود العميل',
          'رقم العميل',
        ],
      ),
      ImportField(
        key: 'phone',
        label: 'Phone Number',
        dataType: ImportDataType.text,
        aliases: [
          'Phone',
          'Mobile',
          'Telephone',
          'الهاتف',
          'الجوال',
          'رقم الهاتف',
        ],
      ),
      ImportField(
        key: 'email',
        label: 'Email Address',
        dataType: ImportDataType.text,
        aliases: ['Email', 'E-mail', 'البريد الإلكتروني', 'البريد'],
      ),
      ImportField(
        key: 'taxNumber',
        label: 'Tax Registration Number (VAT)',
        dataType: ImportDataType.text,
        aliases: ['Tax Number', 'VAT Number', 'TRN', 'الرقم الضريبي'],
      ),
      ImportField(
        key: 'address',
        label: 'Address',
        dataType: ImportDataType.text,
        aliases: ['Address', 'Street', 'City', 'العنوان'],
      ),
      ImportField(
        key: 'creditLimit',
        label: 'Credit Limit',
        dataType: ImportDataType.number,
        aliases: ['Credit Limit', 'Limit', 'حد الائتمان'],
      ),
    ],
  );

  static final ImportProfile _suppliersProfile = ImportProfile(
    profileId: 'PROF-SUPPLIERS',
    entityType: 'Supplier',
    label: 'Suppliers Directory Import',
    requiredPermission: 'suppliers.import',
    defaultPolicy: const ImportPolicy(
      duplicateResolution: DuplicateResolutionStrategy.overwrite,
      createMissingRelations: true,
    ),
    fields: const [
      ImportField(
        key: 'name',
        label: 'Supplier Name',
        dataType: ImportDataType.text,
        isRequired: true,
        aliases: [
          'Supplier Name',
          'Vendor',
          'Vendor Name',
          'اسم المورد',
          'المورد',
        ],
      ),
      ImportField(
        key: 'code',
        label: 'Supplier Code',
        dataType: ImportDataType.text,
        isUnique: true,
        aliases: [
          'Supplier Code',
          'Code',
          'Vendor Code',
          'كود المورد',
          'رقم المورد',
        ],
      ),
      ImportField(
        key: 'phone',
        label: 'Phone Number',
        dataType: ImportDataType.text,
        aliases: ['Phone', 'Mobile', 'Telephone', 'الهاتف', 'الجوال'],
      ),
      ImportField(
        key: 'email',
        label: 'Email Address',
        dataType: ImportDataType.text,
        aliases: ['Email', 'E-mail', 'البريد الإلكتروني'],
      ),
      ImportField(
        key: 'taxNumber',
        label: 'Tax Number',
        dataType: ImportDataType.text,
        aliases: ['Tax Number', 'VAT Number', 'TRN', 'الرقم الضريبي'],
      ),
    ],
  );

  static final ImportProfile _employeesProfile = ImportProfile(
    profileId: 'PROF-EMPLOYEES',
    entityType: 'Employee',
    label: 'Employees Directory Import',
    requiredPermission: 'hr.employees.import',
    defaultPolicy: const ImportPolicy(
      duplicateResolution: DuplicateResolutionStrategy.skip,
    ),
    fields: const [
      ImportField(
        key: 'name',
        label: 'Full Name',
        dataType: ImportDataType.text,
        isRequired: true,
        aliases: [
          'Employee Name',
          'Full Name',
          'Name',
          'اسم الموظف',
          'الاسم كامل',
        ],
      ),
      ImportField(
        key: 'employeeCode',
        label: 'Employee ID / Code',
        dataType: ImportDataType.text,
        isRequired: true,
        isUnique: true,
        aliases: [
          'Employee ID',
          'Code',
          'Staff ID',
          'رقم الموظف',
          'كود الموظف',
        ],
      ),
      ImportField(
        key: 'department',
        label: 'Department',
        dataType: ImportDataType.text,
        aliases: ['Department', 'Dept', 'القسم', 'الإدارة'],
      ),
      ImportField(
        key: 'jobTitle',
        label: 'Job Title',
        dataType: ImportDataType.text,
        aliases: ['Job Title', 'Position', 'المسمى الوظيفي', 'الوظيفة'],
      ),
      ImportField(
        key: 'salary',
        label: 'Basic Salary',
        dataType: ImportDataType.number,
        aliases: ['Basic Salary', 'Salary', 'الراتب الأساسي', 'الراتب'],
      ),
    ],
  );

  static final ImportProfile _warehousesProfile = ImportProfile(
    profileId: 'PROF-WAREHOUSES',
    entityType: 'Warehouse',
    label: 'Warehouses Catalog Import',
    requiredPermission: 'inventory.warehouses.import',
    defaultPolicy: const ImportPolicy(
      duplicateResolution: DuplicateResolutionStrategy.overwrite,
    ),
    fields: const [
      ImportField(
        key: 'name',
        label: 'Warehouse Name',
        dataType: ImportDataType.text,
        isRequired: true,
        aliases: [
          'Warehouse Name',
          'Store Name',
          'Name',
          'اسم المستودع',
          'المخزن',
        ],
      ),
      ImportField(
        key: 'code',
        label: 'Warehouse Code',
        dataType: ImportDataType.text,
        isUnique: true,
        aliases: [
          'Warehouse Code',
          'Code',
          'Store Code',
          'كود المستودع',
          'رمز المخزن',
        ],
      ),
      ImportField(
        key: 'location',
        label: 'Location / Branch',
        dataType: ImportDataType.text,
        aliases: ['Location', 'Branch', 'City', 'الموقع', 'الفرع'],
      ),
    ],
  );

  static final ImportProfile _inventoryOpeningProfile = ImportProfile(
    profileId: 'PROF-INVENTORY-BALANCES',
    entityType: 'InventoryBalance',
    label: 'Inventory Opening Balances Import',
    requiredPermission: 'inventory.opening.import',
    defaultPolicy: const ImportPolicy(
      duplicateResolution: DuplicateResolutionStrategy.overwrite,
    ),
    fields: const [
      ImportField(
        key: 'itemCode',
        label: 'Item Code / SKU',
        dataType: ImportDataType.text,
        isRequired: true,
        aliases: ['Item Code', 'SKU', 'Product Code', 'كود المنتج'],
      ),
      ImportField(
        key: 'warehouseCode',
        label: 'Warehouse Code',
        dataType: ImportDataType.text,
        isRequired: true,
        aliases: ['Warehouse', 'Warehouse Code', 'Store Code', 'كود المستودع'],
      ),
      ImportField(
        key: 'quantity',
        label: 'Opening Quantity',
        dataType: ImportDataType.number,
        isRequired: true,
        aliases: [
          'Quantity',
          'Qty',
          'Stock Qty',
          'الكمية الافتتاحية',
          'الكمية',
        ],
      ),
      ImportField(
        key: 'unitCost',
        label: 'Unit Cost',
        dataType: ImportDataType.number,
        isRequired: true,
        aliases: ['Unit Cost', 'Cost', 'سعر التكلفة', 'التكلفة'],
      ),
    ],
    relations: const [
      ImportRelation(
        relationKey: 'itemCode',
        targetEntityType: 'Product',
        lookupFieldKey: 'itemCode',
        isRequired: true,
      ),
      ImportRelation(
        relationKey: 'warehouseCode',
        targetEntityType: 'Warehouse',
        lookupFieldKey: 'code',
        isRequired: true,
      ),
    ],
  );
}
